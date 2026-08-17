// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'digest_settings_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provider for FlutterSecureStorage instance.

@ProviderFor(secureStorage)
final secureStorageProvider = SecureStorageProvider._();

/// Provider for FlutterSecureStorage instance.

final class SecureStorageProvider
    extends
        $FunctionalProvider<
          FlutterSecureStorage,
          FlutterSecureStorage,
          FlutterSecureStorage
        >
    with $Provider<FlutterSecureStorage> {
  /// Provider for FlutterSecureStorage instance.
  SecureStorageProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'secureStorageProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$secureStorageHash();

  @$internal
  @override
  $ProviderElement<FlutterSecureStorage> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  FlutterSecureStorage create(Ref ref) {
    return secureStorage(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FlutterSecureStorage value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FlutterSecureStorage>(value),
    );
  }
}

String _$secureStorageHash() => r'a4f75721472cf77465bf47f759c90de5ca30856e';

/// Manages and persists user configurable digest notification preferences.

@ProviderFor(DigestSettingsController)
final digestSettingsControllerProvider = DigestSettingsControllerProvider._();

/// Manages and persists user configurable digest notification preferences.
final class DigestSettingsControllerProvider
    extends $NotifierProvider<DigestSettingsController, DigestSettings> {
  /// Manages and persists user configurable digest notification preferences.
  DigestSettingsControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'digestSettingsControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$digestSettingsControllerHash();

  @$internal
  @override
  DigestSettingsController create() => DigestSettingsController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DigestSettings value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DigestSettings>(value),
    );
  }
}

String _$digestSettingsControllerHash() =>
    r'0a3233184ef7bfcab7135e0c7541217e16733f3d';

/// Manages and persists user configurable digest notification preferences.

abstract class _$DigestSettingsController extends $Notifier<DigestSettings> {
  DigestSettings build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<DigestSettings, DigestSettings>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<DigestSettings, DigestSettings>,
              DigestSettings,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
