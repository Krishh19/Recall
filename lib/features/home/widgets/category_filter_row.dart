import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:recall/features/home/home_providers.dart';

/// A horizontally scrollable row of [M3EChip]s for category and filter selection.
class CategoryFilterRow extends ConsumerWidget {
  /// Creates the category filter row.
  const CategoryFilterRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedCategory = ref.watch(selectedCategoryProvider);

    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        itemCount: recallCategories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final category = recallCategories[index];
          final isSelected = category == selectedCategory;

          IconData? icon;
          if (category == 'Unread') {
            icon = Icons.mark_email_unread_outlined;
          } else if (category == 'Favorites') {
            icon = Icons.star_outline_rounded;
          } else if (category == 'Blocked') {
            icon = Icons.lock_outline_rounded;
          }

          return M3EChip(
            label: category,
            leading: icon != null ? Icon(icon, size: 16) : null,
            type: M3EChipType.filter,
            selected: isSelected,
            onPressed: () {
              ref
                  .read(selectedCategoryProvider.notifier)
                  .selectCategory(category);
              if (category == 'Unread') {
                ref.read(unreadOnlyFilterProvider.notifier).setUnreadOnly(true);
              } else {
                ref.read(unreadOnlyFilterProvider.notifier).setUnreadOnly(false);
              }
            },
          );
        },
      ),
    );
  }
}
