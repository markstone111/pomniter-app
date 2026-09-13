/// ONNX-backed MobileCLIP-S0 embedding engine.
///
/// MobileCLIP-S0 is Apple's ultra-compact multimodal model:
///   - Image encoder: MCi0 (11.1M params, 224×224 input)
///   - Text encoder: MCt-S (7.3M params)
///   - Joint embedding dimension: **384**
///   - ~5× faster than CLIP ViT-B/32 at comparable quality
///
/// Exported ONNX model paths (downloaded via [ModelDownloadManager]):
///   - `mobileclip_s0_image_encoder.onnx`  (~44 MB INT8)
///   - `mobileclip_s0_text_encoder.onnx`   (~30 MB INT8)
///   - `clip_vocab.json`                    (CLIP BPE vocabulary)
///   - `clip_merges.txt`                    (BPE merge rules)
///
/// Usage:
/// ```dart
/// final engine = OnnxClipEmbeddingEngine(
///   textEncoderPath: '.../text_encoder.onnx',
///   imageEncoderPath: '.../image_encoder.onnx',
///   vocabJsonPath: '.../clip_vocab.json',
///   mergesTextPath: '.../clip_merges.txt',
/// );
/// await engine.initialize();
/// final vec = await engine.embedText("flight boarding pass Bangalore");
/// ```
library;

import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:onnxruntime/onnxruntime.dart';

import '../exceptions/engine_exceptions.dart';
import '../interfaces/embedding_engine.dart';
import 'onnx_tokenizer.dart';

/// MobileCLIP-S0 joint embedding dimension.
const int _kClipDim = 384;

/// MobileCLIP image encoder input resolution.
const int _kInputSize = 224;

/// ImageNet normalisation constants (used by MobileCLIP preprocessing).
const _kMean = [0.48145466, 0.4578275, 0.40821073];
const _kStd = [0.26862954, 0.26130258, 0.27577711];

/// ONNX MobileCLIP-S0 embedding engine.
class OnnxClipEmbeddingEngine implements EmbeddingEngine {
  final String textEncoderPath;
  final String imageEncoderPath;
  final String vocabJsonPath;
  final String mergesTextPath;

  OrtSession? _textSession;
  OrtSession? _imageSession;
  ClipTokenizer? _tokenizer;
  bool _isInitialized = false;

  OnnxClipEmbeddingEngine({
    required this.textEncoderPath,
    required this.imageEncoderPath,
    required this.vocabJsonPath,
    required this.mergesTextPath,
  });

  // ─── EmbeddingEngine Interface ────────────────────────────────────────────

  @override
  int get vectorDimension => _kClipDim;

  @override
  Future<void> initialize() async {
    try {
      OrtEnv.instance.init();

      final opts = OrtSessionOptions()
        ..setInterOpNumThreads(1)
        ..setIntraOpNumThreads(2)
        ..setSessionGraphOptimizationLevel(GraphOptimizationLevel.ortEnableAll);

      _textSession = OrtSession.fromFile(File(textEncoderPath), opts);
      _imageSession = OrtSession.fromFile(File(imageEncoderPath), opts);

      final vocabJson = await File(vocabJsonPath).readAsString();
      final mergesText = await File(mergesTextPath).readAsString();
      _tokenizer = ClipTokenizer.fromJson(vocabJson, mergesText);

      _isInitialized = true;
    } catch (e, st) {
      throw ModelLoadException(
        'Embedding engine initialization failed: $e',
        modelPath: textEncoderPath,
        cause: e,
        stackTrace: st,
      );
    }
  }

  @override
  Future<List<double>> embedText(String text) async {
    _assertInitialized();

    try {
      final tokens = _tokenizer!.encode(text);
      final tokenTensor = Int32List.fromList(tokens);

      final inputs = {
        'input_ids': OrtValueTensor.createTensorWithDataList(
          tokenTensor,
          [1, kClipContextLength],
        ),
      };

      final outputs =
          await _textSession!.runAsync(OrtRunOptions(), inputs);
      for (final t in inputs.values) {
        t.release();
      }

      if (outputs == null || outputs.isEmpty || outputs[0] == null) {
        throw const EmbeddingEngineException('Text embedding returned null output');
      }

      final rawEmbedding =
          (outputs[0]!.value as List<List<double>>)[0];
      for (final o in outputs) {
        o?.release();
      }

      return _l2Normalize(rawEmbedding);
    } on EmbeddingEngineException {
      rethrow;
    } catch (e, st) {
      throw EmbeddingEngineException(
        'Unexpected error during text embedding: $e',
        cause: e,
        stackTrace: st,
      );
    }
  }

