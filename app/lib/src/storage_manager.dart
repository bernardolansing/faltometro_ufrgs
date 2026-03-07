import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

class StorageManager {
  static late final Directory _basePath;
  
  static Future<void> initialize() async {
    _basePath = await getApplicationDocumentsDirectory();
  }
  
  static StorageEntry getEntry(String name) =>
      _FileStorageEntry(File('${_basePath.path}/$name.json'));
}

/// Represents a JSON content that is saved locally, requiring no network
/// transactions to be accessed.
abstract class StorageEntry {
  /// Reads the JSON content assigned to this entry and returns it deserialized.
  /// If no content could be found, throws [MissingStorageEntry].
  Future<dynamic> load();
}

/// JSON storage based on files. Currently the only available implementation for
/// [StorageEntry].
class _FileStorageEntry implements StorageEntry {
  final File _file;
  
  _FileStorageEntry(this._file);

  @override
  Future<dynamic> load() async {
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

    try {
      return jsonDecode(content);
    }
    catch (error, stackTrace) {
      log(
        '[STORAGE] error while decoding file $fileName: $error',
        stackTrace: stackTrace,
      );
      throw MissingStorageEntry();
    }
  }
}

class MissingStorageEntry implements Exception {}
