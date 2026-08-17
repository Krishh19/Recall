import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:recall/data/models/saved_item.dart';
import 'package:recall/data/repositories/saved_item_repository.dart';

part 'detail_providers.g.dart';

/// Streams the real-time state of a specific [SavedItem] by its [id].
@riverpod
Stream<SavedItem?> itemDetail(Ref ref, String id) {
  final repository = ref.watch(savedItemRepositoryProvider);
  return repository.watchItem(id);
}

