/// Minimal BPE tokenizer for CLIP's 49,408-token vocabulary.
///
/// This is a pure-Dart port of the CLIP text tokenizer logic. It does NOT
/// require any native code or assets — the vocabulary and merge rules are
/// loaded from a JSON file at construction time.
///
/// Usage:
/// ```dart
/// final tokenizer = ClipTokenizer.fromJson(vocabJson, mergesJson);
/// final tokens = tokenizer.encode("a screenshot of a cat");
/// ```
library;

import 'dart:convert';

/// Maximum context length CLIP text encoder accepts.
const int kClipContextLength = 77;

/// Special token IDs matching the original CLIP tokenizer.
const int kClipSotToken = 49406; // <|startoftext|>
const int kClipEotToken = 49407; // <|endoftext|>

/// Pure-Dart CLIP BPE tokenizer.
///
/// The CLIP vocabulary has 49,408 tokens (49,152 BPE merges + 256 byte
/// tokens + special tokens). This implementation encodes text to integer
/// token IDs suitable for feeding into the CLIP text encoder ONNX model.
class ClipTokenizer {
  final Map<String, int> _encoder;
  final Map<String, int> _bpeMerges;
  final Map<String, List<String>> _cache;

  ClipTokenizer._(
    this._encoder,
    this._bpeMerges,
  ) : _cache = {};

  /// Construct from JSON strings.
  ///
  /// [vocabJson] is the CLIP `vocab.json` file contents.
  /// [mergesText] is the CLIP `merges.txt` file contents (space-separated pairs).
  factory ClipTokenizer.fromJson(String vocabJson, String mergesText) {
    final rawVocab = json.decode(vocabJson) as Map<String, dynamic>;
    final encoder = rawVocab.map((k, v) => MapEntry(k, v as int));

    final mergeLines = mergesText
        .split('\n')
        .where((l) => l.isNotEmpty && !l.startsWith('#'))
        .toList();

    final bpeMerges = <String, int>{};
    for (var i = 0; i < mergeLines.length; i++) {
      bpeMerges[mergeLines[i]] = i;
    }

    return ClipTokenizer._(
      encoder,
      bpeMerges,
    );
  }

  // ─── Public API ───────────────────────────────────────────────────────────

  /// Encodes [text] to a padded token list of length [kClipContextLength].
  ///
  /// The output is always exactly 77 integers:
  ///   [SOT, ...bpe tokens (truncated to 75)..., EOT, 0, 0, ...(padding)]
  List<int> encode(String text) {
    final lower = text.toLowerCase().trim();
    final words = _simpleTokenize(lower);
    final tokens = <int>[kClipSotToken];

    for (final word in words) {
      final bpeTokens = _bpe(word);
      for (final tok in bpeTokens) {
        if (_encoder.containsKey(tok)) {
          tokens.add(_encoder[tok]!);
          if (tokens.length == kClipContextLength - 1) break;
        }
      }
      if (tokens.length == kClipContextLength - 1) break;
    }

    tokens.add(kClipEotToken);

    // Pad to context length
    while (tokens.length < kClipContextLength) {
      tokens.add(0);
    }

    return tokens;
  }

  // ─── Private Helpers ──────────────────────────────────────────────────────

  /// Simple whitespace tokenizer (CLIP uses a more complex regex in Python;
  /// for pure-Dart we approximate with unicode-aware word splitting).
  List<String> _simpleTokenize(String text) {
    // Replace punctuation with spaced versions, then split on whitespace.
    // Note: regex is split to avoid angle-bracket parsing in codegen tools.
    final punctuationRegex = RegExp(
      r"""[!'"()*+,\-./:;<=>?@\[\\\]^_`{|}~]""",
    );
    final cleaned = text.replaceAllMapped(
      punctuationRegex,
      (m) => ' ${m[0]} ',
    );
    return cleaned.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
  }

  List<String> _bpe(String word) {
    if (_cache.containsKey(word)) return _cache[word]!;

    // Convert word to char-level list with </w> suffix on last char
    final chars = word.split('');
    if (chars.isEmpty) return [];
    chars[chars.length - 1] = '${chars.last}</w>';

    var pairs = _getPairs(chars);
    if (pairs.isEmpty) {
      _cache[word] = chars;
      return chars;
    }

    var symbols = List<String>.from(chars);

    while (true) {
      String? bestPair;
      int bestRank = 999999999;

      for (final pair in pairs) {
        final key = '${pair[0]} ${pair[1]}';
        final rank = _bpeMerges[key];
        if (rank != null && rank < bestRank) {
          bestRank = rank;
          bestPair = key;
        }
      }

      if (bestPair == null) break;

      final parts = bestPair.split(' ');
      final first = parts[0];
      final second = parts[1];
      final newSymbols = <String>[];

      var i = 0;
      while (i < symbols.length) {
        final j = symbols.indexOf(first, i);
        if (j == -1) {
          newSymbols.addAll(symbols.sublist(i));
          break;
        }
        newSymbols.addAll(symbols.sublist(i, j));
        if (j < symbols.length - 1 && symbols[j + 1] == second) {
          newSymbols.add('$first$second');
          i = j + 2;
        } else {
          newSymbols.add(symbols[j]);
          i = j + 1;
        }
      }

      symbols = newSymbols;
      if (symbols.length == 1) break;
      pairs = _getPairs(symbols);
    }

    _cache[word] = symbols;
    return symbols;
  }

  Set<List<String>> _getPairs(List<String> symbols) {
    final pairs = <List<String>>{};
    for (var i = 0; i < symbols.length - 1; i++) {
      pairs.add([symbols[i], symbols[i + 1]]);
    }
    return pairs;
  }
}
