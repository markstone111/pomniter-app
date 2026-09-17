import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:permission_handler/permission_handler.dart';
import 'package:pomniter_shared_models/pomniter_shared_models.dart';

/// Dart-side wrapper for the native [ScreenshotMethodChannel].
///
/// Responsibilities:
/// - Request the correct media permission for the running Android version.
/// - Start / stop the native Kotlin [ScreenshotIndexerService].
/// - Receive "onScreenshotDetected" callbacks from the native side and
///   dispatch them to registered [ScreenshotDetectedCallback] listeners.
/// - Notify the native side when an index completes (increments notification count).
class ScreenshotIndexerService {
  ScreenshotIndexerService._();

  static final ScreenshotIndexerService instance = ScreenshotIndexerService._();

  static const _channel = MethodChannel('com.pomniter.app/indexer');

  final List<ScreenshotDetectedCallback> _listeners = [];

  bool _initialized = false;
  bool _isRunning = false;

  bool get isRunning => _isRunning;

  // ─── Public API ────────────────────────────────────────────────────────────

  /// Requests the appropriate media permission, registers the method call
  /// handler, and starts the native foreground service.
  ///
  /// Returns `true` if the service started successfully, `false` if the user
  /// denied the required permission.
  Future<bool> start() async {
    if (_isRunning) return true;

    final granted = await _requestMediaPermission();
    if (!granted) return false;

    if (!_initialized) {
      _channel.setMethodCallHandler(_handleNativeCall);
      _initialized = true;
    }

    try {
      await _channel.invokeMethod<void>('startIndexerService');
      _isRunning = true;
      return true;
    } on PlatformException catch (_) {
      return false;
    }
  }

  /// Stops the native foreground service.
  Future<void> stop() async {
    if (!_isRunning) return;
    try {
      await _channel.invokeMethod<void>('stopIndexerService');
    } on PlatformException catch (_) {
      // Service may already be dead — treat as success
    } finally {
      _isRunning = false;
    }
  }

  /// Must be called after a screenshot has been successfully indexed in
  /// ObjectBox. Increments the "X indexed today" counter in the notification.
  Future<void> notifyIndexComplete() async {
    try {
      await _channel.invokeMethod<void>('notifyIndexComplete');
    } on PlatformException catch (_) {}
  }

  void addListener(ScreenshotDetectedCallback callback) {
    _listeners.add(callback);
  }

  void removeListener(ScreenshotDetectedCallback callback) {
    _listeners.remove(callback);
  }

  // ─── Permission ────────────────────────────────────────────────────────────

  /// Returns `true` if media access is granted.
  ///
  /// Permission strategy (adaptive):
  /// - Android ≥ 14 (API 34+): request [Permission.photos] which maps to
  ///   READ_MEDIA_VISUAL_USER_SELECTED on the OS side — user can grant
  ///   "selected photos only" or "all photos".
  /// - Android 13 (API 33): request [Permission.photos] → READ_MEDIA_IMAGES.
  /// - Android ≤ 12 (API ≤ 32): request [Permission.storage] → READ_EXTERNAL_STORAGE.
  Future<bool> _requestMediaPermission() async {
    // permission_handler's Permission.photos automatically maps to the correct
    // permission constant for the current Android API level.
    final status = await Permission.photos.request();
    if (status.isGranted || status.isLimited) return true;

    // Also request notification permission on Android 13+
    await Permission.notification.request();
    return false;
  }

  // ─── Native → Dart call handler ────────────────────────────────────────────

  Future<dynamic> _handleNativeCall(MethodCall call) async {
    if (call.method == 'onScreenshotDetected') {
      final filePath = call.arguments as String?;
      if (filePath == null || filePath.isEmpty) return;
      for (final listener in List.of(_listeners)) {
        listener(filePath);
      }
    }
  }

  // ─── Helper: Build a Screenshot domain object from a raw file path ─────────

  /// Constructs a [Screenshot] from a native file path detected by the
  /// ContentObserver. The extracted text is set to a placeholder until
  /// the real OCR pipeline processes the file.
  static Future<Screenshot> buildFromPath(String filePath) async {
    final file = File(filePath);
    final stat = await file.stat();
    final now = DateTime.now();
    final id = 'sc-auto-${now.millisecondsSinceEpoch}';

    return Screenshot(
      id: id,
      filePath: filePath,
      capturedAt: stat.modified,
      indexedAt: now,
      width: 1080,
      height: 1920,
      fileSizeBytes: stat.size,
      category: ScreenshotCategory.other,
      extractedText: 'Auto-detected: ${p.basename(filePath)}',
      tags: ['auto-indexed'],
      summary: 'Screenshot auto-detected and indexed by Pomniter',
    );
  }
}

typedef ScreenshotDetectedCallback = void Function(String filePath);
