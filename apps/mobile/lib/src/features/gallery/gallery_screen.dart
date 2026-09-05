import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pomniter_design_system/pomniter_design_system.dart';
import 'package:pomniter_shared_models/pomniter_shared_models.dart';
import '../../providers/screenshot_providers.dart';

class GalleryScreen extends ConsumerWidget {
  const GalleryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenshotsAsync = ref.watch(screenshotsListProvider);

    return NeoScaffold(
      currentIndex: 2,
      onTabChanged: (index) {
        if (index == 0) context.go('/home');
        if (index == 1) context.go('/search');
        if (index == 3) context.go('/settings');
      },
      appBar: const NeoAppBar(
        title: 'ALL MEMORIES',
      ),
      body: screenshotsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: ' + err.toString())),
        data: (screenshots) {
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: 0.82,
            ),
            itemCount: screenshots.length,
            itemBuilder: (context, index) {
              final item = screenshots[index];
              return NeoCard(
                onTap: () => context.go('/detail/' + item.id),
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: _colorForCategory(item.category),
                          border: NeoBorders.standard(),
                          borderRadius: NeoBorders.radius,
                        ),
                        child: Center(
                          child: Icon(
                            _iconForCategory(item.category),
                            size: 40,
                            color: NeoColors.black,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    NeoBadge(label: item.category.displayName),
                    const SizedBox(height: 6),
                    Text(
                      item.summary ?? item.extractedText,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: NeoTypography.labelSmall.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Color _colorForCategory(ScreenshotCategory cat) {
    switch (cat) {
      case ScreenshotCategory.receipt:
        return NeoColors.yellow;
      case ScreenshotCategory.code:
        return NeoColors.cyan;
      case ScreenshotCategory.chat:
        return NeoColors.green;
      case ScreenshotCategory.document:
        return NeoColors.peach;
      case ScreenshotCategory.meme:
        return NeoColors.pink;
      default:
        return NeoColors.lavender;
    }
  }

  IconData _iconForCategory(ScreenshotCategory cat) {
    switch (cat) {
      case ScreenshotCategory.receipt:
        return Icons.receipt_long;
      case ScreenshotCategory.code:
        return Icons.terminal;
      case ScreenshotCategory.chat:
        return Icons.forum;
      case ScreenshotCategory.document:
        return Icons.description;
      case ScreenshotCategory.meme:
        return Icons.celebration;
      default:
        return Icons.photo;
    }
  }
}
