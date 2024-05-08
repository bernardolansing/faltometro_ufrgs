import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../course.dart';
import '../notifications.dart';
import '../settings.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  void _applyNotificationFrequency(NotificationFrequency? nf) async {
    // nf is nullable in order to match the Radio's onChanged attribute type.
    // It's guaranteed to be non null though.
    try {
      await Settings.setNotificationFrequency(nf!);
    }
    on InvalidNotificationPermissions {
      Settings.setNotificationFrequency(NotificationFrequency.never);
      if (! mounted) { return; }
      showDialog(
        context: context,
        builder: (context) => const _InvalidNotificationPermissionsDialog(),
      );
    }
    setState(() {});
  }

  void _applyThemeMode(ThemeMode mode) {
    setState(() {
      Settings.setThemeMode(context, mode);
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
          content: Text('Aproveite as férias :)')
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Notificações', style: sectionTitleTextStyle),
              const Text('Lembrar-me de registrar minhas faltas:'),
              ...NotificationFrequency.values.map((option) => ListTile(
                title: Text(option.title),
                contentPadding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
                onTap: () => _applyNotificationFrequency(option),
                leading: Radio(
                  value: option,
                  groupValue: Settings.notificationFrequency,
                  onChanged: _applyNotificationFrequency,
                  activeColor: highlightColor,
                ),
              )),
              const SizedBox(height: 8),

              Text('Tema', style: sectionTitleTextStyle),
              ...ThemeMode.values.map((mode) => ListTile(
                  title: Text(_themeModeLabels[mode]!),
                  contentPadding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                  onTap: () => _applyThemeMode(mode),
                  leading: Radio(
                    value: mode,
                    groupValue: Settings.themeMode,
                    onChanged: (_) => _applyThemeMode(mode),
                    activeColor: highlightColor,
                  )
              )),
              const SizedBox(height: 8),

              Text('Fim de semestre', style: sectionTitleTextStyle),
              ListTile(
                leading: Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: PhosphorIcon(PhosphorIcons.regular.trash),
                ),
                title: const Text('Remover todas as disciplinas'),
                visualDensity: VisualDensity.compact,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                enabled: Courses.courses.isNotEmpty,
                onTap: _openRemoveAllCoursesConfirmationDialog,
              ),
            ]
        ),
      ),
    );
  }

  static const _themeModeLabels = {
    ThemeMode.system: 'Padrão do sistema',
    ThemeMode.light: 'Claro',
    ThemeMode.dark: 'Escuro',
  };
}

class _InvalidNotificationPermissionsDialog extends StatelessWidget {
  const _InvalidNotificationPermissionsDialog();

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Erro ao configurar as notificações'),
    content: const Text(_contentText, textAlign: TextAlign.justify),
    actions: [
      TextButton(onPressed: Navigator.of(context).pop, child: const Text('Ok'))
    ],
  );

  static const _contentText = 'Aparentemente, o Faltômetro não tem permissão '
      'para exibir notificações. Por favor, habilite-as nas configurações '
      'do app antes.';
}

class _RemoveAllCoursesConfirmationDialog extends StatelessWidget {
  const _RemoveAllCoursesConfirmationDialog();

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Remover todas as disciplinas?'),
    actions: [
      TextButton(
        onPressed: Navigator.of(context).pop,
        child: const Text('Cancelar'),
      ),

      ElevatedButton(
        onPressed: () {
          Courses.deleteAllCourses();
          Navigator.of(context).pop(true);
        },
        child: const Text('Confirmar'),
      ),
    ],
  );
}
