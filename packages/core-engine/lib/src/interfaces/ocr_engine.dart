import 'package:pomniter_shared_models/pomniter_shared_models.dart';

/// Result produced by OCR extraction.
class OcrResult {
  final String fullText;
  final List<TextBlock> blocks;
  final double averageConfidence;

  const OcrResult({
    required this.fullText,
    this.blocks = const [],
    required this.averageConfidence,
  });
}

/// Abstract contract for on-device and cloud OCR engines.
abstract interface class OcrEngine {
  Future<void> initialize();
  Future<OcrResult> extractText(String imagePath);
  Future<void> dispose();
}
