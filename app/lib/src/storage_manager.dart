import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'models/restaurant_ticket.dart';
import 'models/settings.dart';
import 'models/user_course.dart';
import 'restaurant_manager.dart';

class StorageManager {
  static late final Directory _basePath;
  static late final Map<String, dynamic>? _oldConfig;

  static Future<void> initialize() async {
    _basePath = await getApplicationDocumentsDirectory();

    // Try to load the old-fashioned config file. If successful, we're going to
    // execute the conversion to the new format and then delete the old file.
    final file = File('${_basePath.path}/config.json');
    if (! await file.exists()) {
      log('Old style config has been converted previously');
      _oldConfig = null;
      return;
    }
    log("Old style config file detected, we're going to make the conversion");
    final fileContent = await file.readAsString();
    _oldConfig = jsonDecode(fileContent);
    file.delete(); // Since it is already loaded in memory and all entries are
    // going to be loaded soon, we can already delete it.
  }

  static StorageEntry<T> getEntry<T>(String name, JsonConverter<T> converter) {
    final entry = _FileStorageEntry<T>(
      name: name,
      file: File('${_basePath.path}/$name.json'),
      jsonConverter: converter,
    );

    // TODO: remove all this when conversion isn't necessary any longer.
    if (_oldConfig != null) {
      switch (name) {
        case 'restaurant':
          if (_oldConfig!.containsKey('restaurantTicket')) {
            final ticket = RestaurantTicketConverter()
                .fromJson(_oldConfig!['restaurantTicket']);
            final data = RestaurantManagerData(ticket);
            entry.store(data as T);
          }
          break;
        case 'courses':
          if (_oldConfig!.containsKey('courses')) {
            final converter = UserCourseJsonConverter();
            final courses = List<dynamic>.from(_oldConfig!['courses'])
                .map((obj) => converter.fromJson(obj))
                .toList();
            entry.store(courses as T);
          }
          break;
        case 'settings':
          if (_oldConfig!.containsKey('settings')) {
            final converter = SettingsJsonConverter();
            final settings = converter.fromJson(_oldConfig!['settings']);
            entry.store(settings as T);
          }
          break;
      }
    }

    return entry;
  }
}

/// Object capable of expressing `T` as a JSON-like object, or parsing such
/// object to retrieve an instance of `T`.
abstract class JsonConverter<T> {
  T fromJson(dynamic json);

  dynamic toJson(T entry);
}

/// Represents a JSON content that is saved locally, requiring no network
/// transactions to be accessed.
abstract class StorageEntry<T> {
  /// Reads the JSON content assigned to this entry and returns it deserialized.
  /// If no content could be found, throws [MissingStorageEntry].
  Future<T> load();
  
  /// Saves the updated entry to the storage.
  Future<void> store(T value);
}

/// JSON storage based on files. Currently the only available implementation for
/// [StorageEntry].
class _FileStorageEntry<T> implements StorageEntry<T> {
  final String _name;
  final File _file;
  final JsonConverter<T> _converter;

  _FileStorageEntry({
    required String name,
    required File file,
    required JsonConverter<T> jsonConverter,
  }) :
        _name = name,
        _file = file,
        _converter = jsonConverter;

  @override
  Future<T> load() async {
    final fileExists = await _file.exists();

    if (! fileExists) {
      log('[FileStorageEntry] stored entry $_name is missing');
      throw MissingStorageEntry();
    }

    log('[FileStorageEntry] reading entry $_name');
    final content = await _file.readAsString();
    if (content.isEmpty) {
      log('[FileStorageEntry] entry $_name had no content');
      throw MissingStorageEntry();
    }

    late final dynamic jsonDeserialized;
    try {
      jsonDeserialized = jsonDecode(content);
    } catch (error, stackTrace) {
      log(
        '[FileStorageEntry] error while decoding entry $_name: $error',
        stackTrace: stackTrace,
      );
      throw MissingStorageEntry();
    }

    return _converter.fromJson(jsonDeserialized);
  }
  
  @override
  Future<void> store(T entry) async {
    log('[STORAGE] storing entry $_name');
    final jsonObject = _converter.toJson(entry);
    final jsonString = jsonEncode(jsonObject);
    await _file.writeAsString(jsonString);
  }
}

class MissingStorageEntry implements Exception {}
