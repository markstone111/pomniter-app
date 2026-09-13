/// Typed exceptions for the Pomniter ML engine pipeline.
///
/// All engine exceptions carry the original [cause] and [stackTrace]
/// so callers can log structured errors or surface them in the UI.
library;

// ─── Base ────────────────────────────────────────────────────────────────────

/// Base class for all Pomniter engine exceptions.
sealed class PomnitrEngineException implements Exception {
  final String message;
  final Object? cause;
  final StackTrace? stackTrace;

  const PomnitrEngineException(this.message, {this.cause, this.stackTrace});

  @override
  String toString() =>
      '$runtimeType: $message${cause != null ? '\nCause: $cause' : ''}';
}

// ─── Model Loading ───────────────────────────────────────────────────────────

/// Thrown when an ONNX or tokenizer model file cannot be loaded.
final class ModelLoadException extends PomnitrEngineException {
  /// Filesystem path or CDN URL of the model that failed to load.
  final String modelPath;

  const ModelLoadException(
    super.message, {
    required this.modelPath,
    super.cause,
    super.stackTrace,
  });
}

/// Thrown when a model download fails (network error, checksum mismatch, etc.).
final class ModelDownloadException extends PomnitrEngineException {
  final String url;
  final int? statusCode;

  const ModelDownloadException(
    super.message, {
    required this.url,
    this.statusCode,
    super.cause,
    super.stackTrace,
  });
}

// ─── OCR Engine ──────────────────────────────────────────────────────────────

/// Thrown by [OcrEngine] implementations for runtime errors.
final class OcrEngineException extends PomnitrEngineException {
  const OcrEngineException(
    super.message, {
    super.cause,
    super.stackTrace,
  });
}

// ─── Embedding Engine ────────────────────────────────────────────────────────

/// Thrown by [EmbeddingEngine] implementations for runtime errors.
final class EmbeddingEngineException extends PomnitrEngineException {
  const EmbeddingEngineException(
    super.message, {
    super.cause,
    super.stackTrace,
  });
}

// ─── Vector Store ────────────────────────────────────────────────────────────

/// Thrown when ObjectBox store operations fail.
final class VectorStoreException extends PomnitrEngineException {
  const VectorStoreException(
    super.message, {
    super.cause,
    super.stackTrace,
  });
}
