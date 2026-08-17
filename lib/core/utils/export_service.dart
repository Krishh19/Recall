import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:recall/data/models/saved_item.dart';
import 'package:share_plus/share_plus.dart';

/// Helper service for exporting saved items to Markdown and JSON formats.
class ExportService {
  /// Converts a list of [SavedItem]s to Obsidian/Notion-compatible Markdown.
  static String toMarkdown(List<SavedItem> items) {
    final buffer = StringBuffer();
    buffer.writeln('# Recall Library Export');
    buffer.writeln('Exported on: ${DateTime.now().toIso8601String().split('T').first}\n');
    buffer.writeln('Total Bookmarks: ${items.length}\n---\n');

    for (final item in items) {
      buffer.writeln('## ${item.title ?? item.url}');
      buffer.writeln('- **URL**: [${item.url}](${item.url})');
      buffer.writeln('- **Platform**: ${item.platform.toUpperCase()}');
      buffer.writeln('- **Category**: ${item.category ?? "Uncategorized"}');
      if (item.tags != null && item.tags!.isNotEmpty) {
        buffer.writeln('- **Tags**: ${item.tags!.map((t) => "#$t").join(" ")}');
      }
      buffer.writeln('- **Saved At**: ${item.createdAt.toIso8601String().split('T').first}\n');

      if (item.summary != null && item.summary!.isNotEmpty) {
        buffer.writeln('### AI Summary');
        buffer.writeln('${item.summary}\n');
      }

      if (item.keyPoints != null && item.keyPoints!.isNotEmpty) {
        buffer.writeln('### Key Takeaways');
        for (final pt in item.keyPoints!) {
          buffer.writeln('- $pt');
        }
        buffer.writeln();
      }

      if (item.rawContent != null && item.rawContent!.isNotEmpty) {
        buffer.writeln('<details><summary>Extracted Content</summary>\n');
        buffer.writeln(item.rawContent);
        buffer.writeln('\n</details>\n');
      }

      buffer.writeln('---\n');
    }

    return buffer.toString();
  }

  /// Converts a list of [SavedItem]s to structured JSON.
  static String toJson(List<SavedItem> items) {
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(items.map((i) => i.toJson()).toList());
  }

  /// Copies exported text to clipboard and shows user feedback.
  static Future<void> copyToClipboard(
    BuildContext context,
    String content, {
    String message = 'Copied library to clipboard!',
  }) async {
    await Clipboard.setData(ClipboardData(text: content));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  /// Shares exported text using system share sheet.
  static Future<void> shareText(String content, {String subject = 'Recall Export'}) async {
    // ignore: deprecated_member_use
    await Share.share(content, subject: subject);
  }
}