  @override
  Future<List<double>> embedImage(String imagePath) async {
    _assertInitialized();

    try {
      final raw = await File(imagePath).readAsBytes();
      final srcImage = img.decodeImage(raw);
      if (srcImage == null) {
        throw EmbeddingEngineException(
          'Cannot decode image for embedding: $imagePath',
        );
      }

      final inputTensor = _preprocessImage(srcImage);

      final inputs = {
        'pixel_values': OrtValueTensor.createTensorWithDataList(
          inputTensor,
          [1, 3, _kInputSize, _kInputSize],
        ),
      };

      final outputs =
          await _imageSession!.runAsync(OrtRunOptions(), inputs);
      for (final t in inputs.values) {
        t.release();
      }

      if (outputs == null || outputs.isEmpty || outputs[0] == null) {
        throw const EmbeddingEngineException('Image embedding returned null output');
      }

      final rawEmbedding =
          (outputs[0]!.value as List<List<double>>)[0];
      for (final o in outputs) {
        o?.release();
      }

      return _l2Normalize(rawEmbedding);
    } on EmbeddingEngineException {
      rethrow;
    } catch (e, st) {
      throw EmbeddingEngineException(
        'Unexpected error during image embedding: $e',
        cause: e,
        stackTrace: st,
      );
    }
  }

  @override
  Future<void> dispose() async {
    _textSession?.release();
    _imageSession?.release();
    _textSession = null;
    _imageSession = null;
    _isInitialized = false;
  }

  // ─── Private: Image Preprocessing ────────────────────────────────────────

  /// Resize + center-crop to 224×224, then normalize with CLIP stats.
  Float32List _preprocessImage(img.Image src) {
    // 1. Resize shortest side to 224
    final scale = _kInputSize / math.min(src.width, src.height);
    final scaled = img.copyResize(
      src,
      width: (src.width * scale).round(),
      height: (src.height * scale).round(),
    );

    // 2. Center crop to 224×224
    final cx = (scaled.width - _kInputSize) ~/ 2;
    final cy = (scaled.height - _kInputSize) ~/ 2;
    final cropped = img.copyCrop(
      scaled,
      x: cx,
      y: cy,
      width: _kInputSize,
      height: _kInputSize,
    );

    // 3. CHW float32 with CLIP normalisation
    final tensor = Float32List(3 * _kInputSize * _kInputSize);
    for (var y = 0; y < _kInputSize; y++) {
      for (var x = 0; x < _kInputSize; x++) {
        final pixel = cropped.getPixel(x, y);
        final idx = y * _kInputSize + x;
        tensor[idx] = ((pixel.r / 255.0) - _kMean[0]) / _kStd[0];
        tensor[_kInputSize * _kInputSize + idx] =
            ((pixel.g / 255.0) - _kMean[1]) / _kStd[1];
        tensor[2 * _kInputSize * _kInputSize + idx] =
            ((pixel.b / 255.0) - _kMean[2]) / _kStd[2];
      }
    }

    return tensor;
  }

  // ─── Private: L2 Normalisation ───────────────────────────────────────────

  /// L2-normalises a vector so that cosine similarity == dot product.
  List<double> _l2Normalize(List<double> v) {
    double norm = 0.0;
    for (final x in v) {
      norm += x * x;
    }
    norm = math.sqrt(norm);
    if (norm < 1e-8) return List.filled(v.length, 0.0);
    return v.map((x) => x / norm).toList();
  }

  void _assertInitialized() {
    if (!_isInitialized) {
      throw EmbeddingEngineException(
        'OnnxClipEmbeddingEngine must be initialized before use. '
        'Call initialize() first.',
      );
    }
  }
}
