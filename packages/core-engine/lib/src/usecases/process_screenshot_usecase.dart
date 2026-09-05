import 'package:pomniter_shared_models/pomniter_shared_models.dart';
import '../interfaces/screenshot_repository.dart';
import '../interfaces/search_repository.dart';
import '../interfaces/ocr_engine.dart';
import '../interfaces/embedding_engine.dart';

/// Orchestrates the ingestion, OCR processing, vector embedding, and indexing of a screenshot.
class ProcessScreenshotUseCase {
  final ScreenshotRepository screenshotRepo;
  final SearchRepository searchRepo;
  final OcrEngine ocrEngine;
  final EmbeddingEngine? embeddingEngine;

  const ProcessScreenshotUseCase({
    required this.screenshotRepo,
    required this.searchRepo,
    required this.ocrEngine,
    this.embeddingEngine,
  });

  Future<Screenshot> execute({
    required String id,
    required String filePath,
    required int width,
    required int height,
    required int fileSizeBytes,
    DateTime? capturedAt,
    ScreenshotCategory category = ScreenshotCategory.other,
  }) async {
    // 1. Run OCR
    final ocrResult = await ocrEngine.extractText(filePath);

    // 2. Generate vector embedding if engine provided
    List<double>? vector;
    if (embeddingEngine != null && ocrResult.fullText.isNotEmpty) {
      vector = await embeddingEngine!.embedText(ocrResult.fullText);
    }

    final now = DateTime.now();
    final screenshot = Screenshot(
      id: id,
      filePath: filePath,
      capturedAt: capturedAt ?? now,
      indexedAt: now,
      width: width,
      height: height,
      fileSizeBytes: fileSizeBytes,
      extractedText: ocrResult.fullText,
      textBlocks: ocrResult.blocks,
      category: category,
    );

    // 3. Save to repository & search index
    await screenshotRepo.saveScreenshot(screenshot);
    await searchRepo.indexScreenshot(screenshot, vector: vector);

    return screenshot;
  }
}
