import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../settings_manager.dart';
import '../courses_manager.dart';
import '../models/settings.dart';
import '../notifications.dart';
import '../theme.dart';
import '../widgets/notification_permission_dialogs.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  void _applyNotificationFrequency(NotificationFrequency? nf) async {
    // nf is nullable in order to match the Radio's onChanged attribute type.
    // It's guaranteed to be non null though.

    // If we're about to disable notifications, we don't have to worry about
    // permissions.
    if (nf == NotificationFrequency.never) {
      SettingsManager.disableNotifications();
      setState(() {
        Notifications.updateSchedules();
      });
    }
    else {
      // If notifications are to be enabled, however, we do.
      bool permissionsOkay = await Notifications.checkPermissions();
      if (! permissionsOkay) {
        try {
          await Notifications.askPermissions();
          permissionsOkay = true;
        }
        on NotificationPermissionDenied catch (denial) {
          SettingsManager.disableNotifications();
          if (mounted) {
            if (denial.weCanAskAgain) {
              ScaffoldMessenger.of(context)
                  .showSnackBar(_notificationPermissionDeniedSnackbar);
            }
            else {
              showDialog(
                  context: context,
                  builder: (context) {
                    return const NotificationPermissionDefinitelyDeniedDialog();
                  }
              );
            }
          }

          return;
        }
      }

      if (permissionsOkay && mounted) {
        setState(() {
          SettingsManager.setNotificationFrequency(nf!);
          Notifications.updateSchedules();
        });
      }
    }
  }

  void _applyThemeMode(ThemeMode? mode) {
    setState(() {
      SettingsManager.setThemeMode(mode!);
      ThemeModeChangedNotification().dispatch(context);
    });
  }

  void _openRemoveAllCoursesConfirmationDialog() async {
    final answer = await showDialog<bool>(
      context: context,
      builder: (context) => const _RemoveAllCoursesConfirmationDialog(),
    );

    // If user has confirmed the deletion of all courses, we may exit the
    // settings screen and wish them some nice vacations:
    if (answer == true && mounted) {
      const deletionConfirmedSnackbar = SnackBar(
        content: Text('Aproveite as férias :)'),
      );
      ScaffoldMessenger.of(context).showSnackBar(deletionConfirmedSnackbar);
      Navigator.of(context).pop(true); // Pop true to indicate that Homepage
      // needs to be refreshed.
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final highlightColor = theme.brightness == Brightness.light
        ? theme.colorScheme.primary
        : theme.colorScheme.secondary;
    final sectionTitleTextStyle = TextStyle(
      color: highlightColor,
      fontSize: 18,
      fontWeight: FontWeight.w600,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Configurações')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Notificações', style: sectionTitleTextStyle),
              const Text('Lembrar-me de registrar minhas faltas:'),
              RadioGroup(
                groupValue: SettingsManager.notificationFrequency,
                onChanged: _applyNotificationFrequency,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: NotificationFrequency.values.map((option) =>
                      RadioListTile(
                        value: option,
                        contentPadding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                        activeColor: highlightColor,
                        title: _notificationFrequencyLabels[option],
                      ))
                      .toList(),
                ),
              ),

              const SizedBox(height: 8),

              Text('Tema', style: sectionTitleTextStyle),
              RadioGroup(
                groupValue: SettingsManager.themeMode,
                onChanged: _applyThemeMode,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: ThemeMode.values.map((mode) => RadioListTile(
                    value: mode,
                    contentPadding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                    activeColor: highlightColor,
                    title: _themeModeLabels[mode],
                  ))
                  .toList(),
                ),
              ),

              const SizedBox(height: 8),

              Text('Fim de semestre', style: sectionTitleTextStyle),
              ListTile(
                leading: const Padding(
                  padding: EdgeInsets.only(right: 12),
                  child: Icon(PhosphorIconsRegular.trash),
                ),
                title: const Text('Remover todas as disciplinas'),
                visualDensity: VisualDensity.compact,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                enabled: CoursesManager.courses.isNotEmpty,
                onTap: _openRemoveAllCoursesConfirmationDialog,
              ),
            ],
          ),
        ),
      ),
    );
  }

  static const _notificationFrequencyLabels = {
    NotificationFrequency.never: Text('Nunca'),
    NotificationFrequency.weekly: Text('Semanalmente'),
    NotificationFrequency.classDays: Text('Nos dias em que tenho aula'),
  };

  static const _themeModeLabels = {
    ThemeMode.system: Text('Padrão do sistema'),
    ThemeMode.light: Text('Claro'),
    ThemeMode.dark: Text('Escuro'),
  };

  static const _notificationPermissionDeniedSnackbar = SnackBar(
    content: Text('Você negou as permissões, tente novamente.'),
  );
}

class _RemoveAllCoursesConfirmationDialog extends StatelessWidget {
  const _RemoveAllCoursesConfirmationDialog();

  void _removeAllCourses(BuildContext context) {
    CoursesManager.deleteAllCourses();
    Notifications.updateSchedules();
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Remover todas as disciplinas?'),
    actions: [
      TextButton(
        onPressed: Navigator.of(context).pop,
        child: const Text('Cancelar'),
      ),

      ElevatedButton(
        onPressed: () => _removeAllCourses(context),
        child: const Text('Confirmar'),
      ),
    ],
  );
}
