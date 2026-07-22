import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../restaurant_manager.dart';

class RestaurantTicketWidget extends StatefulWidget {
  const RestaurantTicketWidget({super.key});

  @override
  State<RestaurantTicketWidget> createState() =>
      _RestaurantTicketWidgetState();
}

class _RestaurantTicketWidgetState extends State<RestaurantTicketWidget> {
  void _openTicketFormDialog() async {
    await showDialog(
      context: context,
      builder: (context) => const _SetTicketFormDialog(),
    );
    if (context.mounted) {
      setState(() {});
    }
  }

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
    if (RestaurantManager.ticket == null) {
      return _buildUnsetTicketVariant();
    }
    if (RestaurantManager.ticket!.amount != null) {
      return _buildTicketWithAmountVariant();
    }
    return _buildTicketWithoutAmountVariant();
  }

  /// Widget to render if the ticket isn't set (or has just been zeroed).
  Widget _buildUnsetTicketVariant() => TextButton.icon(
    icon: const Icon(PhosphorIconsRegular.plus, size: 20),
    onPressed: _openTicketFormDialog,
    label: const Text(
      'Adicionar\nticket RU',
      style: TextStyle(fontSize: 12),
    ),
  );

  /// Widget to render if the ticket number is set but user is not keeping track
  /// of the amount of tickets that are consumed.
  Widget _buildTicketWithoutAmountVariant() => TextButton.icon(
    onPressed: _openManageTicketDialog,
    icon: const Icon(PhosphorIconsRegular.ticket, size: 22),
    label: Text(
      RestaurantManager.ticket!.number,
      style: const TextStyle(fontSize: 18),
    ),
  );

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
          icon: const Icon(PhosphorIconsRegular.ticket, size: 20),
          label: Text(
            RestaurantManager.ticket!.number,
            style: const TextStyle(fontSize: 16),
          ),
        ),
        Text(
          '${RestaurantManager.ticket!.amount} restantes',
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
    assert (RestaurantManager.ticket?.amount != null);
    RestaurantManager.discountTicket();
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

  void _clearTicket(BuildContext context) async {
    final confirmation = await showDialog(
      context: context,
      builder: (context) => const _ConfirmTicketClearingDialog(),
    );
    if (context.mounted && confirmation == true) {
      RestaurantManager.clearTicket();
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    icon: const Icon(PhosphorIconsRegular.ticket),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(_message, textAlign: TextAlign.justify),

        const SizedBox(height: 8),

        Text(
          RestaurantManager.ticket!.number,
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

        if (RestaurantManager.ticket!.amount != null)
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
                  child: Text(RestaurantManager.ticket!.amount!.toString()),
                ),
              ),
            ],
          ),

        const SizedBox(height: 16),

        if (RestaurantManager.ticket!.amount != null)
          ElevatedButton.icon(
            onPressed: () => _discountTicket(context),
            icon: const Icon(PhosphorIconsRegular.forkKnife),
            label: const Text('Descontar um ticket'),
          ),

        TextButton.icon(
          onPressed: () => _editTicket(context),
          icon: const Icon(PhosphorIconsRegular.pencil),
          label: const Text('Editar ticket'),
        ),

        TextButton.icon(
          onPressed: () => _clearTicket(context),
          icon: const Icon(PhosphorIconsRegular.x),
          label: const Text('Limpar ticket'),
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
    if (RestaurantManager.ticket != null) {
      _ticketNumberController.text = RestaurantManager.ticket!.number;
      if (RestaurantManager.ticket!.amount != null) {
        _ticketAmountController.text = RestaurantManager.ticket!.amount!
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
        if (ticketAmount < 0 || ticketAmount > _maxAmount) {
          throw const FormatException();
        }
      }
      on FormatException {
        setState(() => _invalidAmount = true);
        canProceed = false;
      }
    }

    if (canProceed) {
      if (ticketAmount == 0) {
        RestaurantManager.clearTicket();
      }
      else {
        final ticketNumber = _ticketNumberController.text.trim();
        RestaurantManager.setTicket(ticketNumber, ticketAmount);
        ScaffoldMessenger.of(context).showSnackBar(_successSnackbar);
      }

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
          textInputAction: TextInputAction.next,
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
          onEditingComplete: _submit,
          textInputAction: TextInputAction.done,
          decoration: InputDecoration(
            helperText: 'Opcional',
            errorText: _invalidAmount
                ? 'Deve ser um número maior que zero e menor que $_maxAmount'
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

class _ConfirmTicketClearingDialog extends StatelessWidget {
  const _ConfirmTicketClearingDialog();

  @override
  Widget build(BuildContext context) => SimpleDialog(
    title: const Text('Tem certeza de que deseja apagar seu ticket?'),
    children: [
      SimpleDialogOption(
        padding: _optionPadding,

        child: ListTile(
          iconColor: Theme.of(context).colorScheme.error,
          textColor: Theme.of(context).colorScheme.error,
          leading: const Icon(PhosphorIconsRegular.trash),
          title: const Text('Apagar ticket'),
          onTap: () => Navigator.of(context).pop(true),
        ),
      ),
      SimpleDialogOption(
        padding: _optionPadding,
        child: ListTile(
          leading: const Icon(PhosphorIconsRegular.x),
          title: const Text('Cancelar'),
          onTap: Navigator.of(context).pop,
        ),
      ),
    ],
  );

  static const _optionPadding = EdgeInsets
      .symmetric(horizontal: 8, vertical: 0);
}
