// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'retry_tracker.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Tracks consecutive failure retries per item ID.

@ProviderFor(RetryTracker)
final retryTrackerProvider = RetryTrackerProvider._();

/// Tracks consecutive failure retries per item ID.
final class RetryTrackerProvider
    extends $NotifierProvider<RetryTracker, Map<String, int>> {
  /// Tracks consecutive failure retries per item ID.
  RetryTrackerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'retryTrackerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$retryTrackerHash();

  @$internal
  @override
  RetryTracker create() => RetryTracker();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Map<String, int> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Map<String, int>>(value),
    );
  }
}

String _$retryTrackerHash() => r'79ac67f69f4e1e51b1a58cc0ada5174778fea73c';

/// Tracks consecutive failure retries per item ID.

abstract class _$RetryTracker extends $Notifier<Map<String, int>> {
  Map<String, int> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<Map<String, int>, Map<String, int>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<Map<String, int>, Map<String, int>>,
              Map<String, int>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
