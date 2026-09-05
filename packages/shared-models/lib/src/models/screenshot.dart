import '../enums/screenshot_category.dart';
import 'text_block.dart';

/// Core entity representing an indexed screenshot in Pomniter.
class Screenshot {
  final String id;
  final String filePath;
  final String? thumbnailPath;
  final DateTime capturedAt;
  final DateTime? indexedAt;
  final int width;
  final int height;
  final int fileSizeBytes;
  final String extractedText;
  final List<TextBlock> textBlocks;
  final List<String> tags;
  final ScreenshotCategory category;
  final String? summary;
  final Map<String, dynamic> metadata;
  final bool isFavorite;
  final bool isArchived;

  const Screenshot({
    required this.id,
    required this.filePath,
    this.thumbnailPath,
    required this.capturedAt,
    this.indexedAt,
    required this.width,
    required this.height,
    required this.fileSizeBytes,
    required this.extractedText,
    this.textBlocks = const [],
    this.tags = const [],
    this.category = ScreenshotCategory.other,
    this.summary,
    this.metadata = const {},
    this.isFavorite = false,
    this.isArchived = false,
  });

  Screenshot copyWith({
    String? id,
    String? filePath,
    String? thumbnailPath,
    DateTime? capturedAt,
    DateTime? indexedAt,
    int? width,
    int? height,
    int? fileSizeBytes,
    String? extractedText,
    List<TextBlock>? textBlocks,
    List<String>? tags,
    ScreenshotCategory? category,
    String? summary,
    Map<String, dynamic>? metadata,
    bool? isFavorite,
    bool? isArchived,
  }) {
    return Screenshot(
      id: id ?? this.id,
      filePath: filePath ?? this.filePath,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      capturedAt: capturedAt ?? this.capturedAt,
      indexedAt: indexedAt ?? this.indexedAt,
      width: width ?? this.width,
      height: height ?? this.height,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
      extractedText: extractedText ?? this.extractedText,
      textBlocks: textBlocks ?? this.textBlocks,
      tags: tags ?? this.tags,
      category: category ?? this.category,
      summary: summary ?? this.summary,
      metadata: metadata ?? this.metadata,
      isFavorite: isFavorite ?? this.isFavorite,
      isArchived: isArchived ?? this.isArchived,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'filePath': filePath,
        if (thumbnailPath != null) 'thumbnailPath': thumbnailPath,
        'capturedAt': capturedAt.toIso8601String(),
        if (indexedAt != null) 'indexedAt': indexedAt!.toIso8601String(),
        'width': width,
        'height': height,
        'fileSizeBytes': fileSizeBytes,
        'extractedText': extractedText,
        'textBlocks': textBlocks.map((b) => b.toJson()).toList(),
        'tags': tags,
        'category': category.name,
        if (summary != null) 'summary': summary,
        'metadata': metadata,
        'isFavorite': isFavorite,
        'isArchived': isArchived,
      };

  factory Screenshot.fromJson(Map<String, dynamic> json) => Screenshot(
        id: json['id'] as String,
        filePath: json['filePath'] as String,
        thumbnailPath: json['thumbnailPath'] as String?,
        capturedAt: DateTime.parse(json['capturedAt'] as String),
        indexedAt: json['indexedAt'] != null
            ? DateTime.parse(json['indexedAt'] as String)
            : null,
        width: json['width'] as int,
        height: json['height'] as int,
        fileSizeBytes: json['fileSizeBytes'] as int,
        extractedText: json['extractedText'] as String? ?? '',
        textBlocks: (json['textBlocks'] as List<dynamic>?)
                ?.map((b) => TextBlock.fromJson(b as Map<String, dynamic>))
                .toList() ??
            const [],
        tags: (json['tags'] as List<dynamic>?)
                ?.map((t) => t.toString())
                .toList() ??
            const [],
        category: json['category'] != null
            ? ScreenshotCategory.fromString(json['category'] as String)
            : ScreenshotCategory.other,
        summary: json['summary'] as String?,
        metadata: json['metadata'] as Map<String, dynamic>? ?? const {},
        isFavorite: json['isFavorite'] as bool? ?? false,
        isArchived: json['isArchived'] as bool? ?? false,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Screenshot &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Screenshot(id: , category: , size: B)';
}
