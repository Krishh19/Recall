import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:recall/features/home/home_providers.dart';

part 'notification_service.g.dart';

/// Notification ID for the weekly digest.
const int kWeeklyDigestNotificationId = 777;

/// Notification channel ID for the weekly digest.
const String kWeeklyDigestChannelId = 'weekly_digest_channel';

/// Notification channel name.
const String kWeeklyDigestChannelName = 'Weekly Digest';

/// Notification channel description.
const String kWeeklyDigestChannelDesc =
    'Weekly reminders of unread links saved in Recall';

/// Service managing local notifications and digest scheduling.
class NotificationService {
  /// Creates a [NotificationService] with an optional plugin instance.
  NotificationService({
    FlutterLocalNotificationsPlugin? plugin,
    this.onSelectUnread,
  }) : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;

  /// Callback triggered when a digest notification is opened.
  final VoidCallback? onSelectUnread;

  bool _isInitialized = false;

  /// Initializes timezone and local notification plugin settings.
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      tz.initializeTimeZones();
    } catch (_) {
      // Timezone may already be initialized
    }

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const initSettings = InitializationSettings(android: androidSettings);

    await _plugin.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (response) {
        if (response.payload == 'unread') {
          onSelectUnread?.call();
        }
      },
    );

    _isInitialized = true;
  }

  /// Calculates the next [tz.TZDateTime] for a given [targetDayOfWeek] (1=Mon, 7=Sun)
  /// at [targetHour]:[targetMinute].
  static tz.TZDateTime calculateNextOccurrence({
    required tz.TZDateTime now,
    required int targetDayOfWeek,
    required int targetHour,
    required int targetMinute,
  }) {
    var scheduled = tz.TZDateTime(
      now.location,
      now.year,
      now.month,
      now.day,
      targetHour,
      targetMinute,
    );

    while (scheduled.weekday != targetDayOfWeek || scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    return scheduled;
  }

  /// Displays an immediate digest notification with [unreadCount].
  Future<void> showDigestNotification({required int unreadCount}) async {
    final title = 'Your Weekly Reading Digest';
    final body = unreadCount == 1
        ? 'You have 1 unread saved link from this past week.'
        : 'You have $unreadCount unread saved links from this past week.';

    const androidDetails = AndroidNotificationDetails(
      kWeeklyDigestChannelId,
      kWeeklyDigestChannelName,
      channelDescription: kWeeklyDigestChannelDesc,
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );

    const details = NotificationDetails(android: androidDetails);

    await _plugin.show(
      id: kWeeklyDigestNotificationId,
      title: title,
      body: body,
      notificationDetails: details,
      payload: 'unread',
    );
  }

  /// Schedules recurring weekly digest notification at [dayOfWeek] at [hour]:[minute].
  Future<void> scheduleWeeklyDigest({
    required int unreadCount,
    required int dayOfWeek,
    required int hour,
    required int minute,
  }) async {
    final now = tz.TZDateTime.now(tz.local);
    final scheduledDate = calculateNextOccurrence(
      now: now,
      targetDayOfWeek: dayOfWeek,
      targetHour: hour,
      targetMinute: minute,
    );

    final title = 'Your Weekly Reading Digest';
    final body = unreadCount == 1
        ? 'You have 1 unread saved link from this past week.'
        : 'You have $unreadCount unread saved links from this past week.';

    const androidDetails = AndroidNotificationDetails(
      kWeeklyDigestChannelId,
      kWeeklyDigestChannelName,
      channelDescription: kWeeklyDigestChannelDesc,
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );

    const details = NotificationDetails(android: androidDetails);

    await _plugin.zonedSchedule(
      id: kWeeklyDigestNotificationId,
      title: title,
      body: body,
      scheduledDate: scheduledDate,
      notificationDetails: details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      payload: 'unread',
    );
  }

  /// Cancels the scheduled weekly digest notification.
  Future<void> cancelDigestNotification() async {
    await _plugin.cancel(id: kWeeklyDigestNotificationId);
  }
}

/// Provides the singleton [NotificationService] configured to filter Home to unread on open.
@Riverpod(keepAlive: true)
NotificationService notificationService(Ref ref) {
  final service = NotificationService(
    onSelectUnread: () {
      ref.read(unreadOnlyFilterProvider.notifier).setUnreadOnly(true);
    },
  );
  if (!kIsWeb && Platform.isAndroid) {
    service.initialize();
  }
  return service;
}
