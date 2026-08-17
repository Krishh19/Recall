import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Represents the extracted metadata and content from a web link.
class ExtractedContent {
  /// Creates an [ExtractedContent] data model.
  const ExtractedContent({
    required this.title,
    required this.rawContent,
    this.thumbnailUrl,
    required this.platform,
    this.isSubstantive = true,
    this.errorMessage,
  });

  /// The extracted title of the post, video, or article.
  final String title;

  /// The raw markdown or extracted text content.
  final String rawContent;

  /// The media thumbnail URL, if available.
  final String? thumbnailUrl;

  /// The detected platform.
  final String platform;

  /// Whether the extraction retrieved real, substantive post/article body
  /// (as opposed to an empty redirect, login wall, or placeholder link).
  final bool isSubstantive;

  /// Explanatory message if extraction failed or was blocked by auth.
  final String? errorMessage;
}

/// Service that extracts readable content, metadata, and media thumbnails
/// from Twitter/X, Instagram, YouTube, TikTok, Reddit, and generic web articles.
class ContentExtractor {
  /// Creates a [ContentExtractor] instance with injected [Dio].
  ContentExtractor({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                connectTimeout: const Duration(seconds: 12),
                receiveTimeout: const Duration(seconds: 15),
                headers: {
                  'User-Agent':
                      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36',
                  'Accept-Language': 'en-US,en;q=0.9',
                },
              ),
            );

  final Dio _dio;

  static const List<String> _blockedKeywords = [
    'log in • instagram',
    'sign up to see photos',
    'javascript is not available',
    'just a moment...',
    'cf-browser-verification',
    'attention required! | cloudflare',
    'access denied',
    '403 forbidden',
    'page not found',
    'enable javascript to continue',
  ];

  /// Checks if extracted text contains substantive content and not a blocker.
  bool _hasSubstantiveContent(String text) {
    final trimmed = text.trim();
    if (trimmed.length < 50) return false;
    final lower = trimmed.toLowerCase();
    for (final kw in _blockedKeywords) {
      if (lower.contains(kw)) return false;
    }
    return true;
  }

  /// Helper to extract meta tag contents from raw HTML.
  String? _extractMeta(String html, String propertyOrName) {
    final patterns = [
      RegExp(
        '<meta[^>]*property=["\']$propertyOrName["\'][^>]*content=["\']([^"\']+)["\']',
        caseSensitive: false,
      ),
      RegExp(
        '<meta[^>]*content=["\']([^"\']+)["\'][^>]*property=["\']$propertyOrName["\']',
        caseSensitive: false,
      ),
      RegExp(
        '<meta[^>]*name=["\']$propertyOrName["\'][^>]*content=["\']([^"\']+)["\']',
        caseSensitive: false,
      ),
      RegExp(
        '<meta[^>]*content=["\']([^"\']+)["\'][^>]*name=["\']$propertyOrName["\']',
        caseSensitive: false,
      ),
    ];
    for (final pattern in patterns) {
      final match = pattern.firstMatch(html);
      if (match != null && match.group(1) != null) {
        return match.group(1)!.trim();
      }
    }
    return null;
  }

  /// Extracts content based on the target URL domain.
  Future<ExtractedContent> extract(String url) async {
    final uri = Uri.parse(url);
    final host = uri.host.toLowerCase();

    if (host == 'x.com' ||
        host.endsWith('.x.com') ||
        host == 'twitter.com' ||
        host.endsWith('.twitter.com') ||
        host == 't.co') {
      return _extractTwitter(url);
    }

    if (host == 'instagram.com' ||
        host.endsWith('.instagram.com') ||
        host == 'instagr.am') {
      return _extractInstagram(url);
    }

    if (host == 'youtube.com' ||
        host.endsWith('.youtube.com') ||
        host == 'youtu.be') {
      return _extractYouTube(url);
    }

    if (host == 'tiktok.com' || host.endsWith('.tiktok.com')) {
      return _extractTikTok(url);
    }

    if (host == 'reddit.com' || host.endsWith('.reddit.com')) {
      return _extractReddit(url);
    }

    return _extractArticle(url);
  }

