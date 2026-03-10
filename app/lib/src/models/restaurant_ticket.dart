import '../storage_manager.dart';

class RestaurantTicket {
  String number;
  int? amount;

  RestaurantTicket(this.number, [this.amount]);
}

class RestaurantTicketConverter implements JsonConverter<RestaurantTicket> {
  @override
  RestaurantTicket fromJson(json) {
    // Older configuration files will have the restaurant ticket as a simple
    // string, back from when we didn't support ticket amount.
    if (json is String) {
      return RestaurantTicket(json);
    }

    return RestaurantTicket(json['number'], json['amount']);
  }

  @override
  toJson(RestaurantTicket entry) => {
    'number': entry.number,
    'amount': entry.amount,
  };
}
