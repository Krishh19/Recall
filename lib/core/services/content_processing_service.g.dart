// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'content_processing_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provides the active [ContentProcessingService] instance.

@ProviderFor(contentProcessingService)
final contentProcessingServiceProvider = ContentProcessingServiceProvider._();

/// Provides the active [ContentProcessingService] instance.

final class ContentProcessingServiceProvider
    extends
        $FunctionalProvider<
          ContentProcessingService,
          ContentProcessingService,
          ContentProcessingService
        >
    with $Provider<ContentProcessingService> {
  /// Provides the active [ContentProcessingService] instance.
  ContentProcessingServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'contentProcessingServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$contentProcessingServiceHash();

  @$internal
  @override
  $ProviderElement<ContentProcessingService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ContentProcessingService create(Ref ref) {
    return contentProcessingService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ContentProcessingService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ContentProcessingService>(value),
    );
  }
}

String _$contentProcessingServiceHash() =>
    r'6e1c6cd99df915918696fd68f64e9f2b4415c6a8';
