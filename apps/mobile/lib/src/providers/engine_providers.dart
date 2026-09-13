import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:objectbox/objectbox.dart';
import 'package:pomniter_core_engine/pomniter_core_engine.dart';
import 'package:pomniter_shared_models/pomniter_shared_models.dart';

import '../features/onboarding/model_download_manager.dart';

// ─── Seed Data ────────────────────────────────────────────────────────────────

/// Seed sample screenshots for immediate preview and testing
final initialScreenshots = <Screenshot>[
  Screenshot(
    id: 'sc-101',
    filePath: 'assets/samples/receipt_starbucks.png',
    capturedAt: DateTime(2026, 9, 5, 9, 30),
    indexedAt: DateTime(2026, 9, 5, 9, 32),
    width: 1170,
    height: 2532,
    fileSizeBytes: 420100,
    category: ScreenshotCategory.receipt,
    extractedText:
        'Starbucks Coffee Order #1042\n1x Iced Oat Latte \$5.75\n1x Almond Croissant \$4.25\nTotal: \$10.00\nCard: *1234 Apple Pay',
    tags: ['coffee', 'starbucks', 'receipt', 'breakfast'],
    summary: 'Coffee receipt for \$10.00 via Apple Pay',
    isFavorite: true,
  ),
  Screenshot(
    id: 'sc-102',
    filePath: 'assets/samples/code_snippet.png',
    capturedAt: DateTime(2026, 9, 4, 18, 15),
    indexedAt: DateTime(2026, 9, 4, 18, 16),
    width: 1920,
    height: 1080,
    fileSizeBytes: 650000,
    category: ScreenshotCategory.code,
    extractedText:
        'func handleStream(ctx context.Context, ch <-chan Event) error {\n  for event := range ch {\n    log.Printf("Processed event %s", event.ID)\n  }\n  return nil\n}',
    tags: ['golang', 'concurrency', 'channels', 'code'],
    summary: 'Go concurrent event channel handler function',
  ),
  Screenshot(
    id: 'sc-103',
    filePath: 'assets/samples/flight_booking.png',
    capturedAt: DateTime(2026, 9, 3, 14, 05),
    indexedAt: DateTime(2026, 9, 3, 14, 07),
    width: 1080,
    height: 2400,
    fileSizeBytes: 580000,
    category: ScreenshotCategory.document,
    extractedText:
        'INDIGO FLIGHT 6E-204\nDELHI (DEL) -> BANGALORE (BLR)\nGate 14B Seat 12F\nPNR: WXYZ89\nBoarding: 16:45',
    tags: ['flight', 'travel', 'indigo', 'boarding pass'],
    summary: 'Indigo flight boarding pass DEL to BLR PNR WXYZ89',
    isFavorite: true,
  ),
  Screenshot(
    id: 'sc-104',
    filePath: 'assets/samples/chat_address.png',
    capturedAt: DateTime(2026, 9, 2, 21, 40),
    indexedAt: DateTime(2026, 9, 2, 21, 41),
    width: 1080,
    height: 2340,
    fileSizeBytes: 390000,
    category: ScreenshotCategory.chat,
    extractedText:
        'Alex: Hey! Send me the address for tonight\nSam: 42 Silicon Lane, Sector 5, Bengaluru, Karnataka 560102\nAlex: Got it, see you at 8!',
    tags: ['address', 'chat', 'alex', 'bengaluru'],
    summary: 'Chat message with Bangalore residential address',
  ),
  Screenshot(
    id: 'sc-105',
    filePath: 'assets/samples/meme_docker.png',
    capturedAt: DateTime(2026, 9, 1, 11, 20),
    indexedAt: DateTime(2026, 9, 1, 11, 22),
    width: 1200,
    height: 1200,
    fileSizeBytes: 310000,
    category: ScreenshotCategory.meme,
    extractedText:
        'Works on my machine!\nThen we will ship your machine.\nAnd that is how Docker was born.',
    tags: ['docker', 'meme', 'devops', 'humor'],
    summary: 'DevOps joke about Docker birth and shipping machine',
  ),
];

// ─── In-Memory Repos (Demo / Fallback) ───────────────────────────────────────

/// Global ScreenshotRepository provider (in-memory, seeded with demo data)
final screenshotRepoProvider = Provider<ScreenshotRepository>((ref) {
  final repo = InMemoryScreenshotRepository();
  for (final s in initialScreenshots) {
    repo.saveScreenshot(s);
  }
  return repo;
});

/// Global SearchRepository provider (in-memory, seeded with demo data)
final searchRepoProvider = Provider<SearchRepository>((ref) {
  final repo = InMemorySearchRepository();
  for (final s in initialScreenshots) {
    repo.indexScreenshot(s);
  }
  return repo;
});

/// OcrEngine provider (mock — used in tests and before ONNX loads)
final ocrEngineProvider = Provider<OcrEngine>((ref) {
  final engine = MockOcrEngine();
  engine.initialize();
  return engine;
});

/// SearchScreenshotsUseCase provider
final searchUseCaseProvider = Provider<SearchScreenshotsUseCase>((ref) {
  final searchRepo = ref.watch(searchRepoProvider);
  return SearchScreenshotsUseCase(searchRepo: searchRepo);
});

// ─── ObjectBox Store (Phase 1.7) ─────────────────────────────────────────────

/// Async provider that opens (or creates) the ObjectBox Store.
/// Used by ObjectBox repository providers below.
final objectBoxStoreProvider = FutureProvider<Store>((ref) async {
  return openObjectBoxStore();
});

/// ObjectBox-backed ScreenshotRepository (persistent, HNSW vector search).
final objectBoxScreenshotRepoProvider =
    Provider<AsyncValue<ScreenshotRepository>>((ref) {
  final storeAsync = ref.watch(objectBoxStoreProvider);
  return storeAsync.whenData((store) => ObjectBoxScreenshotRepository(store));
});

/// ObjectBox-backed SearchRepository (persistent, HNSW vector search).
final objectBoxSearchRepoProvider =
    Provider<AsyncValue<SearchRepository>>((ref) {
  final storeAsync = ref.watch(objectBoxStoreProvider);
  return storeAsync.whenData((store) => ObjectBoxSearchRepository(store));
});

// ─── ONNX Engine Providers (Phase 1.6) ───────────────────────────────────────

/// Provider for the ONNX PaddleOCR engine, keyed by [ModelPaths].
/// Call [OnnxOcrEngine.initialize] after reading this provider.
final onnxOcrEngineProvider =
    Provider.family<OnnxOcrEngine, ModelPaths>((ref, paths) {
  return OnnxOcrEngine(
    detectorModelPath: paths.detectorModelPath,
    recognizerModelPath: paths.recognizerModelPath,
    characterDictPath: paths.characterDictPath,
  );
});

/// Provider for the ONNX MobileCLIP embedding engine, keyed by [ModelPaths].
/// Call [OnnxClipEmbeddingEngine.initialize] after reading this provider.
final onnxClipEngineProvider =
    Provider.family<OnnxClipEmbeddingEngine, ModelPaths>((ref, paths) {
  return OnnxClipEmbeddingEngine(
    textEncoderPath: paths.textEncoderPath,
    imageEncoderPath: paths.imageEncoderPath,
    vocabJsonPath: paths.vocabJsonPath,
    mergesTextPath: paths.mergesTextPath,
  );
});
