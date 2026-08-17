// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'detail_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Streams the real-time state of a specific [SavedItem] by its [id].

@ProviderFor(itemDetail)
final itemDetailProvider = ItemDetailFamily._();

/// Streams the real-time state of a specific [SavedItem] by its [id].

final class ItemDetailProvider
    extends
        $FunctionalProvider<
          AsyncValue<SavedItem?>,
          SavedItem?,
          Stream<SavedItem?>
        >
    with $FutureModifier<SavedItem?>, $StreamProvider<SavedItem?> {
  /// Streams the real-time state of a specific [SavedItem] by its [id].
  ItemDetailProvider._({
    required ItemDetailFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'itemDetailProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$itemDetailHash();

  @override
  String toString() {
    return r'itemDetailProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<SavedItem?> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<SavedItem?> create(Ref ref) {
    final argument = this.argument as String;
    return itemDetail(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ItemDetailProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$itemDetailHash() => r'64197a6bbc70f8c8190bd89ec607efc4f68c3895';

/// Streams the real-time state of a specific [SavedItem] by its [id].

final class ItemDetailFamily extends $Family
    with $FunctionalFamilyOverride<Stream<SavedItem?>, String> {
  ItemDetailFamily._()
    : super(
        retry: null,
        name: r'itemDetailProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Streams the real-time state of a specific [SavedItem] by its [id].

  ItemDetailProvider call(String id) =>
      ItemDetailProvider._(argument: id, from: this);

  @override
  String toString() => r'itemDetailProvider';
}
