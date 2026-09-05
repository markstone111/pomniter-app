import 'package:pomniter_shared_models/pomniter_shared_models.dart';

/// Abstract contract for persisting and retrieving screenshot records.
abstract interface class ScreenshotRepository {
  Future<List<Screenshot>> getAllScreenshots({int limit = 50, int offset = 0});
  Future<Screenshot?> getScreenshotById(String id);
  Future<void> saveScreenshot(Screenshot screenshot);
  Future<void> updateScreenshot(Screenshot screenshot);
  Future<void> deleteScreenshot(String id);
  Future<int> getScreenshotCount();
  Stream<List<Screenshot>> watchScreenshots();
}
