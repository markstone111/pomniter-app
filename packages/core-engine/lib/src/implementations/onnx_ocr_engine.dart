/// ONNX-backed OCR engine using PaddleOCR PP-OCRv4 models.
///
/// Architecture:
///   1. **Detection model** (`ch_PP-OCRv4_det_infer.onnx`): A DB (Differentiable
///      Binarization) network that outputs a probability map of text regions.
///      Input: [1, 3, H, W] float32 (H and W are multiples of 32, max 960).
///      Output: [1, 1, H, W] — probability heatmap.
///
///   2. **Recognition model** (`ch_PP-OCRv4_rec_infer.onnx`): SVTR-LCNet that
///      decodes a cropped text-line image to character sequences via CTC.
///      Input: [1, 3, 48, W'] float32.
///      Output: [1, T, vocab_size] float32 — CTC logits.
///
/// This implementation is production-wired — it will run real inference when
/// valid model paths are provided. If the models are not yet downloaded,
/// [initialize] throws [ModelLoadException] with a clear message.
///
/// See also:
///   - [MockOcrEngine] for zero-dependency testing.
///   - [ModelDownloadManager] for downloading models on first launch.
library;

import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:onnxruntime/onnxruntime.dart';

import '../exceptions/engine_exceptions.dart';
import '../interfaces/ocr_engine.dart';
import 'package:pomniter_shared_models/pomniter_shared_models.dart';

/// Maximum image dimension fed to the detection model (must be multiple of 32).
const int _kDetMaxSide = 960;
const int _kDetMinSide = 64;

/// Height of the recognition model input strip (PP-OCRv4 rec: 48 px).
const int _kRecHeight = 48;

/// Minimum confidence to include a text block in the result.
const double _kMinBlockConfidence = 0.5;

/// ONNX-backed PaddleOCR PP-OCRv4 implementation.
///
/// Requires two ONNX model files. Obtain them via [ModelDownloadManager]:
///   - `ch_PP-OCRv4_det_infer.onnx` — text detection (~4.9 MB INT8)
///   - `ch_PP-OCRv4_rec_infer.onnx` — text recognition (~10 MB INT8)
///
/// Example:
/// ```dart
/// final engine = OnnxOcrEngine(
///   detectorModelPath: '/data/user/0/.../models/det.onnx',
///   recognizerModelPath: '/data/user/0/.../models/rec.onnx',
///   characterDictPath: '/data/user/0/.../models/ppocr_keys_v1.txt',
/// );
/// await engine.initialize();
/// final result = await engine.extractText('/path/to/screenshot.png');
/// ```
class OnnxOcrEngine implements OcrEngine {
  final String detectorModelPath;
  final String recognizerModelPath;
  final String characterDictPath;

  OrtSession? _detSession;
  OrtSession? _recSession;
  List<String> _charset = [];
  bool _isInitialized = false;

  OnnxOcrEngine({
    required this.detectorModelPath,
    required this.recognizerModelPath,
    required this.characterDictPath,
  });

  // ─── OcrEngine Interface ──────────────────────────────────────────────────

  @override
  Future<void> initialize() async {
    try {
      OrtEnv.instance.init();

      final sessionOptions = OrtSessionOptions()
        ..setInterOpNumThreads(1)
        ..setIntraOpNumThreads(2)
        ..setSessionGraphOptimizationLevel(GraphOptimizationLevel.ortEnableAll);

      _detSession = OrtSession.fromFile(
        File(detectorModelPath),
        sessionOptions,
      );
      _recSession = OrtSession.fromFile(
        File(recognizerModelPath),
        sessionOptions,
      );

      _charset = await _loadCharset(characterDictPath);
      _isInitialized = true;
    } catch (e, st) {
      throw ModelLoadException(
        'OCR initialization failed: $e',
        modelPath: detectorModelPath,
        cause: e,
        stackTrace: st,
      );
    }
  }

