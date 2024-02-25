import 'dart:developer';
import 'package:faltometro_ufrgs/src/screens/notification_request_dialog.dart';
import 'package:faltometro_ufrgs/src/settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class Notifications {
  static late final AndroidFlutterLocalNotificationsPlugin _plugin;

  /// Initializes the Notifications plugin without worrying about permissions.
  static Future<void> initialize() async {
    log('Initalizing notification service');
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('America/Sao_Paulo'));
    _plugin = AndroidFlutterLocalNotificationsPlugin();
    await _plugin.initialize(_initializationSettings);
  }

  /// Checks if the app is set up to send notifications. If it does, checks if
  /// app has permission to do so. In the lack of permissions, it will spawn
  /// a gentle dialog that asks for permissions. Shall the user deny them, it
  /// will also change the app settings to opt out of notifications.
  static Future<void> checkPermissions(BuildContext context) async {
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

  /// Registers scheduled notifications to be shown on Fridays at 8pm. This
  /// registration will live permanently, even if the app is closed (so it
  /// should be called only once by the registration time). The notifications
  /// are aimed to be delivered on Fridays at 8pm.
  static void enableWeeklyNotifications() {
    log('Scheduling weekly notifications');
    const title = 'Faltou essa semana?';
    const body = 'Não esqueça de registrar suas faltas.';

    // Mount the schedule. This is a DateTime-like object that represents the
    // time and date in which the next notification will show up.
    tz.TZDateTime schedule = tz.TZDateTime.now(tz.local);
    // Round up to the next hour:
    schedule = schedule.add(Duration(minutes: 60 - schedule.minute));
    // Increment the date object until it's 8pm.
    while (schedule.hour != 20) {
      schedule = schedule.add(const Duration(hours: 1));
    }
    // Increment the date object until it's Friday.
    while (schedule.weekday != 5) {
      schedule = schedule.add(const Duration(days: 1));
    }

    // Effectively register the notifications.
    _plugin.zonedSchedule(0, title, body, schedule, _notificationDetails,
        scheduleMode: AndroidScheduleMode.inexact,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime);
  }

  /// Revoke the subscription of notifications.
  static Future<void> disableNotifications() async {
    log('Revoking the subscription of all notifications');
    final registeredNotifications = await _plugin.pendingNotificationRequests();
    for (final notification in registeredNotifications) {
      _plugin.cancel(notification.id);
    }
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
