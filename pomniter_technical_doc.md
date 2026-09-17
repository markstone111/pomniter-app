# Building Pomniter: Engineering an AI Screenshot Memory Engine From First Principles

> *"Search screenshots the way you remember them."*

---

## Preface

Most screenshots die alone. You take them compulsively — meeting notes, boarding passes, receipts, memes, code snippets — and they pile up in a gallery that only a sequential scroll can navigate. Apple and Samsung have shipped proprietary "semantic search" for screenshots, but they are black boxes locked to one ecosystem, trained on your private data in the cloud, and unavailable to anyone not buying into their hardware stack.

**Pomniter** (*помнить* — Russian for "to remember") is the answer: an **open-source, local-first, platform-independent AI screenshot memory search engine**. This document is an engineering deep-dive into everything we built across Phases 1.5–1.8: the design system, on-device ML pipeline, local vector database, mobile UX, event-driven backend, and the reasoning behind every critical architectural decision.

This is not a "how I built a to-do app" post. This is an account of production-grade infrastructure, written for engineers who care about doing things right.

---

## 1. Philosophy & Non-Negotiable Engineering Principles

Before a line of code was written, a set of constraints was established:

### 1.1 Local-First Privacy

Screenshots are intimate. They contain bank balances, private conversations, medical records, passwords people forgot they photographed. The user's data **stays on-device by default**. Cloud sync is opt-in, encrypted end-to-end, and fully transparent. No model training on user data. No centralized storage without explicit consent.

This is not a feature. It is the foundational promise of the product.

### 1.2 Monorepo with Strong Package Boundaries

