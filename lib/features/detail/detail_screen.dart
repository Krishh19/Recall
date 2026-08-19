import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:recall/core/ai/gemini_service.dart';
import 'package:recall/data/models/saved_item.dart';
import 'package:recall/data/repositories/saved_item_repository.dart';
import 'package:recall/features/detail/detail_providers.dart';
import 'package:recall/features/onboarding/widgets/ai_gate_prompt.dart';
import 'package:recall/features/save/retry_tracker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// Screen displaying the summarized and extracted details of a [SavedItem].
class DetailScreen extends ConsumerWidget {
  /// Creates the item detail screen.
  const DetailScreen({required this.id, super.key});

  /// The ID of the item to display.
  final String id;

  Future<void> _launchOriginalUrl(BuildContext context, String url) async {
    try {
      final uri = Uri.parse(url.trim());
      bool launched = false;
      try {
        launched = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
      } catch (_) {}

      if (!launched) {
        try {
          launched = await launchUrl(
            uri,
            mode: LaunchMode.platformDefault,
          );
        } catch (_) {}
      }

      if (!launched && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open link in browser.')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to open link: $e')),
        );
      }
    }
  }

  void _shareItem(SavedItem item) {
    final text = item.title != null && item.title!.isNotEmpty
        ? '${item.title}\n${item.url}'
        : item.url;
    // ignore: deprecated_member_use
    Share.share(text, subject: item.title);
  }

  Future<void> _deleteItem(
    BuildContext context,
    WidgetRef ref,
    SavedItem item,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Item'),
        content: const Text(
          'Are you sure you want to delete this item? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(savedItemRepositoryProvider).deleteItem(item.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Item deleted.')),
        );
        context.pop();
      }
    }
  }

  Future<void> _toggleFavorite(
    BuildContext context,
    WidgetRef ref,
    SavedItem item,
  ) async {
    final nextState = !item.isFavorite;
    await ref
        .read(savedItemRepositoryProvider)
        .toggleFavorite(id: item.id, isFavorite: nextState);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 2),
          content: Text(
            nextState ? 'Added to favorites' : 'Removed from favorites',
          ),
        ),
      );
    }
  }

  Future<void> _toggleArchive(
    BuildContext context,
    WidgetRef ref,
    SavedItem item,
  ) async {
    final nextState = !item.isRead;
    await ref
        .read(savedItemRepositoryProvider)
        .toggleRead(id: item.id, isRead: nextState);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 3),
          content: Text(
            nextState ? 'Moved to archive' : 'Restored from archive',
          ),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () {
              ref
                  .read(savedItemRepositoryProvider)
                  .toggleRead(id: item.id, isRead: !nextState);
            },
          ),
        ),
      );
    }
  }

  Future<void> _showManualCaptionDialog(
    BuildContext context,
    WidgetRef ref,
    SavedItem item,
  ) async {
    final titleController = TextEditingController(text: item.title ?? '');
    final contentController = TextEditingController(
      text: (item.rawContent != null && item.rawContent != item.url)
          ? item.rawContent!
          : '',
    );

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        final scheme = theme.colorScheme;
        final textTheme = theme.textTheme;
        final bottomInset = MediaQuery.of(ctx).viewInsets.bottom;

        return Padding(
          padding: EdgeInsets.only(bottom: bottomInset),
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(ctx).size.height * 0.85,
            ),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHigh,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: scheme.primaryContainer,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.edit_note_rounded,
                          color: scheme.onPrimaryContainer,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Add / Edit Content',
                          style: (textTheme.titleLarge ?? const TextStyle(fontSize: 18)).copyWith(
                            fontWeight: FontWeight.bold,
                            color: scheme.onSurface,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: scheme.onSurfaceVariant),
                        onPressed: () => Navigator.of(ctx).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Paste post text, caption, or article excerpts to generate an accurate AI summary.',
                    style: (textTheme.bodyMedium ?? const TextStyle(fontSize: 13)).copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(
                      labelText: 'Title (optional)',
                      filled: true,
                      fillColor: scheme.surfaceContainerLowest,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: contentController,
                    minLines: 3,
                    maxLines: 5,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: 'Paste post caption or article text here...',
                      filled: true,
                      fillColor: scheme.surfaceContainerLowest,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.paste_rounded),
                        tooltip: 'Paste from clipboard',
                        onPressed: () async {
                          final data = await Clipboard.getData('text/plain');
                          if (data?.text != null) {
                            contentController.text = data!.text!.trim();
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton(
                      onPressed: () {
                        final text = contentController.text.trim();
                        if (text.isEmpty) return;
                        Navigator.of(ctx).pop();
                        ref.read(savedItemRepositoryProvider).updateAndResummarize(
                              id: item.id,
                              title: titleController.text.trim().isNotEmpty
                                  ? titleController.text.trim()
                                  : item.title,
                              textContent: text,
                            );
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Generating new AI summary…')),
                        );
                      },
                      child: const Text('Summarize Content'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _formatPlatform(String platform) {
    switch (platform.toLowerCase()) {
      case 'twitter':
      case 'x':
        return 'X / TWITTER';
      case 'youtube':
        return 'YOUTUBE';
      case 'instagram':
        return 'INSTAGRAM';
      case 'tiktok':
        return 'TIKTOK';
      case 'reddit':
        return 'REDDIT';
      case 'article':
        return 'ARTICLE';
      default:
        return platform.toUpperCase();
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
        return (bg: scheme.tertiaryContainer, fg: scheme.onTertiaryContainer);
    }
  }

  String _formatReadingTime(SavedItem item) {
    final fullText = '${item.title ?? ''} ${item.summary ?? ''} ${item.rawContent ?? ''}';
    final words = fullText.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
    final mins = (words / 200).ceil().clamp(1, 60);
    return '$mins min read';
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final itemAsync = ref.watch(itemDetailProvider(id));
    final isGeminiConfigured =
        ref.watch(isGeminiConfiguredProvider).value ?? false;

    return itemAsync.when(
      data: (item) {
        if (item == null) {
          return Scaffold(
            appBar: M3EAppBar.top(
              titleText: 'Item Not Found',
              automaticallyImplyLeading: true,
            ),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.link_off, size: 48, color: scheme.error),
                  const SizedBox(height: 16),
                  Text(
                    'Item no longer exists.',
                    style: textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => context.pop(),
                    child: const Text('Go Back'),
                  ),
                ],
              ),
            ),
          );
        }

        // Automatically mark unread items as read when viewed in detail screen
        if (!item.isRead) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ref
                .read(savedItemRepositoryProvider)
                .toggleRead(id: item.id, isRead: true);
          });
        }

        final platformLabel = _formatPlatform(item.platform);
        final readingTime = _formatReadingTime(item);
        final dateStr = _formatDate(item.createdAt);

        return Scaffold(
          appBar: M3EAppBar.top(
            titleText: platformLabel,
            automaticallyImplyLeading: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_note_rounded),
                tooltip: 'Add / Edit Caption',
                onPressed: () => _showManualCaptionDialog(context, ref, item),
              ),
              IconButton(
                icon: const Icon(Icons.share_outlined),
                tooltip: 'Share',
                onPressed: () => _shareItem(item),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                tooltip: 'Delete',
                onPressed: () => _deleteItem(context, ref, item),
              ),
            ],
          ),
          bottomNavigationBar: SafeArea(
            child: Container(
              height: 68,
              padding: const EdgeInsets.only(bottom: 8, left: 16, right: 16),
              alignment: Alignment.center,
              child: M3EToolbar.floating(
                alignment: Alignment.center,
                actions: [
                  M3EToolbarAction(
                    icon: Icons.open_in_new_rounded,
                    label: 'Open',
                    tooltip: 'Open in browser',
                    onPressed: () => _launchOriginalUrl(context, item.url),
                  ),
                  M3EToolbarAction(
                    icon: item.isFavorite ? Icons.star : Icons.star_border,
                    label: 'Favorite',
                    active: item.isFavorite,
                    tooltip: item.isFavorite ? 'Remove favorite' : 'Add favorite',
                    onPressed: () => _toggleFavorite(context, ref, item),
                  ),
                  M3EToolbarAction(
                    icon: item.isRead
                        ? Icons.mark_email_unread_outlined
                        : Icons.archive_outlined,
                    label: item.isRead ? 'Unread' : 'Archive',
                    active: item.isRead,
                    tooltip: item.isRead ? 'Mark as unread' : 'Archive',
                    onPressed: () => _toggleArchive(context, ref, item),
                  ),
                ],
              ),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Thumbnail Banner
                if (item.thumbnailUrl != null &&
                    item.thumbnailUrl!.isNotEmpty) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: CachedNetworkImage(
                      imageUrl: item.thumbnailUrl!,
                      height: 210,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      placeholder: (ctx, url) => Container(
                        height: 210,
                        color: scheme.surfaceContainerHighest,
                        child: Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: scheme.primary,
                          ),
                        ),
                      ),
                      errorWidget: (ctx, url, error) => const SizedBox.shrink(),
                    ),
                  ),
                  const SizedBox(height: 18),
                ],

                // Title
                Text(
                  item.title?.isNotEmpty == true ? item.title! : item.url,
                  style: (textTheme.headlineSmall ?? const TextStyle(fontSize: 24)).copyWith(
                    fontWeight: FontWeight.bold,
                    color: scheme.onSurface,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 8),

                // Source URL Subtitle
                InkWell(
                  onTap: () => _launchOriginalUrl(context, item.url),
                  borderRadius: BorderRadius.circular(6),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.link_rounded,
                          size: 16,
                          color: scheme.primary,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            Uri.tryParse(item.url)?.host ?? item.url,
                            style: (textTheme.bodySmall ?? const TextStyle(fontSize: 12)).copyWith(
                              color: scheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Metadata Row: Category & Reading Time & Date
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (item.category != null && item.category!.isNotEmpty)
                      Builder(
                        builder: (context) {
                          final colors = _categoryColors(scheme, item.category);
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: colors.bg,
                              borderRadius: BorderRadius.circular(100),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.category_outlined,
                                  size: 15,
                                  color: colors.fg,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  item.category!,
                                  style: (textTheme.labelMedium ??
                                          const TextStyle(fontSize: 12))
                                      .copyWith(
                                    color: colors.fg,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: scheme.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.schedule_rounded,
                            size: 14,
                            color: scheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            readingTime,
                            style: (textTheme.labelMedium ??
                                    const TextStyle(fontSize: 12))
                                .copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: scheme.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.calendar_today_outlined,
                            size: 13,
                            color: scheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            dateStr,
                            style: (textTheme.labelMedium ??
                                    const TextStyle(fontSize: 12))
                                .copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (item.tags != null && item.tags!.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (final tag in item.tags!) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: scheme.surfaceContainerLow,
                              borderRadius: BorderRadius.circular(100),
                              border: Border.all(color: scheme.outlineVariant),
                            ),
                            child: Text(
                              '#$tag',
                              style: (textTheme.labelMedium ??
                                      const TextStyle(fontSize: 12))
                                  .copyWith(
                                color: scheme.onSurface,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 24),

                // Unconfigured Gemini Inline Prompt
                if (!isGeminiConfigured &&
                    (item.summary == null ||
                        item.summary!.isEmpty ||
                        item.isFailed)) ...[
                  AIGatePrompt(
                    onConfigured: () {
                      ref.invalidate(isGeminiConfiguredProvider);
                      ref
                          .read(savedItemRepositoryProvider)
                          .retryItem(item);
                    },
                  ),
                  const SizedBox(height: 20),
                ],

                // Processing Status Banner
                if (item.isProcessing) ...[
                  Card(
                    color: scheme.surfaceContainer,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Row(
                        children: [
                          const M3EProgressIndicator.circularWavy(size: 28),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Summarizing content…',
                                  style: (textTheme.titleMedium ?? const TextStyle(fontSize: 15)).copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: scheme.primary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Our AI is extracting key takeaways.',
                                  style: (textTheme.bodySmall ?? const TextStyle(fontSize: 12)).copyWith(
                                    color: scheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // Failed / Blocked Status Banner
                if (item.isFailed) ...[
                  Card(
                    color: scheme.errorContainer,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.lock_outline_rounded,
                                color: scheme.onErrorContainer,
                                size: 22,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  "Couldn't Read Post Automatically",
                                  style: (textTheme.titleMedium ?? const TextStyle(fontSize: 15)).copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: scheme.onErrorContainer,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            item.summary ??
                                'This platform requires authentication or blocked automated reading.',
                            style: (textTheme.bodyMedium ?? const TextStyle(fontSize: 13)).copyWith(
                              color: scheme.onErrorContainer,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: [
                              FilledButton.icon(
                                onPressed: () =>
                                    _showManualCaptionDialog(context, ref, item),
                                icon: const Icon(Icons.edit_note_rounded, size: 18),
                                label: const Text('Paste Caption Manually'),
                              ),
                              OutlinedButton.icon(
                                onPressed: () {
                                  ref
                                      .read(retryTrackerProvider.notifier)
                                      .retryItem(context, item);
                                },
                                icon: const Icon(Icons.refresh_rounded, size: 18),
                                label: const Text('Retry Auto-Fetch'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: scheme.onErrorContainer,
                                  side: BorderSide(
                                    color: scheme.onErrorContainer.withAlpha(120),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // AI Summary Section
                if (item.summary != null &&
                    item.summary!.isNotEmpty &&
                    !item.isFailed) ...[
                  Row(
                    children: [
                      Icon(Icons.auto_awesome, size: 20, color: scheme.primary),
                      const SizedBox(width: 8),
                      Text(
                        'AI Summary',
                        style: (textTheme.titleMedium ?? const TextStyle(fontSize: 15)).copyWith(
                          fontWeight: FontWeight.bold,
                          color: scheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Card(
                    color: scheme.surfaceContainer,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    elevation: 0,
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Text(
                        item.summary!,
                        style: (textTheme.bodyLarge ?? const TextStyle(fontSize: 15)).copyWith(
                          height: 1.5,
                          color: scheme.onSurface,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Key Points Section
                if (item.keyPoints != null &&
                    item.keyPoints!.isNotEmpty &&
                    !item.isFailed) ...[
                  Row(
                    children: [
                      Icon(Icons.checklist_rounded, size: 20, color: scheme.primary),
                      const SizedBox(width: 8),
                      Text(
                        'Key Takeaways',
                        style: (textTheme.titleMedium ?? const TextStyle(fontSize: 15)).copyWith(
                          fontWeight: FontWeight.bold,
                          color: scheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  for (final point in item.keyPoints!) ...[
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            margin: const EdgeInsets.only(top: 6),
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              color: scheme.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              point,
                              style: (textTheme.bodyMedium ?? const TextStyle(fontSize: 13)).copyWith(
                                height: 1.5,
                                color: scheme.onSurface,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                ],

                // Raw Content / Extracted Text Collapsible Section
                if (item.rawContent != null &&
                    item.rawContent!.isNotEmpty &&
                    item.rawContent != item.summary) ...[
                  Theme(
                    data: Theme.of(context).copyWith(
                      dividerColor: Colors.transparent,
                    ),
                    child: ExpansionTile(
                      tilePadding: EdgeInsets.zero,
                      childrenPadding: EdgeInsets.zero,
                      title: Text(
                        'Extracted Content',
                        style: (textTheme.titleSmall ?? const TextStyle(fontSize: 14)).copyWith(
                          fontWeight: FontWeight.bold,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      leading: Icon(
                        Icons.notes_rounded,
                        color: scheme.onSurfaceVariant,
                        size: 20,
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        tooltip: 'Edit Content',
                        onPressed: () =>
                            _showManualCaptionDialog(context, ref, item),
                      ),
                      children: [
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(top: 8),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: scheme.surfaceContainerHighest.withAlpha(80),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: scheme.outlineVariant.withAlpha(100),
                            ),
                          ),
                          child: SelectableText(
                            item.rawContent!,
                            style: (textTheme.bodySmall ?? const TextStyle(fontSize: 12)).copyWith(
                              color: scheme.onSurfaceVariant,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, stack) => Scaffold(
        appBar: M3EAppBar.top(automaticallyImplyLeading: true),
        body: Center(child: Text('Error loading item: $error')),
      ),
    );
  }
}
