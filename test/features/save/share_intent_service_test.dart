import 'package:flutter_test/flutter_test.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:recall/data/models/saved_item.dart';
import 'package:recall/features/save/share_intent_service.dart';
import '../../helpers/test_saved_item_repository.dart';

class FakeSavedItemRepository extends TestSavedItemRepository {
  final List<Map<String, String>> createdItems = [];

  @override
  Future<SavedItem> createInitialItem({
    required String url,
    required String platform,
  }) async {
    createdItems.add({'url': url, 'platform': platform});
    return SavedItem(
      id: 'test-id-${createdItems.length}',
      url: url,
      platform: platform,
      createdAt: DateTime.now(),
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ShareIntentService', () {
    late FakeSavedItemRepository fakeRepo;
    late List<SavedItem> notifiedItems;
    late ShareIntentService service;

    setUp(() {
      ReceiveSharingIntent.setMockValues(
        initialMedia: [],
        mediaStream: const Stream.empty(),
      );
      fakeRepo = FakeSavedItemRepository();
      notifiedItems = [];
      service = ShareIntentService(
        repository: fakeRepo,
        onSavedItemCreated: (item) => notifiedItems.add(item),
      );
    });

    tearDown(() {
      service.dispose();
    });

    test('handleSharedMedia processes valid URL and saves item', () async {
      final mediaFile = SharedMediaFile(
        path: 'Check out this video: https://youtu.be/test12345',
        type: SharedMediaType.text,
      );

      final result = await service.handleSharedMedia([mediaFile]);

      expect(result, isNotNull);
      expect(result?.url, 'https://youtu.be/test12345');
      expect(result?.platform, 'youtube');
      expect(fakeRepo.createdItems.length, 1);
      expect(fakeRepo.createdItems.first['url'], 'https://youtu.be/test12345');
      expect(fakeRepo.createdItems.first['platform'], 'youtube');
      expect(notifiedItems.length, 1);
    });

    test('handleSharedMedia ignores media without valid web URLs', () async {
      final mediaFile = SharedMediaFile(
        path: 'Just plain text with no link attached',
        type: SharedMediaType.text,
      );

      final result = await service.handleSharedMedia([mediaFile]);

      expect(result, isNull);
      expect(fakeRepo.createdItems, isEmpty);
      expect(notifiedItems, isEmpty);
    });
  });
}
