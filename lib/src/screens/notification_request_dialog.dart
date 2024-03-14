import 'package:flutter/material.dart';

/// A dialog that explains why we need notification permissions. It will pop
/// returning [true] if user agreed to grant permissions, or false/null
/// otherwise.
class NotificationRequestDialog extends StatelessWidget {
  const NotificationRequestDialog({super.key});

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Um minuto de sua atenção!'),
    content: const Text(_text, textAlign: TextAlign.justify),
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

  static const _text = 'O Faltômetro pode te enviar notificações para te '
      'lembrar de preencher suas faltas (você provavelmente vai esquecer de '
      'fazer isso sozinho 🙃). Para isso, precisamos da sua permissão. Se '
      'preferir não recebê-las, basta negar ou alterar as configurações mais '
      'tarde.';
}

class PermissionPermanentlyDeniedDialog extends StatelessWidget {
  const PermissionPermanentlyDeniedDialog({super.key});

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Erro de permissões'),
    content: const Text(_text),
    actions: [
      TextButton(
        onPressed: Navigator.of(context).pop,
        child: const Text('Ok'),
      )
    ],
  );

  static const _text = 'O Faltômetro não possui permissão para emitir '
      'notificações. Conceda as permissões na tela de configurações do '
      'aplicativo.';
}