  /// Twitter / X multi-strategy extraction (FxTwitter API -> oEmbed -> Jina Reader).
  Future<ExtractedContent> _extractTwitter(String url) async {
    // 1. Try FxTwitter API for structured tweet data
    try {
      final match = RegExp(r'status/(\d+)').firstMatch(url);
      if (match != null && match.group(1) != null) {
        final tweetId = match.group(1)!;
        final fxUrl = 'https://api.fxtwitter.com/status/$tweetId';
        final response = await _dio.get<Map<String, dynamic>>(
          fxUrl,
          options: Options(responseType: ResponseType.json),
        );

        if (response.statusCode == 200 && response.data != null) {
          final tweet = response.data!['tweet'] as Map<String, dynamic>?;
          if (tweet != null) {
            final text = tweet['text'] as String? ?? '';
            final author = tweet['author'] as Map<String, dynamic>?;
            final authorName = author?['name'] as String? ?? 'X User';
            final screenName = author?['screen_name'] as String? ?? '';
            final media = tweet['media'] as Map<String, dynamic>?;
            final photos = media?['photos'] as List?;
            final thumbnailUrl = photos != null && photos.isNotEmpty
                ? photos.first['url'] as String?
                : null;

            if (_hasSubstantiveContent(text) || text.trim().isNotEmpty) {
              return ExtractedContent(
                title: 'Post by $authorName (@$screenName)',
                rawContent: 'Post by $authorName (@$screenName):\n\n$text\n\nOriginal: $url',
                thumbnailUrl: thumbnailUrl,
                platform: 'twitter',
                isSubstantive: true,
              );
            }
          }
        }
      }
    } catch (e) {
      debugPrint('FxTwitter API fetch error: $e');
    }

    // 2. Try publish.x.com oEmbed
    try {
      final oembedUrl =
          'https://publish.x.com/oembed?url=${Uri.encodeComponent(url)}&omit_script=true';
      final response = await _dio.get<Map<String, dynamic>>(oembedUrl);

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data!;
        final authorName = data['author_name'] as String? ?? 'X Post';
        final html = data['html'] as String? ?? '';

        final text = html
            .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
            .replaceAll(RegExp(r'<[^>]+>'), '')
            .replaceAll('&amp;', '&')
            .replaceAll('&lt;', '<')
            .replaceAll('&gt;', '>')
            .replaceAll('&quot;', '"')
            .replaceAll('&#39;', "'")
            .trim();

        if (text.isNotEmpty) {
          return ExtractedContent(
            title: 'Post by $authorName',
            rawContent: 'Post by $authorName:\n\n$text\n\nOriginal: $url',
            platform: 'twitter',
            isSubstantive: _hasSubstantiveContent(text),
          );
        }
      }
    } catch (e) {
      debugPrint('Twitter oEmbed fetch warning: $e');
    }

