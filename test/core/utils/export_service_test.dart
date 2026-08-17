import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:recall/core/utils/export_service.dart';
import 'package:recall/data/models/saved_item.dart';

void main() {
  group('ExportService Tests', () {
    final sampleItems = [
      SavedItem(
        id: 'item-1',
        url: 'https://flutter.dev',
        platform: 'article',
        title: 'Flutter Framework Guide',
        summary: 'A fast framework for cross-platform apps.',
        keyPoints: const [
          'High performance rendering engine',
          'Declarative reactive widgets',
        ],
        category: 'Technology',
        tags: const ['flutter', 'dart'],
        rawContent: 'Full article text content here.',
        createdAt: DateTime(2026, 8, 17),
      ),
      SavedItem(
        id: 'item-2',
        url: 'https://youtube.com/watch?v=123',
        platform: 'youtube',
        title: 'State Management Deep Dive',
        summary: 'Comparing Riverpod with alternatives.',
        category: 'Education',
        createdAt: DateTime(2026, 8, 16),
      ),
    ];

    test('toMarkdown generates Obsidian/Notion compatible Markdown', () {
      final md = ExportService.toMarkdown(sampleItems);

      expect(md, contains('# Recall Library Export'));
      expect(md, contains('Total Bookmarks: 2'));
      expect(md, contains('## Flutter Framework Guide'));
      expect(md, contains('- **URL**: [https://flutter.dev](https://flutter.dev)'));
      expect(md, contains('- **Platform**: ARTICLE'));
      expect(md, contains('- **Category**: Technology'));
      expect(md, contains('- **Tags**: #flutter #dart'));
      expect(md, contains('### AI Summary'));
      expect(md, contains('A fast framework for cross-platform apps.'));
      expect(md, contains('### Key Takeaways'));
      expect(md, contains('- High performance rendering engine'));
      expect(md, contains('<details><summary>Extracted Content</summary>'));
      expect(md, contains('## State Management Deep Dive'));
    });

    test('toJson generates structured and parseable JSON string', () {
      final jsonStr = ExportService.toJson(sampleItems);
      final decoded = jsonDecode(jsonStr) as List<dynamic>;

      expect(decoded.length, 2);
      expect(decoded.first['id'], 'item-1');
      expect(decoded.first['title'], 'Flutter Framework Guide');
      expect(decoded.first['category'], 'Technology');
      expect(decoded.last['platform'], 'youtube');
    });
  });
}
