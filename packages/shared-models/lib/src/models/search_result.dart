import '../enums/match_type.dart';
import 'screenshot.dart';

/// Ranked result returned from Pomniter search engine.
class SearchResult {
  final Screenshot screenshot;
  final double score;
  final MatchType matchType;
  final List<String> matchedSnippets;

  const SearchResult({
    required this.screenshot,
    required this.score,
    required this.matchType,
    this.matchedSnippets = const [],
  });

  Map<String, dynamic> toJson() => {
        'screenshot': screenshot.toJson(),
        'score': score,
        'matchType': matchType.name,
        'matchedSnippets': matchedSnippets,
      };

  factory SearchResult.fromJson(Map<String, dynamic> json) => SearchResult(
        screenshot:
            Screenshot.fromJson(json['screenshot'] as Map<String, dynamic>),
        score: (json['score'] as num).toDouble(),
        matchType: MatchType.values.firstWhere(
          (m) => m.name == json['matchType'],
          orElse: () => MatchType.hybrid,
        ),
        matchedSnippets: (json['matchedSnippets'] as List<dynamic>?)
                ?.map((s) => s.toString())
                .toList() ??
            const [],
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SearchResult &&
          runtimeType == other.runtimeType &&
          screenshot.id == other.screenshot.id &&
          score == other.score;

  @override
  int get hashCode => Object.hash(screenshot.id, score);
}
