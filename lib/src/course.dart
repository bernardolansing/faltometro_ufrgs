import 'package:faltometro_ufrgs/src/storage.dart';

class Courses {
  static bool _initialized = false;
  static late final List<Course> _courses;

  List<Course> get courses {
    assert (_initialized);
    return _courses;
  }

  /// Load courses from the stored JSON entries.
  static void load(List<Map<String, dynamic>> entries) {
    assert (! _initialized);

    try { _courses = entries.map(Course.fromEntry).toList(); }
    on TypeError { Storage.condemnStoredCourses(); }

    _initialized = true;
  }
}

class Course {
  String title;
  List<int> periodsPerWeekday;
  int periodsSkipped;

  Course({
    required this.title,
    required this.periodsPerWeekday,
    required this.periodsSkipped,
  });

  Course.fromEntry(Map<String, dynamic> entry) :
      title = entry['title'],
      periodsPerWeekday = entry['periodsPerWeekday'],
      periodsSkipped = entry['periodsSkipped'];

  Map<String, dynamic> get entry => {
    'title': title,
    'periodsPerWeekday': periodsPerWeekday,
    'periodsSkipped': periodsSkipped
  };
}
