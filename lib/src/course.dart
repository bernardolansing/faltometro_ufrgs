import 'dart:developer';

import 'storage.dart';

class Courses {
  static List<Course> courses = [];

  /// A list of weekdays indexes in which the student has classes. 0 is Monday,
  /// 1 is Tuesday and so on.
  static List<int> get weekdaysWithClass {
    final List<int> wkdWithClass = [];

    for (final wk in Iterable.generate(5, (index) => index)) {
      if (courses.any((course) => course.periodsPerWeekday[wk] != 0)) {
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
      courses = Storage.coursesEntry.map(Course.fromEntry).toList();
    }
    on TypeError catch (error) {
      log('[COURSES] error on decoding courses entries: ${error.toString()}');
      Storage.saveCourses(); // This will erase the courses entry from the
      // Storage, as we are saving the default empty list of courses.
    }
  }

  static List<Map<String, dynamic>> get storageEntry => courses
      .map((course) => course.toEntry())
      .toList();

  static void newCourse({
    required String title,
    required List<int> periodsPerWeekday,
    int? durationInWeeks,
  }) {
    assert (periodsPerWeekday.length == 6);
    assert (periodsPerWeekday.any((element) => element > 0));
    assert (title.isNotEmpty);
    if (durationInWeeks != null) {
      assert (durationInWeeks >= 14 && durationInWeeks <= 17);
    }

    log('[COURSES] creating new course now');
    final newCourse = Course(
      title: title,
      periodsPerWeekday: periodsPerWeekday,
      skippedDates: [],
      durationInWeeks: durationInWeeks ?? Course.defaultSemesterLength,
    );
    newCourse._makeCalculations();
    courses.add(newCourse);
    Storage.saveCourses();
  }

  static void editCourse({
    required Course course,
    String? title,
    List<int>? periodsPerWeekday,
    int? durationInWeeks,
  }) {
    log('[COURSE] editing course "${course.title}" now');
    course
      ..title = title ?? course.title
      ..periodsPerWeekday = periodsPerWeekday ?? course.periodsPerWeekday
      ..durationInWeeks = durationInWeeks ?? course.durationInWeeks;
    Storage.saveCourses();
  }

  static void deleteCourse(Course courseToDelete) {
    log('[COURSES] deleting course "${courseToDelete.title}" now');
    courses.remove(courseToDelete);
    Storage.saveCourses();
  }

  static void deleteAllCourses() {
    log('[COURSES] deleting all courses now');
    courses.clear();
    Storage.saveCourses();
  }
}

class Course {
  static const defaultSemesterLength = 15; // Semesters usually have 15 weeks
  // of classes.

  String title;
  /// List with six integers, each integer counting the amount of periods for
  /// a weeday. The first item accounts for Monday and the last item accounts
  /// for Saturday.
  List<int> periodsPerWeekday;
  List<DateTime> skippedDates;
  int durationInWeeks;

  // Cached calculations:
  late bool _uniform;
  late int _periodsPerClassDay;
  late List<int> _weekdaysWithClass;
  late int _skippedPeriods;
  late int _skippedClasses;
  late int _skippablePeriods;
  late int _skippableClassDays;
  late double _burntAbsencesPercentage;
  late bool _critical;
  late bool _gameOver;

  int get credits => periodsPerWeekday.fold(0, (acc, val) => acc + val);
  int get hoursOfClass => credits * 15;

  Course({
    required this.title,
    required this.periodsPerWeekday,
    required this.skippedDates,
    required this.durationInWeeks,
  });

  static Course fromEntry(Map<String, dynamic> entry) {
    final course = Course(
      title: entry['title'],
      periodsPerWeekday: List<int>.from(entry['periodsPerWeekday']),
      skippedDates: List<String>.from(entry['skippedDates'] ?? [])
          .map(DateTime.parse)
          .toList(),
      durationInWeeks: entry['durationInWeeks'],
    );
    course._makeCalculations();
    return course;
  }