The codebase lives in a **Melos-managed Dart/Flutter monorepo** at [`markstone111/pomniter-app`](https://github.com/markstone111/pomniter-app):

```
pomniter-app/
├── apps/mobile/          # Flutter app (Riverpod 2.6 + GoRouter 14.8)
├── packages/
│   ├── design-system/    # Neo-brutal UI library (standalone, 100% tested)
│   ├── shared-models/    # Pure Dart domain entities (zero runtime deps)
│   └── core-engine/      # Repository contracts + ML engines + ObjectBox
├── services/             # Python/TypeScript microservices
│   ├── api-gateway/      # Fastify 4 + TypeScript
│   ├── ocr-service/      # FastAPI + PaddleOCR/ONNX
│   ├── embedding-service/# FastAPI + MobileCLIP-S0
│   └── search-service/   # FastAPI + Hybrid RRF Search
├── infra/                # SQL migrations, Kafka topic scripts
├── telemetry/            # Prometheus configs, Grafana dashboards
└── tests/                # Integration & E2E pipeline test suites
```

Each package has **zero circular dependencies**. `shared-models` imports nothing. `design-system` imports nothing. `core-engine` imports only `shared-models`. `apps/mobile` imports all three packages. This strict boundary enables independent versioning, testing, and eventual open-sourcing of packages.

### 1.3 Enterprise-Grade Observability from Day One

Many teams bolt on monitoring as an afterthought. We integrated **Prometheus instrumentation** into every microservice, **Grafana dashboards** from the first sprint, and **OpenTelemetry-ready tracing hooks** in the base service templates. The principle: if you can't measure it, you can't debug it at 2 AM when a million users are reporting issues.

### 1.4 Test Coverage as a Gate, Not an Afterthought

- `packages/design-system`: **10/10 tests pass**
- `packages/shared-models`: **7/7 tests pass**
- `packages/core-engine`: **14/14 tests pass**
- `apps/mobile`: **1/1 smoke tests pass**
- Backend total: **20/20 tests pass** across 4 services

No code merged without a passing test suite. No exceptions.

---

## 2. The Design System (Phase 1.5)

### 2.1 Why a Custom Design System Instead of Material/Cupertino?

The default Flutter Material theme is adequate for internal tools. Pomniter is a consumer product targeting millions of users across different cultural backgrounds and device types. A generic Material-3 surface would be invisible in an app store.

We chose a **neo-brutal aesthetic**: thick solid borders (no blur), hard offset shadows (no gradient-based elevation), geometric typography, and a curated 4-color accent palette:

| Token | Value | Usage |
|---|---|---|
| `neoYellow` | `#FFE156` | Primary CTAs, highlights |
| `neoCyan` | `#00E5FF` | Interactive states, links |
| `neoPink` | `#FF6B9D` | Error states, destructive |
| `neoGreen` | `#4ADE80` | Success, confirmations |

Why neo-brutal? Because it is **legible at small sizes** (important for OCR-extracted text display), **high-contrast by construction** (accessibility without effort), and **immediately distinctive** (brand recognition).

### 2.2 Design Token Architecture

Tokens are organized into four immutable classes in `packages/design-system/lib/src/tokens/`:

```dart
// All tokens are compile-time constants — no runtime allocation
abstract final class NeoColors {
  static const Color yellow = Color(0xFFFFE156);
  static const Color cyan   = Color(0xFF00E5FF);
  static const Color pink   = Color(0xFFFF6B9D);
  static const Color green  = Color(0xFF4ADE80);
  // ... 20+ semantic color tokens
}

abstract final class NeoTypography {
  // Space Grotesk for headings (geometric, modern)
  static const TextStyle displayLarge = TextStyle(
    fontFamily: 'SpaceGrotesk', fontSize: 48, fontWeight: FontWeight.w800,
  );
  // JetBrains Mono for OCR/code text (monospaced readability)
  static const TextStyle monoBody = TextStyle(
    fontFamily: 'JetBrainsMono', fontSize: 14,
  );
}
```

**Why `abstract final class` instead of a top-level `const`?** Dart's tree-shaker eliminates unused token classes at compile time. A top-level constant map would be treated as a single blob. This granularity can save hundreds of bytes in release builds — and at millions of installs, bytes matter.

### 2.3 Theme Bridge to Material

Rather than fighting Flutter's `ThemeData`, we wrote a `NeoTheme.toMaterialTheme()` bridge that maps neo-brutal tokens to Material 3's `ColorScheme`. This means all Flutter widgets (dialogs, text fields, alerts) receive correct theming automatically while our custom widgets layer the neo-brutal aesthetic on top.

```dart
static ThemeData toMaterialTheme(NeoThemeData neo) => ThemeData(
  colorScheme: ColorScheme(
    primary:    neo.colors.accent,
    secondary:  neo.colors.surface,
    background: neo.colors.background,
    // ...
  ),
  textTheme: _buildTextTheme(neo.typography),
  // Override Material's elevation shadows with our hard offsets:
  cardTheme: CardTheme(
    elevation: 0,
    shape: RoundedRectangleBorder(
      side: BorderSide(color: neo.colors.border, width: neo.borders.widthMedium),
    ),
  ),
);
```

### 2.4 Component Library

Seven production-ready widgets shipped:

| Widget | Purpose | Key Design Decision |
|---|---|---|
| `NeoButton` | Primary/secondary/ghost CTA | Hard shadow on active state, moves 2px on press |
| `NeoCard` | Content card | `BoxDecoration` with `offset` shadow, no `BoxShadow` blur |
| `NeoBadge` | Status chips | Compact pill with configurable accent color |
| `NeoTextField` | Search/input | Bold 3px border, expands on focus |
| `NeoAppBar` | Top navigation | Sticky, no elevation, bottom border separator |
| `NeoScaffold` | Page wrapper | Enforces background color from theme |
| `NeoToast` | Feedback snackbar | High-contrast, visible in both light and dark modes |

The `NeoToast` was refactored after a UX bug discovery: Flutter's default `SnackBar` inherits `SnackBarThemeData`, which in light mode produced nearly-invisible light-gray-on-white text. We replaced it with a fully custom positioned overlay that manages its own `TextStyle` independently of `Theme` — guaranteeing readability in any mode.

---

## 3. Shared Domain Models (Phase 1.5)

### 3.1 The Principle of Zero-Dependency Domain Models

`packages/shared-models` contains the core domain entities. It has **zero runtime dependencies** — no `json_serializable`, no `freezed`, no `equatable`. Just pure Dart.

This is deliberate. Any package that imports `shared-models` should be able to do so without pulling in a transitive dependency graph. If a developer wants to use `Screenshot` in a CLI tool, a web service, or a native desktop app, they can. Zero friction.

### 3.2 Core Entities

```dart
/// The central domain entity — the canonical representation of one screenshot.
class Screenshot {
  final String id;            // UUID (e.g. 'sc-101')
  final String filePath;      // Absolute device path
  final DateTime capturedAt;
  final DateTime? indexedAt;  // null until OCR+embedding completes
  final int width;
  final int height;
  final int fileSizeBytes;
  final String extractedText; // Full OCR output, concatenated
  final List<String> tags;
  final ScreenshotCategory category;
  final String? summary;      // AI-generated one-line summary
  final bool isFavorite;
  final List<TextBlock> textBlocks; // Positional OCR blocks
}

/// A located fragment of recognized text.
class TextBlock {
  final String text;
  final double confidence; // 0.0–1.0
  final BoundingBox? boundingBox;
}

enum ScreenshotCategory { receipt, code, document, chat, meme, other }
```

**Why not `freezed`?** `freezed` is excellent for large teams with complex state. For domain models that need to cross package boundaries cleanly, the generated `_$ScreenshotCopyWith` machinery adds noise. We implement `copyWith()` manually — 10 extra lines per entity, zero dependency cost.

---

## 4. On-Device ML Pipeline (Phase 1.6)

This is the technical centerpiece of Pomniter's local-first promise. Everything runs on-device, inside the Flutter app, with no network calls.

### 4.1 The Two-Engine Architecture

Two ONNX Runtime engines run in sequence when a screenshot is imported:

```
Screenshot File
      │
      ▼
┌─────────────┐
│  OcrEngine  │  → List<TextBlock> (text + bounding boxes)
└─────────────┘
      │
      ▼
┌──────────────────┐
│ EmbeddingEngine  │  → Float32[384] (L2-normalized vector)
└──────────────────┘
      │
      ▼
┌───────────────────┐
│  ObjectBox Store  │  → Persisted entity with HNSW index
└───────────────────┘
```

Both engines implement repository interfaces defined in `packages/core-engine/lib/src/interfaces/`:

```dart
abstract interface class OcrEngine {
  Future<List<TextBlock>> recognize(File imageFile);
  Future<void> initialize();
  bool get isInitialized;
}

abstract interface class EmbeddingEngine {
  Future<List<double>> embed(String text);
  int get vectorDimension; // 384 for MobileCLIP-S0
  Future<void> initialize();
  bool get isInitialized;
}
```

Using interfaces means the `ProcessScreenshotUseCase` is **completely decoupled from any ONNX implementation**. The mock engines (`MockOcrEngine`, `MockEmbeddingEngine`) drop in for unit testing with zero I/O overhead.

### 4.2 OCR: PaddleOCR PP-OCRv4 via ONNX Runtime

**Why PaddleOCR over Google ML Kit?**

| Criteria | PaddleOCR PP-OCRv4 | Google ML Kit |
|---|---|---|
| License | Apache 2.0 (fully open) | Proprietary (usage limits) |
| Offline support | Complete | Partial (requires Play Services) |
| Model portability | ONNX export available | Locked to Google format |
| Accuracy (ICDAR benchmark) | 83.2% | ~80% (unofficial) |
| Script support | 80+ languages | Limited |

PP-OCRv4 uses a **two-stage pipeline**:
1. **Text detection** (`det` model): A lightweight DBNet variant that outputs a probability map of text regions, then applies a differentiable binarization threshold to produce bounding polygons.
2. **Text recognition** (`rec` model): A CRNN (CNN + Bi-LSTM + CTC decoder) that processes each detected text region and outputs the character sequence.

```dart
// OnnxOcrEngine: simplified flow
Future<List<TextBlock>> recognize(File imageFile) async {
  final img = await _loadAndPreprocess(imageFile); // Resize to 960×960, normalize
  
  // Stage 1: Detection
  final detOutput = await _detSession.run(
    OrtRunOptions(), {'x': OrtValueTensor.createTensorWithDataList(img, [1, 3, 960, 960])},
    ['sigmoid_0.tmp_0'],
  );
  final polygons = _extractPolygons(detOutput, threshold: 0.3, boxThreshold: 0.6);
  
  // Stage 2: Recognition per crop
  final blocks = <TextBlock>[];
  for (final poly in polygons) {
    final crop = _perspectiveCrop(img, poly);
    final recOutput = await _recSession.run(...);
    final text = _ctcDecode(recOutput);
    blocks.add(TextBlock(text: text, confidence: ..., boundingBox: _toBoundingBox(poly)));
  }
  return blocks;
}
```

**The ONNX Runtime choice**: We use `onnxruntime_flutter` (community package, Apache 2.0) rather than TensorFlow Lite because:
1. The ONNX format is the **universal ML interop format** — any model from PyTorch, PaddlePaddle, or Keras can be exported to ONNX.
2. ONNX Runtime supports hardware acceleration (CoreML on iOS, NNAPI/XNNPACK on Android) through a single API surface — no platform-specific code.
3. The same ONNX models run identically in the Flutter app and the Python backend (`onnxruntime` Python package), making the architecture truly symmetric.

### 4.3 BPE Tokenizer: Pure Dart, Zero Native Dependencies

MobileCLIP-S0's text encoder uses CLIP's BPE (Byte-Pair Encoding) vocabulary. The reference implementation is Python (`clip.simple_tokenizer`). We implemented a complete BPE tokenizer in pure Dart:

```dart
class ClipTokenizer {
  final Map<String, int> _encoder;   // vocab.json: token → id
  final Map<String, String> _bpeRanks; // merges.txt: pair → merged
  
  List<int> encode(String text) {
    final tokens = <int>[_sot]; // Start-of-text token
    for (final word in _normalizeText(text).split(' ')) {
      tokens.addAll(_bpe(word)); // BPE merge sequence
    }
    tokens.add(_eot); // End-of-text token
    return _padOrTruncate(tokens, 77); // CLIP max context length
  }
  
  // BPE merge: repeatedly merge most frequent adjacent byte pairs
  List<int> _bpe(String word) {
    var chars = word.split('').map((c) => _bytesToUnicode()[c.codeUnitAt(0)]!).toList();
    while (chars.length > 1) {
      String? best;
      for (final pair in _getPairs(chars)) {
        if (_bpeRanks.containsKey(pair)) {
          best = pair; break; // bpeRanks are sorted by merge frequency
        }
      }
      if (best == null) break;
      final parts = best.split(' ');
      chars = _mergeChars(chars, parts[0], parts[1]);
    }
    return chars.map((c) => _encoder[c]!).toList();
  }
}
```

**Why not use an FFI bridge to a C tokenizer?** FFI adds platform-specific build toolchains, complicates the Gradle/CocoaPods integration, and breaks easily on architecture changes (ARM64/x86_64). The pure Dart BPE implementation adds ~3ms per tokenization call — imperceptible to a user, but avoiding weeks of native build maintenance.

### 4.4 Semantic Embeddings: MobileCLIP-S0

**Why MobileCLIP-S0 over larger CLIP models?**

| Model | Vector Dim | Size | On-Device Inference (ARM64) |
|---|---|---|---|
| CLIP ViT-B/32 | 512 | 340 MB | ~800ms |
| MobileCLIP-S0 | 384 | **9.7 MB** | **~45ms** |
| MobileCLIP-S1 | 512 | 21 MB | ~90ms |

MobileCLIP-S0 hits the sweet spot: small enough to ship inside the APK, fast enough to not block the UI thread, and accurate enough for our retrieval task. It was developed by Apple Research and released under an MIT license.

L2-normalization is applied post-inference so that cosine similarity becomes equivalent to dot product — enabling ObjectBox's HNSW index to operate at maximum efficiency:

```dart
List<double> _l2Normalize(List<double> v) {
  final norm = math.sqrt(v.map((x) => x * x).reduce((a, b) => a + b));
  if (norm < 1e-10) return v; // Avoid division by zero for zero vectors
  return v.map((x) => x / norm).toList();
}
```

### 4.5 Model Distribution: CDN Streaming with SHA-256 Verification

ONNX model files are not bundled in the APK (that would make the APK ~25 MB heavier). Instead, `ModelDownloadManager` streams models from a CDN on first launch with:
1. **Chunked HTTP download** with a live progress indicator
2. **SHA-256 checksum verification** — if the hash doesn't match, the file is deleted and the download retries
3. **Local caching** in `getApplicationSupportDirectory()` — subsequent launches skip the download entirely

This pattern is identical to how major ML-powered apps (Google Lens, iOS Visual Intelligence) distribute model weights without bloating the store listing.

---

## 5. ObjectBox: Local Vector Database (Phase 1.7)

### 5.1 Why ObjectBox Over the Alternatives?

When we decided to build a local vector search feature, we evaluated every viable option:

| Option | Vector ANN Search | On-Device | Flutter SDK | License |
|---|---|---|---|---|
| **ObjectBox** | ✅ HNSW index | ✅ Native | ✅ Official | Apache 2.0 |
| SQLite + sqlite-vss | ✅ (via extension) | ✅ | ❌ (FFI-only) | MIT |
| Isar | ❌ (no vector support) | ✅ | ✅ | Apache 2.0 |
| Hive/Box | ❌ | ✅ | ✅ | Apache 2.0 |
| Realm | ✅ | ✅ | ✅ | SSPL (non-commercial) |
| Drift + custom | ❌ | ✅ | ✅ | MIT |

ObjectBox is the only option that offers **native HNSW vector indexing with an official Flutter SDK under a permissive license**. The SSPL license on Realm MongoDB Realm disqualifies it for an open-source product.

### 5.2 HNSW Index: How It Works

HNSW (Hierarchical Navigable Small World) is the current state-of-the-art algorithm for Approximate Nearest Neighbor (ANN) search. It builds a multi-layer graph where:
- **Layer 0** contains all vectors (dense neighborhood)
- **Higher layers** contain progressively fewer "long-range" connections (like highway on-ramps)

A query vector starts at the top layer, greedily navigates to the best candidate, then descends to denser layers. Search complexity is **O(log N)** compared to O(N) for a brute-force scan — critical at millions of screenshots.

Our configuration in `objectbox_entities.dart`:

```dart
@HnswIndex(
  dimensions: 384,                        // Must match MobileCLIP-S0 output
  distanceType: VectorDistanceType.cosine, // Cosine similarity metric
)
Float32List embedding = Float32List(0);
```

`Float32List` is used (not `List<double>`) because:
1. ObjectBox requires it for HNSW indexing
2. A 384-dim `Float32List` occupies **1,536 bytes** vs. 3,072 bytes for `List<double>` (doubles are 64-bit on Dart VM)
3. At one million screenshots, this is the difference between 1.5 GB and 3 GB of vector storage

### 5.3 Entity Design: Domain/Persistence Separation

A common mistake is to use `ObjectBox` annotations directly on domain models. This couples your business logic to a specific database. We maintain clean separation:

```dart
// WRONG: Domain model with DB annotation
@Entity()
class Screenshot {
  @Id() int obId = 0; // ← DB implementation detail leaking into domain
}

// RIGHT: Separate persistence entity with bidirectional converters
@Entity()
class ScreenshotEntity {
  @Id() int obId = 0;            // ObjectBox internal key
  @Index() @Unique(...) late String appId; // Application UUID

  static ScreenshotEntity fromDomain(Screenshot s, {List<double>? embedding}) { ... }
  Screenshot toDomain() { ... }
}
```

`ToMany<TextBlockEntity>` models the 1:N relationship between a screenshot and its extracted text blocks. ObjectBox lazy-loads relations — a screenshot with 50 text blocks does not pay the deserialization cost unless `.textBlocks` is accessed.

### 5.4 Hybrid Search: Keyword + Vector Fusion

`ObjectBoxSearchRepository.search()` implements a two-phase retrieval strategy:

**Phase 1 — Keyword Retrieval:**
```dart
// ObjectBox condition builder (generates optimized native query)
Condition<ScreenshotEntity> condition =
    ScreenshotEntity_.extractedText.contains(query.queryText, caseSensitive: false);
// Optional: AND filter by category
if (query.category != null) {
  condition = condition.and(ScreenshotEntity_.category.equals(query.category!.name));
}
final keywordEntities = _box.query(condition).build().find();
```

**Phase 2 — TF-Weighted Scoring:**
```dart
final occurrences = _countOccurrences(lowerText, lowerQuery);
final kwScore = occurrences / (entity.extractedText.length / 100 + 1);
```

This is a simplified **TF (Term Frequency) score** — the number of query occurrences normalized by document length. It prevents a one-word document from getting an unfairly high score versus a long receipt that contains the query term 15 times.

**Phase 3 (Planned for Phase 1.9) — Vector ANN Fusion:**

Once on-device embeddings are computed and stored, the HNSW nearest-neighbor query will run in parallel and its score will be fused using **Reciprocal Rank Fusion (RRF)**:

```
RRF_score = Σ (1 / (k + rank_i))  where k=60, rank_i = position in ranked list i
```

RRF is chosen over weighted linear combination because it is **rank-order robust** — it doesn't require calibrating score magnitudes across heterogeneous systems (keyword TF scores vs. cosine similarities are on completely different scales).

---

## 6. Flutter Mobile App (Phase 1.7–1.8)

### 6.1 State Management: Riverpod 2.6

We use **Riverpod** over BLoC and Provider for three reasons:
1. **Compile-time safety**: `ref.watch()` errors are caught at analysis time, not runtime.
2. **Autodispose**: Providers automatically release resources when no longer observed — critical for expensive ObjectBox queries.
3. **Testability**: Riverpod's `ProviderContainer` allows overriding any provider in tests without mocking frameworks.

The provider tree for the ML pipeline:

```dart
// Dependency injection via Riverpod
final objectBoxStoreProvider = Provider<Store>((ref) => throw UnimplementedError());
// ↑ Overridden at app startup with actual Store from openObjectBoxStore()

final screenshotRepositoryProvider = Provider<ScreenshotRepository>((ref) {
  final store = ref.watch(objectBoxStoreProvider);
  return ObjectBoxScreenshotRepository(store);
});

final ocrEngineProvider = FutureProvider<OcrEngine>((ref) async {
  final engine = OnnxOcrEngine(modelDir: await _getModelDir());
  await engine.initialize();
  return engine;
});
```

### 6.2 Navigation: GoRouter with StatefulShellRoute

Early iterations used `go_router`'s basic `GoRoute` for all navigation. This caused a critical UX regression: tapping the bottom navigation bar triggered a full route transition — the entire screen rebuilt and the bottom bar visually "jumped". On LinkedIn, Twitter, or any polished app, the navigation bar is **completely static**. It never moves.

The fix was migrating to `StatefulShellRoute.indexedStack`:

```dart
StatefulShellRoute.indexedStack(
  builder: (context, state, navigationShell) =>
      AppShell(navigationShell: navigationShell), // Shell owns the bottom bar
  branches: [
    StatefulShellBranch(routes: [GoRoute(path: '/home', ...)]),
    StatefulShellBranch(routes: [GoRoute(path: '/search', ...)]),
    StatefulShellBranch(routes: [GoRoute(path: '/gallery', ...)]),
    StatefulShellBranch(routes: [GoRoute(path: '/settings', ...)]),
  ],
)
```

**`indexedStack`** is the key. The `IndexedStack` widget renders all four branch pages simultaneously and uses an `index` to show/hide them — no rebuilding on tab switch. The bottom bar widget in `AppShell` is rendered **once** at the shell level and never touched by navigation events below it.

The detail screen is a **separate root-level `GoRoute`** with `parentNavigatorKey: _rootNavigatorKey`. This pushes it above the shell entirely — tapping the hardware back button or the in-app `←` returns cleanly to the previous shell page rather than exiting the app.

### 6.3 Theme Persistence: SharedPreferences

Dark mode preference is stored in `SharedPreferences` and loaded **synchronously before `runApp()`** via `await`:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final isDark = prefs.getBool('isDarkMode') ?? false;
  final store = await openObjectBoxStore();
  runApp(
    ProviderScope(
      overrides: [
        objectBoxStoreProvider.overrideWithValue(store),
        initialThemeModeProvider.overrideWithValue(isDark ? ThemeMode.dark : ThemeMode.light),
      ],
      child: const PomApp(),
    ),
  );
}
```

This ensures there is **zero flash of wrong theme** on launch. The app starts in the correct mode before the first frame is rendered.

### 6.4 Double-Back Exit Protection

Android's "accidental back-exit" problem is solved with a `PopScope` wrapper on the root shell, tracking a timestamp of the last back press:

```dart
PopScope(
  canPop: false,
  onPopInvokedWithResult: (didPop, _) {
    final now = DateTime.now();
    if (_lastBackPress != null &&
        now.difference(_lastBackPress!) < const Duration(seconds: 2)) {
      SystemNavigator.pop(); // Actually exit
    } else {
      _lastBackPress = now;
      NeoToast.show(context, 'Press back again to exit');
    }
  },
  child: ...,
)
```

---

## 7. Event-Driven Backend (Phase 1.8)

### 7.1 Architecture Overview

The backend follows a **CQRS-adjacent event-driven architecture** with Apache Kafka as the message bus. Four microservices form a processing pipeline:

```
Mobile App
    │
    │ HTTP multipart/form-data
    ▼
