import 'dart:developer';

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
    if (Storage.restaurantTicket == null) {
      return _buildUnsetTicketVariant();
    }

    if (Storage.restaurantTicket!.amount != null) {
      return _buildTicketWithAmountVariant();
    }

    // TODO:
    return _buildTicketWithoutAmountVariant();
  }

  /// Widget to render if the ticket isn't set (or has just been zeroed).
  Widget _buildUnsetTicketVariant() => TextButton.icon(
    icon: PhosphorIcon(PhosphorIcons.regular.plus, size: 20),
    onPressed: () => showDialog(
      context: context,
      builder: (context) => const _SetTicketFormDialog(),
    ),
    label: const Text(
      'Adicionar\nticket RU',
      style: TextStyle(fontSize: 12),
    ),
  );

  // TODO
  Widget _buildTicketWithoutAmountVariant() => Container();

  /// Widget to render if the ticket is set and user is counting how many of
  /// them are being consumed.
  Widget _buildTicketWithAmountVariant() => InkWell(
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

class _ManageTicketDialog extends StatelessWidget {
  const _ManageTicketDialog();

  void _discountTicket(BuildContext context) {
    log('Discounting restaurant ticket now');
    assert (Storage.restaurantTicket?.amount != null);
    final ticketsAfterDiscount = Storage.restaurantTicket!.amount! - 1;
    if (ticketsAfterDiscount == 0) {
      log('Number of tickets went down to zero, clearing ticket entry from '
          'Storage');
      Storage.clearRestaurantTicket();
    } else {
      log('New count of tickets is $ticketsAfterDiscount');
      Storage.setRestaurantTicket(Storage.restaurantTicket!.number,
          ticketsAfterDiscount);
    }

    ScaffoldMessenger.of(context).showSnackBar(_haveANiceLunchSnackbar);
    Navigator.of(context).pop();
  }

  void _editTicket(BuildContext context) async {
    // This is not ideal as we're showing one dialog on top of another. However,
    // replacing the dialog would cause the current one to be closed and the
    // upper setState() call would take place before user has finished editing
    // the ticket on the dialog that opens next. Unfortunately, Flutter's
    // NotificationListener doesn't seem to receive notifications dispatched
    // from dialogs, so getting the dialog replacement thing to work without
    // state mismanagement would add a lot of complexity. Maybe one day this
    // project adds Bloc or some state manager of this sort and then we could
    // improve this section here, but not a priority for now.
    await showDialog(
      context: context,
      builder: (context) => const _SetTicketFormDialog(),
    );
    if (context.mounted) {
      Navigator.of(context).pop();
    }
  }

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
            onPressed: () => _discountTicket(context),
            icon: PhosphorIcon(PhosphorIcons.regular.forkKnife),
            label: const Text('Descontar um ticket'),
          ),

        TextButton.icon(
          onPressed: () => _editTicket(context),
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

  static const _haveANiceLunchSnackbar = SnackBar(
    content: Text('Aproveite o almoço!'),
    duration: Duration(seconds: 1),
  );
}

class _SetTicketFormDialog extends StatefulWidget {
  const _SetTicketFormDialog();

  @override
  State<_SetTicketFormDialog> createState() =>
      _SetTicketFormDialogState();
}

class _SetTicketFormDialogState extends State<_SetTicketFormDialog> {
  final _ticketNumberController = TextEditingController();
  final _ticketAmountController = TextEditingController();

  bool _invalidTicketNumber = false;
  bool _invalidAmount = false;

  @override
  void initState() {
    super.initState();

    // Populate fields with current values:
    if (Storage.restaurantTicket != null) {
      _ticketNumberController.text = Storage.restaurantTicket!.number;
      if (Storage.restaurantTicket!.amount != null) {
        _ticketAmountController.text = Storage.restaurantTicket!.amount!
            .toString();
      }
    }
  }

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
        if (ticketAmount > _maxAmount) {
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
                ? 'Deve ser um número menor que $_maxAmount'
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
      ),
    ],
  );

  static const _message = 'Você pode anotar o seu ticket do RU aqui, para não '
      'ter que entrar no portal do aluno caso se esqueça dele.';
  static const _successSnackbar = SnackBar(
    content: Text('Ticket RU atualizado'),
  );
  static const _maxAmount = 50;

  static final _ticketNumberRegex = RegExp(r'^\d{6}$');
}
