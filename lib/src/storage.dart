import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'course.dart';
import 'settings.dart';

/// Settings file manager module. You must initialize it before being able
/// to interact with it.
class Storage {
  static bool _initialized = false;
  static late File _file;
  static late Map<String, dynamic> _content;

  static RestaurantTicket? restaurantTicket;

  static Future<void> initialize() async {
    assert (! _initialized);
    // Open the file and make sure it exists, then parse its content.
    final directory = await getApplicationDocumentsDirectory();
    _file = File('${directory.path}/config.json');
    final fileExists = await _file.exists();

    if (fileExists) {
      final fileRawBytes = await _file.readAsBytes();

      if (fileRawBytes.isEmpty) {
        // Weirdly, it seems that the file is cleared instead of deleted between
        // app reinstalls. It may be a emulator bug also, but since the
        // posibility exists, it doesn't hurt to check.
        _saveAll();
      }

      else {
        final fileDecodedRaw = utf8.decode(fileRawBytes.toList());
        _content = jsonDecode(fileDecodedRaw);
      }
    }

    else {
      // If there are no settings file created, we should load the default ones
      // and save them. Every module that uses Storage should initialize its
      // fields beforehand and provide a "storageEntry" getter that serializes
      // its data in a JSON-encodable way.
      await _file.create();
      _saveAll(); // This will save the defaults of every module.
    }

    _initialized = true;
    try {
      restaurantTicket = RestaurantTicket
          ._fromStorage(_content['restaurantTicket']);
    }
    catch (error) {
      log('Error while loading restaurant ticket from Storage: $error');
      restaurantTicket = null;
    }
  }

  /// Saves the state of all stored data.
  static void _saveAll() {
    log('Writing to Storage file');
    _content = {
      'courses': Courses.storageEntry,
      'settings': Settings.storageEntry,
    };
    _saveToFile();
  }

  /// Writes current state of [Courses] module to the local storage.
  static void saveCourses() {
    _content['courses'] = Courses.storageEntry;
    _saveToFile();
  }

  /// Writes current state of [Settings] module to the local storage.
  static void saveSettings() {
    _content['settings'] = Settings.storageEntry;
    _saveToFile();
  }

  static void setRestaurantTicket(String number, int? amount) {
    log('Updating restaurant ticket entry');
    if (Storage.restaurantTicket == null) {
      Storage.restaurantTicket = RestaurantTicket(number, amount);
    } else {
      Storage.restaurantTicket!.number = number;
      if (amount != null) {
        Storage.restaurantTicket!.amount = amount;
      }
    }
    _content['restaurantTicket'] = {
      'number': number,
      'amount': Storage.restaurantTicket!.amount,
    };
    _saveToFile();
  }

  static void clearRestaurantTicket() {
    log('Clearing restaurant ticket entry');
    Storage.restaurantTicket = null;
    _content['restaurantTicket'] = null;
    _saveToFile();
  }

  static Future<void> _saveToFile() async {
    log('Writing to Storage file');
    final raw = jsonEncode(_content);
    await _file.writeAsString(raw);
  }

  static List<Map<String, dynamic>> get coursesEntry {
    assert (_initialized);
    return List<Map<String, dynamic>>.from(_content['courses']);
  }

  static Map<String, String> get settingsEntry {
    assert (_initialized);
    return Map<String, String>.from(_content['settings']);
  }
}

class RestaurantTicket {
  String number;
  int? amount;

  RestaurantTicket(this.number, [this.amount]);

  static RestaurantTicket? _fromStorage(Object? stored) {
    // Older configuration files will have the restaurant ticket as a simple
    // string, back from when we didn't support ticket amount.
    if (stored is String) {
      return RestaurantTicket(stored);
    }

    if (stored is Map<String, dynamic>) {
      return RestaurantTicket(stored['number'], stored['amount']);
    }

    return null;
  }
}