┌─────────────┐
│ API Gateway │ ─── Kafka: screenshot.uploaded ──────────────────────────────┐
│ (Fastify 4) │                                                              │
│ Port 8000   │                                                              ▼
└─────────────┘                                                    ┌─────────────────┐
                                                                   │   OCR Service   │
                                                                   │ (FastAPI+Paddle) │
                                                                   │   Port 8001     │
                                                                   └─────────────────┘
                                                                          │ Kafka: screenshot.ocr.completed
                                                                          ▼
                                                                   ┌──────────────────────┐
                                                                   │  Embedding Service   │
                                                                   │ (FastAPI+MobileCLIP) │
                                                                   │   Port 8002          │
                                                                   └──────────────────────┘
                                                                          │ Kafka: screenshot.embedding.completed
                                                                          ▼
                                                                   ┌────────────────┐
                                                                   │ Search Service │
                                                                   │ (FastAPI+RRF)  │
                                                                   │   Port 8003    │
                                                                   └────────────────┘
                                                                          │ Kafka: screenshot.indexed
                                                                          ▼
                                                                   Mobile App receives
                                                                   WebSocket push notification
```

### 7.2 Why Kafka Over REST Chaining?

**Alternative A: REST chaining (API Gateway → OCR → Embedding → Search)**

- Simple to reason about
- OCR latency (300–800ms) blocks the API Gateway response thread
- A failure in the embedding service causes the entire upload to fail
- Retry logic must be implemented in every service
- No replay capability for historical data

**Alternative B: Message queue (RabbitMQ)**

- Better than REST chaining
- AMQP protocol has lower throughput ceiling (~50k msg/s vs. Kafka's millions)
- No built-in log replay — once consumed, a message is gone
- Consumer groups are less flexible for fan-out patterns

**Alternative C: Apache Kafka (chosen)**

- Decoupled: the API Gateway publishes `screenshot.uploaded` and is done
- **Log retention**: Kafka retains events for 7 days by default — if the OCR service crashes, it replays from the last committed offset
- **Consumer groups**: Multiple services can consume the same topic independently (future use: analytics service, notification service)
- **Exactly-once semantics** (EOS): Available with `enable.idempotence=true` — critical for preventing duplicate embeddings

### 7.3 Kafka in KRaft Mode (No ZooKeeper)

Traditional Kafka required a ZooKeeper ensemble (3+ nodes) just for metadata coordination. Since Kafka 3.3, **KRaft mode** replaces ZooKeeper with Kafka's own Raft consensus implementation. Our `docker-compose.yml` runs a single-broker KRaft setup:

```yaml
kafka:
  image: confluentinc/cp-kafka:7.6.1
  environment:
    KAFKA_NODE_ID: 1
    KAFKA_PROCESS_ROLES: broker,controller      # Combined broker+controller
    KAFKA_CONTROLLER_QUORUM_VOTERS: 1@kafka:29093
    KAFKA_LISTENERS: PLAINTEXT://0.0.0.0:9092,CONTROLLER://0.0.0.0:29093
    CLUSTER_ID: MkU3OEVBNTcwNTJENDM2Qk        # Required for KRaft
