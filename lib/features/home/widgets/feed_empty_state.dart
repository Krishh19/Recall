import 'package:flutter/material.dart';
import 'package:recall/features/save/widgets/manual_add_url_dialog.dart';

/// Empty state widget displaying tailored illustrations for feed filter states.
class FeedEmptyState extends StatelessWidget {
  /// Creates the feed empty state widget.
  const FeedEmptyState({
    required this.selectedCategory,
    this.onResetFilter,
    super.key,
  });

  /// The active category/filter tab.
  final String selectedCategory;

  /// Optional callback to reset filter to 'All'.
  final VoidCallback? onResetFilter;

  String _assetPathForCategory(String category) {
    switch (category) {
      case 'Unread':
        return 'assets/empty_states/unread_filters.png';
      case 'Favorites':
        return 'assets/empty_states/Favorites.png';
      case 'Blocked':
        return 'assets/empty_states/Blocked_failed.png';
      case 'All':
      default:
        return 'assets/empty_states/home_feed.png';
    }
  }

  String _titleForCategory(String category) {
    switch (category) {
      case 'Unread':
        return 'All Caught Up!';
      case 'Favorites':
        return 'No Favorites Yet';
      case 'Blocked':
        return 'No Blocked Links';
      case 'All':
        return 'Your Recall library is empty';
      default:
        return 'No items in "$category"';
    }
  }

  String _subtitleForCategory(String category) {
    switch (category) {
      case 'Unread':
        return "You've read all your saved bookmarks. Any new links you share into Recall will appear here.";
      case 'Favorites':
        return 'Star your most valuable summaries and articles to quickly access them in this tab.';
      case 'Blocked':
        return 'All your saved links were read and summarized cleanly without issues.';
      case 'All':
        return 'Share links from Twitter/X, YouTube, Instagram, Reddit, or web articles into Recall to extract and summarize them.';
      default:
        return 'Try selecting another filter or save new links relevant to $category.';
    }
  }

  IconData _fallbackIconForCategory(String category) {
    switch (category) {
      case 'Unread':
        return Icons.mark_email_read_outlined;
      case 'Favorites':
        return Icons.star_border_rounded;
      case 'Blocked':
        return Icons.check_circle_outline_rounded;
      default:
        return Icons.bookmark_border_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final isFiltered = selectedCategory != 'All';
    final assetPath = _assetPathForCategory(selectedCategory);
    final title = _titleForCategory(selectedCategory);
    final subtitle = _subtitleForCategory(selectedCategory);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Empty State Illustration with Fallback
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.asset(
                assetPath,
                height: 180,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _fallbackIconForCategory(selectedCategory),
                      size: 48,
                      color: colorScheme.primary,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),

            // Headline
            Text(
              title,
              style: (textTheme.titleLarge ?? const TextStyle(fontSize: 18)).copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),

            // Supporting description
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 320),
              child: Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: (textTheme.bodyMedium ?? const TextStyle(fontSize: 13)).copyWith(
                  color: colorScheme.onSurfaceVariant,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),

            // Primary action button
            if (isFiltered)
              FilledButton(
                onPressed: onResetFilter,
                child: const Text('Show All Items'),
              )
            else
              FilledButton.icon(
                onPressed: () => ManualAddUrlDialog.show(context),
                icon: const Icon(Icons.add_link, size: 18),
                label: const Text('Add Your First Link'),
              ),
          ],
        ),
      ),
    );
  }
}
