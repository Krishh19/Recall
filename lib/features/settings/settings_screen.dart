import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:recall/core/ai/gemini_service.dart';
import 'package:recall/core/notifications/notification_service.dart';
import 'package:recall/core/providers/theme_controller.dart';
import 'package:recall/core/utils/export_service.dart';
import 'package:recall/data/repositories/saved_item_repository.dart';
import 'package:recall/features/settings/digest_settings.dart';
import 'package:recall/features/settings/digest_settings_provider.dart';
import 'package:url_launcher/url_launcher.dart';

/// Settings screen allowing full customization of theme, AI API key, digest notifications, and exports.
class SettingsScreen extends ConsumerStatefulWidget {
  /// Creates the [SettingsScreen].
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late final TextEditingController _apiKeyController;
  bool _obscureApiKey = true;
  bool _hasSavedKey = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _apiKeyController = TextEditingController();
    _loadApiKey();
  }

  Future<void> _loadApiKey() async {
    final gemini = ref.read(geminiServiceProvider);
    final key = await gemini.getApiKey();
    if (mounted) {
      setState(() {
        _apiKeyController.text = key;
        _hasSavedKey = key.isNotEmpty;
      });
    }
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  Future<void> _saveApiKey() async {
    setState(() => _isSaving = true);
    final newKey = _apiKeyController.text.trim();
    final gemini = ref.read(geminiServiceProvider);
    await gemini.setApiKey(newKey);
    if (mounted) {
      setState(() {
        _hasSavedKey = newKey.isNotEmpty;
        _isSaving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            newKey.isNotEmpty
                ? 'Gemini API key saved successfully!'
                : 'Gemini API key cleared.',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data != null && data.text != null && data.text!.trim().isNotEmpty) {
      setState(() {
        _apiKeyController.text = data.text!.trim();
      });
      await _saveApiKey();
    }
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

  Future<void> _rescheduleDigest({
    required bool enabled,
    required int dayOfWeek,
    required int hour,
    required int minute,
  }) async {
    final notifService = ref.read(notificationServiceProvider);
    if (!enabled) {
      await notifService.cancelDigestNotification();
      return;
    }
    final unread = await ref
        .read(savedItemRepositoryProvider)
        .getUnreadCountPast7Days();
    await notifService.scheduleWeeklyDigest(
      unreadCount: unread,
      dayOfWeek: dayOfWeek,
      hour: hour,
      minute: minute,
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, M3EThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            title,
            style: theme.typeScale.titleSmall.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = M3ETheme.of(context);
    final scheme = theme.colorScheme;
    final currentThemeMode = ref.watch(themeControllerProvider);
    final digestSettings = ref.watch(digestSettingsControllerProvider);

    return Scaffold(
      appBar: M3EAppBar.top(
        titleText: 'Settings',
        automaticallyImplyLeading: true,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        children: [
          // ─── Section 1: Appearance ───
          _buildSectionHeader('Appearance', Icons.palette_outlined, theme),
          M3ECard(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Theme Mode',
                    style: theme.typeScale.titleMedium.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Choose your preferred visual style across Recall.',
                    style: theme.typeScale.bodySmall.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: SegmentedButton<ThemeMode>(
                      showSelectedIcon: false,
                      style: ButtonStyle(
                        visualDensity: VisualDensity.compact,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        padding: WidgetStateProperty.all(
                          const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                      segments: const [
                        ButtonSegment(
                          value: ThemeMode.system,
                          label: Text('System'),
                        ),
                        ButtonSegment(
                          value: ThemeMode.light,
                          label: Text('Light'),
                        ),
                        ButtonSegment(
                          value: ThemeMode.dark,
                          label: Text('Dark'),
                        ),
                      ],
                      selected: {currentThemeMode},
                      onSelectionChanged: (newSelection) {
                        ref
                            .read(themeControllerProvider.notifier)
                            .setThemeMode(newSelection.first);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // ─── Section 2: AI Intelligence ───
          _buildSectionHeader('AI Intelligence', Icons.auto_awesome, theme),
          M3ECard(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Google Gemini 2.5 Flash',
                          style: theme.typeScale.titleMedium.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: _hasSavedKey
                              ? Colors.green.withAlpha(30)
                              : Colors.orange.withAlpha(30),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _hasSavedKey
                                  ? Icons.check_circle_rounded
                                  : Icons.info_outline_rounded,
                              size: 13,
                              color: _hasSavedKey
                                  ? Colors.green.shade700
                                  : Colors.orange.shade800,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _hasSavedKey ? 'Configured' : 'Needs Key',
                              style: theme.typeScale.labelSmall.copyWith(
                                color: _hasSavedKey
                                    ? Colors.green.shade700
                                    : Colors.orange.shade800,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Summaries, key takeaways, categories, and tags are generated directly using your Gemini API key.',
                    style: theme.typeScale.bodySmall.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _apiKeyController,
                    obscureText: _obscureApiKey,
                    onChanged: (_) {
                      setState(() {});
                    },
                    decoration: InputDecoration(
                      labelText: 'Gemini API Key',
                      hintText: 'Enter your AI Studio API key',
                      filled: true,
                      fillColor: scheme.surfaceContainerLowest,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      suffixIcon: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(
                              _obscureApiKey
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              size: 20,
                            ),
                            tooltip: _obscureApiKey ? 'Show key' : 'Hide key',
                            onPressed: () {
                              setState(() => _obscureApiKey = !_obscureApiKey);
                            },
                          ),
                          if (_apiKeyController.text.isNotEmpty)
                            IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 20),
                              tooltip: 'Clear',
                              onPressed: () {
                                setState(() => _apiKeyController.clear());
                                _saveApiKey();
                              },
                            )
                          else
                            IconButton(
                              icon: const Icon(Icons.content_paste_rounded, size: 20),
                              tooltip: 'Paste from clipboard',
                              onPressed: _pasteFromClipboard,
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      InkWell(
                        onTap: _openGoogleAIStudio,
                        borderRadius: BorderRadius.circular(6),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 4,
                            horizontal: 4,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Get free API key',
                                style: theme.typeScale.labelMedium.copyWith(
                                  color: scheme.primary,
                                  fontWeight: FontWeight.bold,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                              const SizedBox(width: 2),
                              Icon(
                                Icons.open_in_new_rounded,
                                size: 13,
                                color: scheme.primary,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const Spacer(),
                      M3EButton(
                        onPressed: _isSaving ? null : _saveApiKey,
                        child: _isSaving
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Save Key'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // ─── Section 3: Notifications ───
          _buildSectionHeader('Notifications', Icons.notifications_outlined, theme),
          M3ECard(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      'Weekly Digest Notification',
                      style: theme.typeScale.titleSmall.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      'Receive a gentle summary of unread bookmarks saved during the week.',
                      style: theme.typeScale.bodySmall.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    value: digestSettings.enabled,
                    onChanged: (enabled) async {
                      await ref
                          .read(digestSettingsControllerProvider.notifier)
                          .setEnabled(enabled);
                      await _rescheduleDigest(
                        enabled: enabled,
                        dayOfWeek: digestSettings.dayOfWeek,
                        hour: digestSettings.hour,
                        minute: digestSettings.minute,
                      );
                    },
                  ),
                  if (digestSettings.enabled) ...[
                    const Divider(height: 20),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        Icons.schedule_rounded,
                        color: scheme.primary,
                      ),
                      title: const Text('Delivery Schedule'),
                      subtitle: Text(
                        'Every ${DigestSettings.dayName(digestSettings.dayOfWeek)} at ${digestSettings.hour.toString().padLeft(2, '0')}:${digestSettings.minute.toString().padLeft(2, '0')}',
                        style: theme.typeScale.bodySmall,
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () async {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay(
                            hour: digestSettings.hour,
                            minute: digestSettings.minute,
                          ),
                        );
                        if (time != null) {
                          await ref
                              .read(digestSettingsControllerProvider.notifier)
                              .setTime(hour: time.hour, minute: time.minute);
                          await _rescheduleDigest(
                            enabled: digestSettings.enabled,
                            dayOfWeek: digestSettings.dayOfWeek,
                            hour: time.hour,
                            minute: time.minute,
                          );
                        }
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // ─── Section 4: Export & Backup ───
          _buildSectionHeader('Export & Backup', Icons.ios_share_rounded, theme),
          M3ECard(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: scheme.primaryContainer,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.description_outlined,
                        color: scheme.onPrimaryContainer,
                        size: 20,
                      ),
                    ),
                    title: const Text('Export as Markdown (.md)'),
                    subtitle: const Text('Formatted for Obsidian, Notion & Bear'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () async {
                      final items = await ref
                          .read(savedItemRepositoryProvider)
                          .getAllItems();
                      final md = ExportService.toMarkdown(items);
                      await ExportService.shareText(
                        md,
                        subject: 'Recall Library Export (Markdown)',
                      );
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: scheme.secondaryContainer,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.code_rounded,
                        color: scheme.onSecondaryContainer,
                        size: 20,
                      ),
                    ),
                    title: const Text('Export as JSON (.json)'),
                    subtitle: const Text('Full raw structured backup with metadata'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () async {
                      final items = await ref
                          .read(savedItemRepositoryProvider)
                          .getAllItems();
                      final jsonStr = ExportService.toJson(items);
                      await ExportService.shareText(
                        jsonStr,
                        subject: 'Recall Library Export (JSON)',
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // ─── Section 5: Privacy & Local Storage ───
          _buildSectionHeader('Storage & Privacy', Icons.shield_outlined, theme),
          M3ECard(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: scheme.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.lock_outline_rounded,
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
                          '100% Local & Private',
                          style: theme.typeScale.titleSmall.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'All saved links, raw content, and AI summaries reside locally on your device inside SQLite.',
                          style: theme.typeScale.bodySmall.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
