import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pomniter_shared_models/pomniter_shared_models.dart';
import 'engine_providers.dart';

/// All screenshots state
final screenshotsListProvider = FutureProvider<List<Screenshot>>((ref) async {
  final repo = ref.watch(screenshotRepoProvider);
  return repo.getAllScreenshots(limit: 100);
});

/// Active search text query
final searchQueryTextProvider = StateProvider<String>((ref) => '');

/// Active category filter
final selectedCategoryFilterProvider = StateProvider<ScreenshotCategory?>((ref) => null);

/// Search results provider
final searchResultsProvider = FutureProvider<List<SearchResult>>((ref) async {
  final queryText = ref.watch(searchQueryTextProvider);
  final category = ref.watch(selectedCategoryFilterProvider);
  final useCase = ref.watch(searchUseCaseProvider);

  return useCase.execute(SearchQuery(
    queryText: queryText,
    category: category,
    minScore: 0.2,
    limit: 30,
  ));
});

/// Single screenshot by ID provider
final screenshotByIdProvider = FutureProvider.family<Screenshot?, String>((ref, id) async {
  final repo = ref.watch(screenshotRepoProvider);
  return repo.getScreenshotById(id);
});
