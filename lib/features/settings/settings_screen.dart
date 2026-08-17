import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:recall/core/ai/gemini_service.dart';
import 'package:recall/core/notifications/notification_service.dart';
import 'package:recall/core/providers/theme_controller.dart';
import 'package:recall/core/utils/export_service.dart';
import 'package:recall/data/repositories/saved_item_repository.dart';
import 'package:recall/features/settings/digest_settings.dart';
import 'package:recall/features/settings/digest_settings_provider.dart';
import 'package:recall/features/settings/widgets/gemini_config_sheet.dart';

/// Settings screen allowing full customization of theme, AI API key, digest notifications, and exports.
class SettingsScreen extends ConsumerStatefulWidget {
  /// Creates the [SettingsScreen].
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
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

  Widget _buildSectionHeader(String title, IconData icon, ThemeData theme) {
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8, top: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            title,
            style: (textTheme.titleMedium ?? const TextStyle(fontSize: 15)).copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final currentThemeMode = ref.watch(themeControllerProvider);
    final currentPreset = ref.watch(themePresetControllerProvider);
    final digestSettings = ref.watch(digestSettingsControllerProvider);
    final isGeminiConfiguredAsync = ref.watch(isGeminiConfiguredProvider);
    final isGeminiConfigured = isGeminiConfiguredAsync.value ?? false;

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
          Card(
            color: scheme.surfaceContainer,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            elevation: 0,
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Theme Mode',
                    style: (textTheme.titleMedium ?? const TextStyle(fontSize: 15)).copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Choose your preferred visual style across Recall.',
                    style: (textTheme.bodySmall ?? const TextStyle(fontSize: 12)).copyWith(
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
                  const SizedBox(height: 18),
                  Divider(color: scheme.outlineVariant, height: 1),
                  const SizedBox(height: 14),
                  Text(
                    'Theme Color Accent',
                    style: (textTheme.titleMedium ?? const TextStyle(fontSize: 15)).copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Select dynamic wallpaper colors or a custom Material 3 accent.',
                    style: (textTheme.bodySmall ?? const TextStyle(fontSize: 12)).copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: ThemePreset.values.map((p) {
                      final isSelected = p == currentPreset;
                      return FilterChip(
                        selected: isSelected,
                        showCheckmark: false,
                        avatar: p == ThemePreset.dynamicColor
                            ? Icon(
                                Icons.auto_awesome,
                                size: 16,
                                color: isSelected
                                    ? scheme.onSecondaryContainer
                                    : scheme.onSurfaceVariant,
                              )
                            : Container(
                                width: 14,
                                height: 14,
                                decoration: BoxDecoration(
                                  color: p.color,
                                  shape: BoxShape.circle,
                                ),
                              ),
                        label: Text(p.label),
                        labelStyle: TextStyle(
                          fontSize: 12,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isSelected
                              ? scheme.onSecondaryContainer
                              : scheme.onSurfaceVariant,
                        ),
                        selectedColor: scheme.secondaryContainer,
                        backgroundColor: scheme.surface,
                        side: BorderSide(
                          color: isSelected
                              ? scheme.primary
                              : scheme.outlineVariant,
                          width: isSelected ? 1.5 : 1,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(100),
                        ),
                        onSelected: (_) {
                          ref
                              .read(themePresetControllerProvider.notifier)
                              .setPreset(p);
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // ─── Section 2: AI Intelligence (BYOK Status Card) ───
          _buildSectionHeader('AI Intelligence', Icons.auto_awesome, theme),
          Card(
            color: scheme.surfaceContainer,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            elevation: 0,
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.key_rounded,
                        size: 20,
                        color: isGeminiConfigured
                            ? scheme.primary
                            : scheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Google Gemini',
                          style: (textTheme.titleMedium ??
                                  const TextStyle(fontSize: 15))
                              .copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isGeminiConfigured
                              ? scheme.primaryContainer
                              : scheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isGeminiConfigured
                                  ? Icons.check_circle_rounded
                                  : Icons.info_outline_rounded,
                              size: 13,
                              color: isGeminiConfigured
                                  ? scheme.onPrimaryContainer
                                  : scheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isGeminiConfigured
                                  ? 'Connected'
                                  : 'Not configured',
                              style: (textTheme.labelSmall ??
                                      const TextStyle(fontSize: 11))
                                  .copyWith(
                                color: isGeminiConfigured
                                    ? scheme.onPrimaryContainer
                                    : scheme.onSurfaceVariant,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isGeminiConfigured
                        ? 'Summaries, key takeaways, categories, and tags are generated using your Gemini API key.'
                        : 'Add your Gemini API key to enable AI-powered summaries, categories, and tags.',
                    style: (textTheme.bodySmall ?? const TextStyle(fontSize: 12))
                        .copyWith(
                      color: scheme.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (isGeminiConfigured) ...[
                    Divider(color: scheme.outlineVariant, height: 1),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () => GeminiConfigSheet.show(
                        context,
                        isConfigured: true,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 4,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.lock_rounded,
                              size: 18,
                              color: scheme.primary,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'API key',
                                    style: (textTheme.titleSmall ??
                                            const TextStyle(fontSize: 14))
                                        .copyWith(fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Stored securely on this device',
                                    style: (textTheme.bodySmall ??
                                            const TextStyle(fontSize: 12))
                                        .copyWith(
                                      color: scheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.chevron_right_rounded,
                              color: scheme.onSurfaceVariant,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ] else ...[
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () => GeminiConfigSheet.show(
                          context,
                          isConfigured: false,
                        ),
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: const Text('Configure'),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // ─── Section 3: Notifications ───
          _buildSectionHeader('Notifications', Icons.notifications_outlined, theme),
          Card(
            color: scheme.surfaceContainer,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            elevation: 0,
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      'Weekly Digest Notification',
                      style: (textTheme.titleSmall ?? const TextStyle(fontSize: 14)).copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      'Receive a gentle summary of unread bookmarks saved during the week.',
                      style: (textTheme.bodySmall ?? const TextStyle(fontSize: 12)).copyWith(
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
                    Divider(color: scheme.outlineVariant, height: 20),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        Icons.schedule_rounded,
                        color: scheme.primary,
                      ),
                      title: Text(
                        'Delivery Schedule',
                        style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        'Every ${DigestSettings.dayName(digestSettings.dayOfWeek)} at ${digestSettings.hour.toString().padLeft(2, '0')}:${digestSettings.minute.toString().padLeft(2, '0')}',
                        style: textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                      ),
                      trailing: Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
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

          const SizedBox(height: 24),

          // ─── Section 4: Export & Backup ───
          _buildSectionHeader('Export & Backup', Icons.ios_share_rounded, theme),
          Card(
            color: scheme.surfaceContainer,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            elevation: 0,
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      width: 40,
                      height: 40,
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
                    title: Text(
                      'Export as Markdown (.md)',
                      style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      'Formatted for Obsidian, Notion & Bear',
                      style: textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                    trailing: Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
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
                  Divider(color: scheme.outlineVariant, height: 1),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      width: 40,
                      height: 40,
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
                    title: Text(
                      'Export as JSON (.json)',
                      style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      'Full raw structured backup with metadata',
                      style: textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                    trailing: Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
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

          const SizedBox(height: 24),

          // ─── Section 5: Privacy & Local Storage ───
          _buildSectionHeader('Storage & Privacy', Icons.shield_outlined, theme),
          Card(
            color: scheme.surfaceContainer,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            elevation: 0,
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: scheme.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.lock_outline_rounded,
                      color: scheme.onPrimaryContainer,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '100% Local & Private',
                          style: (textTheme.titleSmall ?? const TextStyle(fontSize: 14)).copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'All saved links, raw content, and AI summaries reside locally on your device inside SQLite.',
                          style: (textTheme.bodySmall ?? const TextStyle(fontSize: 12)).copyWith(
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
