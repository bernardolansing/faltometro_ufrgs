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
      file: File('${_basePath.path}/$name.json'),
      jsonConverter: converter,
    );
  }

}

/// Object capable of expressing `T` as a JSON-like object, or parsing such
/// object to retrieve an instance of `T`.
abstract class JsonConverter<T> {
  T fromJson(dynamic json);

  dynamic toJson(T self);
}

/// Represents a JSON content that is saved locally, requiring no network
/// transactions to be accessed.
abstract class StorageEntry<T> {
  /// Reads the JSON content assigned to this entry and returns it deserialized.
  /// If no content could be found, throws [MissingStorageEntry].
  Future<T> load();
}

/// JSON storage based on files. Currently the only available implementation for
/// [StorageEntry].
class _FileStorageEntry<T> implements StorageEntry<T> {
  final File _file;
  final JsonConverter<T> _converter;

  _FileStorageEntry({
    required File file,
    required JsonConverter<T> jsonConverter,
  }) :
        _file = file,
        _converter = jsonConverter;

  @override
  Future<T> load() async {
    final fileName = _file.uri.pathSegments.last;
    final fileExists = await _file.exists();

    if (! fileExists) {
      log('[STORAGE] File $fileName is missing');
      throw MissingStorageEntry();
    }

    log('[STORAGE] reading file $fileName');
    final content = await _file.readAsString();
    if (content.isEmpty) {
      log('[STORAGE] file $fileName had no content');
      throw MissingStorageEntry();
    }

    late final dynamic jsonDeserialized;
    try {
      jsonDeserialized = jsonDecode(content);
    } catch (error, stackTrace) {
      log(
        '[STORAGE] error while decoding file $fileName: $error',
        stackTrace: stackTrace,
      );
      throw MissingStorageEntry();
    }

    return _converter.fromJson(jsonDeserialized);
  }
}

class MissingStorageEntry implements Exception {}
