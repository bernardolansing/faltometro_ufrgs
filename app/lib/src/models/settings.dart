import 'package:flutter/material.dart';

import '../storage_manager.dart';

class Settings {
  static Settings get defaultSettings => Settings(
    notificationFrequency: NotificationFrequency.weekly,
    themeMode: ThemeMode.system,
  );

  NotificationFrequency notificationFrequency;
  ThemeMode themeMode;

  Settings({
    required this.notificationFrequency,
    required this.themeMode,
  });
}

enum NotificationFrequency {
  never,
  weekly,
  classDays,
}

class SettingsJsonConverter implements JsonConverter<Settings> {
  @override
  Settings fromJson(json) => Settings(
    notificationFrequency: NotificationFrequency.values
        .byName(json['notificationFrequency']),
    themeMode: ThemeMode.values.byName(json['themeMode']),
  );

  @override
  toJson(Settings entry) => {
    'notificationFrequency': entry.notificationFrequency.name,
    'themeMode': entry.themeMode.name,
  };
}
