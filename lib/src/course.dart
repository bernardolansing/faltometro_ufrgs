import 'dart:developer';
import 'package:faltometro_ufrgs/src/storage.dart';

class Courses {
  static bool _initialized = false;
  static late final List<Course> _courses;

  static List<Course> get courses {
    assert (_initialized);
    return _courses;
  }

  /// Load courses from the stored JSON entries.
  static void load(List<Map<String, dynamic>> entries) {
    assert (! _initialized);

    try { _courses = entries.map(Course.fromEntry).toList(); }
    on TypeError catch (error) {
      log('Error on decoding courses entries: ${error.toString()}');
      Storage.condemnStoredCourses();
    }

    _initialized = true;
  }

  /// Create new course.
  static void newCourse({
    required String title,
    required List<int> periodsPerWeekday,
  }) {
    assert (periodsPerWeekday.length == 5);
    assert (periodsPerWeekday.any((element) => element > 0));
    assert (title.isNotEmpty);

    final newCourse = Course(
        title: title,
        periodsPerWeekday: periodsPerWeekday,
        periodsSkipped: 0
    );
    _courses.add(newCourse);
    Storage.updateCourses();
  }

  static void deleteCourse(Course courseToDelete) {
    _courses.remove(courseToDelete);
    Storage.updateCourses();
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
        periodsPerWeekday = List<int>.from(entry['periodsPerWeekday']),
        periodsSkipped = entry['periodsSkipped'];

  Map<String, dynamic> get entry => {
    'title': title,
    'periodsPerWeekday': periodsPerWeekday,
    'periodsSkipped': periodsSkipped
  };
}
