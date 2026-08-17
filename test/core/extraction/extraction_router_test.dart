import 'package:flutter_test/flutter_test.dart';
import 'package:recall/core/utils/url_extractor.dart';

void main() {
  group('Extraction Router Platform Detection', () {
    group('Twitter / X Routing', () {
      test('routes standard x.com status URLs', () {
        expect(
          UrlExtractor.detectPlatform(
            'https://x.com/flutterdev/status/1824123456789',
          ),
          'twitter',
        );
      });

      test('routes twitter.com URLs with subdomains and query params', () {
        expect(
          UrlExtractor.detectPlatform(
            'https://mobile.twitter.com/sama/status/987654321?s=20&t=abc',
          ),
          'twitter',
        );
      });

      test('routes t.co short links', () {
        expect(UrlExtractor.detectPlatform('https://t.co/xyz123'), 'twitter');
      });

      test('routes uppercase X URLs', () {
        expect(
          UrlExtractor.detectPlatform('HTTPS://X.COM/USER/STATUS/12345'),
          'twitter',
        );
      });
    });

    group('Instagram Routing', () {
      test('routes instagram.com post URLs', () {
        expect(
          UrlExtractor.detectPlatform('https://www.instagram.com/p/C_abc123/'),
          'instagram',
        );
      });

      test('routes instagram reels URLs', () {
        expect(
          UrlExtractor.detectPlatform('https://instagram.com/reel/D_xyz987/'),
          'instagram',
        );
      });

      test('routes instagr.am short links', () {
        expect(
          UrlExtractor.detectPlatform('https://instagr.am/p/sample123'),
          'instagram',
        );
      });
    });

    group('YouTube Routing', () {
      test('routes standard youtube.com watch URLs', () {
        expect(
          UrlExtractor.detectPlatform(
            'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
          ),
          'youtube',
        );
      });

      test('routes mobile youtube URLs with extra timestamps and params', () {
        expect(
          UrlExtractor.detectPlatform(
            'https://m.youtube.com/watch?v=dQw4w9WgXcQ&t=45s&feature=shared',
          ),
          'youtube',
        );
      });

      test('routes youtu.be short links', () {
        expect(
          UrlExtractor.detectPlatform('https://youtu.be/dQw4w9WgXcQ'),
          'youtube',
        );
      });

      test('routes youtube shorts URLs', () {
        expect(
          UrlExtractor.detectPlatform('https://youtube.com/shorts/3xyz_abc-89'),
          'youtube',
        );
      });
    });

    group('Generic Article Routing', () {
      test('routes blogs and news websites to article extractor', () {
        expect(
          UrlExtractor.detectPlatform('https://blog.samaltman.com/ideas'),
          'article',
        );
        expect(
          UrlExtractor.detectPlatform('https://techcrunch.com/2026/08/ai-news'),
          'article',
        );
        expect(
          UrlExtractor.detectPlatform(
            'https://developer.mozilla.org/en-US/docs/Web/HTTP',
          ),
          'article',
        );
      });

      test('routes github, substack, medium articles to article extractor', () {
        expect(
          UrlExtractor.detectPlatform(
            'https://pragmaticengineer.com/newsletter',
          ),
          'article',
        );
        expect(
          UrlExtractor.detectPlatform('https://github.com/flutter/flutter'),
          'article',
        );
      });

      test('defaults to article on empty or non-URL string', () {
        expect(UrlExtractor.detectPlatform('not-a-valid-url'), 'article');
      });
    });
  });
}
