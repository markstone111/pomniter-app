import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pomniter_design_system/pomniter_design_system.dart';
import 'package:pomniter_shared_models/pomniter_shared_models.dart';
import '../../providers/engine_providers.dart';
import '../../providers/screenshot_providers.dart';
import '../../providers/indexer_providers.dart';
import '../../widgets/neo_toast.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  Future<void> _handleImport(BuildContext context, WidgetRef ref) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 90,
      );

      if (picked == null) {
        return;
      }

      final docsDir = await getApplicationDocumentsDirectory();
      final screenshotsDir =
          Directory(p.join(docsDir.path, 'imported_screenshots'));
      if (!await screenshotsDir.exists()) {
        await screenshotsDir.create(recursive: true);
      }

      final timestamp = DateTime.now();
      final fileExt = p.extension(picked.path).isNotEmpty
          ? p.extension(picked.path)
          : '.png';
      final fileName = 'import_${timestamp.millisecondsSinceEpoch}$fileExt';
      final savedFile =
          await File(picked.path).copy(p.join(screenshotsDir.path, fileName));
      final fileLength = await savedFile.length();

      final newScreenshot = Screenshot(
        id: 'sc-imp-${timestamp.millisecondsSinceEpoch}',
        filePath: savedFile.path,
        capturedAt: timestamp,
        indexedAt: timestamp,
        width: 1080,
        height: 1920,
        fileSizeBytes: fileLength,
        category: ScreenshotCategory.document,
        extractedText:
            'Imported Screenshot (${p.basename(picked.path)})\nSaved to local storage on ${timestamp.toLocal()}',
        tags: ['imported', 'gallery'],
        summary: 'Imported gallery screenshot saved to local memory engine',
      );

      final repo = ref.read(screenshotRepoProvider);
      await repo.saveScreenshot(newScreenshot);

      final searchRepo = ref.read(searchRepoProvider);
      await searchRepo.indexScreenshot(newScreenshot);

      ref.invalidate(screenshotsListProvider);

      if (context.mounted) {
        showNeoToast(
          context,
          'Screenshot imported & indexed locally!',
          isSuccess: true,
          icon: Icons.check_circle_outline,
        );
      }
    } catch (e) {
      if (context.mounted) {
        showNeoToast(
          context,
          'Failed to import screenshot: $e',
          isError: true,
          icon: Icons.error_outline,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenshotsAsync = ref.watch(screenshotsListProvider);
    final neo = NeoTheme.of(context);

    return Scaffold(
      backgroundColor: neo.bgMain,
      appBar: NeoAppBar(
        title: 'POMNITER',
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.go('/settings'),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _handleImport(context, ref),
        backgroundColor: NeoColors.yellow,
        foregroundColor: NeoColors.black,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: NeoColors.black, width: 2),
          borderRadius: NeoBorders.radius,
        ),
        icon: const Icon(Icons.add_photo_alternate),
        label: Text(
          'IMPORT',
          style: NeoTypography.labelMedium.copyWith(fontWeight: FontWeight.w900),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Search Trigger Card
            NeoCard(
              backgroundColor: NeoColors.yellow,
              padding: const EdgeInsets.all(18.0),
              onTap: () => context.go('/search'),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.bolt, color: NeoColors.black, size: 24),
                      const SizedBox(width: 8),
                      Text(
                        'LOCAL MEMORY ENGINE',
                        style: NeoTypography.labelLarge.copyWith(
                          color: NeoColors.black,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const Spacer(),
                      NeoBadge.green(label: 'ON-DEVICE'),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Search screenshots the way you remember them.',
                    style: NeoTypography.headlineSmall.copyWith(
                      color: NeoColors.black,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: NeoColors.white,
                      border: NeoBorders.standard(),
                      borderRadius: NeoBorders.radius,
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.search, color: NeoColors.black, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          '"starbucks receipt", "indigo flight pnr"...',
                          style: NeoTypography.bodyMedium.copyWith(
                            fontFamily: NeoTypography.fontMono,
                            color: NeoColors.gray600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Quick Stats Row
            Row(
              children: [
                Expanded(
                  child: NeoCard(
                    backgroundColor: NeoColors.cyan,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('INDEXED',
                            style: NeoTypography.labelSmall
                                .copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        screenshotsAsync.maybeWhen(
                          data: (items) => Text(
                            '${items.length} SHOTS',
                            style: NeoTypography.headlineMedium
                                .copyWith(fontWeight: FontWeight.w900),
                          ),
                          orElse: () => Text(
                            '-- SHOTS',
                            style: NeoTypography.headlineMedium
                                .copyWith(fontWeight: FontWeight.w900),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: NeoCard(
                    backgroundColor: NeoColors.pink,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('PRIVACY',
                            style: NeoTypography.labelSmall
                                .copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text('100% LOCAL',
                            style: NeoTypography.headlineMedium
                                .copyWith(fontWeight: FontWeight.w900)),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // Live Auto-Indexer Status Bar
            const SizedBox(height: 12),
            Consumer(
              builder: (context, ref, _) {
                final indexerState = ref.watch(indexerProvider);
                final isRunning = indexerState.isRunning;
                return NeoCard(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isRunning ? NeoColors.green : NeoColors.gray400,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          indexerState.statusText,
                          style: NeoTypography.bodySmall.copyWith(
                            fontFamily: NeoTypography.fontMono,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (!indexerState.isEnabled)
                        GestureDetector(
                          onTap: () => context.go('/settings'),
                          child: NeoBadge(
                            label: 'ENABLE →',
                            color: NeoColors.yellow,
                            textColor: NeoColors.black,
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),


            // Section Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'RECENT SCREENSHOTS',
                  style: NeoTypography.headlineSmall.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
                TextButton(
                  onPressed: () => context.go('/gallery'),
                  child: Text(
                    'VIEW ALL ->',
                    style: NeoTypography.labelMedium.copyWith(
                      color: neo.textMain,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Recent Screenshots Grid / List
            screenshotsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => NeoCard(
                backgroundColor: NeoColors.error,
                child: Text('Error: $err', style: NeoTypography.bodyMedium),
              ),
              data: (screenshots) {
                if (screenshots.isEmpty) {
                  return const NeoCard(
                    child: Center(
                      child: Text('No screenshots indexed yet.'),
                    ),
                  );
                }

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: screenshots.take(4).length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final item = screenshots[index];
                    return NeoCard(
                      onTap: () => context.push('/detail/${item.id}'),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: NeoColors.yellow,
                              border: NeoBorders.standard(),
                              borderRadius: NeoBorders.radius,
                            ),
                            child: Icon(_categoryIcon(item.category),
                                size: 28, color: NeoColors.black),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    NeoBadge(label: item.category.displayName),
                                    const Spacer(),
                                    Text(
                                      '${item.capturedAt.day}/${item.capturedAt.month}',
                                      style: NeoTypography.labelSmall.copyWith(
                                        fontFamily: NeoTypography.fontMono,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  item.summary ?? item.extractedText,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: NeoTypography.bodyMedium.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  IconData _categoryIcon(ScreenshotCategory cat) {
    switch (cat) {
      case ScreenshotCategory.receipt:
        return Icons.receipt_long;
      case ScreenshotCategory.code:
        return Icons.code;
      case ScreenshotCategory.chat:
        return Icons.chat_bubble_outline;
      case ScreenshotCategory.document:
        return Icons.description_outlined;
      case ScreenshotCategory.meme:
        return Icons.sentiment_very_satisfied;
      case ScreenshotCategory.map:
        return Icons.map_outlined;
      case ScreenshotCategory.social:
        return Icons.share_outlined;
      case ScreenshotCategory.financial:
        return Icons.account_balance;
      case ScreenshotCategory.other:
        return Icons.image_outlined;
    }
  }
}