  @override
  Future<OcrResult> extractText(String imagePath) async {
    _assertInitialized();

    try {
      final raw = await File(imagePath).readAsBytes();
      final srcImage = img.decodeImage(raw);
      if (srcImage == null) {
        throw OcrEngineException('Cannot decode image at $imagePath');
      }

      // ── Step 1: Detection ────────────────────────────────────────────────
      final detBoxes = await _runDetection(srcImage);
      if (detBoxes.isEmpty) {
        return const OcrResult(fullText: '', blocks: [], averageConfidence: 1.0);
      }

      // ── Step 2: Recognition per detected box ─────────────────────────────
      final blocks = <TextBlock>[];
      final textParts = <String>[];
      double totalConf = 0.0;

      for (final box in detBoxes) {
        final cropped = _cropTextRegion(srcImage, box);
        final (text, conf) = await _runRecognition(cropped);
        if (conf >= _kMinBlockConfidence && text.isNotEmpty) {
          blocks.add(TextBlock(
            text: text,
            confidence: conf,
            boundingBox: BoundingBox(
              left: box['x']!.toDouble(),
              top: box['y']!.toDouble(),
              width: box['w']!.toDouble(),
              height: box['h']!.toDouble(),
            ),
          ));
          textParts.add(text);
          totalConf += conf;
        }
      }

      return OcrResult(
        fullText: textParts.join('\n'),
        blocks: blocks,
        averageConfidence: blocks.isEmpty ? 0.0 : totalConf / blocks.length,
      );
    } on OcrEngineException {
      rethrow;
    } catch (e, st) {
      throw OcrEngineException(
        'Unexpected OCR error for $imagePath: $e',
        cause: e,
        stackTrace: st,
      );
    }
  }

  @override
  Future<void> dispose() async {
    _detSession?.release();
    _recSession?.release();
    _detSession = null;
    _recSession = null;
    _isInitialized = false;
  }

  // ─── Private: Detection ───────────────────────────────────────────────────

  Future<List<Map<String, num>>> _runDetection(img.Image src) async {
    final (resized, scaleX, scaleY) = _resizeForDetection(src);
    final inputTensor = _imageToTensor(resized, normalize: true);

    final inputs = {
      'x': OrtValueTensor.createTensorWithDataList(
        inputTensor,
        [1, 3, resized.height, resized.width],
      ),
    };

    final outputs = await _detSession!.runAsync(OrtRunOptions(), inputs);
    for (final t in inputs.values) {
      t.release();
    }

    if (outputs == null || outputs.isEmpty || outputs[0] == null) {
      return [];
    }

    final heatmap = outputs[0]!.value as List<List<List<List<double>>>>;
    for (final o in outputs) {
      o?.release();
    }

    return _extractBoxesFromHeatmap(heatmap[0][0], scaleX, scaleY, src);
  }

  /// Resize image so the shortest side is in [_kDetMinSide, _kDetMaxSide],
  /// preserving aspect ratio and rounding to multiples of 32.
  (img.Image, double, double) _resizeForDetection(img.Image src) {
    var w = src.width.toDouble();
    var h = src.height.toDouble();
    final shortest = math.min(w, h);
    final longest = math.max(w, h);

    double scale = 1.0;
    if (longest > _kDetMaxSide) {
      scale = _kDetMaxSide / longest;
    } else if (shortest < _kDetMinSide) {
      scale = _kDetMinSide / shortest;
    }

    var newW = ((w * scale) / 32).round() * 32;
    var newH = ((h * scale) / 32).round() * 32;
    newW = newW.clamp(32, _kDetMaxSide);
    newH = newH.clamp(32, _kDetMaxSide);

    final resized = img.copyResize(src, width: newW, height: newH);
    return (resized, src.width / newW, src.height / newH);
  }

  List<Map<String, num>> _extractBoxesFromHeatmap(
    List<List<double>> heatmap,
    double scaleX,
    double scaleY,
    img.Image src,
  ) {
    const double threshold = 0.3;
    const int minArea = 100;

    final h = heatmap.length;
    final w = heatmap[0].length;
    final boxes = <Map<String, num>>[];

    // Simple row-scan to find bounding rectangles above threshold.
    // A production implementation would use connected-component labeling.
    var inRegion = false;
    int regionTop = 0;

    for (var row = 0; row < h; row++) {
      final rowHasText =
          heatmap[row].any((v) => v > threshold);

      if (rowHasText && !inRegion) {
        inRegion = true;
        regionTop = row;
      } else if (!rowHasText && inRegion) {
        inRegion = false;
        final y1 = regionTop;
        final y2 = row;

        // Find left/right extents in this region
        int x1 = w, x2 = 0;
        for (var r = y1; r < y2; r++) {
          for (var c = 0; c < w; c++) {
            if (heatmap[r][c] > threshold) {
              if (c < x1) x1 = c;
              if (c > x2) x2 = c;
            }
          }
        }

        final area = (x2 - x1) * (y2 - y1);
        if (area >= minArea) {
          boxes.add({
            'x': (x1 * scaleX).round().clamp(0, src.width),
            'y': (y1 * scaleY).round().clamp(0, src.height),
            'w': ((x2 - x1) * scaleX).round().clamp(1, src.width),
            'h': ((y2 - y1) * scaleY).round().clamp(1, src.height),
          });
        }
      }
    }

    return boxes;
  }

