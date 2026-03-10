import 'dart:developer';

import 'models/restaurant_ticket.dart';
import 'storage_manager.dart';

class RestaurantManager {
  static RestaurantTicket? ticket;
  static late final StorageEntry<_RestaurantManagerData> _storageEntry;

  static Future<void> initialize() async {
    log('[RestaurantManager] initializing');
    _storageEntry = StorageManager
        .getEntry('restaurant', _RestaurantManagerDataConverter());
    try {
      final data = await _storageEntry.load();
      ticket = data.ticket;
    }
    on MissingStorageEntry {
      ticket = null;
    }
  }

  static void discountTicket() {
    log('[RestaurantManager] decrementing restaurant tickets');
    assert (ticket != null && (ticket!.amount ?? 0) > 0);
    ticket!.amount = ticket!.amount! - 1;
    if (ticket!.amount == 0) {
      log('[RestaurantManager] ticket count went down to zero, clearing');
      clearTicket(); // Already invokes _store().
    } else {
      _store();
    }
  }

  static void setTicket(String number, int? amount) {
    log('[RestaurantManager] assigning ticket');
    ticket = RestaurantTicket(number, amount);
    _store();
  }

  static void clearTicket() {
    log('[RestaurantTicket] erasing ticket entry');
    ticket = null;
    _store();
  }

  static void _store() => _storageEntry.store(_RestaurantManagerData(ticket));
}

class _RestaurantManagerData {
  RestaurantTicket? ticket;

  _RestaurantManagerData(this.ticket);
}

class _RestaurantManagerDataConverter
    implements JsonConverter<_RestaurantManagerData> {
  @override
  _RestaurantManagerData fromJson(json) {
    final ticket = json['ticket'] != null
        ? RestaurantTicketConverter().fromJson(json['ticket'])
        : null;
    return _RestaurantManagerData(ticket);
  }

  @override
  toJson(_RestaurantManagerData entry) => {
    'ticket': entry.ticket != null
        ? RestaurantTicketConverter().toJson(entry.ticket!)
        : null,
  };
}
