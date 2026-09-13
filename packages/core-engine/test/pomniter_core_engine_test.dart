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

  // ─── Phase 1.6: ONNX Engine Contract Tests ──────────────────────────────

  group('OnnxOcrEngine — uninitialized guard', () {
    test('throws OcrEngineException before initialize()', () async {
      final engine = OnnxOcrEngine(
        detectorModelPath: '/nonexistent/det.onnx',
        recognizerModelPath: '/nonexistent/rec.onnx',
        characterDictPath: '/nonexistent/keys.txt',
      );

      expect(
        () => engine.extractText('/nonexistent/image.png'),
        throwsA(isA<OcrEngineException>()),
      );
    });

    test('dispose() is idempotent on uninitialized engine', () async {
      final engine = OnnxOcrEngine(
        detectorModelPath: '/x/det.onnx',
        recognizerModelPath: '/x/rec.onnx',
        characterDictPath: '/x/keys.txt',
      );
      // Should not throw
      await expectLater(engine.dispose(), completes);
    });
  });

  group('OnnxClipEmbeddingEngine — uninitialized guard', () {
    test('throws EmbeddingEngineException before initialize()', () async {
      final engine = OnnxClipEmbeddingEngine(
        textEncoderPath: '/nonexistent/text.onnx',
        imageEncoderPath: '/nonexistent/image.onnx',
        vocabJsonPath: '/nonexistent/vocab.json',
        mergesTextPath: '/nonexistent/merges.txt',
      );

      expect(
        () => engine.embedText('hello world'),
        throwsA(isA<EmbeddingEngineException>()),
      );
    });

    test('vectorDimension is 384 (MobileCLIP-S0 contract)', () {
      final engine = OnnxClipEmbeddingEngine(
        textEncoderPath: '/x/text.onnx',
        imageEncoderPath: '/x/image.onnx',
        vocabJsonPath: '/x/vocab.json',
        mergesTextPath: '/x/merges.txt',
      );
      expect(engine.vectorDimension, 384);
    });
  });

  group('ClipTokenizer', () {
    // Minimal test vocabulary and merge rules for unit testing
    const minimalVocabJson = '{"hello": 100, "world": 200, "hello</w>": 101, '
        '"world</w>": 201, "<|startoftext|>": 49406, "<|endoftext|>": 49407}';
    const minimalMerges = '# merges\n';

    test('encodes to exactly kClipContextLength tokens', () {
      final tokenizer =
          ClipTokenizer.fromJson(minimalVocabJson, minimalMerges);
      final tokens = tokenizer.encode('hello world');
      expect(tokens.length, kClipContextLength);
    });

    test('first token is SOT, followed by EOT for empty input', () {
      final tokenizer =
          ClipTokenizer.fromJson(minimalVocabJson, minimalMerges);
      final tokens = tokenizer.encode('');
      expect(tokens[0], kClipSotToken);
      expect(tokens[1], kClipEotToken);
      // Rest should be padding (0)
      expect(tokens.sublist(2).every((t) => t == 0), isTrue);
    });
  });

  // ─── Phase 1.6: Typed Exceptions ────────────────────────────────────────

  group('Engine Exceptions', () {
    test('ModelLoadException carries modelPath and cause', () {
      final ex = ModelLoadException(
        'Could not open model',
        modelPath: '/models/det.onnx',
        cause: Exception('file not found'),
      );
      expect(ex.modelPath, '/models/det.onnx');
      expect(ex.cause, isNotNull);
      expect(ex.toString(), contains('ModelLoadException'));
    });

    test('ModelDownloadException carries url and statusCode', () {
      const ex = ModelDownloadException(
        'HTTP 404',
        url: 'https://cdn.example.com/model.onnx',
        statusCode: 404,
      );
      expect(ex.url, contains('cdn.example.com'));
      expect(ex.statusCode, 404);
    });

    test('VectorStoreException is a PomnitrEngineException', () {
      const ex = VectorStoreException('store closed');
      expect(ex, isA<PomnitrEngineException>());
    });

    test('Exception hierarchy is sealed — OcrEngineException', () {
      const ex = OcrEngineException('inference failed');
      expect(ex, isA<PomnitrEngineException>());
      expect(ex.message, 'inference failed');
    });
  });

  // ─── Phase 1.7: ObjectBox Entity Mapping ─────────────────────────────────

  group('ObjectBox Entity Conversion', () {
    test('ScreenshotEntity.fromDomain and toDomain roundtrip', () {
      final s = Screenshot(
        id: 'sc-roundtrip-1',
        filePath: '/storage/test.png',
        capturedAt: DateTime(2026, 9, 14, 10, 0),
        indexedAt: DateTime(2026, 9, 14, 10, 5),
        width: 1080,
        height: 2400,
        fileSizeBytes: 450000,
        extractedText: 'Flight to Tokyo JL001',
        tags: ['travel', 'flight', 'tokyo'],
        category: ScreenshotCategory.document,
        summary: 'Flight booking to Tokyo',
        isFavorite: true,
      );

      final dummyVector = List<double>.generate(384, (i) => i / 384.0);
      final entity = ScreenshotEntity.fromDomain(s, embedding: dummyVector);

      expect(entity.appId, 'sc-roundtrip-1');
      expect(entity.extractedText, 'Flight to Tokyo JL001');
      expect(entity.category, 'document');
      expect(entity.isFavorite, isTrue);
      expect(entity.embedding.length, 384);
      expect(entity.embedding[0], closeTo(0.0, 1e-5));

      final restored = entity.toDomain();
      expect(restored.id, s.id);
      expect(restored.filePath, s.filePath);
      expect(restored.extractedText, s.extractedText);
      expect(restored.category, s.category);
      expect(restored.tags, ['travel', 'flight', 'tokyo']);
      expect(restored.isFavorite, isTrue);
      expect(restored.summary, s.summary);
    });

    test('TextBlockEntity.fromDomain and toDomain roundtrip', () {
      final tb = TextBlock(
        text: 'Flight to Tokyo',
        confidence: 0.98,
        boundingBox: const BoundingBox(
          left: 10.0,
          top: 20.0,
          width: 200.0,
          height: 40.0,
        ),
      );

      final entity = TextBlockEntity.fromDomain(tb);
      expect(entity.text, 'Flight to Tokyo');
      expect(entity.confidence, 0.98);
      expect(entity.boxLeft, 10.0);
      expect(entity.boxTop, 20.0);
      expect(entity.boxWidth, 200.0);
      expect(entity.boxHeight, 40.0);

      final restored = entity.toDomain();
      expect(restored.text, tb.text);
      expect(restored.confidence, tb.confidence);
      expect(restored.boundingBox?.left, 10.0);
      expect(restored.boundingBox?.width, 200.0);
    });
  });
}

