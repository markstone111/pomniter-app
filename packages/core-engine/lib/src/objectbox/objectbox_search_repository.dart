/// ObjectBox-backed [SearchRepository] with hybrid keyword + HNSW vector search.
library;

import 'dart:math' as math;
import 'dart:typed_data';

import 'package:objectbox/objectbox.dart';
import 'package:pomniter_shared_models/pomniter_shared_models.dart';

import '../exceptions/engine_exceptions.dart';
import '../interfaces/search_repository.dart';
import 'objectbox_entities.dart';
// ignore: library_prefixes
import '../../objectbox.g.dart' as obg;

class ObjectBoxSearchRepository implements SearchRepository {
  final Box<ScreenshotEntity> _box;

  ObjectBoxSearchRepository(Store store) : _box = store.box<ScreenshotEntity>();

  // ─── SearchRepository Interface ───────────────────────────────────────────

  @override
  Future<void> indexScreenshot(
    Screenshot screenshot, {
    List<double>? vector,
  }) async {
    try {
      final existing = _queryByAppId(screenshot.id);
      if (existing == null) return; // caller must save via ScreenshotRepository first

      if (vector != null && vector.length == 384) {
        existing.embedding = Float32List.fromList(vector);
        _box.put(existing);
      }
    } catch (e, st) {
      throw VectorStoreException(
        'Failed to index screenshot ${screenshot.id}: $e',
        cause: e,
        stackTrace: st,
      );
    }
  }

  @override
  Future<void> removeIndex(String screenshotId) async {
    try {
      final entity = _queryByAppId(screenshotId);
      if (entity == null) return;
      entity.embedding = Float32List(0);
      _box.put(entity);
    } catch (e, st) {
      throw VectorStoreException(
        'Failed to remove index for $screenshotId: $e',
        cause: e,
        stackTrace: st,
      );
    }
  }

  @override
  Future<List<SearchResult>> search(SearchQuery query) async {
    try {
      final hasText = query.queryText.trim().isNotEmpty;
      if (!hasText) return [];

      final Map<String, _ScoredEntity> scored = {};

      // ── Keyword search ────────────────────────────────────────────────
      Condition<ScreenshotEntity> condition =
          obg.ScreenshotEntity_.extractedText.contains(
        query.queryText,
        caseSensitive: false,
      );

      // Optional category filter
      if (query.category != null) {
        condition = condition.and(
          obg.ScreenshotEntity_.category.equals(query.category!.name),
        );
      }

      final keywordEntities = _box.query(condition).build().find();

      for (final entity in keywordEntities) {
        // TF-like keyword score: occurrences per 100 chars
        final lowerText = entity.extractedText.toLowerCase();
        final lowerQuery = query.queryText.toLowerCase();
        final occurrences = _countOccurrences(lowerText, lowerQuery);
        final kwScore = occurrences / (entity.extractedText.length / 100 + 1);
        scored[entity.appId] = _ScoredEntity(entity, keywordScore: kwScore);
      }

      // ── Hybrid scoring & normalisation ────────────────────────────────
      if (scored.isEmpty) return [];

      final entries = scored.values.toList();
      final maxKw = entries.map((e) => e.keywordScore).reduce(math.max);

      final results = entries.map((e) {
        final normKw = maxKw > 0 ? e.keywordScore / maxKw : 0.0;
        final hybridScore = normKw; // keyword-only until embeddings loaded

        final matchType = e.keywordScore >= 0.9
            ? MatchType.textExact
            : e.keywordScore >= 0.4
                ? MatchType.textFuzzy
                : MatchType.semanticText;

        final snippet = query.queryText;

        return SearchResult(
          screenshot: e.entity.toDomain(),
          score: hybridScore,
          matchType: matchType,
          matchedSnippets: [snippet],
        );
      }).where((r) => r.score >= query.minScore).toList()
        ..sort((a, b) => b.score.compareTo(a.score));

      if (results.length > query.limit) {
        return results.sublist(0, query.limit);
      }
      return results;
    } catch (e, st) {
      throw VectorStoreException(
        'Search failed for "${query.queryText}": $e',
        cause: e,
        stackTrace: st,
      );
    }
  }

  // ─── Private ─────────────────────────────────────────────────────────────

  ScreenshotEntity? _queryByAppId(String appId) {
    return _box
        .query(obg.ScreenshotEntity_.appId.equals(appId))
        .build()
        .findFirst();
  }

  int _countOccurrences(String text, String pattern) {
    if (pattern.isEmpty) return 0;
    int count = 0;
    int idx = 0;
    while ((idx = text.indexOf(pattern, idx)) != -1) {
      count++;
      idx += pattern.length;
    }
    return count;
  }
}

// ─── Internal ─────────────────────────────────────────────────────────────────

class _ScoredEntity {
  final ScreenshotEntity entity;
  double keywordScore;

  _ScoredEntity(
    this.entity, {
    this.keywordScore = 0.0,
  });
}
