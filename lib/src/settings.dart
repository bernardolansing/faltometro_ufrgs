import 'dart:developer';

import 'package:faltometro_ufrgs/src/theme.dart';
import 'package:flutter/material.dart';

import 'notifications.dart';
import 'storage.dart';

const _defaultNotificationFrequency = NotificationFrequency.weekly;
const _defaultThemeMode = ThemeMode.system;

class Settings {
  static bool _initialized = false;

  // Declare every setting with its default value. We will then try to load the
  // stored settings, but that might fail, so we need a backdoor.
  static NotificationFrequency _notificationFrequency =
      _defaultNotificationFrequency;
  static ThemeMode _themeMode = _defaultThemeMode;


  /// Loads the stored settings from the local storage.
  static void load() {
    assert (! _initialized);
    try {
      _notificationFrequency = NotificationFrequency.values
          .byName(Storage.settingsEntry['notificationFrequency'] as String);
      _themeMode = ThemeMode.values
          .byName(Storage.settingsEntry['themeMode'] as String);
    }
    catch (error) {
      log('Error while loading settings from local storage: $error');
      Storage.saveSettings(); // Will save the defaults to the file.
    }
    _initialized = true;
  }

  static Map<String, String> get storageEntry => {
    'notificationFrequency': _notificationFrequency.name,
    'themeMode': _themeMode.name,
  };

  static NotificationFrequency get notificationFrequency {
    assert (_initialized);
    return _notificationFrequency;
  }

  /// True if we should send notifications at some moment.
  static bool get notificationsEnabled =>
      _notificationFrequency != NotificationFrequency.never;

  static ThemeMode get themeMode {
    assert (_initialized);
    return _themeMode;
  }

  static Future<void> setNotificationFrequency(
      NotificationFrequency frequency) async {
    if (frequency != _notificationFrequency) {
      _notificationFrequency = frequency;
      await Notifications.updateSchedules();
      Storage.saveSettings();
    }
  }

  static void setThemeMode(BuildContext context, ThemeMode mode) {
    if (_themeMode != mode) {
      log('[SETTINGS] setting theme mode to $mode');
      ThemeModeChangedNotification().dispatch(context);
      _themeMode = mode;
      Storage.saveSettings();
    }
  }
}

enum NotificationFrequency {
  never('Nunca'),
  weekly('Semanalmente'),
  classDays('Nos dias em que tenho aula');

  /// The pretty text that will be displayed in the screen to refer to each
  /// variant.
  final String title;

  const NotificationFrequency(this.title);
}
