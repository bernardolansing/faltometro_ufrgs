import 'dart:developer';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'settings_manager.dart';
import 'courses_manager.dart';
import 'models/settings.dart';

class Notifications {
  static late final AndroidFlutterLocalNotificationsPlugin _plugin;

  /// Initializes the Notifications plugin without worrying about permissions.
  static Future<void> initialize() async {
    log('[Notifications] initalizing notification service');
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('America/Sao_Paulo'));
    _plugin = AndroidFlutterLocalNotificationsPlugin();
    await _plugin.initialize(_initializationSettings);
  }

  /// Returns `true` if we have permission to dispatch push notifications.
  static Future<bool> checkPermissions() async {
    final granted = await Permission.notification.isGranted;
    log('[Notifications] notifications permission granted: $granted');
    return granted;
  }

  static Future<void> askPermissions() async {
    log('[Notifications] prompting for notifications permission');
    final granted = await _plugin.requestNotificationsPermission();

    if (granted != true) {
      final status = await Permission.notification.status;
      if (status.isDenied) {
        log('[Notifications] permissions were denied, but we can ask again');
        throw const NotificationPermissionDenied(true);
      }
      else if (status.isPermanentlyDenied) {
        log("[Notifications] permissions were denied and we're unable to "
            'prompt for them further');
        throw const NotificationPermissionDenied(false);
      }
    }

    log('[Notifications] permissions were successfully granted');
  }

  /// Makes sure that the notifications are properly scheduled according to what
  /// is configured in [Settings] module. Make sure that [checkPermissions]
  /// returned `true` before calling.
  static Future<void> updateSchedules() async {
    log('[Notifications] updating notification schedules');

    // We start by erasing all living schedules.
    final registeredNotifications = await _plugin.pendingNotificationRequests();
    for (final notification in registeredNotifications) {
      _plugin.cancel(notification.id);
    }

    if (CoursesManager.courses.isEmpty) {
      log('[Notifications] cleared schedules as no courses are registered');
      return;
    }

    switch (SettingsManager.notificationFrequency) {
      case NotificationFrequency.never:
      // If that's the case, we're good as we've just unscheduled all
      // notifications.
        log('[Notifications] notifications were disabled');
        break;

      case NotificationFrequency.weekly:
        await _scheduleWeeklyNotifications();
        break;

      case NotificationFrequency.classDays:
        await _scheduleClassDaysNotifications();
        break;
    }
  }

  /// Registers scheduled notifications to be shown on Fridays at 8pm. This
  /// registration will live permanently, even if the app is closed (so it
  /// should be called only once at registration time). The notifications are
  /// aimed to be delivered on Fridays at 8pm. If notification permissions
  /// problems are detected, throws [InvalidNotificationPermissions].
  static Future<void> _scheduleWeeklyNotifications() async {
    log('[Notifications] scheduling weekly notifications');
    const title = 'Faltou essa semana?';
    const body = 'Não esqueça de registrar suas faltas.';

    await _ensurePermissions();

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

  /// Registers scheduled notifications to be emitted at 8pm of every day the
  /// student has classes. If notification permissions problems are detected,
  /// throws [InvalidNotificationPermissions].
  static Future<void> _scheduleClassDaysNotifications() async {
    log('[Notifications] scheduling class days notifications');
    const title = 'Faltou hoje?';
    const body = 'Não esqueça de registrar.';

    await _ensurePermissions();

    // Create the schedule date object:
    tz.TZDateTime schedule = tz.TZDateTime.now(tz.local);
    // Round up to the next hour:
    schedule = schedule.add(Duration(minutes: 60 - schedule.minute));
    // Increment until it's 8pm:
    while (schedule.hour != 20) {
      schedule = schedule.add(const Duration(hours: 1));
    }

    // Progressively update the date object until it matches every class
    // weekday.
    for (final weekday in CoursesManager.weekdaysWithClass) {
      // We add 1 because tz considers that the week starts by Monday and the
      // week is 1-indexed.
      while (schedule.weekday != weekday + 1) {
        schedule = schedule.add(const Duration(days: 1));
      }

      // Invoke the scheduling:
      _plugin.zonedSchedule(weekday, title, body, schedule,
          _notificationDetails, scheduleMode: AndroidScheduleMode.inexact,
          matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime);
    }
  }

  /// Quietly makes sure that permissions are okay. On the contrary of
  /// [checkPermissions()], this function is used to certify that the
  /// permissions are okay, and throws [InvalidNotificationPermissions] if they
  /// are not. This should only happen in the event that the user manually
  /// revoked the notifications of the app.
  static Future<void> _ensurePermissions() async {
    final permission = await Permission.notification.status;
    if (! permission.isGranted) {
      log('[Notifications] tried to schedule notifications, but the app '
          'permission seems to have been manually revoked.');
      throw NotificationPermissionDenied(! permission.isPermanentlyDenied);
    }
  }
}

/// Thrown when we wanted to prompt for notification permission but user/OS
/// denied our request. Contains a field `weCanAskAgain` for checking if we may
/// as for permissions again.
class NotificationPermissionDenied implements Exception {
  /// If `false`, asking for permissions again is useless as we are blocked by
  /// the OS from requesting them.
  final bool weCanAskAgain;

  const NotificationPermissionDenied(this.weCanAskAgain);
}

const _initializationSettings = AndroidInitializationSettings(
    'notification_icon'
);

const _notificationDetails = AndroidNotificationDetails(
    'report-absences-reminder', 'Lembrete para registrar faltas'
);