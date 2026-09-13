/// Model download manager for Pomniter's on-device ML pipeline.
///
/// Downloads ONNX model files and vocabulary assets from GitHub Releases CDN
/// on first launch, verifies SHA-256 checksums, and caches to the app's
/// documents directory. Subsequent launches skip the download and serve
/// from cache.
///
/// ## Model Manifest
/// All model URLs and checksums are defined in [ModelManifest]. The manifest
/// is versioned — if the version changes, stale cached models are purged.
///
/// ## Usage
/// ```dart
/// final manager = ModelDownloadManager();
/// await manager.downloadAllIfNeeded(
///   onProgress: (modelName, bytesReceived, totalBytes) {
///     // Update UI progress
///   },
/// );
/// final paths = await manager.resolvedPaths();
/// ```
library;

import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Metadata for a single downloadable model asset.
class ModelAsset {
  final String name;
  final String url;
  final String sha256;
  final int sizeBytes;

  const ModelAsset({
    required this.name,
    required this.url,
    required this.sha256,
    required this.sizeBytes,
  });
}

/// Versioned manifest of all model assets required for on-device ML.
///
/// Update [version] whenever any URL or checksum changes — this triggers
/// automatic cache invalidation on-device.
class ModelManifest {
  static const String version = '1.0.0';

  /// GitHub Releases CDN base for Pomniter model assets.
  static const String _baseUrl =
      'https://github.com/markstone111/pomniter-app/releases/download/models-v1.0.0';

  static const List<ModelAsset> assets = [
    // ── PaddleOCR PP-OCRv4 (INT8 quantized) ──────────────────────────────
    ModelAsset(
      name: 'det.onnx',
      url: '$_baseUrl/ch_PP-OCRv4_det_infer_int8.onnx',
      sha256: 'PLACEHOLDER_DET_SHA256', // replaced at release time
      sizeBytes: 5_100_000,
    ),
    ModelAsset(
      name: 'rec.onnx',
      url: '$_baseUrl/ch_PP-OCRv4_rec_infer_int8.onnx',
      sha256: 'PLACEHOLDER_REC_SHA256',
      sizeBytes: 10_200_000,
    ),
    ModelAsset(
      name: 'ppocr_keys_v1.txt',
      url: '$_baseUrl/ppocr_keys_v1.txt',
      sha256: 'PLACEHOLDER_KEYS_SHA256',
      sizeBytes: 6_500,
    ),

    // ── MobileCLIP-S0 (INT8 quantized) ───────────────────────────────────
    ModelAsset(
      name: 'clip_text_encoder.onnx',
      url: '$_baseUrl/mobileclip_s0_text_int8.onnx',
      sha256: 'PLACEHOLDER_CLIP_TEXT_SHA256',
      sizeBytes: 30_000_000,
    ),
    ModelAsset(
      name: 'clip_image_encoder.onnx',
      url: '$_baseUrl/mobileclip_s0_image_int8.onnx',
      sha256: 'PLACEHOLDER_CLIP_IMAGE_SHA256',
      sizeBytes: 44_000_000,
    ),

    // ── CLIP Tokenizer Vocabulary ─────────────────────────────────────────
    ModelAsset(
      name: 'clip_vocab.json',
      url: '$_baseUrl/clip_vocab.json',
      sha256: 'PLACEHOLDER_VOCAB_SHA256',
      sizeBytes: 1_100_000,
    ),
    ModelAsset(
      name: 'clip_merges.txt',
      url: '$_baseUrl/clip_merges.txt',
      sha256: 'PLACEHOLDER_MERGES_SHA256',
      sizeBytes: 456_000,
    ),
  ];
}

/// Progress callback fired during model downloads.
typedef DownloadProgressCallback = void Function(
  String modelName,
  int bytesReceived,
  int totalBytes,
);

/// Manages the lifecycle of on-device ML model files.
class ModelDownloadManager {
  static const String _modelsDirName = 'pomniter_models';
  static const String _versionFileName = '.manifest_version';

  late final String _modelsDir;
  bool _initialized = false;

  // ─── Public API ───────────────────────────────────────────────────────────

  /// Resolves the local models directory and prepares it.
  Future<void> init() async {
    if (_initialized) return;
    final docsDir = await getApplicationDocumentsDirectory();
    _modelsDir = p.join(docsDir.path, _modelsDirName);
    await Directory(_modelsDir).create(recursive: true);
    _initialized = true;
  }

