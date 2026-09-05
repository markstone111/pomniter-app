import 'bounding_box.dart';

/// An individual block of OCR-detected text with positional bounds.
class TextBlock {
  final String text;
  final double confidence;
  final BoundingBox? boundingBox;

  const TextBlock({
    required this.text,
    required this.confidence,
    this.boundingBox,
  });

  Map<String, dynamic> toJson() => {
        'text': text,
        'confidence': confidence,
        if (boundingBox != null) 'boundingBox': boundingBox!.toJson(),
      };

  factory TextBlock.fromJson(Map<String, dynamic> json) => TextBlock(
        text: json['text'] as String,
        confidence: (json['confidence'] as num).toDouble(),
        boundingBox: json['boundingBox'] != null
            ? BoundingBox.fromJson(json['boundingBox'] as Map<String, dynamic>)
            : null,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TextBlock &&
          runtimeType == other.runtimeType &&
          text == other.text &&
          confidence == other.confidence &&
          boundingBox == other.boundingBox;

  @override
  int get hashCode => Object.hash(text, confidence, boundingBox);

  @override
  String toString() => 'TextBlock(text: , confidence: )';
}
