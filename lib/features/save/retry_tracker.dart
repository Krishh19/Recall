import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:recall/data/models/saved_item.dart';
import 'package:recall/data/repositories/saved_item_repository.dart';
import 'package:url_launcher/url_launcher.dart';

part 'retry_tracker.g.dart';

/// Tracks consecutive failure retries per item ID.
@Riverpod(keepAlive: true)
class RetryTracker extends _$RetryTracker {
  @override
  Map<String, int> build() => const <String, int>{};

  /// Increments the retry count for [itemId].
  int increment(String itemId) {
    final current = state[itemId] ?? 0;
    final updated = current + 1;
    state = {...state, itemId: updated};
    return updated;
  }

  /// Resets the retry count for [itemId].
  void reset(String itemId) {
    if (state.containsKey(itemId)) {
      final updated = Map<String, int>.from(state)..remove(itemId);
      state = updated;
    }
  }

  /// Executes a retry on [item], showing a helpful guidance SnackBar if it has
  /// failed twice or more in a row.
  Future<void> retryItem(BuildContext context, SavedItem item) async {
    final attempts = increment(item.id);

    if (attempts >= 2) {
      final messenger = ScaffoldMessenger.maybeOf(context);
      messenger?.showSnackBar(
        SnackBar(
          content: const Text(
            'Processing failed multiple times. Please check if the original link is accessible.',
          ),
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'Open Link',
            onPressed: () async {
              try {
                final uri = Uri.parse(item.url.trim());
                final ok = await launchUrl(
                  uri,
                  mode: LaunchMode.externalApplication,
                );
                if (!ok) {
                  await launchUrl(uri, mode: LaunchMode.platformDefault);
                }
              } catch (_) {}
            },
          ),
        ),
      );
    }

    await ref.read(savedItemRepositoryProvider).retryItem(item);
  }
}
