import 'package:flutter/foundation.dart';

/// User configuration preferences for the weekly unread digest notification.
@immutable
class DigestSettings {
  /// Creates a [DigestSettings] configuration.
  const DigestSettings({
    this.enabled = true,
    this.dayOfWeek = 7, // Sunday
    this.hour = 18, // 6:00 PM
    this.minute = 0,
  });

  /// Whether weekly digest notifications are enabled.
  final bool enabled;

  /// Day of week (1 = Monday, 7 = Sunday) when digest is delivered.
  final int dayOfWeek;

  /// Hour of day (0-23) in 24-hour format.
  final int hour;

  /// Minute of hour (0-59).
  final int minute;

  /// Returns English day name for the given weekday index (1=Monday, 7=Sunday).
  static String dayName(int day) {
    const days = [
      '',
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    if (day >= 1 && day <= 7) return days[day];
    return 'Sunday';
  }

  /// Creates a copy of [DigestSettings] with the specified fields replaced.
  DigestSettings copyWith({
    bool? enabled,
    int? dayOfWeek,
    int? hour,
    int? minute,
  }) {
    return DigestSettings(
      enabled: enabled ?? this.enabled,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
    );
  }

  /// Converts this configuration to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'enabled': enabled,
      'dayOfWeek': dayOfWeek,
      'hour': hour,
      'minute': minute,
    };
  }

  /// Deserializes a [DigestSettings] from JSON.
  factory DigestSettings.fromJson(Map<String, dynamic> json) {
    return DigestSettings(
      enabled: json['enabled'] as bool? ?? true,
      dayOfWeek: json['dayOfWeek'] as int? ?? 7,
      hour: json['hour'] as int? ?? 18,
      minute: json['minute'] as int? ?? 0,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DigestSettings &&
          runtimeType == other.runtimeType &&
          enabled == other.enabled &&
          dayOfWeek == other.dayOfWeek &&
          hour == other.hour &&
          minute == other.minute;

  @override
  int get hashCode => Object.hash(enabled, dayOfWeek, hour, minute);
}
