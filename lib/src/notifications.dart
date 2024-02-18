import 'package:faltometro_ufrgs/src/screens/notification_request_dialog.dart';
import 'package:faltometro_ufrgs/src/settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class Notifications {
  static late final AndroidFlutterLocalNotificationsPlugin _plugin;

  static Future<void> initialize(BuildContext context) async {
    _plugin = AndroidFlutterLocalNotificationsPlugin();
    await _plugin.initialize(_initializationSettings);
    final permissionIsGranted = await _plugin.areNotificationsEnabled();
    final shouldSendNotifications =
        Settings.notificationFrequency != NotificationFrequency.never;

    // Notifications are enabled in settings, but we lack permissions to send
    // them.
    if (permissionIsGranted != true && shouldSendNotifications) {
      if (! context.mounted) { return; }
      final userWantsToGrantPermission = await showDialog<bool>(
          context: context,
          builder: (context) => const NotificationRequestDialog()
      );
      
      if (userWantsToGrantPermission == true) {
        // TODO: find a way to request permission again once user has refused it
        // previously.
        final granted = await _plugin.requestNotificationsPermission();

        if (granted == true && context.mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(_notificationsEnabledSnackbar);
        }

        // User ended up refusing the notifications permission, therefore we
        // change the settings to never notify.
        else {
          Settings.setNotificationFrequency(NotificationFrequency.never);
          if (context.mounted) {
            ScaffoldMessenger.of(context)
                .showSnackBar(_notificationsDisabledSnackbar);
          }
        }
      }

      // Same as before, user closed the dialog so we opt out of notifications.
      else {
        Settings.setNotificationFrequency(NotificationFrequency.never);
        if (context.mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(_notificationsDisabledSnackbar);
        }
      }
    }
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

const _notificationsEnabledSnackbar = SnackBar(
    content: Text('As notificações estarão habilitadas!')
);

const _notificationsDisabledSnackbar = SnackBar(
  content: Text('As notificações estarão desativadas.'),
);
