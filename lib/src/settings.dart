import 'dart:developer';
import 'storage.dart';

const _defaultNotificationFrequency = NotificationFrequency.weekly;

class Settings {
  static bool _initialized = false;

  // Declare every setting with its default value. We will then try to load the
  // stored settings, but that might fail, so we need a backdoor.
  static NotificationFrequency _notificationFrequency =
      _defaultNotificationFrequency;

  /// Loads the stored settings from the local storage.
  static void load() {
    assert (! _initialized);
    try {
      _notificationFrequency = NotificationFrequency.values
          .byName(Storage.settingsEntry['notificationFrequency'] as String);
    }
    catch (error) {
      log('Error while loading settings from local storage: $error');
      Storage.saveSettings(); // Will save the defaults to the file.
    }
    _initialized = true;
  }

  static Map<String, String> get storageEntry => {
    'notificationFrequency': _notificationFrequency.name,
  };

  static NotificationFrequency get notificationFrequency {
    assert (_initialized);
    return _notificationFrequency;
  }

  static void setNotificationFrequency(NotificationFrequency frequency) {
    if (frequency != _notificationFrequency) {
      _notificationFrequency = frequency;
      Storage.saveSettings();
    }
  }
}

enum NotificationFrequency {
  never,
  weekly,
  classDays,
}
