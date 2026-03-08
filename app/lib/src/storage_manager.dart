import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

class StorageManager {
  static late final Directory _basePath;

  static Future<void> initialize() async {
    _basePath = await getApplicationDocumentsDirectory();
  }

  static StorageEntry<T> getEntry<T>(String name, JsonConverter<T> converter) {
    return _FileStorageEntry<T>(
      name: name,
      file: File('${_basePath.path}/$name.json'),
      jsonConverter: converter,
    );
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
