/// Method by which a screenshot matched a search query.
enum MatchType {
  textExact,
  textFuzzy,
  semanticText,
  visualSemantic,
  hybrid;

  String get label {
    switch (this) {
      case MatchType.textExact:
        return 'EXACT TEXT';
      case MatchType.textFuzzy:
        return 'FUZZY TEXT';
      case MatchType.semanticText:
        return 'AI TEXT';
      case MatchType.visualSemantic:
        return 'VISUAL';
      case MatchType.hybrid:
        return 'HYBRID AI';
    }
  }
}
