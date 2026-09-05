import '../enums/screenshot_category.dart';

/// Parameters for querying the local/cloud search engine.
class SearchQuery {
  final String queryText;
  final ScreenshotCategory? category;
  final List<String>? tags;
  final DateTime? dateFrom;
  final DateTime? dateTo;
  final int limit;
  final double minScore;

  const SearchQuery({
    required this.queryText,
    this.category,
    this.tags,
    this.dateFrom,
    this.dateTo,
    this.limit = 20,
    this.minScore = 0.3,
  });

  Map<String, dynamic> toJson() => {
        'queryText': queryText,
        if (category != null) 'category': category!.name,
        if (tags != null) 'tags': tags,
        if (dateFrom != null) 'dateFrom': dateFrom!.toIso8601String(),
        if (dateTo != null) 'dateTo': dateTo!.toIso8601String(),
        'limit': limit,
        'minScore': minScore,
      };

  factory SearchQuery.fromJson(Map<String, dynamic> json) => SearchQuery(
        queryText: json['queryText'] as String,
        category: json['category'] != null
            ? ScreenshotCategory.fromString(json['category'] as String)
            : null,
        tags: (json['tags'] as List<dynamic>?)
            ?.map((t) => t.toString())
            .toList(),
        dateFrom: json['dateFrom'] != null
            ? DateTime.parse(json['dateFrom'] as String)
            : null,
        dateTo: json['dateTo'] != null
            ? DateTime.parse(json['dateTo'] as String)
            : null,
        limit: json['limit'] as int? ?? 20,
        minScore: (json['minScore'] as num?)?.toDouble() ?? 0.3,
      );
}
