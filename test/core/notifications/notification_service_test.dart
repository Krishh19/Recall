import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:recall/core/notifications/notification_service.dart';
import 'package:recall/features/home/home_providers.dart';
import 'package:recall/features/settings/digest_settings.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

void main() {
  setUpAll(() {
    tz.initializeTimeZones();
  });

  group('DigestSettings', () {
    test('serializes and deserializes correctly', () {
      const settings = DigestSettings(
        enabled: true,
        dayOfWeek: 5,
        hour: 20,
        minute: 30,
      );

      final json = settings.toJson();
      final parsed = DigestSettings.fromJson(json);

      expect(parsed.enabled, true);
      expect(parsed.dayOfWeek, 5);
      expect(parsed.hour, 20);
      expect(parsed.minute, 30);
      expect(parsed, equals(settings));
    });

    test('copyWith modifies specified fields', () {
      const initial = DigestSettings();
      final updated = initial.copyWith(enabled: false, hour: 10);

      expect(updated.enabled, false);
      expect(updated.dayOfWeek, initial.dayOfWeek);
      expect(updated.hour, 10);
      expect(updated.minute, initial.minute);
    });
  });

  group('NotificationService', () {
    test('calculateNextOccurrence computes correct upcoming target time', () {
      final location = tz.getLocation('UTC');
      // Tuesday at 10:00 AM
      final now = tz.TZDateTime(location, 2026, 8, 18, 10, 0);

      // Target: Sunday (7) at 18:00
      final nextSunday = NotificationService.calculateNextOccurrence(
        now: now,
        targetDayOfWeek: 7,
        targetHour: 18,
        targetMinute: 0,
      );

      expect(nextSunday.weekday, DateTime.sunday);
      expect(nextSunday.hour, 18);
      expect(nextSunday.minute, 0);
      expect(nextSunday.isAfter(now), true);
      expect(nextSunday.day, 23); // Aug 23, 2026 is Sunday
    });

    test('calculateNextOccurrence schedules for next week if time today has passed', () {
      final location = tz.getLocation('UTC');
      // Sunday at 19:00 PM
      final now = tz.TZDateTime(location, 2026, 8, 23, 19, 0);

      // Target: Sunday (7) at 18:00 (which was 1 hour ago)
      final nextOccurrence = NotificationService.calculateNextOccurrence(
        now: now,
        targetDayOfWeek: 7,
        targetHour: 18,
        targetMinute: 0,
      );

      expect(nextOccurrence.weekday, DateTime.sunday);
      expect(nextOccurrence.hour, 18);
      expect(nextOccurrence.day, 30); // Next Sunday (Aug 30)
      expect(nextOccurrence.isAfter(now), true);
    });

    test('onSelectUnread triggers unreadOnly filter update', () {
      final container = ProviderContainer();
      expect(container.read(unreadOnlyFilterProvider), false);

      var didCall = false;
      final service = NotificationService(
        onSelectUnread: () {
          didCall = true;
          container.read(unreadOnlyFilterProvider.notifier).setUnreadOnly(true);
        },
      );

      service.onSelectUnread?.call();

      expect(didCall, true);
      expect(container.read(unreadOnlyFilterProvider), true);

      // Toggle off
      container.read(unreadOnlyFilterProvider.notifier).toggle();
      expect(container.read(unreadOnlyFilterProvider), false);
    });
  });
}
