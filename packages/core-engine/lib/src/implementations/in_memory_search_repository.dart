import 'package:pomniter_shared_models/pomniter_shared_models.dart';
import '../interfaces/search_repository.dart';

/// In-memory search repository supporting exact keyword, fuzzy matching, and category filtering.
class InMemorySearchRepository implements SearchRepository {
  final Map<String, Screenshot> _index = {};

  @override
  Future<void> indexScreenshot(Screenshot screenshot, {List<double>? vector}) async {
    _index[screenshot.id] = screenshot;
  }

  @override
  Future<void> removeIndex(String screenshotId) async {
    _index.remove(screenshotId);
  }

  @override
  Future<List<SearchResult>> search(SearchQuery query) async {
    final queryLower = query.queryText.trim().toLowerCase();
    final results = <SearchResult>[];

    for (final screenshot in _index.values) {
      if (query.category != null && screenshot.category != query.category) {
        continue;
      }

      final textLower = screenshot.extractedText.toLowerCase();
      double score = 0.0;
      MatchType matchType = MatchType.textFuzzy;
      final matchedSnippets = <String>[];

      if (queryLower.isEmpty) {
        score = 1.0;
        matchType = MatchType.hybrid;
      } else if (textLower.contains(queryLower)) {
        score = 0.95;
        matchType = MatchType.textExact;
        matchedSnippets.add(query.queryText);
      } else {
        final queryWords = queryLower.split(RegExp(r'\s+'));
        int matches = 0;
        for (final word in queryWords) {
          if (word.isNotEmpty && textLower.contains(word)) {
            matches++;
            matchedSnippets.add(word);
          }
        }
        if (matches > 0) {
          score = 0.4 + (0.5 * matches / queryWords.length);
          matchType = MatchType.semanticText;
        }
      }

      if (score >= query.minScore) {
        results.add(SearchResult(
          screenshot: screenshot,
          score: score,
          matchType: matchType,
          matchedSnippets: matchedSnippets,
        ));
      }
    }

    results.sort((a, b) => b.score.compareTo(a.score));
    if (results.length > query.limit) {
      return results.sublist(0, query.limit);
    }
    return results;
  }
}
