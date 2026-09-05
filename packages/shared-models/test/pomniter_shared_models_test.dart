import 'package:flutter_test/flutter_test.dart';
import 'package:pomniter_shared_models/pomniter_shared_models.dart';

void main() {
  group('ScreenshotCategory', () {
    test('displayName returns readable title', () {
      expect(ScreenshotCategory.receipt.displayName, 'Receipt');
      expect(ScreenshotCategory.code.displayName, 'Code & Tech');
      expect(ScreenshotCategory.other.displayName, 'Other');
    });

    test('fromString parses correctly and defaults to other', () {
      expect(ScreenshotCategory.fromString('receipt'), ScreenshotCategory.receipt);
      expect(ScreenshotCategory.fromString('RECEIPT'), ScreenshotCategory.receipt);
      expect(ScreenshotCategory.fromString('unknown_value'), ScreenshotCategory.other);
    });
  });

  group('Screenshot model', () {
    final now = DateTime(2026, 9, 5, 12, 0, 0);
    final screenshot = Screenshot(
      id: 'sc-123',
      filePath: '/storage/screenshots/receipt.png',
      capturedAt: now,
      width: 1080,
      height: 2400,
      fileSizeBytes: 524288,
      extractedText: 'TOTAL: .50 Starbucks Coffee',
      category: ScreenshotCategory.receipt,
      tags: ['coffee', 'starbucks'],
      textBlocks: [
        TextBlock(
          text: 'TOTAL: .50',
          confidence: 0.98,
          boundingBox: const BoundingBox(left: 10, top: 100, width: 200, height: 40),
        ),
      ],
    );

    test('serializes to JSON and back losslessly', () {
      final json = screenshot.toJson();
      final restored = Screenshot.fromJson(json);

      expect(restored.id, screenshot.id);
      expect(restored.filePath, screenshot.filePath);
      expect(restored.capturedAt, screenshot.capturedAt);
      expect(restored.extractedText, screenshot.extractedText);
      expect(restored.category, screenshot.category);
      expect(restored.tags, screenshot.tags);
      expect(restored.textBlocks.length, 1);
      expect(restored.textBlocks.first.confidence, 0.98);
      expect(restored.textBlocks.first.boundingBox?.width, 200.0);
    });

    test('copyWith works correctly', () {
      final updated = screenshot.copyWith(isFavorite: true, summary: 'Coffee receipt');
      expect(updated.id, screenshot.id);
      expect(updated.isFavorite, isTrue);
      expect(updated.summary, 'Coffee receipt');
      expect(screenshot.isFavorite, isFalse);
    });

    test('equality compares id', () {
      final s2 = screenshot.copyWith(extractedText: 'Different text');
      expect(screenshot == s2, isTrue);
      expect(screenshot.hashCode, s2.hashCode);
    });
  });

  group('SearchResult model', () {
    test('serializes and deserializes', () {
      final now = DateTime(2026, 9, 5, 12, 0, 0);
      final screenshot = Screenshot(
        id: 'sc-456',
        filePath: '/storage/1.png',
        capturedAt: now,
        width: 800,
        height: 600,
        fileSizeBytes: 100000,
        extractedText: 'Flight ticket confirmation',
      );

      final result = SearchResult(
        screenshot: screenshot,
        score: 0.92,
        matchType: MatchType.hybrid,
        matchedSnippets: ['Flight ticket confirmation'],
      );

      final json = result.toJson();
      final restored = SearchResult.fromJson(json);

      expect(restored.score, 0.92);
      expect(restored.matchType, MatchType.hybrid);
      expect(restored.matchedSnippets, ['Flight ticket confirmation']);
      expect(restored.screenshot.id, 'sc-456');
    });
  });

  group('User model', () {
    test('serialization round trip', () {
      final user = User(
        id: 'u-1',
        email: 'test@pomniter.in',
        displayName: 'Test User',
        createdAt: DateTime(2026, 9, 5),
        isAnonymous: false,
      );

      final json = user.toJson();
      final restored = User.fromJson(json);

      expect(restored.id, 'u-1');
      expect(restored.email, 'test@pomniter.in');
      expect(restored.displayName, 'Test User');
      expect(restored.isAnonymous, isFalse);
    });
  });
}
