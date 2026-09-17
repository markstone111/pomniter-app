import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/engine_providers.dart';
import '../providers/screenshot_providers.dart';
import '../services/screenshot_indexer_service.dart';

// ─── State ────────────────────────────────────────────────────────────────────

class IndexerState {
  final bool isRunning;
  final bool isEnabled;
  final String statusText;

  const IndexerState({
    required this.isRunning,
    required this.isEnabled,
    required this.statusText,
  });

  IndexerState copyWith({bool? isRunning, bool? isEnabled, String? statusText}) {
    return IndexerState(
      isRunning: isRunning ?? this.isRunning,
      isEnabled: isEnabled ?? this.isEnabled,
      statusText: statusText ?? this.statusText,
    );
  }
}

// ─── Notifier ─────────────────────────────────────────────────────────────────

class IndexerNotifier extends Notifier<IndexerState> {
  static const _prefKey = 'autoIndexEnabled';

  @override
  IndexerState build() {
    // Wire the native callback into the Riverpod graph
    ScreenshotIndexerService.instance.addListener(_onScreenshotDetected);
    ref.onDispose(() {
      ScreenshotIndexerService.instance.removeListener(_onScreenshotDetected);
    });
    // Restore persisted preference
    _restoreState();
    return const IndexerState(
      isRunning: false,
      isEnabled: false,
      statusText: 'Auto-indexing is off',
    );
  }

  // ─── Public ────────────────────────────────────────────────────────────────

  Future<void> enable() async {
    final started = await ScreenshotIndexerService.instance.start();
    if (!started) {
      state = state.copyWith(
        isRunning: false,
        statusText: 'Permission denied — grant media access in Settings',
      );
      return;
    }
    state = state.copyWith(
      isRunning: true,
      isEnabled: true,
      statusText: 'Watching for new screenshots…',
    );
    await _persist(true);
  }

  Future<void> disable() async {
    await ScreenshotIndexerService.instance.stop();
    state = state.copyWith(
      isRunning: false,
      isEnabled: false,
      statusText: 'Auto-indexing is off',
    );
    await _persist(false);
  }

  // ─── Private ──────────────────────────────────────────────────────────────

  Future<void> _restoreState() async {
    final prefs = await SharedPreferences.getInstance();
    final wasEnabled = prefs.getBool(_prefKey) ?? false;
    if (wasEnabled) {
      await enable();
    }
  }

  Future<void> _persist(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKey, enabled);
  }

  /// Called when the native ContentObserver detects a new screenshot.
  Future<void> _onScreenshotDetected(String filePath) async {
    state = state.copyWith(statusText: 'Indexing ${filePath.split('/').last}…');
    try {
      final screenshot =
          await ScreenshotIndexerService.buildFromPath(filePath);
      final screenshotRepo = ref.read(screenshotRepoProvider);
      final searchRepo = ref.read(searchRepoProvider);

      await screenshotRepo.saveScreenshot(screenshot);
      await searchRepo.indexScreenshot(screenshot);
      await ScreenshotIndexerService.instance.notifyIndexComplete();

      // Refresh any active UI provider watching the list
      ref.invalidate(screenshotsListProvider);

      state = state.copyWith(statusText: 'Indexed ${filePath.split('/').last}');
    } catch (_) {
      state = state.copyWith(statusText: 'Failed to index — will retry');
    }
  }
}

// ─── Providers ────────────────────────────────────────────────────────────────

final indexerProvider =
    NotifierProvider<IndexerNotifier, IndexerState>(IndexerNotifier.new);
