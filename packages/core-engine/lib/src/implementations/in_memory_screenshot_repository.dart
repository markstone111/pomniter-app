import 'dart:async';
import 'package:pomniter_shared_models/pomniter_shared_models.dart';
import '../interfaces/screenshot_repository.dart';

/// In-memory implementation of [ScreenshotRepository] for testing and local development.
class InMemoryScreenshotRepository implements ScreenshotRepository {
  final Map<String, Screenshot> _storage = {};
  final StreamController<List<Screenshot>> _controller =
      StreamController<List<Screenshot>>.broadcast();

  void _notify() {
    _controller.add(_storage.values.toList());
  }

  @override
  Future<List<Screenshot>> getAllScreenshots({int limit = 50, int offset = 0}) async {
    final list = _storage.values.toList()
      ..sort((a, b) => b.capturedAt.compareTo(a.capturedAt));
    if (offset >= list.length) return [];
    final end = (offset + limit) > list.length ? list.length : (offset + limit);
    return list.sublist(offset, end);
  }

  @override
  Future<Screenshot?> getScreenshotById(String id) async {
    return _storage[id];
  }

  @override
  Future<void> saveScreenshot(Screenshot screenshot) async {
    _storage[screenshot.id] = screenshot;
    _notify();
  }

  @override
  Future<void> updateScreenshot(Screenshot screenshot) async {
    _storage[screenshot.id] = screenshot;
    _notify();
  }

  @override
  Future<void> deleteScreenshot(String id) async {
    _storage.remove(id);
    _notify();
  }

  @override
  Future<int> getScreenshotCount() async {
    return _storage.length;
  }

  @override
  Stream<List<Screenshot>> watchScreenshots() {
    return _controller.stream;
  }

  void dispose() {
    _controller.close();
  }
}
