import 'package:faltometro_ufrgs/src/screens/notification_request_dialog.dart';
import 'package:faltometro_ufrgs/src/settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

class Notifications {
  static late final AndroidFlutterLocalNotificationsPlugin _plugin;

  static Future<void> initialize(BuildContext context) async {
    _plugin = AndroidFlutterLocalNotificationsPlugin();
    await _plugin.initialize(_initializationSettings);
    final permission = await Permission.notification.status;
    final shouldSendNotifications =
        Settings.notificationFrequency != NotificationFrequency.never;

    // Notifications are enabled in settings, but we lack permissions to send
    // them. The permission is "denied" when user has never been prompted about
    // wheter they consent with the permission or not; in other words it's the
    // default state.
    if (permission.isDenied && shouldSendNotifications) {
      if (! context.mounted) { return; }
      final userWantsToGrantPermission = await showDialog<bool>(
          context: context,
          builder: (context) => const NotificationRequestDialog()
      );
      
      if (userWantsToGrantPermission == true) {
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

    // If user has rejected the permission prompt, this permission will turn
    // "permanently denied". In this case, we can't invoke new permission
    // requests. However, user may still manually grant the permission in the
    // app settings.
    if (permission.isPermanentlyDenied && shouldSendNotifications) {
      Settings.setNotificationFrequency(NotificationFrequency.never);
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) => const PermissionPermanentlyDeniedDialog()
        );
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