  // ─── Private: Recognition ─────────────────────────────────────────────────

  Future<(String, double)> _runRecognition(img.Image crop) async {
    // Resize to fixed height 48, preserve aspect ratio (max width 320)
    final scale = _kRecHeight / crop.height;
    var newW = (crop.width * scale).round().clamp(8, 320);
    final resized = img.copyResize(crop, width: newW, height: _kRecHeight);
    final inputTensor = _imageToTensor(resized, normalize: true);

    final inputs = {
      'x': OrtValueTensor.createTensorWithDataList(
        inputTensor,
        [1, 3, _kRecHeight, newW],
      ),
    };

    final outputs = await _recSession!.runAsync(OrtRunOptions(), inputs);
    for (final t in inputs.values) {
      t.release();
    }

    if (outputs == null || outputs.isEmpty || outputs[0] == null) {
      return ('', 0.0);
    }

    final logits = outputs[0]!.value as List<List<List<double>>>;
    for (final o in outputs) {
      o?.release();
    }

    return _ctcDecode(logits[0]);
  }

  /// CTC greedy decoder. Returns (text, meanConfidence).
  (String, double) _ctcDecode(List<List<double>> logits) {
    final chars = <String>[];
    double totalConf = 0.0;
    int prev = -1;

    for (final frame in logits) {
      // Softmax
      final maxLogit = frame.reduce(math.max);
      final exps = frame.map((v) => math.exp(v - maxLogit)).toList();
      final sumExp = exps.reduce((a, b) => a + b);
      final probs = exps.map((e) => e / sumExp).toList();

      int argmax = 0;
      double maxProb = probs[0];
      for (var i = 1; i < probs.length; i++) {
        if (probs[i] > maxProb) {
          maxProb = probs[i];
          argmax = i;
        }
      }

      // CTC blank = last class index
      final blank = _charset.length;
      if (argmax != blank && argmax != prev) {
        if (argmax < _charset.length) {
          chars.add(_charset[argmax]);
          totalConf += maxProb;
        }
      }
      prev = argmax;
    }

    final text = chars.join();
    final conf = chars.isEmpty ? 0.0 : totalConf / chars.length;
    return (text, conf);
  }

  // ─── Private: Utilities ───────────────────────────────────────────────────

  /// Converts an [img.Image] to a CHW float32 tensor normalised to [0,1]
  /// then standardised with ImageNet mean/std if [normalize] is true.
  Float32List _imageToTensor(img.Image image, {bool normalize = true}) {
    final mean = [0.485, 0.456, 0.406];
    final std = [0.229, 0.224, 0.225];

    final h = image.height;
    final w = image.width;
    final tensor = Float32List(3 * h * w);

    for (var y = 0; y < h; y++) {
      for (var x = 0; x < w; x++) {
        final pixel = image.getPixel(x, y);
        final idx = y * w + x;
        if (normalize) {
          tensor[idx] = ((pixel.r / 255.0) - mean[0]) / std[0];
          tensor[h * w + idx] = ((pixel.g / 255.0) - mean[1]) / std[1];
          tensor[2 * h * w + idx] = ((pixel.b / 255.0) - mean[2]) / std[2];
        } else {
          tensor[idx] = pixel.r / 255.0;
          tensor[h * w + idx] = pixel.g / 255.0;
          tensor[2 * h * w + idx] = pixel.b / 255.0;
        }
      }
    }
    return tensor;
  }

  img.Image _cropTextRegion(img.Image src, Map<String, num> box) {
    final x = (box['x'] as num).toInt().clamp(0, src.width - 1);
    final y = (box['y'] as num).toInt().clamp(0, src.height - 1);
    final w = (box['w'] as num).toInt().clamp(1, src.width - x);
    final h = (box['h'] as num).toInt().clamp(1, src.height - y);
    return img.copyCrop(src, x: x, y: y, width: w, height: h);
  }

  Future<List<String>> _loadCharset(String dictPath) async {
    final file = File(dictPath);
    if (!await file.exists()) {
      throw ModelLoadException(
        'Character dictionary not found: $dictPath',
        modelPath: dictPath,
      );
    }
    final lines = await file.readAsLines();
    return lines.where((l) => l.isNotEmpty).toList();
  }

  void _assertInitialized() {
    if (!_isInitialized) {
      throw OcrEngineException(
        'OnnxOcrEngine must be initialized before use. Call initialize() first.',
      );
    }
  }
}
