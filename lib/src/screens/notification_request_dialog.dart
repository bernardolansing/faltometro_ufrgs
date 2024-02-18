import 'package:flutter/material.dart';

/// A dialog that explains why we need notification permissions. It will pop
/// returning [true] if user agreed to grant permissions, or false/null
/// otherwise.
class NotificationRequestDialog extends StatelessWidget {
  const NotificationRequestDialog({super.key});

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Um minuto de sua atenção!'),
    content: const Text(_contentText, textAlign: TextAlign.justify),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(false),
        child: const Text('Ignorar'),
      ),

      ElevatedButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Dar permissão')
      ),
    ],
  );
}

const _contentText = 'O Faltômetro pode te enviar notificações para te lembrar '
    'de preencher suas faltas (você provavelmente vai esquecer de fazer isso '
    'sozinho 🙃). Para isso, precisamos da sua permissão. Se preferir não '
    'recebê-las, basta negar ou alterar as configurações mais tarde.';
