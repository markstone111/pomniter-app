import 'package:flutter_test/flutter_test.dart';
import 'package:pomniter_core_engine/pomniter_core_engine.dart';
import 'package:pomniter_shared_models/pomniter_shared_models.dart';

void main() {
  group('InMemoryScreenshotRepository', () {
    late InMemoryScreenshotRepository repo;

    setUp(() {
      repo = InMemoryScreenshotRepository();
    });

    tearDown(() {
      repo.dispose();
    });

    test('saves, retrieves, updates and deletes screenshots', () async {
      final s1 = Screenshot(
        id: 'sc-1',
        filePath: '/storage/1.png',
        capturedAt: DateTime(2026, 9, 1),
        width: 1080,
        height: 1920,
        fileSizeBytes: 200000,
        extractedText: 'Apple Store Receipt #98765',
        category: ScreenshotCategory.receipt,
      );

      await repo.saveScreenshot(s1);
      expect(await repo.getScreenshotCount(), 1);

      final fetched = await repo.getScreenshotById('sc-1');
      expect(fetched?.extractedText, 'Apple Store Receipt #98765');

      final updated = s1.copyWith(isFavorite: true);
      await repo.updateScreenshot(updated);
      expect((await repo.getScreenshotById('sc-1'))?.isFavorite, isTrue);

      await repo.deleteScreenshot('sc-1');
      expect(await repo.getScreenshotCount(), 0);
    });
  });

  group('End-to-End Pipeline Use Cases', () {
    test('processes and indexes screenshot, then performs search', () async {
      final screenshotRepo = InMemoryScreenshotRepository();
      final searchRepo = InMemorySearchRepository();
      final ocrEngine = MockOcrEngine();
      final embedEngine = MockEmbeddingEngine(dimension: 128);

      await ocrEngine.initialize();
      await embedEngine.initialize();

      final processUseCase = ProcessScreenshotUseCase(
        screenshotRepo: screenshotRepo,
        searchRepo: searchRepo,
        ocrEngine: ocrEngine,
        embeddingEngine: embedEngine,
      );

      final searchUseCase = SearchScreenshotsUseCase(
        searchRepo: searchRepo,
      );

      // Ingest a screenshot
      final processed = await processUseCase.execute(
        id: 'screen-abc',
        filePath: '/storage/screen.png',
        width: 1080,
        height: 2400,
        fileSizeBytes: 350000,
        category: ScreenshotCategory.code,
      );

      expect(processed.id, 'screen-abc');
      expect(processed.extractedText, 'Simulated OCR extracted text from screenshot');

      // Search for exact match
      final results = await searchUseCase.execute(
        const SearchQuery(queryText: 'Simulated OCR', minScore: 0.1),
      );

      expect(results.length, 1);
      expect(results.first.screenshot.id, 'screen-abc');
      expect(results.first.matchType, MatchType.textExact);

      // Search with non-matching query
      final emptyResults = await searchUseCase.execute(
        const SearchQuery(queryText: 'xyznonexistentword', minScore: 0.5),
      );
      expect(emptyResults.isEmpty, isTrue);

      await ocrEngine.dispose();
      await embedEngine.dispose();
      screenshotRepo.dispose();
    });
  });
}
