import 'dart:developer';
import 'dart:math' as math;
import 'package:faltometro_ufrgs/src/storage.dart';

class Courses {
  static List<Course> _courses = [];

  static List<Course> get courses => _courses;

  /// A list of weekdays indexes in which the student has classes. 0 is Monday,
  /// 1 is Tuesday and so on.
  static List<int> get weekdaysWithClass {
    final List<int> wkdWithClass = [];

    for (final wk in Iterable.generate(5, (index) => index)) {
      if (_courses.any((course) => course.periodsPerWeekday[wk] != 0)) {
        wkdWithClass.add(wk);
      }
    }

    return wkdWithClass;
  }

  /// Load courses from the stored JSON entries. If something fails, it will
  /// invoke the Storage erasure.
  static void load() {
    try {
      log('[COURSES] loading courses from settings');
      _courses = Storage.coursesEntry.map(Course.fromEntry).toList();
    }
    on TypeError catch (error) {
      log('[COURSES] error on decoding courses entries: ${error.toString()}');
      Storage.saveCourses(); // This will erase the courses entry from the
      // Storage, as we are saving the default empty list of courses.
    }
  }

  static List<Map<String, dynamic>> get storageEntry => _courses
      .map((course) => course.entry)
      .toList();

  static void newCourse({
    required String title,
    required List<int> periodsPerWeekday,
  }) {
    assert (periodsPerWeekday.length == 6);
    assert (periodsPerWeekday.any((element) => element > 0));
    assert (title.isNotEmpty);

    log('[COURSES] creating new course now');
    final newCourse = Course(
        title: title,
        periodsPerWeekday: periodsPerWeekday,
        periodsSkipped: 0
    );
    _courses.add(newCourse);
    Storage.saveCourses();
  }

  static void editCourse({
    required Course course,
    String? title,
    List<int>? periodsPerWeekday
  }) {
    log('[COURSE] editing course "${course.title}" now');
    course
      ..title = title ?? course.title
      ..periodsPerWeekday = periodsPerWeekday ?? course.periodsPerWeekday;
    Storage.saveCourses();
  }

  static void deleteCourse(Course courseToDelete) {
    log('[COURSES] deleting course "${courseToDelete.title}" now');
    _courses.remove(courseToDelete);
    Storage.saveCourses();
  }

  static void deleteAllCourses() {
    log('[COURSES] deleting all courses now');
    _courses.clear();
    Storage.saveCourses();
  }

  static void registerAbsences(Course course, {int? absences, int? weekday}) {
    assert (absences != null || weekday != null);
    log('[COURSES] registering absences for course "${course.title}"');

    if (absences != null) {
      assert (course.isUniform);
      course.periodsSkipped += absences * course.periodsPerClassDay;
    }

    else {
      assert (! course.isUniform);
      course.periodsSkipped += course.periodsPerWeekday[weekday!];
    }

    Storage.saveCourses();
  }

  static void discountAbsences(Course course, {int? absences, int? weekday}) {
    assert (absences != null || weekday != null);
    log('[COURSES] discounting absences for course "${course.title}"');

    if (absences != null) {
      assert (course.isUniform);
      course.periodsSkipped -= absences * course.periodsPerClassDay;
    }

    else {
      assert (! course.isUniform);
      course.periodsSkipped -= course.periodsPerWeekday[weekday!];
    }

    Storage.saveCourses();
  }
}

class Course {
  String title;
  List<int> periodsPerWeekday;
  int _periodsSkipped;

  Course({
    required this.title,
    required this.periodsPerWeekday,
    required int periodsSkipped,
  }) :
        _periodsSkipped = periodsSkipped;

  int get periodsSkipped => _periodsSkipped;

  set periodsSkipped(int value) {
    _periodsSkipped = math.max(value, 0);
  }

  Course.fromEntry(Map<String, dynamic> entry) :
        title = entry['title'],
        periodsPerWeekday = List<int>.from(entry['periodsPerWeekday']),
        _periodsSkipped = entry['periodsSkipped'];

  Map<String, dynamic> get entry => {
    'title': title,
    'periodsPerWeekday': periodsPerWeekday,
    'periodsSkipped': _periodsSkipped
  };

  /// A course is uniform if the amount of periods is the same in all class
  /// days. So for example if a course has two periods on Monday, Wednesday and
  /// Friday, it will be uniform. In contrast, if a course has two periods on
  /// Monday and three periods on Wednesday, it will NOT me uniform.
  bool get isUniform => periodsPerWeekday.toSet().length < 3;
  // With .toSet(), we remove the duplicates in periodsPerWeekday. We expect to
  // have 0 (from the days that there is no class) and at least one other
  // number. If we have only one number other than 0, the course is uniform as
  // that is the amount of periods for all class days.

  /// Number of periods in a class day. Valid only for 'uniform' courses.
  int get periodsPerClassDay {
    assert (isUniform);
    return periodsPerWeekday.firstWhere((periods) => periods > 0);
  }

  /// The percentage of absences that already have been consumed for this
  /// course. It ranges between 0 and 1 (100%). If it is 100%, it means that
  /// the student has already used all of the tolerated absences, and therefore
  /// it should be reproved.
  double get burnAbsencesPercentage => (_periodsSkipped / skippablePeriods)
      .clamp(0, 1.0);

  /// The amount of class periods that can be safely skipped by a student.
  int get skippablePeriods {
    // We are considering that courses are 15 weeks long. That is not always
    // true, but is a good approximation.
    final totalPeriods = 15 * periodsPerWeekday.reduce((acc, val) => acc + val);
    return (totalPeriods * 0.25).toInt(); // 75% of class attendance is
    // demanded.
  }

  /// The total number of class days that may be skipped by the student over the
  /// semester. Valid only for 'uniform' courses.
  int get skippableClassDays {
    assert (isUniform);
    return skippablePeriods ~/ periodsPerClassDay;
  }

  /// Number of class days that were skipped. Valid only for uniform courses.
  int get skippedClasses {
    assert (isUniform);
    return _periodsSkipped ~/ periodsPerClassDay;
  }

  /// A course is in critical state if the student has burnt more than 80% of
  /// the courses absences.
  bool get isCritical => burnAbsencesPercentage > 0.8;

  /// The student has probably skipped more classes than it could, so its
  /// reprovation is almost certain.
  bool get isGameOver => burnAbsencesPercentage >= 1.0;
}

extension PercentageFormattingExtension on double {
  String get asPercentage => '${(this * 100).toInt()}%';
}

const weekdaysNames = ['Segunda-feira', 'Terça-feira', 'Quarta-feira',
  'Quinta-feira', 'Sexta-feira', 'Sábado'];
