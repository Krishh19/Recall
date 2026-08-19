import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:recall/core/ai/gemini_service.dart';
import 'package:recall/features/onboarding/onboarding_controller.dart';
import 'package:url_launcher/url_launcher.dart';

/// Canonical onboarding step states.
enum OnboardingStep {
  welcome,
  geminiIntro,
  geminiKeyEntry,
  verifying,
  success,
}

/// The first-launch onboarding & Gemini setup flow screen.
class OnboardingFlowScreen extends ConsumerStatefulWidget {
  /// Creates the [OnboardingFlowScreen].
  const OnboardingFlowScreen({
    super.key,
    this.isInlineModal = false,
    this.initialStep,
  });

  /// Whether this screen is displayed as a modal bottom sheet / subflow.
  final bool isInlineModal;

  /// Optional step override (e.g. for direct AI feature gating).
  final OnboardingStep? initialStep;

  /// Shows the onboarding key entry modal directly (for AI feature gating).
  static Future<bool?> showKeyEntryModal(BuildContext context) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => const FractionallySizedBox(
        heightFactor: 0.9,
        child: OnboardingFlowScreen(
          isInlineModal: true,
          initialStep: OnboardingStep.geminiKeyEntry,
        ),
      ),
    );
  }

  @override
  ConsumerState<OnboardingFlowScreen> createState() =>
      _OnboardingFlowScreenState();
}

class _OnboardingFlowScreenState extends ConsumerState<OnboardingFlowScreen> {
  late OnboardingStep _currentStep;
  late final TextEditingController _keyController;
  bool _obscureKey = true;
  bool _showHowKeyIsUsed = false;
  String? _errorHeadline;
  String? _errorMessage;
  GeminiValidationCategory? _errorCategory;

  @override
  void initState() {
    super.initState();
    _currentStep = widget.initialStep ?? OnboardingStep.welcome;
    _keyController = TextEditingController();
  }

  @override
  void dispose() {
    _keyController.dispose();
    super.dispose();
  }

