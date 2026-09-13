/// ObjectBox entity definitions for Pomniter's local vector database.
///
/// These entities map 1:1 to the domain models in `pomniter_shared_models`
/// but add ObjectBox-specific annotations (IDs, HNSW vector index, relations).
///
/// ## Vector Index
/// [ScreenshotEntity.embedding] is annotated with [@HnswIndex] for
/// approximate nearest-neighbour (ANN) search using the Hierarchical
/// Navigable Small World (HNSW) algorithm at query time.
///
/// ## Code Generation
/// Run `dart run build_runner build` to generate `objectbox.g.dart`.
library;

import 'dart:typed_data';

import 'package:objectbox/objectbox.dart';
import 'package:pomniter_shared_models/pomniter_shared_models.dart';

// ─── Screenshot Entity ────────────────────────────────────────────────────────

@Entity()
class ScreenshotEntity {
  /// ObjectBox internal auto-increment integer ID.
  @Id()
  int obId = 0;

  /// Application-level string UUID (e.g. 'sc-101').
  @Index()
  @Unique(onConflict: ConflictStrategy.replace)
  late String appId;

  late String filePath;
  late String capturedAt;   // ISO 8601
  late String indexedAt;    // ISO 8601

  late int width;
  late int height;
  late int fileSizeBytes;

  late String extractedText;
  late String tagsJson;     // JSON array of strings
  late String category;     // ScreenshotCategory.name
  late String? summary;
  late bool isFavorite;

  /// 384-dimensional MobileCLIP-S0 L2-normalised embedding vector.
  ///
  /// HNSW index configuration:
  ///   - `dimensions`: must match [EmbeddingEngine.vectorDimension] (384).
  ///   - `distanceType`: cosine — but since vectors are L2-normalised by
  ///     [OnnxClipEmbeddingEngine._l2Normalize], dot product and cosine
  ///     similarity are equivalent, giving maximum HNSW efficiency.
  @HnswIndex(dimensions: 384, distanceType: VectorDistanceType.cosine)
  Float32List embedding = Float32List(0);

  final textBlocks = ToMany<TextBlockEntity>();

  // ─── Converters ───────────────────────────────────────────────────────────

  static ScreenshotEntity fromDomain(
    Screenshot s, {
    List<double>? embedding,
  }) {
    return ScreenshotEntity()
      ..appId = s.id
      ..filePath = s.filePath
      ..capturedAt = s.capturedAt.toIso8601String()
      ..indexedAt = s.indexedAt?.toIso8601String() ?? DateTime.now().toIso8601String()
      ..width = s.width
      ..height = s.height
      ..fileSizeBytes = s.fileSizeBytes
      ..extractedText = s.extractedText
      ..tagsJson = _encodeStringList(s.tags)
      ..category = s.category.name
      ..summary = s.summary
      ..isFavorite = s.isFavorite
      ..embedding = embedding != null
          ? Float32List.fromList(embedding)
          : Float32List(0);
  }

  Screenshot toDomain() {
    return Screenshot(
      id: appId,
      filePath: filePath,
      capturedAt: DateTime.parse(capturedAt),
      indexedAt: indexedAt.isNotEmpty ? DateTime.tryParse(indexedAt) : null,
      width: width,
      height: height,
      fileSizeBytes: fileSizeBytes,
      extractedText: extractedText,
      tags: _decodeStringList(tagsJson),
      category: ScreenshotCategory.values.firstWhere(
        (c) => c.name == category,
        orElse: () => ScreenshotCategory.other,
      ),
      summary: summary,
      isFavorite: isFavorite,
      textBlocks: textBlocks.map((tb) => tb.toDomain()).toList(),
    );
  }


  static String _encodeStringList(List<String> list) {
    if (list.isEmpty) return '[]';
    return '[${list.map((s) => '"$s"').join(',')}]';
  }

  static List<String> _decodeStringList(String json) {
    final trimmed = json.trim();
    if (trimmed == '[]' || trimmed.isEmpty) return [];
    final inner = trimmed.substring(1, trimmed.length - 1);
    return inner
        .split(',')
        .map((s) => s.trim().replaceAll('"', ''))
        .where((s) => s.isNotEmpty)
        .toList();
  }
}

// ─── TextBlock Entity ─────────────────────────────────────────────────────────

@Entity()
class TextBlockEntity {
  @Id()
  int obId = 0;

  late String text;
  late double confidence;

  // BoundingBox fields (flattened)
  late double boxLeft;
  late double boxTop;
  late double boxWidth;
  late double boxHeight;

  /// Back-reference to the parent screenshot.
  final screenshot = ToOne<ScreenshotEntity>();

  static TextBlockEntity fromDomain(TextBlock tb) {
    return TextBlockEntity()
      ..text = tb.text
      ..confidence = tb.confidence
      ..boxLeft = tb.boundingBox?.left ?? 0
      ..boxTop = tb.boundingBox?.top ?? 0
      ..boxWidth = tb.boundingBox?.width ?? 0
      ..boxHeight = tb.boundingBox?.height ?? 0;
  }

  TextBlock toDomain() {
    return TextBlock(
      text: text,
      confidence: confidence,
      boundingBox: BoundingBox(
        left: boxLeft,
        top: boxTop,
        width: boxWidth,
        height: boxHeight,
      ),
    );
  }
}
