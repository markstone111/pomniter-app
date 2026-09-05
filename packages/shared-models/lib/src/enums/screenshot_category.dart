/// Categories for classifying screenshots in Pomniter.
enum ScreenshotCategory {
  receipt,
  code,
  chat,
  document,
  meme,
  map,
  social,
  financial,
  other;

  String get displayName {
    switch (this) {
      case ScreenshotCategory.receipt:
        return 'Receipt';
      case ScreenshotCategory.code:
        return 'Code & Tech';
      case ScreenshotCategory.chat:
        return 'Chat & Messages';
      case ScreenshotCategory.document:
        return 'Document & PDF';
      case ScreenshotCategory.meme:
        return 'Meme & Fun';
      case ScreenshotCategory.map:
        return 'Location & Map';
      case ScreenshotCategory.social:
        return 'Social Media';
      case ScreenshotCategory.financial:
        return 'Finance & Banking';
      case ScreenshotCategory.other:
        return 'Other';
    }
  }

  static ScreenshotCategory fromString(String value) {
    return ScreenshotCategory.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => ScreenshotCategory.other,
    );
  }
}
