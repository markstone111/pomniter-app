import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pomniter_design_system/pomniter_design_system.dart';
import 'package:pomniter_shared_models/pomniter_shared_models.dart';
import '../../providers/screenshot_providers.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenshotsAsync = ref.watch(screenshotsListProvider);
    final neo = NeoTheme.of(context);

    return NeoScaffold(
      currentIndex: 0,
      onTabChanged: (index) {
        if (index == 1) context.go('/search');
        if (index == 2) context.go('/gallery');
        if (index == 3) context.go('/settings');
      },
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
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Auto-indexing active: screenshots captured on device are indexed automatically.'),
              backgroundColor: NeoColors.black,
            ),
          );
        },
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
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                        Text('INDEXED', style: NeoTypography.labelSmall.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text('5 SHOTS', style: NeoTypography.headlineMedium.copyWith(fontWeight: FontWeight.w900)),
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
                        Text('PRIVACY', style: NeoTypography.labelSmall.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text('100% LOCAL', style: NeoTypography.headlineMedium.copyWith(fontWeight: FontWeight.w900)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),

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
                child: Text('Error: ' + err.toString(), style: NeoTypography.bodyMedium),
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
                      onTap: () => context.go('/detail/' + item.id),
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
                            child: Icon(_categoryIcon(item.category), size: 28, color: NeoColors.black),
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
                                      item.capturedAt.day.toString() + '/' + item.capturedAt.month.toString(),
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
