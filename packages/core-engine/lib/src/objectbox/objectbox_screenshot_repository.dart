/// ObjectBox-backed [ScreenshotRepository] implementation.
library;

import 'dart:async';

import 'package:objectbox/objectbox.dart';
import 'package:pomniter_shared_models/pomniter_shared_models.dart';

import '../exceptions/engine_exceptions.dart';
import '../interfaces/screenshot_repository.dart';
import 'objectbox_entities.dart';
// ignore: library_prefixes
import '../../objectbox.g.dart' as obg;

/// Persistent [ScreenshotRepository] backed by ObjectBox.
///
/// All methods are synchronous at the ObjectBox layer but wrapped in
/// [Future] to satisfy the interface contract and allow seamless swap with
/// the [InMemoryScreenshotRepository] in tests.
class ObjectBoxScreenshotRepository implements ScreenshotRepository {
  final Store _store;
  late final Box<ScreenshotEntity> _box;
  final StreamController<List<Screenshot>> _controller =
      StreamController<List<Screenshot>>.broadcast();

  ObjectBoxScreenshotRepository(Store store) : _store = store {
    _box = store.box<ScreenshotEntity>();
  }

  // ─── ScreenshotRepository Interface ──────────────────────────────────────

  @override
  Future<void> saveScreenshot(Screenshot screenshot) async {
    try {
      final entity = ScreenshotEntity.fromDomain(screenshot);

      // Upsert: find existing by appId to preserve obId and embedding vector
      final existing = _queryByAppId(screenshot.id);
      if (existing != null) {
        entity.obId = existing.obId;
        // Preserve existing embedding — empty Float32List means "not yet embedded"
        if (existing.embedding.isNotEmpty) {
          entity.embedding = existing.embedding;
        }
      }

      _box.put(entity);

      // Cascade text blocks
      final blockBox = _store.box<TextBlockEntity>();
      if (existing != null && existing.textBlocks.isNotEmpty) {
        blockBox.removeMany(
          existing.textBlocks.map((tb) => tb.obId).toList(),
        );
      }
      if (screenshot.textBlocks.isNotEmpty) {
        final blocks = screenshot.textBlocks.map((tb) {
          final be = TextBlockEntity.fromDomain(tb);
          be.screenshot.target = entity;
          return be;
        }).toList();
        blockBox.putMany(blocks);
      }

      _notify();
    } catch (e, st) {
      throw VectorStoreException(
        'Failed to save screenshot ${screenshot.id}: $e',
        cause: e,
        stackTrace: st,
      );
    }
  }

  @override
  Future<void> updateScreenshot(Screenshot screenshot) async {
    return saveScreenshot(screenshot); // upsert covers update
  }

  @override
  Future<Screenshot?> getScreenshotById(String id) async {
    return _queryByAppId(id)?.toDomain();
  }

  @override
  Future<List<Screenshot>> getAllScreenshots({
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final all = _box
          .query()
          .order(obg.ScreenshotEntity_.capturedAt, flags: Order.descending)
          .build()
          .find();
      if (offset >= all.length) return [];
      final end = (offset + limit).clamp(0, all.length);
      return all.sublist(offset, end).map((e) => e.toDomain()).toList();
    } catch (e, st) {
      throw VectorStoreException(
        'Failed to retrieve all screenshots: $e',
        cause: e,
        stackTrace: st,
      );
    }
  }

  @override
  Future<void> deleteScreenshot(String id) async {
    try {
      final entity = _queryByAppId(id);
      if (entity == null) return;

      // Remove associated text blocks first
      final blockBox = _store.box<TextBlockEntity>();
      blockBox.removeMany(entity.textBlocks.map((tb) => tb.obId).toList());
      _box.remove(entity.obId);

      _notify();
    } catch (e, st) {
      throw VectorStoreException(
        'Failed to delete screenshot $id: $e',
        cause: e,
        stackTrace: st,
      );
    }
  }

  @override
  Future<int> getScreenshotCount() async {
    return _box.count();
  }

  @override
  Stream<List<Screenshot>> watchScreenshots() {
    return _controller.stream;
  }

  // ─── Private ────────────────────────────────────────────────────────────

  ScreenshotEntity? _queryByAppId(String appId) {
    return _box
        .query(obg.ScreenshotEntity_.appId.equals(appId))
        .build()
        .findFirst();
  }

  void _notify() {
    try {
      final all = _box
          .query()
          .order(obg.ScreenshotEntity_.capturedAt, flags: Order.descending)
          .build()
          .find()
          .map((e) => e.toDomain())
          .toList();
      _controller.add(all);
    } catch (_) {
      // Swallow notification errors — they don't affect write correctness.
    }
  }

  /// Must be called when the repository is no longer needed.
  void dispose() {
    _controller.close();
  }
}
