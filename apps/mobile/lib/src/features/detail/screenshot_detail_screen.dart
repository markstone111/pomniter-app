import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pomniter_design_system/pomniter_design_system.dart';
import '../../providers/screenshot_providers.dart';
import '../../widgets/neo_toast.dart';

class ScreenshotDetailScreen extends ConsumerWidget {
  final String screenshotId;

  const ScreenshotDetailScreen({
    super.key,
    required this.screenshotId,
  });

  void _handleBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenshotAsync = ref.watch(screenshotByIdProvider(screenshotId));
    final neo = NeoTheme.of(context);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleBack(context);
      },
      child: Scaffold(
        backgroundColor: neo.bgMain,
        appBar: NeoAppBar(
          title: 'DETAIL',
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => _handleBack(context),
          ),
        ),
        body: screenshotAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(child: Text('Error: $err')),
          data: (item) {
            if (item == null) {
              return const Center(child: Text('Screenshot not found'));
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Visual Card Representation
                  NeoCard(
                    backgroundColor: NeoColors.yellow,
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        const Icon(Icons.screenshot,
                            size: 72, color: NeoColors.black),
                        const SizedBox(height: 12),
                        Text(
                          item.summary ?? 'Screenshot Inspection',
                          textAlign: TextAlign.center,
                          style: NeoTypography.headlineSmall.copyWith(
                            fontWeight: FontWeight.w900,
                            color: NeoColors.black,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            NeoBadge(label: item.category.displayName),
                            const SizedBox(width: 8),
                            NeoBadge(label: '${item.width}x${item.height}'),
                            const SizedBox(width: 8),
                            NeoBadge(
                                label:
                                    '${(item.fileSizeBytes / 1024).toStringAsFixed(0)} KB'),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Extracted Text Header & Copy Button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'OCR EXTRACTED TEXT',
                        style: NeoTypography.headlineSmall
                            .copyWith(fontWeight: FontWeight.w900),
                      ),
                      NeoButton(
                        label: 'COPY',
                        color: NeoColors.pink,
                        onPressed: () {
                          Clipboard.setData(
                              ClipboardData(text: item.extractedText));
                          showNeoToast(
                            context,
                            'Extracted text copied to clipboard!',
                            isSuccess: true,
                            icon: Icons.copy,
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // OCR Content Box
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: NeoColors.white,
                      border: NeoBorders.standard(),
                      borderRadius: NeoBorders.radius,
                      boxShadow: NeoShadows.sm(),
                    ),
                    child: SelectableText(
                      item.extractedText,
                      style: NeoTypography.bodyMedium.copyWith(
                        fontFamily: NeoTypography.fontMono,
                        color: NeoColors.black,
                        height: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Tags
                  if (item.tags.isNotEmpty) ...[
                    Text(
                      'TAGS',
                      style: NeoTypography.labelLarge
                          .copyWith(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final tag in item.tags)
                          NeoBadge(label: '#$tag', color: NeoColors.cyan),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Metadata Section
                  NeoCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('METADATA',
                            style: NeoTypography.labelMedium
                                .copyWith(fontWeight: FontWeight.w900)),
                        const SizedBox(height: 8),
                        Text('ID: ${item.id}',
                            style: NeoTypography.bodySmall
                                .copyWith(fontFamily: NeoTypography.fontMono)),
                        Text('Captured: ${item.capturedAt.toIso8601String()}',
                            style: NeoTypography.bodySmall
                                .copyWith(fontFamily: NeoTypography.fontMono)),
                        Text('Storage path: ${item.filePath}',
                            style: NeoTypography.bodySmall
                                .copyWith(fontFamily: NeoTypography.fontMono)),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
