import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'course.dart';

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
      final fileRawBytes = await _file.readAsBytes();
      final fileDecodedRaw = utf8.decode(fileRawBytes.toList());
      _content = jsonDecode(fileDecodedRaw);
    }
    else {
      await _file.create();
      _content = _emptyConfigTemplate;
      _saveToFile();
    }

    _initialized = true;
  }

  /// If the courses parsing fails, it means that this section of the file
  /// could be outdated or was corrupted. As the data can't be trusted anymore,
  /// all courses will be deleted.
  static Future<void> condemnStoredCourses() async {
    _content['courses'] = [];
    await _saveToFile();
  }

  static Future<void> updateCourses() async {
    _content['courses'] = Courses.courses
        .map((course) => course.entry)
        .toList(growable: false);
    await _saveToFile();
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
