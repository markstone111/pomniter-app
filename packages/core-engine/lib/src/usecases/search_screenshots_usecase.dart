import 'package:pomniter_shared_models/pomniter_shared_models.dart';
import '../interfaces/search_repository.dart';

/// Executes ranked search queries against the indexed screenshots.
class SearchScreenshotsUseCase {
  final SearchRepository searchRepo;

  const SearchScreenshotsUseCase({
    required this.searchRepo,
  });

  Future<List<SearchResult>> execute(SearchQuery query) async {
    return searchRepo.search(query);
  }
}