```

This removes an entire infrastructure component (ZooKeeper) from the stack — reducing operational complexity by 33% in the local development environment and meaningfully in production.

### 7.4 API Gateway: Fastify 4 + TypeScript

**Why Fastify over Express?**

| Metric | Fastify 4 | Express 4 |
|---|---|---|
| Requests/sec (JSON payload) | ~82,000 | ~28,000 |
| Schema validation | Built-in (Ajv) | Third-party |
| TypeScript support | Official `@fastify/type-provider-typebox` | `@types/express` |
| Plugin lifecycle | Promise-based, no callback hell | Mixed |

Fastify's **schema-first validation** catches malformed API requests before they reach business logic — no manual `if (!req.body.userId)` guards:

```typescript
const UploadSchema = {
  consumes: ['multipart/form-data'],
  response: {
    201: Type.Object({ id: Type.String(), status: Type.String() }),
    400: Type.Object({ error: Type.String() }),
  },
};
```

Authentication uses **JWT** (`@fastify/jwt`) with the `preHandler` hook pattern — routes opt-in to auth rather than opting out, preventing accidental unprotected endpoints:

```typescript
fastify.addHook('preHandler', async (request, reply) => {
  await request.jwtVerify();
});
```

File uploads stream directly to **MinIO** (S3-compatible object storage) without buffering the entire file in memory — critical for large screenshots (up to 25 MB).

### 7.5 OCR Service: FastAPI + PaddleOCR

FastAPI is chosen for Python services over Flask/Django because:
1. **Native `async def`** — I/O-bound Kafka consumer + model inference runs on asyncio without blocking threads
2. **Pydantic v2** — data validation with zero-runtime-cost compiled validators
3. **OpenAPI autodoc** — `/docs` endpoint auto-generated from route schemas (useful for frontend team integration)

The OCR service Kafka consumer uses a **transactional commit pattern**:

```python
consumer.poll(timeout_ms=100)
# ... process message
consumer.commit()  # Only after successful OCR + producer.send()
# If the process crashes between poll() and commit(), the message is re-delivered
```

This guarantees **at-least-once delivery** — no screenshots slip through without OCR. The deduplication logic in the embedding service handles the rare duplicate.

### 7.6 Hybrid Search Service: Reciprocal Rank Fusion

The search service maintains a dual index:
- **Inverted index** (dictionary-of-lists) for lexical token lookup: O(1) lookup per token
- **NumPy array** for batch cosine similarity computation: vectorized matmul, ~3ms for 10,000 items

Scores from both are fused with RRF:

```python
def reciprocal_rank_fusion(self, text_hits, vector_hits, k=60) -> List[SearchHit]:
    scores = defaultdict(float)
    for rank, hit in enumerate(text_hits):
        scores[hit.id] += 1.0 / (k + rank + 1)
    for rank, hit in enumerate(vector_hits):
        scores[hit.id] += 1.0 / (k + rank + 1)
    
    merged = sorted(scores.items(), key=lambda x: x[1], reverse=True)
    return [self._index[id_] for id_, _ in merged]