  Map<String, dynamic> toEntry() => {
    'title': title,
    'periodsPerWeekday': periodsPerWeekday,
    'skippedDates': skippedDates
        .map((date) => date.toString())
        .toList(),
    'durationInWeeks': durationInWeeks,
  };

  void setDatesSkipped(List<DateTime> newDatesSkipped) {
    log('[COURSES] updating list of skipped dates');
    skippedDates = newDatesSkipped;
    _makeCalculations();
    Storage.saveCourses();
  }

  /// A course is uniform if the amount of periods is the same in all class
  /// days. So for example if a course has two periods on Monday, Wednesday and
  /// Friday, it will be uniform. In contrast, if a course has two periods on
  /// Monday and three periods on Wednesday, it will NOT me uniform.
  bool get isUniform => _uniform;

  /// Number of periods in a class day. Valid only for 'uniform' courses.
  int get periodsPerClassDay {
    assert (isUniform);
    return _periodsPerClassDay;
  }

  int get skippedPeriods => _skippedPeriods;

  /// The percentage of absences that have already been consumed for this
  /// course. It ranges between 0 and 1 (100%).
  double get burntAbsencesPercentage => _burntAbsencesPercentage;

  /// The amount of class periods that can be safely skipped by a student.
  int get skippablePeriods => _skippablePeriods;

  /// The total number of class days that may be skipped by the student over the
  /// semester. Valid only for 'uniform' courses.
  int get skippableClassDays {
    assert (isUniform);
    return _skippableClassDays;
  }

  /// Number of class days that were skipped. Valid only for uniform courses.
  int get skippedClasses {
    assert (isUniform);
    return _skippedClasses;
  }

  /// List of weekdays on which the student has classes. For this list, 0 is
  /// Monday and 5 is Saturday.
  List<int> get weekdaysWithClass => _weekdaysWithClass;

  /// A course is in critical state if the student has burnt more than 80% of
  /// the courses absences.
  bool get isCritical => _critical;

  /// The student has probably skipped more classes than they could, so their
  /// reprovation is almost certain.
  bool get isGameOver => _gameOver;

  void _makeCalculations() {
    // The course is uniform if all class days have the same amount of periods.
    _uniform = periodsPerWeekday.where((p) => p > 0).toSet().length == 1;

    final periodsPerWeek = periodsPerWeekday.reduce((acc, val) => acc + val);
    final totalPeriods = durationInWeeks * periodsPerWeek;
    _skippablePeriods = (totalPeriods * 0.25).toInt(); // 75% of class
    // attendance is demanded.
    _weekdaysWithClass = periodsPerWeekday.indexed
        .where((indexAndPeriods) => indexAndPeriods.$2 > 0)
        .map((indexAndPeriods) => indexAndPeriods.$1)
        .toList();

    if (_uniform) {
      _periodsPerClassDay = periodsPerWeekday
          .firstWhere((periods) => periods != 0);
      _skippedClasses = skippedDates.length;
      _skippedPeriods = _skippedClasses * _periodsPerClassDay;
      _skippableClassDays = _skippablePeriods ~/ _periodsPerClassDay;
    } else {
      _skippedPeriods = 0;
      for (final skippedDay in skippedDates) {
        // DateTime weekday is 1 for Monday and 6 to Saturday, so we have to
        // discount 1 for it to serve as an index.
        _skippedPeriods += periodsPerWeekday[skippedDay.weekday - 1];
      }
    }

    _burntAbsencesPercentage = (_skippedPeriods / _skippablePeriods)
        .clamp(0, 1.0);
    _critical = _burntAbsencesPercentage >= 0.8;
    _gameOver = _burntAbsencesPercentage >= 1;
  }
}

extension PercentageFormattingExtension on double {
  String get asPercentage => '${(this * 100).toInt()}%';
}

const weekdaysNames = ['Segunda-feira', 'Terça-feira', 'Quarta-feira',
  'Quinta-feira', 'Sexta-feira', 'Sábado'];
