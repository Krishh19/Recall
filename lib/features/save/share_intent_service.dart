import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:recall/core/utils/url_extractor.dart';
import 'package:recall/data/models/saved_item.dart';
import 'package:recall/data/repositories/saved_item_repository.dart';

part 'share_intent_service.g.dart';

/// Holds the most recently shared and persisted [SavedItem], if any.
@riverpod
class LatestSharedItem extends _$LatestSharedItem {
  @override
  SavedItem? build() => null;

  /// Updates the latest shared item state.
  void setItem(SavedItem item) {
    state = item;
  }

  /// Clears the latest shared item state once acknowledged.
  void clear() {
    state = null;
  }
}

/// Service that listens to Android share intents (both cold start and foreground)
/// and saves shared links into the database.
class ShareIntentService {
  /// Creates a [ShareIntentService] with injected dependencies.
  ShareIntentService({
    required this.repository,
    required this.onSavedItemCreated,
  });

  /// The repository used for persisting saved items.
  final SavedItemRepository repository;

  /// Callback triggered when a new saved item is created.
  final void Function(SavedItem) onSavedItemCreated;

  StreamSubscription<List<SharedMediaFile>>? _intentSubscription;

  /// Initializes listening to incoming share intents.
  void init() {
    // Listen to media sharing while the app is already open / running
    _intentSubscription = ReceiveSharingIntent.instance.getMediaStream().listen(
      handleSharedMedia,
      onError: (err) {
        debugPrint('Error listening to media stream: $err');
      },
    );

    // Get the initial media if app was started by a share intent (cold start)
    ReceiveSharingIntent.instance
        .getInitialMedia()
        .then((mediaList) {
          if (mediaList.isNotEmpty) {
            handleSharedMedia(mediaList);
          }
        })
        .catchError((err) {
          debugPrint('Error getting initial media: $err');
        });
  }

  /// Processes a list of incoming [SharedMediaFile]s, extracts the web link,
  /// and saves it asynchronously to Supabase.
  Future<SavedItem?> handleSharedMedia(List<SharedMediaFile> mediaFiles) async {
    if (mediaFiles.isEmpty) return null;

    for (final file in mediaFiles) {
      final text = file.path;
      final url = UrlExtractor.extractUrl(text);

      if (url != null) {
        final platform = UrlExtractor.detectPlatform(url);
        try {
          final savedItem = await repository.createInitialItem(
            url: url,
            platform: platform,
          );
          onSavedItemCreated(savedItem);
          await ReceiveSharingIntent.instance.reset();
          return savedItem;
        } catch (e) {
          debugPrint('Failed to save shared item: $e');
        }
      }
    }

    await ReceiveSharingIntent.instance.reset();
    return null;
  }

  /// Cancels intent stream subscriptions and cleans up resources.
  void dispose() {
    _intentSubscription?.cancel();
    _intentSubscription = null;
  }
}

/// Provides the active [ShareIntentService] instance.
@riverpod
ShareIntentService shareIntentService(Ref ref) {
  final repository = ref.watch(savedItemRepositoryProvider);
  final service = ShareIntentService(
    repository: repository,
    onSavedItemCreated: (item) {
      ref.read(latestSharedItemProvider.notifier).setItem(item);
    },
  );

  service.init();
  ref.onDispose(service.dispose);
  return service;
}
