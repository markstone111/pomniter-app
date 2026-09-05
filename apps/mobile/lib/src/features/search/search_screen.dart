import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pomniter_design_system/pomniter_design_system.dart';
import 'package:pomniter_shared_models/pomniter_shared_models.dart';
import '../../providers/screenshot_providers.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final searchResultsAsync = ref.watch(searchResultsProvider);
    final activeCategory = ref.watch(selectedCategoryFilterProvider);

    return NeoScaffold(
      currentIndex: 1,
      onTabChanged: (index) {
        if (index == 0) context.go('/home');
        if (index == 2) context.go('/gallery');
        if (index == 3) context.go('/settings');
      },
      appBar: const NeoAppBar(
        title: 'SEARCH ENGINE',
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            NeoTextField(
              controller: _searchController,
              hintText: 'Type keywords, numbers, or natural query...',
              isSearch: true,
              autofocus: true,
              onChanged: (val) {
                ref.read(searchQueryTextProvider.notifier).state = val;
              },
            ),
            const SizedBox(height: 14),

            // Category Filter Pills
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      ref.read(selectedCategoryFilterProvider.notifier).state = null;
                    },
                    child: NeoBadge(
                      label: 'ALL',
                      color: activeCategory == null ? NeoColors.yellow : NeoColors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  for (final cat in [
                    ScreenshotCategory.receipt,
                    ScreenshotCategory.code,
                    ScreenshotCategory.document,
                    ScreenshotCategory.chat,
                    ScreenshotCategory.meme,
                  ]) ...[
                    GestureDetector(
                      onTap: () {
                        final current = ref.read(selectedCategoryFilterProvider);
                        ref.read(selectedCategoryFilterProvider.notifier).state =
                            current == cat ? null : cat;
                      },
                      child: NeoBadge(
                        label: cat.displayName,
                        color: activeCategory == cat ? NeoColors.yellow : NeoColors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Search Results List
            Expanded(
              child: searchResultsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => NeoCard(
                  backgroundColor: NeoColors.error,
                  child: Text('Search error: ' + err.toString()),
                ),
                data: (results) {
                  if (results.isEmpty) {
                    return Center(
                      child: NeoCard(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.search_off, size: 48, color: NeoColors.black),
                            const SizedBox(height: 12),
                            Text(
                              'NO MATCHES FOUND',
                              style: NeoTypography.headlineSmall.copyWith(fontWeight: FontWeight.w900),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Try searching for "Starbucks", "Indigo", "Docker", or "Address"',
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return ListView.separated(
                    itemCount: results.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = results[index];
                      return NeoCard(
                        onTap: () => context.go('/detail/' + item.screenshot.id),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                NeoBadge(
                                  label: item.matchType.label,
                                  color: item.score > 0.9 ? NeoColors.green : NeoColors.cyan,
                                ),
                                const SizedBox(width: 8),
                                NeoBadge(label: item.screenshot.category.displayName),
                                const Spacer(),
                                Text(
                                  (item.score * 100).toInt().toString() + '% MATCH',
                                  style: NeoTypography.labelSmall.copyWith(
                                    fontFamily: NeoTypography.fontMono,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              item.screenshot.summary ?? item.screenshot.extractedText,
                              style: NeoTypography.bodyLarge.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: NeoColors.gray100,
                                borderRadius: NeoBorders.radiusSoft,
                              ),
                              child: Text(
                                item.screenshot.extractedText,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: NeoTypography.bodySmall.copyWith(
                                  fontFamily: NeoTypography.fontMono,
                                  color: NeoColors.black,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
