import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:recall/core/ai/gemini_service.dart';
import 'package:url_launcher/url_launcher.dart';

/// A Material 3 Modal Bottom Sheet providing a secure, write-only BYOK
/// management interface for Google Gemini API credentials.
class GeminiConfigSheet extends ConsumerStatefulWidget {
  /// Creates a [GeminiConfigSheet].
  const GeminiConfigSheet({
    super.key,
    required this.isInitiallyConfigured,
  });

  /// Whether a valid key is already stored on this device.
  final bool isInitiallyConfigured;

  /// Shows the [GeminiConfigSheet] modal.
  static Future<void> show(
    BuildContext context, {
    required bool isConfigured,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => GeminiConfigSheet(
        isInitiallyConfigured: isConfigured,
      ),
    );
  }

  @override
  ConsumerState<GeminiConfigSheet> createState() => _GeminiConfigSheetState();
}

class _GeminiConfigSheetState extends ConsumerState<GeminiConfigSheet> {
  late final TextEditingController _keyInputController;
  late bool _isInputMode;
  late bool _isReplace;
  bool _isValidating = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _keyInputController = TextEditingController();
    _isInputMode = !widget.isInitiallyConfigured;
    _isReplace = widget.isInitiallyConfigured;
  }

  @override
  void dispose() {
    _keyInputController.dispose();
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
        _keyInputController.text = data.text!.trim();
        _errorMessage = null;
      });
    }
  }

  Future<void> _saveAndValidate() async {
    final candidateKey = _keyInputController.text.trim();
    if (candidateKey.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter or paste your Gemini API key.';
      });
      return;
    }

    setState(() {
      _isValidating = true;
      _errorMessage = null;
    });

    final gemini = ref.read(geminiServiceProvider);

    try {
      // Validate candidate key against Gemini before persisting
      await gemini.validateApiKey(candidateKey);

      // Successfully verified: store securely
      await gemini.setApiKey(candidateKey);
      ref.invalidate(isGeminiConfiguredProvider);

      if (mounted) {
        _keyInputController.clear();
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: const [
                Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text('Gemini connected successfully!'),
              ],
            ),
            backgroundColor: Colors.green.shade700,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } on GeminiValidationException catch (e) {
      if (mounted) {
        setState(() {
          _isValidating = false;
          _errorMessage = e.message;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isValidating = false;
          _errorMessage =
              "Couldn't connect to Gemini. Please verify your key and network connection.";
        });
      }
    }
  }

  Future<void> _confirmAndRemoveKey() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final scheme = Theme.of(dialogContext).colorScheme;
        final textTheme = Theme.of(dialogContext).textTheme;

        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          icon: Icon(
            Icons.delete_outline_rounded,
            color: scheme.error,
            size: 28,
          ),
          title: Text(
            'Remove Gemini key?',
            style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          content: Text(
            'Your stored API key will be removed from this device.\n\nAI summaries, categories, and tags will stop working until another key is configured.',
            style: textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: scheme.error,
                foregroundColor: scheme.onError,
              ),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Remove key'),
            ),
          ],
        );
      },
    );

    if (confirmed == true && mounted) {
      final gemini = ref.read(geminiServiceProvider);
      await gemini.setApiKey('');
      ref.invalidate(isGeminiConfiguredProvider);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gemini API key removed.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
        child: _isInputMode
            ? _buildInputView(scheme, textTheme)
            : _buildConnectedView(scheme, textTheme),
      ),
    );
  }

  Widget _buildConnectedView(ColorScheme scheme, TextTheme textTheme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: scheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.key_rounded,
                color: scheme.onPrimaryContainer,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Google Gemini',
                    style: (textTheme.titleLarge ?? const TextStyle(fontSize: 18))
                        .copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_circle_rounded,
                        size: 14,
                        color: scheme.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Connected',
                        style: (textTheme.labelMedium ??
                                const TextStyle(fontSize: 12))
                            .copyWith(
                          color: scheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Text(
          'Your Gemini API key is stored securely on this device and is only used for Gemini requests.',
          style: (textTheme.bodyMedium ?? const TextStyle(fontSize: 13))
              .copyWith(color: scheme.onSurfaceVariant, height: 1.4),
        ),
        const SizedBox(height: 20),

        // Stored Securely Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: scheme.surfaceContainer,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: scheme.outlineVariant.withAlpha(80),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'API KEY',
                style: (textTheme.labelSmall ?? const TextStyle(fontSize: 11))
                    .copyWith(
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.lock_rounded,
                    size: 18,
                    color: scheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Stored securely',
                    style: (textTheme.titleSmall ??
                            const TextStyle(fontSize: 14))
                        .copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'The key is never displayed after saving.',
                style: (textTheme.bodySmall ?? const TextStyle(fontSize: 12))
                    .copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Connection status card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Icon(
                Icons.check_circle_outline_rounded,
                size: 18,
                color: scheme.primary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Gemini API is configured',
                  style: (textTheme.bodyMedium ?? const TextStyle(fontSize: 13))
                      .copyWith(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Action Buttons
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: () {
              setState(() {
                _isInputMode = true;
                _isReplace = true;
                _errorMessage = null;
              });
            },
            icon: const Icon(Icons.sync_rounded, size: 18),
            label: const Text('Replace API key'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: TextButton.icon(
            onPressed: _confirmAndRemoveKey,
            icon: Icon(
              Icons.delete_outline_rounded,
              size: 18,
              color: scheme.error,
            ),
            label: Text(
              'Remove key',
              style: TextStyle(
                color: scheme.error,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInputView(ColorScheme scheme, TextTheme textTheme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _isReplace ? 'Replace API key' : 'Connect Gemini',
          style: (textTheme.headlineSmall ?? const TextStyle(fontSize: 22))
              .copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        Text(
          _isReplace
              ? 'Enter a new Gemini API key. Your existing key will remain active until the new key is successfully validated and saved.'
              : 'Add your Gemini API key to enable AI-powered bookmark organization.',
          style: (textTheme.bodyMedium ?? const TextStyle(fontSize: 13))
              .copyWith(color: scheme.onSurfaceVariant, height: 1.4),
        ),
        const SizedBox(height: 18),

        // Error Notice if Validation Failed
        if (_errorMessage != null) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: scheme.errorContainer,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: scheme.onErrorContainer,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "Couldn't connect",
                      style: (textTheme.titleSmall ??
                              const TextStyle(fontSize: 14))
                          .copyWith(
                        fontWeight: FontWeight.bold,
                        color: scheme.onErrorContainer,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  _errorMessage!,
                  style: (textTheme.bodySmall ?? const TextStyle(fontSize: 12))
                      .copyWith(color: scheme.onErrorContainer, height: 1.3),
                ),
                if (_isReplace) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Existing key remains active.',
                    style: (textTheme.labelSmall ??
                            const TextStyle(fontSize: 11))
                        .copyWith(
                      fontWeight: FontWeight.bold,
                      color: scheme.onErrorContainer,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Secure Write-Only Text Field
        TextField(
          controller: _keyInputController,
          obscureText: true,
          autofocus: true,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            labelText: 'Gemini API key',
            hintText: 'Paste your API key...',
            filled: true,
            fillColor: scheme.surfaceContainerLowest,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: scheme.outlineVariant),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: scheme.outlineVariant),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: scheme.primary, width: 1.5),
            ),
            suffixIcon: _keyInputController.text.isNotEmpty
                ? IconButton(
                    icon: Icon(
                      Icons.clear_rounded,
                      size: 20,
                      color: scheme.onSurfaceVariant,
                    ),
                    tooltip: 'Clear input',
                    onPressed: () =>
                        setState(() => _keyInputController.clear()),
                  )
                : IconButton(
                    icon: Icon(
                      Icons.content_paste_rounded,
                      size: 20,
                      color: scheme.onSurfaceVariant,
                    ),
                    tooltip: 'Paste from clipboard',
                    onPressed: _pasteFromClipboard,
                  ),
          ),
        ),
        const SizedBox(height: 8),

        Row(
          children: [
            Icon(
              Icons.lock_outline_rounded,
              size: 14,
              color: scheme.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                'Stored securely on this device. Never displayed after saving.',
                style: (textTheme.bodySmall ?? const TextStyle(fontSize: 12))
                    .copyWith(
                  color: scheme.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Free Key Link
        InkWell(
          onTap: _openGoogleAIStudio,
          borderRadius: BorderRadius.circular(6),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Get a free API key',
                  style: (textTheme.labelMedium ?? const TextStyle(fontSize: 12))
                      .copyWith(
                    color: scheme.primary,
                    fontWeight: FontWeight.bold,
                    decoration: TextDecoration.underline,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.open_in_new_rounded,
                  size: 13,
                  color: scheme.primary,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Action Buttons / Loading State
        if (_isValidating) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: scheme.surfaceContainer,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: scheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Checking API key…',
                  style: (textTheme.bodyMedium ?? const TextStyle(fontSize: 13))
                      .copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ] else ...[
          Row(
            children: [
              if (_isReplace) ...[
                Expanded(
                  child: TextButton(
                    onPressed: () {
                      setState(() {
                        _isInputMode = false;
                        _errorMessage = null;
                        _keyInputController.clear();
                      });
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                flex: _isReplace ? 1 : 2,
                child: FilledButton(
                  onPressed: _saveAndValidate,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(_isReplace ? 'Save key' : 'Save & connect'),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
