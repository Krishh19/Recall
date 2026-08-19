// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'gemini_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provides the active [GeminiService] instance.

@ProviderFor(geminiService)
final geminiServiceProvider = GeminiServiceProvider._();

/// Provides the active [GeminiService] instance.

final class GeminiServiceProvider
    extends $FunctionalProvider<GeminiService, GeminiService, GeminiService>
    with $Provider<GeminiService> {
  /// Provides the active [GeminiService] instance.
  GeminiServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'geminiServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$geminiServiceHash();

  @$internal
  @override
  $ProviderElement<GeminiService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  GeminiService create(Ref ref) {
    return geminiService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GeminiService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GeminiService>(value),
    );
  }
}

String _$geminiServiceHash() => r'e5feb19f16ed3b98580dffdb3a321139b26a7d6d';

/// Exposes whether a Gemini API key is currently configured.

@ProviderFor(isGeminiConfigured)
final isGeminiConfiguredProvider = IsGeminiConfiguredProvider._();

/// Exposes whether a Gemini API key is currently configured.

final class IsGeminiConfiguredProvider
    extends $FunctionalProvider<AsyncValue<bool>, bool, FutureOr<bool>>
    with $FutureModifier<bool>, $FutureProvider<bool> {
  /// Exposes whether a Gemini API key is currently configured.
  IsGeminiConfiguredProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'isGeminiConfiguredProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$isGeminiConfiguredHash();

  @$internal
  @override
  $FutureProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<bool> create(Ref ref) {
    return isGeminiConfigured(ref);
  }
}

String _$isGeminiConfiguredHash() =>
    r'880076c81c2d907427c4f070d95e7f28b24b57ef';

/// Exposes the safe masked Gemini API key (e.g. AIza••••••••••••) if configured.

@ProviderFor(maskedGeminiKey)
final maskedGeminiKeyProvider = MaskedGeminiKeyProvider._();

/// Exposes the safe masked Gemini API key (e.g. AIza••••••••••••) if configured.

final class MaskedGeminiKeyProvider
    extends $FunctionalProvider<AsyncValue<String>, String, FutureOr<String>>
    with $FutureModifier<String>, $FutureProvider<String> {
  /// Exposes the safe masked Gemini API key (e.g. AIza••••••••••••) if configured.
  MaskedGeminiKeyProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'maskedGeminiKeyProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$maskedGeminiKeyHash();

  @$internal
  @override
  $FutureProviderElement<String> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<String> create(Ref ref) {
    return maskedGeminiKey(ref);
  }
}

String _$maskedGeminiKeyHash() => r'0b04710cb53ed453be3537b6b6efcb59933d4858';
