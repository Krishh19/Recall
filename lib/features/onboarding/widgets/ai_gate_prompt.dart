import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:recall/features/onboarding/screens/onboarding_flow_screen.dart';

/// An inline prompt displayed when an AI feature is accessed but Gemini is not yet configured.
class AIGatePrompt extends ConsumerWidget {
  /// Creates the [AIGatePrompt].
  const AIGatePrompt({
    super.key,
    this.message = 'Connect Gemini to unlock AI summaries, categories, and tags.',
    this.onConfigured,
  });

  /// The explanation message.
  final String message;

  /// Optional callback invoked after Gemini key is successfully configured.
  final VoidCallback? onConfigured;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: scheme.outlineVariant.withAlpha(80),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.auto_awesome_rounded,
                size: 20,
                color: scheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Connect Gemini to unlock AI summaries',
                  style: (textTheme.titleSmall ?? const TextStyle(fontSize: 14))
                      .copyWith(
                    fontWeight: FontWeight.bold,
                    color: scheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            message,
            style: (textTheme.bodySmall ?? const TextStyle(fontSize: 12))
                .copyWith(
              color: scheme.onSurfaceVariant,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () async {
              final configured =
                  await OnboardingFlowScreen.showKeyEntryModal(context);
              if (configured == true && onConfigured != null) {
                onConfigured!();
              }
            },
            icon: const Icon(Icons.key_rounded, size: 16),
            label: const Text('Connect Gemini'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
