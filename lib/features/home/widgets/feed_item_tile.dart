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
        return Icons.tag_rounded;
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

  ({Color bg, Color fg}) _categoryColors(ColorScheme scheme, String? category) {
    switch (category?.toLowerCase()) {
      case 'technology':
        return (bg: scheme.primaryContainer, fg: scheme.onPrimaryContainer);
      case 'finance':
      case 'business':
        return (bg: scheme.secondaryContainer, fg: scheme.onSecondaryContainer);
      case 'entertainment':
      case 'food':
      case 'news':
        return (bg: scheme.tertiaryContainer, fg: scheme.onTertiaryContainer);
      case 'health':
      case 'education':
        return (bg: scheme.surfaceContainerHigh, fg: scheme.onSurfaceVariant);
      default:
        return (bg: scheme.surfaceContainerLow, fg: scheme.onSurfaceVariant);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    String supportingText;
    if (item.isProcessing) {
      supportingText = 'Summarizing with AI…';
    } else if (item.isFailed) {
      supportingText = item.summary ?? "Couldn't process — tap to retry";
    } else {
      supportingText = item.summary ?? 'No summary available';
    }

    final headline = item.title?.isNotEmpty == true ? item.title! : item.url;

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
                      color: colorScheme.secondaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _platformIcon(item.platform),
                      color: colorScheme.onSecondaryContainer,
                      size: 20,
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
                          color: colorScheme.primary,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: colorScheme.surface,
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
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: colorScheme.primary,
                ),
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
                    color: colorScheme.tertiaryContainer,
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.lock_outline_rounded,
                        size: 13,
                        color: colorScheme.onTertiaryContainer,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Blocked',
                        style: (textTheme.labelSmall ?? const TextStyle(fontSize: 11)).copyWith(
                          color: colorScheme.onTertiaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else if (item.category != null && item.category!.isNotEmpty)
              Builder(
                builder: (context) {
                  final catColors =
                      _categoryColors(colorScheme, item.category);
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: catColors.bg,
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Text(
                      item.category!,
                      style: (textTheme.labelSmall ??
                              const TextStyle(fontSize: 11))
                          .copyWith(
                        color: catColors.fg,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                },
              ),
            if (item.isFavorite) ...[
              const SizedBox(width: 6),
              Icon(Icons.star_rounded, size: 18, color: colorScheme.primary),
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
          color: colorScheme.secondaryContainer,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              item.isRead ? 'Mark Unread' : 'Archive',
              style: (textTheme.labelLarge ?? const TextStyle(fontSize: 13)).copyWith(
                color: colorScheme.onSecondaryContainer,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              item.isRead ? Icons.unarchive_outlined : Icons.archive_outlined,
              color: colorScheme.onSecondaryContainer,
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
