import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../storage.dart';

class RestaurantTicketWidget extends StatefulWidget {
  const RestaurantTicketWidget({super.key});

  @override
  State<RestaurantTicketWidget> createState() =>
      _RestaurantTicketWidgetState();
}

class _RestaurantTicketWidgetState extends State<RestaurantTicketWidget> {
  @override
  Widget build(BuildContext context) {
    if (Storage.restaurantTicket == null) {
      return TextButton.icon(
        icon: PhosphorIcon(PhosphorIcons.regular.plus, size: 20,),
        onPressed: () => showDialog(
          context: context,
          builder: (context) => const _SetTicketFormDialog(),
        ),
        label: const Text(
          'Adicionar\nticket RU',
          style: TextStyle(fontSize: 12),
        ),
      );
    }

    // TODO:
    return InkWell();
  }
}

// TODO
class _ManageTicketDialog extends StatelessWidget {
  const _ManageTicketDialog();

  @override
  Widget build(BuildContext context) => Container();
}

// TODO
class _SetTicketFormDialog extends StatefulWidget {
  const _SetTicketFormDialog();

  @override
  State<_SetTicketFormDialog> createState() =>
      _SetTicketFormDialogState();
}

class _SetTicketFormDialogState extends State<_SetTicketFormDialog> {
  // TODO: preload these from the Storage when data format is updated.
  final _ticketNumberController = TextEditingController();
  final _ticketAmountController = TextEditingController();

  bool _invalidTicketNumber = false;
  bool _invalidAmount = false;

  void _submit() {
    bool canProceed = true;

    // Validate ticket number
    if (! _ticketNumberRegex.hasMatch(_ticketNumberController.text)) {
      setState(() => _invalidTicketNumber = true);
      canProceed = false;
    }

    // Validate ticket amount (it's optional, so we're falling in an error state
    // only if it's filled with a erratic value).
    final ticketAmountText = _ticketAmountController.text.trim();
    int? ticketAmount;
    if (ticketAmountText.isNotEmpty) {
      try {
        ticketAmount = int.parse(ticketAmountText);
        if (ticketAmount < _minAmount || ticketAmount > _maxAmount) {
          throw const FormatException();
        }
      }
      on FormatException {
        setState(() => _invalidAmount = true);
        canProceed = false;
      }
    }

    if (! canProceed) {
      return;
    }
    // TODO: effetively set the ticket in Storage module.
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Definir ticket RU'),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 8,
      children: [
        const Text(_message, textAlign: TextAlign.justify),

        TextField(
          controller: _ticketNumberController,
          keyboardType: TextInputType.number,
          maxLength: 6,
          onChanged: (value) => setState(() => _invalidTicketNumber = false),
          decoration: InputDecoration(
            filled: true,
            hintText: 'Digite o seu ticket',
            errorText: _invalidTicketNumber
                ? 'O ticket digitado não é válido'
                : null,
          ),
        ),

        Text(
          'Quantidade comprada:',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        TextField(
          controller: _ticketAmountController,
          keyboardType: TextInputType.number,
          onChanged: (value) => setState(() => _invalidAmount = false),
          decoration: InputDecoration(
            helperText: 'Opcional',
            errorText: _invalidAmount
                ? _amountInputHelperText
                : null,
          ),
        ),
      ],
    ),
    actions: [
      TextButton(
        onPressed: Navigator.of(context).pop,
        child: const Text('Cancelar'),
      ),

      ElevatedButton(
        onPressed: _ticketNumberController.text.isNotEmpty ? _submit : null,
        child: const Text('Salvar ticket'),
      )
    ],
  );

  static const _message = 'Você pode anotar o seu ticket do RU aqui, para não '
      'ter que entrar no portal do aluno caso se esqueça dele.';
  static const _minAmount = 6;
  static const _maxAmount = 50;
  static const _amountInputHelperText = 'Deve ser um número entre $_minAmount '
      'e $_maxAmount';

  static final _ticketNumberRegex = RegExp(r'^\d{6}$');
}
