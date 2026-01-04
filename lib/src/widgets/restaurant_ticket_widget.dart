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
  void _openManageTicketDialog() async {
    await showDialog(
      context: context,
      builder: (context) => const _ManageTicketDialog(),
    );
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    // Widget to render if the ticket isn't set (or has just been zeroed).
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

    // Widget to render if the ticket is set and user is counting how many of
    // them are being consumed.
    if (Storage.restaurantTicket!.amount != null) {
      return InkWell(
        onTap: _openManageTicketDialog,
        borderRadius: BorderRadius.circular(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextButton.icon(
              onPressed: _openManageTicketDialog,
              style: const ButtonStyle(
                visualDensity: VisualDensity.compact,
                minimumSize: WidgetStatePropertyAll(Size.zero),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              icon: PhosphorIcon(PhosphorIcons.regular.ticket, size: 20),
              label: Text(
                Storage.restaurantTicket!.number,
                style: const TextStyle(fontSize: 16),
              ),
            ),
            Text(
              '${Storage.restaurantTicket!.amount} restantes',
              style: TextStyle(
                decoration: TextDecoration.underline,
                decorationColor: Theme.of(context).colorScheme.secondary,
                decorationThickness: 2,
              ),
            ),
          ],
        ),
      );
    }

    // TODO:
    return SizedBox(width: 1, height: 1,);
  }
}

class _ManageTicketDialog extends StatelessWidget {
  const _ManageTicketDialog();

  @override
  Widget build(BuildContext context) => AlertDialog(
    icon: PhosphorIcon(PhosphorIcons.regular.ticket),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(_message, textAlign: TextAlign.justify),

        const SizedBox(height: 8),

        Text(
          Storage.restaurantTicket!.number,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
          ),
        ),
        const Text(
          'Ticket atual',
          style: TextStyle(fontWeight: FontWeight.w300),
        ),

        const SizedBox(height: 8),

        if (Storage.restaurantTicket!.amount != null)
          Row(
            spacing: 16,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Tickets restantes:'),

              DecoratedBox(
                decoration: BoxDecoration(
                  border: BoxBorder.all(width: 1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Text(Storage.restaurantTicket!.amount!.toString()),
                ),
              ),
            ],
          ),

        const SizedBox(height: 16),

        if (Storage.restaurantTicket!.amount != null)
          ElevatedButton.icon(
            onPressed: () {},
            icon: PhosphorIcon(PhosphorIcons.regular.forkKnife),
            label: const Text('Descontar um ticket'),
          ),

        TextButton.icon(
          onPressed: () {},
          icon: PhosphorIcon(PhosphorIcons.regular.pencil),
          label: const Text('Editar ticket'),
        ),

        TextButton(
          onPressed: Navigator.of(context).pop,
          child: const Text('Fechar'),
        ),
      ],
    ),
  );

  static const _message = 'O Faltômetro não tem acesso ao servidor da UFRGS, '
      'então a contagem de tickets deve ser feita manualmente por você.';
}

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

    if (canProceed) {
      Storage.setRestaurantTicket(_ticketNumberController.text.trim(),
          ticketAmount);
      ScaffoldMessenger.of(context).showSnackBar(_successSnackbar);
      Navigator.of(context).pop(true);
    }
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
  static const _successSnackbar = SnackBar(
    content: Text('Ticket RU atualizado'),
  );
  static const _minAmount = 6;
  static const _maxAmount = 50;
  static const _amountInputHelperText = 'Deve ser um número entre $_minAmount '
      'e $_maxAmount';

  static final _ticketNumberRegex = RegExp(r'^\d{6}$');
}
