import 'dart:developer';
import 'package:faltometro_ufrgs/src/course.dart';
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
    log('[NOTIFICATIONS] initalizing notification service');
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('America/Sao_Paulo'));
    _plugin = AndroidFlutterLocalNotificationsPlugin();
    await _plugin.initialize(_initializationSettings);
  }

  /// Checks if the app has permission to send push notifications. This function
  /// assumes that notifications are enabled in settings. In the lack of
  /// permissions, it will spawn a gentle dialog that asks for permissions.
  /// Shall the user deny them, it will also change the app settings to opt out
  /// of notifications. If permissions are enabled (or were enabled during its
  /// course), it will return true. If permissions were denied (and therefore
  /// disabled in Settings), it will return false.
  static Future<bool> checkPermissions(BuildContext context) async {
    assert (Settings.notificationsEnabled);
    log('[NOTIFICATIONS] checking for notification permissions');

    final permission = await Permission.notification.status;

    // Notifications are enabled in settings, but we lack permissions to send
    // them. The permission is "denied" when user has never been prompted about
    // wheter they consent with the permission or not; in other words it's the
    // default state for when the app has just been installed.
    if (permission.isDenied) {
      if (! context.mounted) { return false; }
      final userWantsToGrantPermission = await showDialog<bool>(
          context: context,
          builder: (context) => const NotificationRequestDialog()
      );

      // User has confirmed the in-app dialog. Now, show the system dialog.
      if (userWantsToGrantPermission == true) {
        final granted = await _plugin.requestNotificationsPermission();

        if (granted == true && context.mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(_notificationsEnabledSnackbar);
          return true;
        }

        // User ended up refusing the notifications permission, therefore we
        // change the settings to never notify.
        else {
          Settings.setNotificationFrequency(NotificationFrequency.never);
          if (context.mounted) {
            ScaffoldMessenger.of(context)
                .showSnackBar(_notificationsDisabledSnackbar);
          }
          return false;
        }
      }

      // Same as before, user closed the dialog so we opt out of notifications.
      else {
        Settings.setNotificationFrequency(NotificationFrequency.never);
        if (context.mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(_notificationsDisabledSnackbar);
        }
        return false;
      }
    }

    // If user has rejected the permission prompt, this permission will turn
    // "permanently denied". In this case, we can't invoke new permission
    // requests. However, user may still manually grant the permission in the
    // app settings.
    if (permission.isPermanentlyDenied) {
      Settings.setNotificationFrequency(NotificationFrequency.never);
      if (context.mounted) {
        showDialog(
            context: context,
            builder: (context) => const PermissionPermanentlyDeniedDialog()
        );
      }
      return false;
    }

    assert (permission.isGranted);
    return true;
  }

  /// Makes sure that the notifications are properly scheduled according to what
  /// is configured in [Settings] module.
  static void updateSchedules() async {
    log('[NOTIFICATIONS] updating notification schedules');

    // We start by erasing all living schedules.
    final registeredNotifications = await _plugin.pendingNotificationRequests();
    for (final notification in registeredNotifications) {
      _plugin.cancel(notification.id);
    }

    if (Courses.courses.isEmpty) {
      log('[NOTIFICATIONS] cleared schedules as no courses are registered');
      return;
    }

    switch (Settings.notificationFrequency) {
      case NotificationFrequency.never:
      // If that's the case, we're good.
        log('[NOTIFICATIONS] notifications were disabled');
        break;

      case NotificationFrequency.weekly:
        _scheduleWeeklyNotifications();
        break;

      case NotificationFrequency.classDays:
      // TODO
        break;
    }
  }

  /// Registers scheduled notifications to be shown on Fridays at 8pm. This
  /// registration will live permanently, even if the app is closed (so it
  /// should be called only once by the registration time). The notifications
  /// are aimed to be delivered on Fridays at 8pm.
  static void _scheduleWeeklyNotifications() {
    log('[NOTIFICATIONS] scheduling weekly notifications');
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
