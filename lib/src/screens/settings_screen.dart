import 'package:faltometro_ufrgs/src/settings.dart';
import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  void _applyNotificationFrequency(NotificationFrequency? nf) {
    // nf is nullable in order to match the Radio's onChanged attribute type.
    // It's guaranteed to be non null though.
    Settings.setNotificationFrequency(nf!);
    setState(() {});
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
            ))
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