```

**Why not a weighted sum?** A BM25 lexical score of `0.73` and a cosine similarity of `0.73` carry completely different semantics. BM25 is already normalized per-document; cosine similarity depends on embedding space geometry. RRF treats only the *rank position* — immune to score calibration issues.

### 7.7 Infrastructure as Code

The entire stack — 9 services + 2 observability tools — is defined in a single `docker-compose.yml` with named volumes for persistence. Spin up the full production-equivalent stack with:

```bash
make infra-up  # docker compose up -d with health checks
make infra-down # Tear down, preserving volumes
make test-e2e  # Runs tests/integration/test_pipeline_e2e.py
```

The E2E test suite (`pytest + httpx`) validates the full pipeline end-to-end:
1. `POST /api/v1/screenshots` to the API Gateway with a real image file
2. Poll the search service until `screenshot.indexed` Kafka event is confirmed
3. `GET /api/v1/search?q=test` and assert the uploaded screenshot appears in results
4. Verify Prometheus metrics incremented on all four services

---

## 8. Observability: The Three Pillars

### 8.1 Metrics (Prometheus)

Every service exposes a `/metrics` endpoint with:
- `http_requests_total{method, route, status}` — request counter by outcome
- `http_request_duration_seconds{method, route}` — latency histogram
- Service-specific metrics (e.g., `ocr_processing_seconds`, `kafka_messages_consumed_total`)

### 8.2 Dashboards (Grafana)

Pre-configured Grafana dashboards (defined in `telemetry/grafana/`) visualize:
- Kafka consumer lag per topic/partition — the critical metric for detecting processing backpressure
- OCR + Embedding throughput in screenshots/minute
- P50/P95/P99 API latency percentiles

### 8.3 Tracing (Planned: OpenTelemetry)

Service base templates include an `OTEL_EXPORTER_OTLP_ENDPOINT` environment variable hook. Phase 2 will activate distributed tracing via Jaeger, enabling cross-service trace correlation (see a single screenshot's journey from upload to indexed as a single trace with spans).

---

## 9. Lessons Learned & Engineering Traps

### 9.1 Android AGP 9.1 + compileSdk 36

AGP (Android Gradle Plugin) 9.1 introduced strict transitive dependency SDK version enforcement. Building with `compileSdk 34` (the Flutter default at the time) failed with `checkDebugAarMetadata` errors when newer AndroidX libraries required 36. **Fix**: Set `compileSdk = 36` at the root `android/build.gradle.kts` — all transitive dependencies inherit it.

### 9.2 SnackBar Color in Light Mode

Flutter's `SnackBar` inherits from `SnackBarThemeData`. In light mode, the default theme produces near-invisible text. **Fix**: Build a custom `NeoToast` overlay with explicit `TextStyle` independent of `Theme` — visible in all modes.

### 9.3 GoRouter Shell Navigation "Jump"

Using `GoRoute` for tab switching triggered full route transitions. **Fix**: Migrate to `StatefulShellRoute.indexedStack` with the shell wrapping an `IndexedStack` — all branches are rendered simultaneously, switching is a simple index change with zero rebuilds.

### 9.4 `Float32List` vs `List<double>` for Vectors

ObjectBox's `@HnswIndex` requires `Float32List`. Storing vectors as `List<double>` compiles but fails at runtime with an `AssertionError`. At 384 dimensions × 4 bytes/float, each embedding is exactly 1,536 bytes — this matters at scale.

---

## 10. What's Next: Phase 1.9

With the entire local-first pipeline validated and the backend infrastructure scaffolded, the next phase integrates them:

1. **Android Background Screenshot Auto-Detection**: A foreground service using `MediaStore` + `ContentObserver` that watches for new screenshots and pipes them through the OCR → Embedding → ObjectBox pipeline automatically — without the user ever tapping "Import."

2. **Cloud Sync Client**: An encrypted, resumable sync client in `apps/mobile` that pushes local ObjectBox vectors to the API Gateway when on Wi-Fi, enabling cross-device search and backup.

3. **First-Launch Privacy Modal**: A transparent, legally-precise consent flow explaining exactly what data stays on-device and what (if anything) goes to the cloud.

---

## 11. By the Numbers

| Metric | Value |
|---|---|
| Total test assertions passing | 52/52 |
| Dart/Flutter packages in monorepo | 3 |
| Backend microservices | 4 |
| Infrastructure containers (Docker) | 9 |
| Kafka topics | 4 |
| On-device ML models | 3 (OCR det, OCR rec, MobileCLIP-S0) |
| Vector dimensions | 384 |
| Model download size | ~25 MB total (streaming, not bundled) |
| Max screenshot upload | 25 MB |
| Approximate HNSW search latency | O(log N), ~5ms at 100k items |
| Lines of production Dart code | ~4,200 |
| Lines of Python backend code | ~2,100 |
| Lines of TypeScript backend code | ~900 |

---

## Conclusion

Pomniter is being built the way software should be built: with clear principles, deliberate tradeoffs documented in code, observable infrastructure, and a test suite that proves the system works before a user ever touches it.

The hardest engineering problems were not the ML models — those exist as open, well-documented packages. The hardest problems were the boring ones: making the bottom navigation bar not jump, ensuring theme persists across cold starts, choosing the right vector similarity metric, and selecting a database that could survive a decade of Android API changes.

Those are the problems worth writing about. Those are the decisions that determine whether a product survives at scale.

The code is open-source at [github.com/markstone111/pomniter-app](https://github.com/markstone111/pomniter-app).

---

*Built with: Flutter 3.x · Dart 3.x · Riverpod 2.6 · GoRouter 14.8 · ObjectBox 4.x · ONNX Runtime · FastAPI · Fastify 4 · Apache Kafka 3.7 KRaft · PostgreSQL 16 · Redis 7 · MinIO · Prometheus · Grafana*
