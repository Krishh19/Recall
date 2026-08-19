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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final selectedCategory = ref.watch(selectedCategoryProvider);

    return SizedBox(
      height: 48,
      child: ShaderMask(
        shaderCallback: (Rect bounds) {
          return const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            stops: [0.0, 0.90, 1.0],
            colors: [
              Colors.black,
              Colors.black,
              Colors.transparent,
            ],
          ).createShader(bounds);
        },
        blendMode: BlendMode.dstIn,
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

          return FilterChip(
            label: Text(category),
            avatar: icon != null
                ? Icon(
                    icon,
                    size: 16,
                    color: isSelected
                        ? colorScheme.onSecondaryContainer
                        : colorScheme.onSurfaceVariant,
                  )
                : null,
            selected: isSelected,
            showCheckmark: false,
            selectedColor: colorScheme.secondaryContainer,
            backgroundColor: colorScheme.surface,
            side: BorderSide(
              color: isSelected ? Colors.transparent : colorScheme.outlineVariant,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(100),
            ),
            labelStyle: (textTheme.labelLarge ?? const TextStyle(fontSize: 13)).copyWith(
              color: isSelected
                  ? colorScheme.onSecondaryContainer
                  : colorScheme.onSurfaceVariant,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            ),
            onSelected: (_) {
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
      ),
    );
  }
}