  Future<void> _openGoogleAIStudio() async {
    final uri = Uri.parse('https://aistudio.google.com/app/apikey');
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open browser.')),
        );
      }
    }
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data != null && data.text != null && data.text!.trim().isNotEmpty) {
      setState(() {
        _keyController.text = data.text!.trim();
        _errorHeadline = null;
        _errorMessage = null;
        _errorCategory = null;
      });
    }
  }

  Future<void> _handleSkip() async {
    if (widget.isInlineModal) {
      Navigator.of(context).pop(false);
    } else {
      await ref.read(onboardingControllerProvider.notifier).skipOnboarding();
      if (mounted) {
        context.go('/');
      }
    }
  }

  Future<void> _handleComplete() async {
    if (widget.isInlineModal) {
      Navigator.of(context).pop(true);
    } else {
      await ref
          .read(onboardingControllerProvider.notifier)
          .completeOnboarding();
      if (mounted) {
        context.go('/');
      }
    }
  }

  Future<void> _verifyKey() async {
    final candidateKey = _keyController.text.trim();
    if (candidateKey.isEmpty) {
      setState(() {
        _errorHeadline = 'API key required';
        _errorMessage = 'Please enter or paste your Gemini API key.';
        _errorCategory = GeminiValidationCategory.invalidKey;
      });
      return;
    }

    setState(() {
      _currentStep = OnboardingStep.verifying;
      _errorHeadline = null;
      _errorMessage = null;
      _errorCategory = null;
    });

    final gemini = ref.read(geminiServiceProvider);

    try {
      await gemini.validateApiKey(candidateKey);

      // Successfully verified: store securely immediately
      await gemini.setApiKey(candidateKey);
      ref.invalidate(isGeminiConfiguredProvider);
      ref.invalidate(maskedGeminiKeyProvider);

      if (mounted) {
        setState(() {
          _currentStep = OnboardingStep.success;
        });
      }
    } on GeminiValidationException catch (e) {
      if (mounted) {
        String headline;
        switch (e.category) {
          case GeminiValidationCategory.networkError:
            headline = "Couldn't reach Gemini";
            break;
          case GeminiValidationCategory.quotaOrPermission:
            headline = 'Gemini needs attention';
            break;
          case GeminiValidationCategory.invalidKey:
            headline = "Couldn't connect to Gemini";
            break;
        }

        setState(() {
          _currentStep = OnboardingStep.geminiKeyEntry;
          _errorHeadline = headline;
          _errorMessage = e.message;
          _errorCategory = e.category;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _currentStep = OnboardingStep.geminiKeyEntry;
          _errorHeadline = "Couldn't reach Gemini";
          _errorMessage =
              'Check your internet connection and verify your key, then try again.';
          _errorCategory = GeminiValidationCategory.networkError;
        });
      }
    }
  }

  void _handleBack() {
    if (_currentStep == OnboardingStep.verifying) {
      // In-flight request: ignore back to avoid corrupted state
      return;
    }

    switch (_currentStep) {
      case OnboardingStep.welcome:
        if (widget.isInlineModal) {
          Navigator.of(context).pop(false);
        } else {
          SystemNavigator.pop();
        }
        break;
      case OnboardingStep.geminiIntro:
        setState(() => _currentStep = OnboardingStep.welcome);
        break;
      case OnboardingStep.geminiKeyEntry:
        if (widget.isInlineModal) {
          Navigator.of(context).pop(false);
        } else {
          setState(() => _currentStep = OnboardingStep.geminiIntro);
        }
        break;
      case OnboardingStep.verifying:
        break;
      case OnboardingStep.success:
        _handleComplete();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return PopScope(
      canPop: _currentStep != OnboardingStep.verifying &&
          (widget.isInlineModal || _currentStep == OnboardingStep.welcome),
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          _handleBack();
        }
      },
      child: Scaffold(
        backgroundColor: scheme.surface,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: _currentStep == OnboardingStep.verifying
              ? const SizedBox.shrink()
              : IconButton(
                  icon: const Icon(Icons.arrow_back),
                  tooltip: 'Back',
                  onPressed: _handleBack,
                ),
          actions: [
            if (_currentStep == OnboardingStep.welcome ||
                _currentStep == OnboardingStep.geminiIntro)
              TextButton(
                onPressed: _handleSkip,
                child: Text(
                  _currentStep == OnboardingStep.welcome
                      ? 'Skip setup'
                      : "I'll do this later",
                  style: TextStyle(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
        body: SafeArea(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: _buildCurrentView(scheme, textTheme),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentView(ColorScheme scheme, TextTheme textTheme) {
    switch (_currentStep) {
      case OnboardingStep.welcome:
        return _buildWelcomeView(scheme, textTheme);
      case OnboardingStep.geminiIntro:
        return _buildGeminiIntroView(scheme, textTheme);
      case OnboardingStep.geminiKeyEntry:
      case OnboardingStep.verifying:
        return _buildKeyEntryView(scheme, textTheme);
      case OnboardingStep.success:
        return _buildSuccessView(scheme, textTheme);
    }
  }

  Widget _buildWelcomeView(ColorScheme scheme, TextTheme textTheme) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight - 40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SizedBox(height: 12),
                // Hero Illustration / Icon
                Column(
                  children: [
                    Container(
                      width: 104,
                      height: 104,
                      decoration: BoxDecoration(
                        color: scheme.primaryContainer,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: scheme.primary.withAlpha(40),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(30),
                        child: Image.asset(
                          'assets/icon.png',
                          errorBuilder: (_, _, _) => Icon(
                            Icons.auto_stories_rounded,
                            size: 52,
                            color: scheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'Recall',
                      style: (textTheme.headlineMedium ??
                              const TextStyle(fontSize: 28))
                          .copyWith(
                        fontWeight: FontWeight.w800,
                        color: scheme.onSurface,
                        letterSpacing: -0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Save anything. Remember everything.',
                      style: (textTheme.titleMedium ??
                              const TextStyle(fontSize: 16))
                          .copyWith(
                        fontWeight: FontWeight.w600,
                        color: scheme.primary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Save links from across the web and let Recall turn them into useful summaries, categories, and tags.',
                      style: (textTheme.bodyLarge ??
                              const TextStyle(fontSize: 15))
                          .copyWith(
                        color: scheme.onSurfaceVariant,
                        height: 1.45,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
                const SizedBox(height: 36),
                Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () {
                          setState(() {
                            _currentStep = OnboardingStep.geminiIntro;
                          });
                        },
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        child: const Text(
                          'Get Started',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: _handleSkip,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text(
                        'Skip setup',
                        style: TextStyle(
                          color: scheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildGeminiIntroView(ColorScheme scheme, TextTheme textTheme) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight - 40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: scheme.primaryContainer,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.auto_awesome_rounded,
                        color: scheme.onPrimaryContainer,
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Make Recall intelligent',
                      style: (textTheme.headlineSmall ??
                              const TextStyle(fontSize: 24))
                          .copyWith(
                        fontWeight: FontWeight.bold,
                        color: scheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Recall uses Google Gemini to understand your saved links and create summaries, categories, and tags.',
                      style: (textTheme.bodyLarge ??
                              const TextStyle(fontSize: 15))
                          .copyWith(
                        color: scheme.onSurfaceVariant,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: scheme.surfaceContainer,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: scheme.outlineVariant.withAlpha(80),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text(
                                '✨',
                                style: TextStyle(fontSize: 18),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Google Gemini — Bring your own API key',
                                  style: (textTheme.titleSmall ??
                                          const TextStyle(fontSize: 14))
                                      .copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Your Gemini API key lets Recall use AI without requiring a Recall account.',
                            style: (textTheme.bodyMedium ??
                                    const TextStyle(fontSize: 13))
                                .copyWith(
                              color: scheme.onSurfaceVariant,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 36),
                Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () {
                          setState(() {
                            _currentStep = OnboardingStep.geminiKeyEntry;
                          });
                        },
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        child: const Text(
                          'Connect Gemini',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: _handleSkip,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text(
                        "I'll do this later",
                        style: TextStyle(
                          color: scheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildKeyEntryView(ColorScheme scheme, TextTheme textTheme) {
    final isVerifying = _currentStep == OnboardingStep.verifying;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Connect Gemini',
            style: (textTheme.headlineSmall ?? const TextStyle(fontSize: 24))
                .copyWith(
              fontWeight: FontWeight.bold,
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Give Recall access to Gemini so it can understand and organize your saved links.',
            style: (textTheme.bodyMedium ?? const TextStyle(fontSize: 14))
                .copyWith(
              color: scheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),

          // Error Banner if validation failed
          if (_errorMessage != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: scheme.errorContainer,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: scheme.onErrorContainer,
                        size: 22,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _errorHeadline ?? "Couldn't connect",
                          style: (textTheme.titleSmall ??
                                  const TextStyle(fontSize: 14))
                              .copyWith(
                            fontWeight: FontWeight.bold,
                            color: scheme.onErrorContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _errorMessage!,
                    style: (textTheme.bodySmall ??
                            const TextStyle(fontSize: 12))
                        .copyWith(
                      color: scheme.onErrorContainer,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      FilledButton.tonal(
                        style: FilledButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          backgroundColor: scheme.onErrorContainer,
                          foregroundColor: scheme.errorContainer,
                        ),
                        onPressed: _verifyKey,
                        child: const Text('Try Again'),
                      ),
                      if (_errorCategory ==
                          GeminiValidationCategory.invalidKey)
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                            side: BorderSide(color: scheme.onErrorContainer),
                            foregroundColor: scheme.onErrorContainer,
                          ),
                          onPressed: _openGoogleAIStudio,
                          child: const Text('Get a new key'),
                        )
                      else if (_errorCategory ==
                          GeminiValidationCategory.networkError)
                        TextButton(
                          style: TextButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                            foregroundColor: scheme.onErrorContainer,
                          ),
                          onPressed: _handleSkip,
                          child: const Text('Continue without Gemini'),
                        )
                      else if (_errorCategory ==
                          GeminiValidationCategory.quotaOrPermission)
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                            side: BorderSide(color: scheme.onErrorContainer),
                            foregroundColor: scheme.onErrorContainer,
                          ),
                          onPressed: _openGoogleAIStudio,
                          child: const Text('Open AI Studio'),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Step 1 — Get your key
          Text(
            'Step 1 — Get your key',
            style: (textTheme.titleSmall ?? const TextStyle(fontSize: 14))
                .copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'Create a Gemini API key in Google AI Studio.',
            style: (textTheme.bodySmall ?? const TextStyle(fontSize: 12))
                .copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: isVerifying ? null : _openGoogleAIStudio,
            icon: const Icon(Icons.open_in_new_rounded, size: 16),
            label: const Text('Open Google AI Studio ↗'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Step 2 — Paste your key
          Text(
            'Step 2 — Paste your key',
            style: (textTheme.titleSmall ?? const TextStyle(fontSize: 14))
                .copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _keyController,
            obscureText: _obscureKey,
            enabled: !isVerifying,
            maxLines: 1,
            decoration: InputDecoration(
              labelText: 'Gemini API key',
              hintText: 'AIzaSy...',
              prefixIcon: const Icon(Icons.key_rounded, size: 20),
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(
                      _obscureKey
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      size: 20,
                    ),
                    tooltip: _obscureKey ? 'Show API key' : 'Hide API key',
                    onPressed: () {
                      setState(() {
                        _obscureKey = !_obscureKey;
                      });
                    },
                  ),
                  if (_keyController.text.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 20),
                      tooltip: 'Clear input',
                      onPressed: isVerifying
                          ? null
                          : () {
                              setState(() => _keyController.clear());
                            },
                    )
                  else
                    IconButton(
                      icon: const Icon(Icons.content_paste_rounded, size: 20),
                      tooltip: 'Paste from clipboard',
                      onPressed: isVerifying ? null : _pasteFromClipboard,
                    ),
                  const SizedBox(width: 4),
                ],
              ),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 8),

          // Security note
          Row(
            children: [
              Icon(
                Icons.lock_rounded,
                size: 14,
                color: scheme.primary,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '🔒 Stored securely on this device.',
                  style: (textTheme.bodySmall ?? const TextStyle(fontSize: 12))
                      .copyWith(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Expandable explanation
          InkWell(
            onTap: () {
              setState(() {
                _showHowKeyIsUsed = !_showHowKeyIsUsed;
              });
            },
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Icon(
                    _showHowKeyIsUsed
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    size: 18,
                    color: scheme.primary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'How is my key used?',
                    style: (textTheme.labelMedium ??
                            const TextStyle(fontSize: 12))
                        .copyWith(
                      color: scheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_showHowKeyIsUsed) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Recall uses your key to communicate with Google Gemini. Your key is stored locally and is never displayed in full after it is saved.',
                style: (textTheme.bodySmall ?? const TextStyle(fontSize: 12))
                    .copyWith(
                  color: scheme.onSurfaceVariant,
                  height: 1.35,
                ),
              ),
            ),
          ],
          const SizedBox(height: 32),

          // Verify & Continue CTA
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: isVerifying ? null : _verifyKey,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              child: isVerifying
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: scheme.onPrimary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Verifying…',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    )
                  : const Text(
                      'Verify & Continue',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessView(ColorScheme scheme, TextTheme textTheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const SizedBox(height: 20),
          Column(
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle_rounded,
                  color: scheme.primary,
                  size: 52,
                ),
              ),
              const SizedBox(height: 28),
              Text(
                '✨ Gemini connected',
                style: (textTheme.headlineSmall ??
                        const TextStyle(fontSize: 24))
                    .copyWith(
                  fontWeight: FontWeight.bold,
                  color: scheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Recall is ready to turn your saved links into something useful.',
                style: (textTheme.bodyLarge ?? const TextStyle(fontSize: 15))
                    .copyWith(
                  color: scheme.onSurfaceVariant,
                  height: 1.45,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          const SizedBox(height: 36),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _handleComplete,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              child: const Text(
                'Start using Recall',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
