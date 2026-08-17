import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:recall/features/detail/detail_providers.dart';
import 'package:recall/features/save/retry_tracker.dart';

/// Modal bottom sheet shown immediately after a URL is saved into Recall.
class SaveConfirmationSheet extends ConsumerWidget {
  /// Creates the save confirmation sheet.
  const SaveConfirmationSheet({required this.itemId, super.key});

  /// The ID of the item just saved.
  final String itemId;

  /// Convenience method to show the save confirmation sheet modal.
  static Future<void> show(BuildContext context, {required String itemId}) {
    return M3EBottomSheet.show<void>(
      context,
      showDragHandle: true,
      builder: (context) => SaveConfirmationSheet(itemId: itemId),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = M3ETheme.of(context);
    final scheme = theme.colorScheme;
    final itemAsync = ref.watch(itemDetailProvider(itemId));

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: Checkmark + "Saved to Recall"
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_rounded,
                  color: scheme.onPrimaryContainer,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  'Saved to Recall',
                  style: theme.typeScale.titleLarge.copyWith(
                    fontWeight: FontWeight.bold,
                    color: scheme.onSurface,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                tooltip: 'Dismiss',
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Reactive Status Area
          itemAsync.when(
            data: (item) {
              if (item == null) {
                return Text(
                  'Link saved successfully.',
                  style: theme.typeScale.bodyMedium.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title / URL preview
                  if (item.title != null && item.title!.isNotEmpty)
                    Text(
                      item.title!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.typeScale.bodyLarge.copyWith(
                        fontWeight: FontWeight.w600,
                        color: scheme.onSurface,
                      ),
                    )
                  else
                    Text(
                      item.url,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.typeScale.bodyMedium.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  const SizedBox(height: 16),

                  // State: Processing
                  if (item.isProcessing) ...[
                    Row(
                      children: [
                        const M3EProgressIndicator.circularWavy(size: 28),
                        const SizedBox(width: 14),
                        Text(
                          'Summarizing…',
                          style: theme.typeScale.bodyMedium.copyWith(
                            fontWeight: FontWeight.w500,
                            color: scheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ],

                  // State: Done
                  if (item.isDone) ...[
                    Row(
                      children: [
                        if (item.category != null &&
                            item.category!.isNotEmpty) ...[
                          M3EChip(
                            label: item.category!,
                            type: M3EChipType.assist,
                            leading: const Icon(Icons.category_outlined),
                          ),
                          const SizedBox(width: 12),
                        ],
                        const Spacer(),
                        M3EButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            context.push('/detail/${item.id}');
                          },
                          child: const Text('View Details'),
                        ),
                      ],
                    ),
                  ],

                  // State: Failed
                  if (item.isFailed) ...[
                    Row(
                      children: [
                        Icon(
                          Icons.lock_outline_rounded,
                          size: 20,
                          color: scheme.error,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "Couldn't process — tap to retry",
                            style: theme.typeScale.bodySmall.copyWith(
                              color: scheme.error,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () {
                            ref
                                .read(retryTrackerProvider.notifier)
                                .retryItem(context, item);
                          },
                          child: const Text('Retry'),
                        ),
                        const SizedBox(width: 8),
                        M3EButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            context.push('/detail/${item.id}');
                          },
                          child: const Text('View Details'),
                        ),
                      ],
                    ),
                  ],
                ],
              );
            },
            loading: () => Row(
              children: [
                const M3EProgressIndicator.circularWavy(size: 28),
                const SizedBox(width: 14),
                Text(
                  'Summarizing…',
                  style: theme.typeScale.bodyMedium.copyWith(
                    fontWeight: FontWeight.w500,
                    color: scheme.primary,
                  ),
                ),
              ],
            ),
            error: (error, stack) => Text(
              'Link saved to your library.',
              style: theme.typeScale.bodyMedium.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
