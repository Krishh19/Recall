import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:recall/core/utils/url_extractor.dart';
import 'package:recall/data/repositories/saved_item_repository.dart';
import 'package:recall/features/save/widgets/save_confirmation_sheet.dart';

/// Modal bottom sheet allowing users to manually paste and save a link into Recall.
class ManualAddUrlDialog extends ConsumerStatefulWidget {
  /// Creates a [ManualAddUrlDialog].
  const ManualAddUrlDialog({super.key});

  /// Displays the add link dialog.
  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const ManualAddUrlDialog(),
    );
  }

  @override
  ConsumerState<ManualAddUrlDialog> createState() => _ManualAddUrlDialogState();
}

class _ManualAddUrlDialogState extends ConsumerState<ManualAddUrlDialog> {
  final TextEditingController _textController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData('text/plain');
    final text = data?.text;
    if (text != null && text.isNotEmpty) {
      setState(() {
        _textController.text = text.trim();
        _errorMessage = null;
      });
    }
  }

  Future<void> _saveUrl() async {
    final rawText = _textController.text.trim();
    if (rawText.isEmpty) {
      setState(() => _errorMessage = 'Please enter or paste a URL');
      return;
    }

    final url = UrlExtractor.extractUrl(rawText);
    if (url == null) {
      setState(() => _errorMessage = 'Could not find a valid web link');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final repository = ref.read(savedItemRepositoryProvider);
      final existing = await repository.getItemByUrl(url);

      if (existing != null && mounted) {
        setState(() => _isLoading = false);
        final proceed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Link Already Saved'),
            content: Text(
              'This link is already in your library:\n"${existing.title ?? existing.url}"\n\nWould you like to view the existing bookmark or save a new copy?',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(ctx).pop(false);
                  Navigator.of(context).pop();
                  context.push('/detail/${existing.id}');
                },
                child: const Text('View Existing'),
              ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Save New Copy'),
              ),
            ],
          ),
        );

        if (proceed != true) {
          return;
        }
        setState(() => _isLoading = true);
      }

      final platform = UrlExtractor.detectPlatform(url);
      final item = await repository.createInitialItem(
        url: url,
        platform: platform,
      );

      if (mounted) {
        Navigator.of(context).pop();
        SaveConfirmationSheet.show(context, itemId: item.id);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to save: ${e.toString()}';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.only(
        top: 24,
        left: 24,
        right: 24,
        bottom: bottomInset + 24,
      ),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.link, color: scheme.onPrimaryContainer, size: 24),
              ),
              const SizedBox(width: 12),
              Text(
                'Save Link',
                style: (textTheme.headlineSmall ?? const TextStyle(fontSize: 24)).copyWith(
                  fontWeight: FontWeight.bold,
                  color: scheme.onSurface,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: Icon(Icons.close, color: scheme.onSurfaceVariant),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Paste any article, YouTube video, Twitter/X post, or webpage to summarize.',
            style: (textTheme.bodyMedium ?? const TextStyle(fontSize: 13)).copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _textController,
            autofocus: true,
            keyboardType: TextInputType.url,
            decoration: InputDecoration(
              hintText: 'https://...',
              filled: true,
              fillColor: scheme.surfaceContainerLowest,
              errorText: _errorMessage,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: scheme.outlineVariant),
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  Icons.paste_rounded,
                  color: scheme.onSurfaceVariant,
                ),
                tooltip: 'Paste from clipboard',
                onPressed: _pasteFromClipboard,
              ),
            ),
            onSubmitted: (_) => _saveUrl(),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton(
              onPressed: _isLoading ? null : _saveUrl,
              child: _isLoading
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: scheme.onPrimary,
                      ),
                    )
                  : const Text('Save & Summarize'),
            ),
          ),
        ],
      ),
    );
  }
}
