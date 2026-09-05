import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pomniter_design_system/pomniter_design_system.dart';
import '../../providers/theme_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return NeoScaffold(
      currentIndex: 3,
      onTabChanged: (index) {
        if (index == 0) context.go('/home');
        if (index == 1) context.go('/search');
        if (index == 2) context.go('/gallery');
      },
      appBar: const NeoAppBar(
        title: 'SETTINGS',
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Engine Status Card
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
                          'Your screenshots and OCR vectors never leave this device.',
                          style: NeoTypography.bodySmall.copyWith(
                            color: NeoColors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Appearance section
            Text('APPEARANCE', style: NeoTypography.headlineSmall.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 10),
            NeoCard(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('DARK MODE', style: NeoTypography.labelMedium.copyWith(fontWeight: FontWeight.bold)),
                      Text('High-contrast neo-brutal dark theme', style: NeoTypography.bodySmall),
                    ],
                  ),
                  Switch(
                    value: themeMode == ThemeMode.dark,
                    activeThumbColor: NeoColors.yellow,
                    onChanged: (isDark) {
                      ref.read(themeModeProvider.notifier).state =
                          isDark ? ThemeMode.dark : ThemeMode.light;
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Engine & Hardware section
            Text('AI & STORAGE', style: NeoTypography.headlineSmall.copyWith(fontWeight: FontWeight.w900)),
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
                  _settingsRow('Storage Used', '2.3 MB (5 screenshots)'),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Open Source & About
            Text('ABOUT POMNITER', style: NeoTypography.headlineSmall.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 10),
            NeoCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('VERSION 1.0.0-ALPHA', style: NeoTypography.labelMedium.copyWith(fontWeight: FontWeight.bold)),
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
          Text(label, style: NeoTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
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
