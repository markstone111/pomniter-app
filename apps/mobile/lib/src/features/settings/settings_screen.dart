import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pomniter_design_system/pomniter_design_system.dart';
import '../../providers/theme_provider.dart';
import '../../providers/indexer_providers.dart';
import '../../services/cloud_sync_service.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final indexerState = ref.watch(indexerProvider);
    final syncState = ref.watch(cloudSyncProvider);
    final neo = NeoTheme.of(context);

    return Scaffold(
      backgroundColor: neo.bgMain,
      appBar: const NeoAppBar(title: 'SETTINGS'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Local-First Banner ────────────────────────────────────────
            NeoCard(
              backgroundColor: NeoColors.green,
              child: Row(
                children: [
                  const Icon(Icons.security, size: 36, color: NeoColors.black),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'LOCAL-FIRST GUARANTEE',
                          style: NeoTypography.labelMedium.copyWith(
                            color: NeoColors.black,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Your screenshots and OCR vectors never leave this device by default.',
                          style:
                              NeoTypography.bodySmall.copyWith(color: NeoColors.black),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Appearance ────────────────────────────────────────────────
            Text('APPEARANCE',
                style: NeoTypography.headlineSmall
                    .copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 10),
            NeoCard(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('DARK MODE',
                          style: NeoTypography.labelMedium
                              .copyWith(fontWeight: FontWeight.bold)),
                      Text('High-contrast neo-brutal dark theme',
                          style: NeoTypography.bodySmall),
                    ],
                  ),
                  Switch(
                    value: themeMode == ThemeMode.dark,
                    activeThumbColor: NeoColors.yellow,
                    onChanged: (isDark) {
                      ref.read(themeModeProvider.notifier).setMode(
                            isDark ? ThemeMode.dark : ThemeMode.light,
                          );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Auto-Indexing ─────────────────────────────────────────────
            Text('AUTO-INDEXING',
                style: NeoTypography.headlineSmall
                    .copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 10),
            NeoCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('AUTO-INDEX SCREENSHOTS',
                                style: NeoTypography.labelMedium
                                    .copyWith(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 2),
                            Text(
                              'Automatically indexes new screenshots as you take them.',
                              style: NeoTypography.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Switch(
                        value: indexerState.isEnabled,
                        activeThumbColor: NeoColors.green,
                        onChanged: (enabled) async {
                          if (enabled) {
                            await ref.read(indexerProvider.notifier).enable();
                          } else {
                            await ref.read(indexerProvider.notifier).disable();
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: indexerState.isRunning
                          ? NeoColors.green.withValues(alpha: 0.1)
                          : neo.bgMain,
                      border: NeoBorders.standard(),
                      borderRadius: NeoBorders.radius,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: indexerState.isRunning
                                ? NeoColors.green
                                : NeoColors.gray400,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            indexerState.statusText,
                            style: NeoTypography.bodySmall.copyWith(
                              fontFamily: NeoTypography.fontMono,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Cloud Backup ──────────────────────────────────────────────
            Text('CLOUD BACKUP',
                style: NeoTypography.headlineSmall
                    .copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 4),
            Text(
              'Optional. Wi-Fi only. Metadata only — your images stay on-device.',
              style: NeoTypography.bodySmall.copyWith(color: neo.textMuted),
            ),
            const SizedBox(height: 10),
            NeoCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('ENABLE CLOUD BACKUP',
                                style: NeoTypography.labelMedium
                                    .copyWith(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 2),
                            Text(
                                'Syncs screenshot metadata to Pomniter Cloud',
                                style: NeoTypography.bodySmall),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Switch(
                        value: syncState.isEnabled,
                        activeThumbColor: NeoColors.cyan,
                        onChanged: (enabled) async {
                          if (enabled) {
                            await ref.read(cloudSyncProvider.notifier).enable();
                          } else {
                            await ref
                                .read(cloudSyncProvider.notifier)
                                .disable();
                          }
                        },
                      ),
                    ],
                  ),
                  if (syncState.isEnabled) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            syncState.statusText,
                            style: NeoTypography.bodySmall.copyWith(
                              fontFamily: NeoTypography.fontMono,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        NeoButton(
                          label: syncState.status == SyncStatus.syncing
                              ? 'SYNCING…'
                              : 'SYNC NOW',
                          color: NeoColors.cyan,
                          onPressed:
                              syncState.status == SyncStatus.syncing
                                  ? null
                                  : () => ref
                                      .read(cloudSyncProvider.notifier)
                                      .sync(),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── AI & Storage ──────────────────────────────────────────────
            Text('AI & STORAGE',
                style: NeoTypography.headlineSmall
                    .copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 10),
            NeoCard(
              child: Column(
                children: [
                  _settingsRow('OCR Engine', 'PaddleOCR-Lite (ONNX)'),
                  const Divider(),
                  _settingsRow('Vector Embeddings', 'MobileCLIP-S0 (384-dim)'),
                  const Divider(),
                  _settingsRow('Vector Index', 'ObjectBox HNSW Index'),
                  const Divider(),
                  _settingsRow('Storage Used', 'Local On-Device Database'),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── About ─────────────────────────────────────────────────────
            Text('ABOUT POMNITER',
                style: NeoTypography.headlineSmall
                    .copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 10),
            NeoCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('VERSION 1.0.0-ALPHA',
                      style: NeoTypography.labelMedium
                          .copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(
                    'Built with Flutter, Apache 2.0 Open Source, Local-First AI architecture.',
                    style: NeoTypography.bodySmall,
                  ),
                  const SizedBox(height: 12),
                  NeoButton(
                    label: 'PROJECT GITHUB REPOSITORY',
                    color: NeoColors.yellow,
                    onPressed: () {},
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _settingsRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style:
                  NeoTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
          Text(
            value,
            style: NeoTypography.bodySmall.copyWith(
              fontFamily: NeoTypography.fontMono,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
