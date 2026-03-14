import 'dart:developer';

import 'package:flutter/material.dart';

import 'models/settings.dart';
import 'notifications.dart';
import 'storage_manager.dart';
import 'theme.dart';

class SettingsManager {
  static final _storageEntry = StorageManager
      .getEntry('settings', SettingsJsonConverter());
  static late final Settings _settings;

  static NotificationFrequency get notificationFrequency =>
      _settings.notificationFrequency;
  static ThemeMode get themeMode => _settings.themeMode;
  /// `true` if the app is supposed to send notifications at some point.
  static bool get notificationsEnabled =>
      notificationFrequency != NotificationFrequency.never;

  /// Depends on [StorageManager] being already initialized.
  static Future<void> initialize() async {
    try {
      log('[SettingsManager] loading settings now');
      _settings = await _storageEntry.load();
    }
    on MissingStorageEntry {
      log('[SettingsManager] settings were not initialized, loading defaults');
      _settings = Settings.defaultSettings;
    }
    catch (error, stackTrace) {
      log(
        '[SettingsManager] error while loading settings: $error',
        stackTrace: stackTrace,
      );
      _settings = Settings.defaultSettings;
    }
  }

  static void setNotificationFrequency(NotificationFrequency freq) {
    if (freq != _settings.notificationFrequency) {
      log('[SettingsManager] updating notification frequency');
      _settings.notificationFrequency = freq;
      Notifications.updateSchedules();
      _storageEntry.store(_settings);
    }
  }

  static void setThemeMode(BuildContext context, ThemeMode mode) {
    if (mode != _settings.themeMode) {
      log('[SettingsManager] updating theme mode');
      _settings.themeMode = mode;
      _storageEntry.store(_settings);
      ThemeModeChangedNotification().dispatch(context);
    }
  }
}
