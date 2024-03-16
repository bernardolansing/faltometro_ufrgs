import 'package:faltometro_ufrgs/src/course.dart';
import 'package:faltometro_ufrgs/src/notifications.dart';
import 'package:faltometro_ufrgs/src/settings.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

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
          builder: (context) => const _InvalidNotificationPermissionsDialog()
      );
    }
    setState(() {});
  }

  void _openRemoveAllCoursesConfirmationDialog() async {
    final answer = await showDialog<bool>(
        context: context,
        builder: (context) => const _RemoveAllCoursesConfirmationDialog()
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
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Configurações')),
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Notificações', style: _sectionTitleTextStyle),
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
              ),
            )),
            const SizedBox(height: 8),

            Text('Fim de semestre', style: _sectionTitleTextStyle),
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

  TextStyle get _sectionTitleTextStyle => TextStyle(
    color: Theme.of(context).colorScheme.primary,
    fontSize: 18,
    fontWeight: FontWeight.w600,
  );
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
