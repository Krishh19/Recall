import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:recall/features/home/widgets/feed_item_tile.dart';
import 'package:recall/features/search/search_providers.dart';

/// Full dedicated search screen utilizing [M3ESearchAnchor.bar].
class SearchScreen extends ConsumerStatefulWidget {
  /// Creates the search screen.
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  late final M3ESearchController _searchController;

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

  @override
  Widget build(BuildContext context) {
    final theme = M3ETheme.of(context);
    final scheme = theme.colorScheme;
    final searchResultsAsync = ref.watch(searchResultsProvider);
    final currentQuery = ref.watch(searchQueryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Recall'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: M3ESearchAnchor.bar(
              searchController: _searchController,
              barHintText: 'Search by title, summary, or #tag…',
              barLeading: const Icon(Icons.search),
              onChanged: (query) {
                ref.read(searchQueryProvider.notifier).setQuery(query);
              },
              suggestionsBuilder: (context, controller) {
                final query = controller.text.trim().toLowerCase();
                final items = searchResultsAsync.value ?? [];
                final matching = items.where((item) {
                  final titleMatch =
                      item.title?.toLowerCase().contains(query) ?? false;
                  final summaryMatch =
                      item.summary?.toLowerCase().contains(query) ?? false;
                  final tagMatch =
                      item.tags?.any(
                        (tag) => tag.toLowerCase().contains(query),
                      ) ??
                      false;
                  return titleMatch || summaryMatch || tagMatch;
                }).toList();

                if (matching.isEmpty) {
                  return [
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        query.isEmpty
                            ? 'Start typing to search your library'
                            : 'No results found for "$query"',
                        style: theme.typeScale.bodyMedium.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ];
                }

                return matching.map((item) {
                  return FeedItemTile(
                    item: item,
                    onTap: () {
                      controller.closeView(item.title ?? item.url);
                      context.push('/detail/${item.id}');
                    },
                  );
                }).toList();
              },
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: searchResultsAsync.when(
              data: (items) {
                if (currentQuery.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search,
                          size: 48,
                          color: scheme.primary.withAlpha(120),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Search your saved links',
                          style: theme.typeScale.titleMedium.copyWith(
                            color: scheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Search through AI summaries, titles, and topics',
                          style: theme.typeScale.bodySmall.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                if (items.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 48,
                          color: scheme.onSurfaceVariant,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No results found',
                          style: theme.typeScale.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Try searching for a different keyword or tag',
                          style: theme.typeScale.bodySmall.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return FeedItemTile(
                      item: item,
                      onTap: () => context.push('/detail/${item.id}'),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) =>
                  Center(child: Text('Search error: $error')),
            ),
          ),
        ],
      ),
    );
  }
}