  /// Returns true if all required model files are present and the manifest
  /// version matches the current [ModelManifest.version].
  Future<bool> areModelsReady() async {
    await init();

    final versionFile = File(p.join(_modelsDir, _versionFileName));
    if (!await versionFile.exists()) return false;

    final cachedVersion = await versionFile.readAsString();
    if (cachedVersion.trim() != ModelManifest.version) return false;

    for (final asset in ModelManifest.assets) {
      final file = File(p.join(_modelsDir, asset.name));
      if (!await file.exists()) return false;
    }

    return true;
  }

  /// Downloads all missing model assets, skipping files that already exist
  /// and pass checksum verification.
  ///
  /// Calls [onProgress] for each asset being downloaded.
  /// Throws [ModelDownloadException] on network failures or checksum mismatches.
  Future<void> downloadAllIfNeeded({
    DownloadProgressCallback? onProgress,
  }) async {
    await init();

    // Purge stale cache if manifest version changed
    await _purgeIfStale();

    for (final asset in ModelManifest.assets) {
      final file = File(p.join(_modelsDir, asset.name));

      if (await file.exists()) {
        // Verify checksum of existing file — skip download if valid
        if (!asset.sha256.startsWith('PLACEHOLDER') &&
            await _verifySha256(file, asset.sha256)) {
          onProgress?.call(asset.name, asset.sizeBytes, asset.sizeBytes);
          continue;
        }
      }

      await _downloadAsset(asset, file, onProgress: onProgress);
    }

    // Write manifest version sentinel
    await File(p.join(_modelsDir, _versionFileName))
        .writeAsString(ModelManifest.version);
  }

  /// Returns the resolved absolute paths for all model files.
  /// Call only after [downloadAllIfNeeded] completes successfully.
  Future<ModelPaths> resolvedPaths() async {
    await init();
    return ModelPaths(
      detectorModelPath: p.join(_modelsDir, 'det.onnx'),
      recognizerModelPath: p.join(_modelsDir, 'rec.onnx'),
      characterDictPath: p.join(_modelsDir, 'ppocr_keys_v1.txt'),
      textEncoderPath: p.join(_modelsDir, 'clip_text_encoder.onnx'),
      imageEncoderPath: p.join(_modelsDir, 'clip_image_encoder.onnx'),
      vocabJsonPath: p.join(_modelsDir, 'clip_vocab.json'),
      mergesTextPath: p.join(_modelsDir, 'clip_merges.txt'),
    );
  }

  // ─── Private ─────────────────────────────────────────────────────────────

  Future<void> _downloadAsset(
    ModelAsset asset,
    File dest, {
    DownloadProgressCallback? onProgress,
  }) async {
    final request = http.Request('GET', Uri.parse(asset.url));
    final response = await http.Client().send(request);

    if (response.statusCode != 200) {
      throw Exception(
        'HTTP ${response.statusCode} downloading ${asset.name} from ${asset.url}',
      );
    }

    final total = response.contentLength ?? asset.sizeBytes;
    int received = 0;

    final sink = dest.openWrite();
    await for (final chunk in response.stream) {
      sink.add(chunk);
      received += chunk.length;
      onProgress?.call(asset.name, received, total);
    }
    await sink.close();

    // Verify checksum (skip for PLACEHOLDER values during development)
    if (!asset.sha256.startsWith('PLACEHOLDER')) {
      if (!await _verifySha256(dest, asset.sha256)) {
        await dest.delete();
        throw Exception(
          'SHA-256 checksum mismatch for ${asset.name}. '
          'Expected ${asset.sha256}. File deleted for safety.',
        );
      }
    }
  }

  Future<bool> _verifySha256(File file, String expectedHex) async {
    final bytes = await file.readAsBytes();
    final digest = sha256.convert(bytes);
    return digest.toString() == expectedHex.toLowerCase();
  }

  Future<void> _purgeIfStale() async {
    final versionFile = File(p.join(_modelsDir, _versionFileName));
    if (!await versionFile.exists()) return;

    final cachedVersion = await versionFile.readAsString();
    if (cachedVersion.trim() == ModelManifest.version) return;

    // Delete all model files; keep directory structure
    final dir = Directory(_modelsDir);
    await for (final entity in dir.list()) {
      if (entity is File) {
        await entity.delete();
      }
    }
  }
}

/// Resolved filesystem paths to all model assets.
class ModelPaths {
  final String detectorModelPath;
  final String recognizerModelPath;
  final String characterDictPath;
  final String textEncoderPath;
  final String imageEncoderPath;
  final String vocabJsonPath;
  final String mergesTextPath;

  const ModelPaths({
    required this.detectorModelPath,
    required this.recognizerModelPath,
    required this.characterDictPath,
    required this.textEncoderPath,
    required this.imageEncoderPath,
    required this.vocabJsonPath,
    required this.mergesTextPath,
  });
}
