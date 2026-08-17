import 'dart:convert';
import 'package:flutter/foundation.dart';

/// Represents an item saved by a user in Recall.
@immutable
class SavedItem {
  /// Unique identifier for the saved item.
  final String id;

  /// The ID of the authenticated user who owns this item, if any.
  final String? userId;

  /// The original URL that was shared into Recall.
  final String url;

  /// The source platform ('twitter', 'instagram', 'youtube', 'article').
  final String platform;

  /// The extracted or inferred title of the content.
  final String? title;

  /// The URL of the thumbnail image, if available.
  final String? thumbnailUrl;

  /// The raw extracted text or transcript before summarization.
  final String? rawContent;

  /// The AI-generated 1-2 sentence summary.
  final String? summary;

  /// Key takeaways extracted by the AI summarizer.
  final List<String>? keyPoints;

  /// The detected category (e.g., Technology, Business, Health, etc.).
  final String? category;

  /// Lowercase tags associated with the content.
  final List<String>? tags;

  /// Processing status ('processing', 'done', 'failed').
  final String status;

  /// Whether the user has marked this item as read.
  final bool isRead;

  /// Whether the user has favorited this item.
  final bool isFavorite;

  /// Timestamp when the item was saved.
  final DateTime createdAt;

  /// Whether this item is currently being extracted/summarized.
  bool get isProcessing => status == 'processing';

  /// Whether processing failed.
  bool get isFailed => status == 'failed';

  /// Whether processing completed successfully.
  bool get isDone => status == 'done';

  /// Creates a [SavedItem] instance.
  const SavedItem({
    required this.id,
    this.userId,
    required this.url,
    required this.platform,
    this.title,
    this.thumbnailUrl,
    this.rawContent,
    this.summary,
    this.keyPoints,
    this.category,
    this.tags,
    this.status = 'processing',
    this.isRead = false,
    this.isFavorite = false,
    required this.createdAt,
  });

  /// Creates a [SavedItem] from a JSON map (e.g. Supabase row).
  factory SavedItem.fromJson(Map<String, dynamic> json) {
    List<String>? parseStringList(dynamic value) {
      if (value == null) return null;
      if (value is List) {
        return value.map((item) => item.toString()).toList();
      }
      return null;
    }

    return SavedItem(
      id: json['id'] as String,
      userId: json['user_id'] as String?,
      url: json['url'] as String,
      platform: json['platform'] as String,
      title: json['title'] as String?,
      thumbnailUrl: json['thumbnail_url'] as String?,
      rawContent: json['raw_content'] as String?,
      summary: json['summary'] as String?,
      keyPoints: parseStringList(json['key_points']),
      category: json['category'] as String?,
      tags: parseStringList(json['tags']),
      status: (json['status'] as String?) ?? 'processing',
      isRead: (json['is_read'] as bool?) ?? false,
      isFavorite: (json['is_favorite'] as bool?) ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  /// Creates a [SavedItem] from a Drift table row.
  factory SavedItem.fromDrift(dynamic data) {
    List<String>? parseJsonList(String? jsonStr) {
      if (jsonStr == null || jsonStr.isEmpty) return null;
      try {
        final decoded = json.decode(jsonStr);
        if (decoded is List) {
          return decoded.map((e) => e.toString()).toList();
        }
      } catch (_) {}
      return null;
    }

    return SavedItem(
      id: data.id as String,
      url: data.url as String,
      platform: data.platform as String,
      title: data.title as String?,
      thumbnailUrl: data.thumbnailUrl as String?,
      rawContent: data.rawContent as String?,
      summary: data.summary as String?,
      keyPoints: parseJsonList(data.keyPoints as String?),
      category: data.category as String?,
      tags: parseJsonList(data.tags as String?),
      status: data.status as String? ?? 'processing',
      isRead: data.isRead as bool? ?? false,
      isFavorite: data.isFavorite as bool? ?? false,
      createdAt: data.createdAt as DateTime? ?? DateTime.now(),
    );
  }

  /// Converts this [SavedItem] to a JSON map suitable for Supabase.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'url': url,
      'platform': platform,
      'title': title,
      'thumbnail_url': thumbnailUrl,
      'raw_content': rawContent,
      'summary': summary,
      'key_points': keyPoints,
      'category': category,
      'tags': tags,
      'status': status,
      'is_read': isRead,
      'is_favorite': isFavorite,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Creates a copy of this [SavedItem] with the given fields replaced.
  SavedItem copyWith({
    String? id,
    String? userId,
    String? url,
    String? platform,
    String? title,
    String? thumbnailUrl,
    String? rawContent,
    String? summary,
    List<String>? keyPoints,
    String? category,
    List<String>? tags,
    String? status,
    bool? isRead,
    bool? isFavorite,
    DateTime? createdAt,
  }) {
    return SavedItem(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      url: url ?? this.url,
      platform: platform ?? this.platform,
      title: title ?? this.title,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      rawContent: rawContent ?? this.rawContent,
      summary: summary ?? this.summary,
      keyPoints: keyPoints ?? this.keyPoints,
      category: category ?? this.category,
      tags: tags ?? this.tags,
      status: status ?? this.status,
      isRead: isRead ?? this.isRead,
      isFavorite: isFavorite ?? this.isFavorite,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SavedItem &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          userId == other.userId &&
          url == other.url &&
          platform == other.platform &&
          title == other.title &&
          thumbnailUrl == other.thumbnailUrl &&
          rawContent == other.rawContent &&
          summary == other.summary &&
          listEquals(keyPoints, other.keyPoints) &&
          category == other.category &&
          listEquals(tags, other.tags) &&
          status == other.status &&
          isRead == other.isRead &&
          isFavorite == other.isFavorite &&
          createdAt == other.createdAt;

  @override
  int get hashCode =>
      id.hashCode ^
      userId.hashCode ^
      url.hashCode ^
      platform.hashCode ^
      title.hashCode ^
      thumbnailUrl.hashCode ^
      rawContent.hashCode ^
      summary.hashCode ^
      Object.hashAll(keyPoints ?? []) ^
      category.hashCode ^
      Object.hashAll(tags ?? []) ^
      status.hashCode ^
      isRead.hashCode ^
      isFavorite.hashCode ^
      createdAt.hashCode;

  @override
  String toString() =>
      'SavedItem(id: $id, platform: $platform, status: $status, title: $title)';
}
