import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:recall/core/notifications/notification_service.dart';
import 'package:recall/core/utils/export_service.dart';
import 'package:recall/data/models/saved_item.dart';
import 'package:recall/data/repositories/saved_item_repository.dart';
import 'package:recall/features/home/home_providers.dart';
import 'package:recall/features/home/widgets/category_filter_row.dart';
import 'package:recall/features/home/widgets/feed_empty_state.dart';
import 'package:recall/features/home/widgets/feed_item_tile.dart';
import 'package:recall/features/save/share_intent_service.dart';
import 'package:recall/features/save/widgets/manual_add_url_dialog.dart';
import 'package:recall/features/save/widgets/save_confirmation_sheet.dart';

/// The primary Home library feed screen for Recall.
class HomeScreen extends ConsumerStatefulWidget {
  /// Creates the home screen.
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  late final M3ESearchController _searchController;
  bool _isSelectionMode = false;
  final Set<String> _selectedIds = {};

  @override
  void initState() {
    super.initState();
    _searchController = M3ESearchController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
        if (_selectedIds.isEmpty) {
          _isSelectionMode = false;
        }
      } else {
        _selectedIds.add(id);
      }
    });
  }

  void _selectAll(List<SavedItem> items) {
    setState(() {
      _selectedIds.addAll(items.map((e) => e.id));
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedIds.clear();
      _isSelectionMode = false;
    });
  }

  Future<void> _bulkArchive() async {
    final ids = _selectedIds.toList();
    await ref.read(savedItemRepositoryProvider).bulkToggleRead(
          ids: ids,
          isRead: true,
        );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Archived ${ids.length} items')),
      );
      _clearSelection();
    }
  }

  Future<void> _bulkFavorite() async {
    final ids = _selectedIds.toList();
    await ref.read(savedItemRepositoryProvider).bulkToggleFavorite(
          ids: ids,
          isFavorite: true,
        );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Added ${ids.length} items to favorites')),
      );
      _clearSelection();
    }
  }

  Future<void> _bulkDelete() async {
    final ids = _selectedIds.toList();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Selected Items'),
        content: Text(
          'Are you sure you want to delete ${ids.length} items? This action cannot be undone.',
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
      await ref.read(savedItemRepositoryProvider).bulkDelete(ids: ids);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Deleted ${ids.length} items')),
        );
        _clearSelection();
      }
    }
  }

  void _showExportSheet(BuildContext context, List<SavedItem> items) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        final scheme = theme.colorScheme;
        final textTheme = theme.textTheme;

        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerLow,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
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
                      Icons.ios_share_rounded,
                      color: scheme.onPrimaryContainer,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Export Library',
                    style: (textTheme.titleLarge ?? const TextStyle(fontSize: 18)).copyWith(
                      fontWeight: FontWeight.bold,
                      color: scheme.onSurface,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(Icons.close, color: scheme.onSurfaceVariant),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Export all ${items.length} saved bookmarks for Obsidian, Notion, or personal archives.',
                style: (textTheme.bodyMedium ?? const TextStyle(fontSize: 13)).copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.description_outlined,
                    color: scheme.onPrimaryContainer,
                    size: 20,
                  ),
                ),
                title: Text(
                  'Export as Markdown (.md)',
                  style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  'Formatted for Obsidian, Notion & Bear',
                  style: textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
                ),
                trailing: Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
                onTap: () async {
                  Navigator.of(ctx).pop();
                  final md = ExportService.toMarkdown(items);
                  await ExportService.shareText(md, subject: 'Recall Library Export');
                },
              ),
              Divider(color: scheme.outlineVariant, height: 1),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: scheme.secondaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.code_rounded,
                    color: scheme.onSecondaryContainer,
                    size: 20,
                  ),
                ),
                title: Text(
                  'Export as JSON (.json)',
                  style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  'Raw structured data with all metadata',
                  style: textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
                ),
                trailing: Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
                onTap: () async {
                  Navigator.of(ctx).pop();
                  final jsonStr = ExportService.toJson(items);
                  await ExportService.shareText(jsonStr, subject: 'Recall JSON Export');
                },
              ),
              Divider(color: scheme.outlineVariant, height: 1),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: scheme.tertiaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.copy_rounded,
                    color: scheme.onTertiaryContainer,
                    size: 20,
                  ),
                ),
                title: Text(
                  'Copy Markdown to Clipboard',
                  style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  'Paste directly into notes or editors',
                  style: textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
                ),
                trailing: Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
                onTap: () async {
                  Navigator.of(ctx).pop();
                  final md = ExportService.toMarkdown(items);
                  await ExportService.copyToClipboard(context, md);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Ensure share intent & notification services are initialized
    ref.watch(shareIntentServiceProvider);
    ref.watch(notificationServiceProvider);

    // Listen for new shared items to show the bottom sheet confirmation
    ref.listen(latestSharedItemProvider, (previous, next) {
      if (next != null) {
        SaveConfirmationSheet.show(context, itemId: next.id);
        ref.read(latestSharedItemProvider.notifier).clear();
      }
    });

    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final feedAsync = ref.watch(savedItemsFeedProvider);
    final selectedCategory = ref.watch(selectedCategoryProvider);
    final currentItems = feedAsync.value ?? [];

    PreferredSizeWidget buildAppBar() {
      if (_isSelectionMode) {
        return AppBar(
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: _clearSelection,
          ),
          title: Text(
            '${_selectedIds.length} Selected',
            style: textTheme.titleLarge,
          ),
          actions: [
            TextButton(
              onPressed: () => _selectAll(currentItems),
              child: const Text('Select All'),
            ),
          ],
        );
      }

      return M3EAppBar.search(
        searchController: _searchController,
        barHintText: 'Search saved links, summaries, tags…',
        barLeading: Icon(Icons.search, color: scheme.onSurfaceVariant),
        barTrailing: [
          IconButton(
            icon: Icon(Icons.ios_share_outlined, color: scheme.onSurfaceVariant),
            tooltip: 'Export Library',
            onPressed: () => _showExportSheet(context, currentItems),
          ),
          IconButton(
            icon: Icon(Icons.settings_outlined, color: scheme.onSurfaceVariant),
            tooltip: 'Settings',
            onPressed: () => context.push('/settings'),
          ),
        ],
        suggestionsBuilder: (context, controller) {
          final query = controller.text.toLowerCase();
          final items = feedAsync.value ?? [];
          final filtered = items.where((item) {
            final titleMatch =
                item.title?.toLowerCase().contains(query) ?? false;
            final summaryMatch =
                item.summary?.toLowerCase().contains(query) ?? false;
            final tagMatch =
                item.tags?.any((t) => t.toLowerCase().contains(query)) ?? false;
            return titleMatch || summaryMatch || tagMatch;
          }).toList();

          if (filtered.isEmpty) {
            return [
              Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  query.isEmpty
                      ? 'Type to search across all your saved bookmarks'
                      : 'No items matching "$query"',
                  style: (textTheme.bodyMedium ?? const TextStyle(fontSize: 13)).copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ];
          }

          return filtered.map((item) {
            return FeedItemTile(
              item: item,
              onTap: () {
                controller.closeView(item.title ?? item.url);
                context.push('/detail/${item.id}');
              },
            );
          }).toList();
        },
      );
    }

    return Scaffold(
      appBar: buildAppBar(),
      bottomNavigationBar: _isSelectionMode
          ? SafeArea(
              child: Container(
                height: 64,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHigh,
                  border: Border(top: BorderSide(color: scheme.outlineVariant)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    IconButton(
                      icon: Icon(Icons.archive_outlined, color: scheme.onSurfaceVariant),
                      tooltip: 'Archive Selected',
                      onPressed: _selectedIds.isEmpty ? null : _bulkArchive,
                    ),
                    IconButton(
                      icon: Icon(Icons.star_rounded, color: scheme.primary),
                      tooltip: 'Favorite Selected',
                      onPressed: _selectedIds.isEmpty ? null : _bulkFavorite,
                    ),
                    IconButton(
                      icon: Icon(Icons.delete_outline, color: scheme.error),
                      tooltip: 'Delete Selected',
                      onPressed: _selectedIds.isEmpty ? null : _bulkDelete,
                    ),
                  ],
                ),
              ),
            )
          : null,
      body: Column(
        children: [
          const SizedBox(height: 8),
          const CategoryFilterRow(),
          const SizedBox(height: 8),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              child: feedAsync.when(
                data: (items) {
                  if (items.isEmpty) {
                    return FeedEmptyState(
                      key: ValueKey('empty_${selectedCategory}'),
                      selectedCategory: selectedCategory,
                      onResetFilter: selectedCategory != 'All'
                          ? () {
                              ref
                                  .read(selectedCategoryProvider.notifier)
                                  .selectCategory('All');
                              ref
                                  .read(unreadOnlyFilterProvider.notifier)
                                  .setUnreadOnly(false);
                            }
                          : null,
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () async {
                      ref.invalidate(savedItemsFeedProvider);
                    },
                    child: ListView.separated(
                      key: ValueKey('feed_${selectedCategory}_${items.length}'),
                      padding: const EdgeInsets.only(
                        left: 16,
                        right: 16,
                        top: 8,
                        bottom: 88, // 88px bottom padding to prevent FAB overlap
                      ),
                      itemCount: items.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final item = items[index];
                        final isSelected = _selectedIds.contains(item.id);

                        return FeedItemTile(
                          item: item,
                          selected: isSelected,
                          selectionMode: _isSelectionMode,
                          onTap: () {
                            if (_isSelectionMode) {
                              _toggleSelection(item.id);
                            } else {
                              context.push('/detail/${item.id}');
                            }
                          },
                          onLongPress: () {
                            if (!_isSelectionMode) {
                              setState(() {
                                _isSelectionMode = true;
                                _selectedIds.add(item.id);
                              });
                            }
                          },
                        );
                      },
                    ),
                  );
                },
                loading: () => Center(
                  child: CircularProgressIndicator(color: scheme.primary),
                ),
                error: (error, stack) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 48, color: scheme.error),
                        const SizedBox(height: 16),
                        Text(
                          'Failed to load saved items',
                          style: (textTheme.titleMedium ?? const TextStyle(fontSize: 15)).copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          error.toString(),
                          style: (textTheme.bodySmall ?? const TextStyle(fontSize: 12)).copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: () => ref.invalidate(savedItemsFeedProvider),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: _isSelectionMode
          ? null
          : FloatingActionButton.extended(
              onPressed: () => ManualAddUrlDialog.show(context),
              icon: const Icon(Icons.add_link),
              label: const Text('Add Link'),
            ),
    );
  }
}
