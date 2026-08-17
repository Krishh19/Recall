// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'theme_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Controls whether Recall follows the system, light, or dark theme.

@ProviderFor(ThemeController)
final themeControllerProvider = ThemeControllerProvider._();

/// Controls whether Recall follows the system, light, or dark theme.
final class ThemeControllerProvider
    extends $NotifierProvider<ThemeController, ThemeMode> {
  /// Controls whether Recall follows the system, light, or dark theme.
  ThemeControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'themeControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$themeControllerHash();

  @$internal
  @override
  ThemeController create() => ThemeController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ThemeMode value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ThemeMode>(value),
    );
  }
}

String _$themeControllerHash() => r'6c011ef2d2bdec1b285324585381a6adbbbeebbf';

/// Controls whether Recall follows the system, light, or dark theme.

abstract class _$ThemeController extends $Notifier<ThemeMode> {
  ThemeMode build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<ThemeMode, ThemeMode>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ThemeMode, ThemeMode>,
              ThemeMode,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// Controls the active user-selected Material 3 color preset.

@ProviderFor(ThemePresetController)
final themePresetControllerProvider = ThemePresetControllerProvider._();

/// Controls the active user-selected Material 3 color preset.
final class ThemePresetControllerProvider
    extends $NotifierProvider<ThemePresetController, ThemePreset> {
  /// Controls the active user-selected Material 3 color preset.
  ThemePresetControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'themePresetControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$themePresetControllerHash();

  @$internal
  @override
  ThemePresetController create() => ThemePresetController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ThemePreset value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ThemePreset>(value),
    );
  }
}

String _$themePresetControllerHash() =>
    r'6b4f2b16a4412736eabaf3b96cde953b05e5d1d5';

/// Controls the active user-selected Material 3 color preset.

abstract class _$ThemePresetController extends $Notifier<ThemePreset> {
  ThemePreset build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<ThemePreset, ThemePreset>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ThemePreset, ThemePreset>,
              ThemePreset,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
