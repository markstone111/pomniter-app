import '../interfaces/ocr_engine.dart';
import 'package:pomniter_shared_models/pomniter_shared_models.dart';

/// Mock OCR engine that simulates text extraction with high fidelity for tests.
class MockOcrEngine implements OcrEngine {
  bool _isInitialized = false;

  @override
  Future<void> initialize() async {
    _isInitialized = true;
  }

  @override
  Future<OcrResult> extractText(String imagePath) async {
    if (!_isInitialized) {
      throw StateError('OcrEngine must be initialized before calling extractText');
    }

    // Default mock response
    return const OcrResult(
      fullText: 'Simulated OCR extracted text from screenshot',
      averageConfidence: 0.96,
      blocks: [
        TextBlock(
          text: 'Simulated OCR extracted text',
          confidence: 0.98,
          boundingBox: BoundingBox(left: 0, top: 0, width: 300, height: 40),
        ),
      ],
    );
  }

  @override
  Future<void> dispose() async {
    _isInitialized = false;
  }
}
