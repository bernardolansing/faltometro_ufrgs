import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

const _configFilename = 'config.json';
const Map<String, dynamic> _emptyConfigTemplate = {
  'courses': []
};

/// Settings file manager module. You must initialize it before being able
/// to interact with it.
class Storage {
  static bool _initialized = false;
  static late File _file;
  static late Map<String, dynamic> _content;

  static Future<void> initialize() async {
    assert (! _initialized);
    // Open the file and make sure it exists, then parse its content.
    final directory = await getApplicationDocumentsDirectory();
    _file = File('${directory.path}/$_configFilename');
    final fileExists = await _file.exists();

    if (fileExists) {
      final fileRawContent = await _file.readAsBytes();
      _content = jsonDecode(fileRawContent.toString());
    }
    else {
      await _file.create();
      _content = _emptyConfigTemplate;
      _saveToFile();
    }

    _initialized = true;
  }

  static Future<void> _saveToFile() async {
    final raw = jsonEncode(_content);
    await _file.writeAsString(raw);
  }

  static List<Map<String, dynamic>> get coursesEntry {
    assert (_initialized);
    return List<Map<String, dynamic>>.from(_content['courses']);
  }
}
