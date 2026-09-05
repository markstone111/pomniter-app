import 'package:pomniter_shared_models/pomniter_shared_models.dart';

/// Abstract contract for indexing and querying screenshots across vector and lexical indices.
abstract interface class SearchRepository {
  Future<List<SearchResult>> search(SearchQuery query);
  Future<void> indexScreenshot(Screenshot screenshot, {List<double>? vector});
  Future<void> removeIndex(String screenshotId);
}
