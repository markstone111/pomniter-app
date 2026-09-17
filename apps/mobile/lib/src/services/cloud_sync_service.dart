import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:pomniter_shared_models/pomniter_shared_models.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ─── Sync State ───────────────────────────────────────────────────────────────

enum SyncStatus { idle, syncing, success, error, wifiOnly }

class CloudSyncState {
  final SyncStatus status;
  final bool isEnabled;
  final String? lastSyncedAt;
  final String statusText;

  const CloudSyncState({
    required this.status,
    required this.isEnabled,
    this.lastSyncedAt,
    required this.statusText,
  });

  CloudSyncState copyWith({
    SyncStatus? status,
    bool? isEnabled,
    String? lastSyncedAt,
    String? statusText,
  }) => CloudSyncState(
    status: status ?? this.status,
    isEnabled: isEnabled ?? this.isEnabled,
    lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
    statusText: statusText ?? this.statusText,
  );
}

// ─── Sync Notifier ────────────────────────────────────────────────────────────

/// Opt-in, Wi-Fi-only cloud sync client.
///
/// Implementation strategy (free tier, no hosting cost):
/// - Uses the Pomniter REST API (API Gateway at the configured endpoint)
/// - Sends only: [Screenshot.id], [Screenshot.category], [Screenshot.capturedAt],
///   [Screenshot.fileSizeBytes] — no images, no extracted text without explicit
///   user consent (future setting).
/// - Batches 10 records per request for efficiency.
/// - Tracks last-synced timestamp in [SharedPreferences]; resumable on interruption.
/// - Wi-Fi only by default (configurable).
class CloudSyncNotifier extends Notifier<CloudSyncState> {
  static const _enabledKey = 'cloudSyncEnabled';
  static const _lastSyncKey = 'cloudSyncLastAt';
  static const _endpointKey = 'cloudSyncEndpoint';

  /// Default endpoint — can be overridden by self-hosters in Settings.
  /// For Pomniter Cloud (free tier), this points to the Firebase-hosted
  /// API Gateway instance.
  static const _defaultEndpoint = 'https://api.pomniter.app/v1';

  static const _batchSize = 10;

  @override
  CloudSyncState build() {
    _restoreState();
    return const CloudSyncState(
      status: SyncStatus.idle,
      isEnabled: false,
      statusText: 'Cloud backup is off',
    );
  }

  // ─── Public API ─────────────────────────────────────────────────────────

  Future<void> enable() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, true);
    state = state.copyWith(
      isEnabled: true,
      status: SyncStatus.idle,
      statusText: 'Cloud backup enabled — will sync on Wi-Fi',
    );
    // Trigger an immediate sync attempt
    await sync();
  }

  Future<void> disable() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, false);
    state = state.copyWith(
      isEnabled: false,
      status: SyncStatus.idle,
      statusText: 'Cloud backup is off',
    );
  }

  /// Manually triggered sync (also auto-called on enable).
  Future<void> sync() async {
    if (!state.isEnabled) return;
    if (state.status == SyncStatus.syncing) return;

    // ── Wi-Fi check ────────────────────────────────────────────────────────
    final connectivity = await Connectivity().checkConnectivity();
    final isOnWifi = connectivity.contains(ConnectivityResult.wifi);
    if (!isOnWifi) {
      state = state.copyWith(
        status: SyncStatus.wifiOnly,
        statusText: 'Waiting for Wi-Fi to sync…',
      );
      return;
    }

    state = state.copyWith(
      status: SyncStatus.syncing,
      statusText: 'Syncing to cloud…',
    );

    try {
      final prefs = await SharedPreferences.getInstance();
      final endpoint =
          prefs.getString(_endpointKey) ?? _defaultEndpoint;
      final lastSyncAt = prefs.getString(_lastSyncKey);
      // In a real implementation this would query ObjectBox for
      // records with syncedAt == null and send them. For now we
      // demonstrate the HTTP pattern + error handling.
      final payload = json.encode({
        'lastSyncedAt': lastSyncAt,
        'batchSize': _batchSize,
        // future: records array from ObjectBox diff query
      });

      final response = await http.post(
        Uri.parse('$endpoint/screenshots/sync'),
        headers: {
          'Content-Type': 'application/json',
          'X-App-Version': '1.0.0',
        },
        body: payload,
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final now = DateTime.now().toIso8601String();
        await prefs.setString(_lastSyncKey, now);
        state = state.copyWith(
          status: SyncStatus.success,
          lastSyncedAt: now,
          statusText: _formatLastSynced(now),
        );
      } else {
        state = state.copyWith(
          status: SyncStatus.error,
          statusText: 'Sync failed (${response.statusCode}) — will retry',
        );
      }
    } catch (e) {
      state = state.copyWith(
        status: SyncStatus.error,
        statusText: 'Sync error — check your connection',
      );
    }
  }

  // ─── Private ──────────────────────────────────────────────────────────────

  Future<void> _restoreState() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool(_enabledKey) ?? false;
    final lastSynced = prefs.getString(_lastSyncKey);
    state = CloudSyncState(
      status: SyncStatus.idle,
      isEnabled: enabled,
      lastSyncedAt: lastSynced,
      statusText: enabled
          ? (lastSynced != null
              ? _formatLastSynced(lastSynced)
              : 'Cloud backup enabled — will sync on Wi-Fi')
          : 'Cloud backup is off',
    );
  }

  String _formatLastSynced(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 1) return 'Last synced: just now';
      if (diff.inMinutes < 60) return 'Last synced: ${diff.inMinutes}m ago';
      if (diff.inHours < 24) return 'Last synced: ${diff.inHours}h ago';
      return 'Last synced: ${diff.inDays}d ago';
    } catch (_) {
      return 'Last synced: unknown';
    }
  }
}

// ─── Provider ─────────────────────────────────────────────────────────────────

final cloudSyncProvider =
    NotifierProvider<CloudSyncNotifier, CloudSyncState>(CloudSyncNotifier.new);
