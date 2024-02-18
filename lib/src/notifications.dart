import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class Notifications {
  static late final AndroidFlutterLocalNotificationsPlugin _plugin;

  static Future<void> initialize() async {
    _plugin = AndroidFlutterLocalNotificationsPlugin();
    await _plugin.initialize(_initializationSettings);
    // TODO: gently ask for notification permissions for Android 13 or higher.
  }

  static void sendTestNotification() {
    _plugin.show(0, 'title', 'body', notificationDetails: _notificationDetails);
  }
}

const _initializationSettings = AndroidInitializationSettings(
    'notification_icon'
);
const _notificationDetails = AndroidNotificationDetails(
    'channelId', 'channelName'
);
