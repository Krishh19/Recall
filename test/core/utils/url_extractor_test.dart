import 'package:flutter_test/flutter_test.dart';
import 'package:recall/core/utils/url_extractor.dart';

void main() {
  group('UrlExtractor.extractUrl', () {
    test('extracts clean URL directly', () {
      const input = 'https://example.com/article/123';
      expect(UrlExtractor.extractUrl(input), 'https://example.com/article/123');
    });

    test('extracts URL surrounded by text and extra spaces', () {
      const input =
          'Hey check this out: https://news.ycombinator.com/item?id=12345 from Hacker News!';
      expect(
        UrlExtractor.extractUrl(input),
        'https://news.ycombinator.com/item?id=12345',
      );
    });

    test('strips trailing punctuation', () {
      const input = 'Check (https://flutter.dev), it is awesome.';
      expect(UrlExtractor.extractUrl(input), 'https://flutter.dev');
    });

    test('returns null for plain text without links', () {
      expect(UrlExtractor.extractUrl('Just some plain text message'), isNull);
      expect(UrlExtractor.extractUrl(''), isNull);
      expect(UrlExtractor.extractUrl(null), isNull);
    });
  });

  group('UrlExtractor.detectPlatform', () {
    test('detects Twitter / X links', () {
      expect(
        UrlExtractor.detectPlatform(
          'https://x.com/flutterdev/status/123456789',
        ),
        'twitter',
      );
      expect(
        UrlExtractor.detectPlatform(
          'https://twitter.com/flutterdev/status/123456789',
        ),
        'twitter',
      );
      expect(UrlExtractor.detectPlatform('https://t.co/abc123xyz'), 'twitter');
    });

    test('detects YouTube links', () {
      expect(
        UrlExtractor.detectPlatform(
          'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
        ),
        'youtube',
      );
      expect(
        UrlExtractor.detectPlatform('https://youtu.be/dQw4w9WgXcQ'),
        'youtube',
      );
    });

    test('detects Instagram links', () {
      expect(
        UrlExtractor.detectPlatform('https://www.instagram.com/p/C123456789/'),
        'instagram',
      );
    });

    test('detects generic articles', () {
      expect(
        UrlExtractor.detectPlatform('https://medium.com/@user/my-story-123'),
        'article',
      );
      expect(
        UrlExtractor.detectPlatform('https://techcrunch.com/2026/08/16/news'),
        'article',
      );
    });
  });
}