    return _extractArticle(url);
  }

  /// Instagram multi-strategy extraction (Embed HTML -> Crawler UA -> Jina Reader).
  Future<ExtractedContent> _extractInstagram(String url) async {
    String? shortcode;
    final match = RegExp(r'/(?:p|reel|reels|share/p|share/reel)/([A-Za-z0-9_-]+)').firstMatch(url);
    if (match != null && match.group(1) != null) {
      shortcode = match.group(1);
    }

    // 1. Try public captioned embed endpoint
    if (shortcode != null) {
      try {
        final embedUrl = 'https://www.instagram.com/p/$shortcode/embed/captioned/';
        final embedRes = await _dio.get<String>(
          embedUrl,
          options: Options(
            responseType: ResponseType.plain,
            headers: {
              'User-Agent':
                  'Mozilla/5.0 (iPhone; CPU iPhone OS 16_5 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.5 Mobile/15E148 Safari/604.1',
            },
          ),
        );

        if (embedRes.statusCode == 200 && embedRes.data != null) {
          final html = embedRes.data!;
          final captionMatch = RegExp(
            r'<div class="Caption"[^>]*>(.*?)</div>',
            dotAll: true,
          ).firstMatch(html);

          if (captionMatch != null && captionMatch.group(1) != null) {
            final captionText = captionMatch.group(1)!
                .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
                .replaceAll(RegExp(r'<[^>]+>'), '')
                .replaceAll('&amp;', '&')
                .replaceAll('&lt;', '<')
                .replaceAll('&gt;', '>')
                .replaceAll('&#39;', "'")
                .replaceAll('&quot;', '"')
                .trim();

            final thumbnail = _extractMeta(html, 'og:image');

            if (_hasSubstantiveContent(captionText) || captionText.length >= 25) {
              return ExtractedContent(
                title: 'Instagram Post',
                rawContent: 'Instagram Post Caption:\n\n$captionText\n\nOriginal: $url',
                thumbnailUrl: thumbnail,
                platform: 'instagram',
                isSubstantive: true,
              );
            }
          }
        }
      } catch (e) {
        debugPrint('Instagram embed extraction warning: $e');
      }
    }

    // 2. Try OpenGraph with Social Crawler User-Agent (WhatsApp / Facebook)
    try {
      final ogRes = await _dio.get<String>(
        url,
        options: Options(
          responseType: ResponseType.plain,
          headers: {
            'User-Agent':
                'facebookexternalhit/1.1 (+http://www.facebook.com/externalhit_uatext.php)',
            'Accept': 'text/html,application/xhtml+xml',
          },
        ),
      );

      if (ogRes.statusCode == 200 && ogRes.data != null) {
        final html = ogRes.data!;
        final title = _extractMeta(html, 'og:title') ?? 'Instagram Post';
        final desc = _extractMeta(html, 'og:description') ?? '';
        final thumbnail = _extractMeta(html, 'og:image');

        if (_hasSubstantiveContent(desc) || desc.length >= 25) {
          return ExtractedContent(
            title: title,
            rawContent: '$title\n\n$desc\n\nOriginal: $url',
            thumbnailUrl: thumbnail,
            platform: 'instagram',
            isSubstantive: true,
          );
        }
      }
    } catch (e) {
      debugPrint('Instagram OG crawler warning: $e');
    }

    // 3. Try Jina Reader
    try {
      final jinaRes = await _dio.get<String>(
        'https://r.jina.ai/$url',
        options: Options(responseType: ResponseType.plain),
      );
      if (jinaRes.statusCode == 200 && jinaRes.data != null) {
        final markdown = jinaRes.data!;
        if (_hasSubstantiveContent(markdown)) {
          return ExtractedContent(
            title: 'Instagram Post',
            rawContent: markdown.trim(),
            platform: 'instagram',
            isSubstantive: true,
          );
        }
      }
    } catch (_) {}

    // Honest unextractable return for Instagram auth wall
    return ExtractedContent(
      title: 'Instagram Post',
      rawContent: 'Saved Instagram Post: $url',
      platform: 'instagram',
      isSubstantive: false,
      errorMessage:
          'Instagram requires user login to read this post caption. Tap below to paste the caption manually.',
    );
  }

  /// TikTok extraction via official oEmbed endpoint.
  Future<ExtractedContent> _extractTikTok(String url) async {
    try {
      final oembedUrl =
          'https://www.tiktok.com/oembed?url=${Uri.encodeComponent(url)}';
      final response = await _dio.get<Map<String, dynamic>>(oembedUrl);

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data!;
        final title = data['title'] as String? ?? 'TikTok Video';
        final author = data['author_name'] as String? ?? '';
        final thumbnail = data['thumbnail_url'] as String?;

        return ExtractedContent(
          title: title.isNotEmpty ? title : 'TikTok by $author',
          rawContent: 'TikTok by $author:\n$title\n\nOriginal: $url',
          thumbnailUrl: thumbnail,
          platform: 'tiktok',
          isSubstantive: _hasSubstantiveContent(title) || title.isNotEmpty,
        );
      }
    } catch (e) {
      debugPrint('TikTok oEmbed error: $e');
    }
    return _extractArticle(url);
  }

  /// Reddit extraction via public JSON API.
  Future<ExtractedContent> _extractReddit(String url) async {
    try {
      var cleanUrl = url.split('?').first;
      if (cleanUrl.endsWith('/')) {
        cleanUrl = cleanUrl.substring(0, cleanUrl.length - 1);
      }
      final jsonUrl = cleanUrl.endsWith('.json') ? cleanUrl : '$cleanUrl.json';

      final response = await _dio.get<dynamic>(
        jsonUrl,
        options: Options(
          headers: {
            'User-Agent': 'android:com.recall.app:v1.0.0 (by /u/recall_app)',
          },
        ),
      );

      if (response.statusCode == 200 && response.data is List) {
        final list = response.data as List;
        if (list.isNotEmpty) {
          final postData =
              list.first['data']?['children']?[0]?['data'] as Map<String, dynamic>?;
          if (postData != null) {
            final title = postData['title'] as String? ?? 'Reddit Post';
            final selftext = postData['selftext'] as String? ?? '';
            final targetUrl = postData['url'] as String? ?? '';
            final author = postData['author'] as String? ?? '';
            final subreddit = postData['subreddit'] as String? ?? '';
            final thumbnail = postData['thumbnail'] as String?;

            // Extract top comments from second element if present
            final commentsBuffer = StringBuffer();
            if (list.length > 1 && list[1]['data']?['children'] is List) {
              final comments = list[1]['data']['children'] as List;
              for (final c in comments.take(3)) {
                final body = c['data']?['body'] as String?;
                if (body != null &&
                    body.trim().isNotEmpty &&
                    body != '[deleted]' &&
                    body != '[removed]') {
                  commentsBuffer.writeln('- $body');
                }
              }
            }

            final commentsText = commentsBuffer.toString().trim();

            final rawContent = 'Reddit Post in r/$subreddit by u/$author:\n'
                'Title: $title\n\n'
                '${selftext.isNotEmpty ? 'Content:\n$selftext\n\n' : ''}'
                '${targetUrl.isNotEmpty && targetUrl != url ? 'Linked URL: $targetUrl\n\n' : ''}'
                '${commentsText.isNotEmpty ? 'Community Discussion:\n$commentsText\n\n' : ''}'
                'Original: $url';

            return ExtractedContent(
              title: title,
              rawContent: rawContent,
              thumbnailUrl: thumbnail != null && thumbnail.startsWith('http')
                  ? thumbnail
                  : null,
              platform: 'reddit',
              isSubstantive: true,
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Reddit JSON extraction warning: $e');
    }

    // Fallback to Jina Reader
    try {
      final jinaRes = await _dio.get<String>(
        'https://r.jina.ai/$url',
        options: Options(responseType: ResponseType.plain),
      );
      if (jinaRes.statusCode == 200 && jinaRes.data != null) {
        final markdown = jinaRes.data!;
        if (_hasSubstantiveContent(markdown)) {
          return ExtractedContent(
            title: 'Reddit Discussion',
            rawContent: markdown.trim(),
            platform: 'reddit',
            isSubstantive: true,
          );
        }
      }
    } catch (_) {}

    return ExtractedContent(
      title: 'Reddit Post',
      rawContent: 'Saved Reddit Link: $url',
      platform: 'reddit',
      isSubstantive: false,
      errorMessage:
          'Reddit blocked automated reading of this thread. Tap below to paste the post or comments manually.',
    );
  }

  /// YouTube extraction with oEmbed metadata and caption track fetching.
  Future<ExtractedContent> _extractYouTube(String url) async {
    String videoId = '';
    final uri = Uri.parse(url);

    if (uri.host.contains('youtu.be')) {
      videoId = uri.path.replaceAll('/', '');
    } else if (uri.queryParameters.containsKey('v')) {
      videoId = uri.queryParameters['v'] ?? '';
    } else if (uri.pathSegments.contains('shorts')) {
      final index = uri.pathSegments.indexOf('shorts');
      if (index + 1 < uri.pathSegments.length) {
        videoId = uri.pathSegments[index + 1];
      }
    }

    String title = 'YouTube Video';
    String authorName = '';
    String? thumbnailUrl = videoId.isNotEmpty
        ? 'https://i.ytimg.com/vi/$videoId/hqdefault.jpg'
        : null;

    try {
      final oembedUrl =
          'https://www.youtube.com/oembed?url=${Uri.encodeComponent(url)}&format=json';
      final response = await _dio.get<Map<String, dynamic>>(oembedUrl);
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data!;
        title = data['title'] as String? ?? title;
        authorName = data['author_name'] as String? ?? '';
        thumbnailUrl = data['thumbnail_url'] as String? ?? thumbnailUrl;
      }
    } catch (e) {
      debugPrint('YouTube oEmbed warning: $e');
    }

    // Try fetching captions
    String transcript = '';
    if (videoId.isNotEmpty) {
      try {
        final pageRes = await _dio.get<String>(
          'https://www.youtube.com/watch?v=$videoId',
          options: Options(
            responseType: ResponseType.plain,
            headers: {'Accept-Language': 'en-US,en;q=0.9'},
          ),
        );

        if (pageRes.statusCode == 200 && pageRes.data != null) {
          final match =
              RegExp(r'"captionTracks":\s*(\[.*?\])').firstMatch(pageRes.data!);
          if (match != null && match.group(1) != null) {
            final tracks = jsonDecode(match.group(1)!) as List;
            final englishTrack = tracks.firstWhere(
              (t) => t['languageCode'] == 'en',
              orElse: () => tracks.isNotEmpty ? tracks.first : null,
            );

            if (englishTrack != null && englishTrack['baseUrl'] != null) {
              final capRes = await _dio.get<String>(
                englishTrack['baseUrl'] as String,
                options: Options(responseType: ResponseType.plain),
              );

              if (capRes.statusCode == 200 && capRes.data != null) {
                final xml = capRes.data!;
                final textMatches =
                    RegExp(r'<text[^>]*>([^<]+)<\/text>').allMatches(xml);
                final lines = textMatches.map((m) {
                  return (m.group(1) ?? '')
                      .replaceAll('&amp;', '&')
                      .replaceAll('&lt;', '<')
                      .replaceAll('&gt;', '>')
                      .replaceAll('&#39;', "'")
                      .replaceAll('&quot;', '"');
                }).join(' ');

                transcript = lines.replaceAll(RegExp(r'\s+'), ' ').trim();
              }
            }
          }
        }
      } catch (e) {
        debugPrint('YouTube caption extraction warning: $e');
      }
    }

    final rawContent = transcript.isNotEmpty
        ? 'Video: $title\nChannel: $authorName\n\nTranscript:\n$transcript'
        : 'Video: $title\nChannel: $authorName\nURL: $url';

    return ExtractedContent(
      title: title,
      rawContent: rawContent,
      thumbnailUrl: thumbnailUrl,
      platform: 'youtube',
      isSubstantive: true,
    );
  }

  /// Generic article extraction with Jina Reader and HTML Open Graph fallback.
  Future<ExtractedContent> _extractArticle(String url) async {
    // 1. Try Jina Reader
    try {
      final jinaRes = await _dio.get<String>(
        'https://r.jina.ai/$url',
        options: Options(
          responseType: ResponseType.plain,
          headers: {
            'X-With-Generated-Alt': 'true',
            'X-Return-Format': 'markdown',
          },
        ),
      );

      if (jinaRes.statusCode == 200 && jinaRes.data != null) {
        final markdown = jinaRes.data!;
        String title = 'Web Article';
        final titleMatch =
            RegExp(r'^Title:\s*(.+)$', multiLine: true, caseSensitive: false)
                    .firstMatch(markdown) ??
                RegExp(r'^#\s+(.+)$', multiLine: true).firstMatch(markdown);

        if (titleMatch != null && titleMatch.group(1) != null) {
          title = titleMatch.group(1)!.trim();
        }

        final imageMatch =
            RegExp(r'!\[.*?\]\((https?:\/\/[^\s)]+)\)').firstMatch(markdown);
        final thumbnail = imageMatch?.group(1);

        if (_hasSubstantiveContent(markdown)) {
          return ExtractedContent(
            title: title,
            rawContent: markdown.trim(),
            thumbnailUrl: thumbnail,
            platform: 'article',
            isSubstantive: true,
          );
        }
      }
    } catch (e) {
      debugPrint('Jina Reader failed, using direct HTML fetch fallback: $e');
    }

    // 2. Direct HTML fetch fallback
    try {
      final res = await _dio.get<String>(
        url,
        options: Options(
          responseType: ResponseType.plain,
          headers: {'Accept': 'text/html,application/xhtml+xml'},
        ),
      );

      if (res.statusCode == 200 && res.data != null) {
        final html = res.data!;

        final titleTagMatch =
            RegExp(r'<title[^>]*>([^<]+)<\/title>', caseSensitive: false)
                .firstMatch(html);
        final title = _extractMeta(html, 'og:title') ??
            titleTagMatch?.group(1) ??
            'Web Article';

        final thumbnail = _extractMeta(html, 'og:image');
        final description =
            _extractMeta(html, 'og:description') ?? _extractMeta(html, 'description') ?? '';

        final cleanedBody = html
            .replaceAll(
              RegExp(r'<script\b[^<]*(?:(?!<\/script>)<[^<]*)*<\/script>'),
              '',
            )
            .replaceAll(
              RegExp(r'<style\b[^<]*(?:(?!<\/style>)<[^<]*)*<\/style>'),
              '',
            )
            .replaceAll(RegExp(r'<[^>]+>'), ' ')
            .replaceAll(RegExp(r'\s+'), ' ')
            .trim();

        final truncated =
            cleanedBody.length > 4000 ? cleanedBody.substring(0, 4000) : cleanedBody;
        final rawContent =
            description.isNotEmpty ? '$description\n\n$truncated' : truncated;

        final isSubstantive = _hasSubstantiveContent(rawContent);

        return ExtractedContent(
          title: title.trim(),
          rawContent: rawContent,
          thumbnailUrl: thumbnail,
          platform: 'article',
          isSubstantive: isSubstantive,
          errorMessage: isSubstantive
              ? null
              : 'Could not extract article content automatically. You can paste the text manually.',
        );
      }
    } catch (e) {
      debugPrint('Direct HTML fetch error: $e');
    }

    return ExtractedContent(
      title: 'Saved Link',
      rawContent: 'Saved URL: $url',
      platform: 'article',
      isSubstantive: false,
      errorMessage:
          'Could not fetch content from this link. You can paste the content manually.',
    );
  }
}
