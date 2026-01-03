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

// TODO
class _SetTicketFormDialogState extends State<_SetTicketFormDialog> {
  @override
  Widget build(BuildContext context) => Container();
}
