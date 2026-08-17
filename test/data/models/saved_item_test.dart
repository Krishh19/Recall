import 'package:flutter_test/flutter_test.dart';
import 'package:recall/data/models/saved_item.dart';

void main() {
  group('SavedItem', () {
    final now = DateTime.parse('2026-08-16T12:00:00.000Z');

    final sampleJson = <String, dynamic>{
      'id': 'd0e3c8f0-1234-5678-9abc-def012345678',
      'user_id': 'user-123',
      'url': 'https://example.com/article',
      'platform': 'article',
      'title': 'Sample Article Title',
      'thumbnail_url': 'https://example.com/thumb.jpg',
      'raw_content': 'Raw article body text...',
      'summary': 'A short summary of the article.',
      'key_points': ['Point 1', 'Point 2', 'Point 3'],
      'category': 'Technology',
      'tags': ['flutter', 'dart', 'supabase'],
      'status': 'done',
      'is_read': true,
      'is_favorite': true,
      'created_at': now.toIso8601String(),
    };

    test('parses fromJson correctly with all fields populated', () {
      final item = SavedItem.fromJson(sampleJson);

      expect(item.id, 'd0e3c8f0-1234-5678-9abc-def012345678');
      expect(item.userId, 'user-123');
      expect(item.url, 'https://example.com/article');
      expect(item.platform, 'article');
      expect(item.title, 'Sample Article Title');
      expect(item.thumbnailUrl, 'https://example.com/thumb.jpg');
      expect(item.rawContent, 'Raw article body text...');
      expect(item.summary, 'A short summary of the article.');
      expect(item.keyPoints, ['Point 1', 'Point 2', 'Point 3']);
      expect(item.category, 'Technology');
      expect(item.tags, ['flutter', 'dart', 'supabase']);
      expect(item.status, 'done');
      expect(item.isRead, isTrue);
      expect(item.isFavorite, isTrue);
      expect(item.createdAt, now);
    });

    test('parses fromJson with optional fields omitted/null', () {
      final minimalJson = <String, dynamic>{
        'id': 'd0e3c8f0-1234-5678-9abc-def012345678',
        'url': 'https://example.com/article',
        'platform': 'article',
        'created_at': now.toIso8601String(),
      };

      final item = SavedItem.fromJson(minimalJson);

      expect(item.id, 'd0e3c8f0-1234-5678-9abc-def012345678');
      expect(item.userId, isNull);
      expect(item.title, isNull);
      expect(item.thumbnailUrl, isNull);
      expect(item.rawContent, isNull);
      expect(item.summary, isNull);
      expect(item.keyPoints, isNull);
      expect(item.category, isNull);
      expect(item.tags, isNull);
      expect(item.status, 'processing');
      expect(item.isRead, isFalse);
      expect(item.isFavorite, isFalse);
    });

    test('serializes toJson correctly', () {
      final item = SavedItem.fromJson(sampleJson);
      final json = item.toJson();

      expect(json['id'], 'd0e3c8f0-1234-5678-9abc-def012345678');
      expect(json['user_id'], 'user-123');
      expect(json['url'], 'https://example.com/article');
      expect(json['platform'], 'article');
      expect(json['title'], 'Sample Article Title');
      expect(json['thumbnail_url'], 'https://example.com/thumb.jpg');
      expect(json['raw_content'], 'Raw article body text...');
      expect(json['summary'], 'A short summary of the article.');
      expect(json['key_points'], ['Point 1', 'Point 2', 'Point 3']);
      expect(json['category'], 'Technology');
      expect(json['tags'], ['flutter', 'dart', 'supabase']);
      expect(json['status'], 'done');
      expect(json['is_read'], true);
      expect(json['is_favorite'], true);
      expect(json['created_at'], now.toIso8601String());
    });

    test('copyWith updates specified fields only', () {
      final item = SavedItem.fromJson(sampleJson);
      final updated = item.copyWith(
        status: 'failed',
        isFavorite: false,
        title: 'New Title',
      );

      expect(updated.status, 'failed');
      expect(updated.isFavorite, false);
      expect(updated.title, 'New Title');
      expect(updated.id, item.id);
      expect(updated.url, item.url);
      expect(updated.userId, item.userId);
      expect(updated.summary, item.summary);
    });

    test('supports value equality', () {
      final item1 = SavedItem.fromJson(sampleJson);
      final item2 = SavedItem.fromJson(sampleJson);

      expect(item1, equals(item2));
      expect(item1.hashCode, equals(item2.hashCode));
    });
  });
}
