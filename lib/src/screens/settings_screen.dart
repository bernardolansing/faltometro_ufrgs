import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final sectionTitleTextStyle = TextStyle(
      color: Theme.of(context).colorScheme.primary,
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
              ListTile(
                title: const Text('Nos dias em que tenho aula'),
                contentPadding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
                leading: Radio(
                  value: 'a',
                  groupValue: 'b',
                  onChanged: (value) {},
                ),
              ),
              ListTile(
                title: const Text('Semanalmente'),
                contentPadding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
                leading: Radio(
                  value: 'b',
                  groupValue: 'b',
                  onChanged: (value) {},
                ),
              ),
            ]
        ),
      ),
    );
  }
}
