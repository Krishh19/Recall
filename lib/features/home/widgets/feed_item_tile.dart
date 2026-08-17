import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:recall/data/models/saved_item.dart';
import 'package:recall/data/repositories/saved_item_repository.dart';
import 'package:recall/features/save/retry_tracker.dart';

/// Renders a single [SavedItem] within the Home feed as an expressive list item.
class FeedItemTile extends ConsumerWidget {
  /// Creates the feed item tile.
  const FeedItemTile({
    required this.item,
    this.onTap,
    this.onLongPress,
    this.selected = false,
    this.selectionMode = false,
    super.key,
  });

  /// The item model.
  final SavedItem item;

  /// Optional callback invoked when the item is tapped.
  final VoidCallback? onTap;

  /// Optional callback invoked when the item is long-pressed.
  final VoidCallback? onLongPress;

  /// Whether this tile is selected in multi-select mode.
  final bool selected;

  /// Whether the parent list is in selection mode.
  final bool selectionMode;

  IconData _platformIcon(String platform) {
    switch (platform.toLowerCase()) {
      case 'twitter':
      case 'x':
        return Icons.tag;
      case 'youtube':
        return Icons.play_arrow_rounded;
      case 'instagram':
        return Icons.camera_alt_outlined;
      case 'tiktok':
        return Icons.music_note_rounded;
      case 'reddit':
        return Icons.forum_outlined;
      case 'article':
      default:
        return Icons.article_outlined;
    }
  }

  Color _platformColor(String platform, M3EColorScheme scheme) {
    switch (platform.toLowerCase()) {
      case 'twitter':
      case 'x':
        return scheme.primary;
      case 'youtube':
        return scheme.error;
      case 'instagram':
        return scheme.tertiary;
      case 'tiktok':
        return Colors.pinkAccent;
      case 'reddit':
        return Colors.deepOrange;
      case 'article':
      default:
        return scheme.secondary;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = M3ETheme.of(context);
    final scheme = theme.colorScheme;

    String supportingText;
    if (item.isProcessing) {
      supportingText = 'Summarizing with AI…';
    } else if (item.isFailed) {
      supportingText = item.summary ?? "Couldn't process — tap to retry";
    } else {
      supportingText = item.summary ?? 'No summary available';
    }

    final headline = item.title?.isNotEmpty == true ? item.title! : item.url;
    final platformColor = _platformColor(item.platform, scheme);

    final tileWidget = GestureDetector(
      onLongPress: onLongPress,
      child: M3EListItem(
        selected: selected,
        overline: Uri.tryParse(item.url)?.host,
        headline: headline,
        supportingText: supportingText,
        leading: selectionMode
            ? Checkbox(
                value: selected,
                onChanged: (_) => onTap?.call(),
              )
            : Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: platformColor.withAlpha(25),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _platformIcon(item.platform),
                      color: platformColor,
                      size: 22,
                    ),
                  ),
                  if (!item.isRead)
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: scheme.primary,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: scheme.surface,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (item.isProcessing)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else if (item.isFailed)
              GestureDetector(
                onTap: () {
                  ref
                      .read(retryTrackerProvider.notifier)
                      .retryItem(context, item);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: scheme.errorContainer,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.lock_outline_rounded,
                        size: 14,
                        color: scheme.onErrorContainer,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Blocked',
                        style: theme.typeScale.labelSmall.copyWith(
                          color: scheme.onErrorContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else if (item.category != null && item.category!.isNotEmpty)
              M3EChip(label: item.category!, type: M3EChipType.assist),
            if (item.isFavorite) ...[
              const SizedBox(width: 6),
              Icon(Icons.star_rounded, size: 18, color: scheme.primary),
            ],
          ],
        ),
        onTap: () {
          if (selectionMode) {
            onTap?.call();
          } else if (onTap != null) {
            onTap!();
          }
        },
      ),
    );

    if (selectionMode) {
      return tileWidget;
    }

    return Dismissible(
      key: ValueKey('dismissible_${item.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          color: scheme.secondaryContainer,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              item.isRead ? 'Mark Unread' : 'Archive',
              style: theme.typeScale.labelLarge.copyWith(
                color: scheme.onSecondaryContainer,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              item.isRead ? Icons.unarchive_outlined : Icons.archive_outlined,
              color: scheme.onSecondaryContainer,
            ),
          ],
        ),
      ),
      confirmDismiss: (direction) async {
        await ref
            .read(savedItemRepositoryProvider)
            .toggleRead(id: item.id, isRead: !item.isRead);
        return false;
      },
      child: tileWidget,
    );
  }
}
