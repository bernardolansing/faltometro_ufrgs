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
      .map((course) => course.entry)
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
      datesSkipped: [],
      durationInWeeks: durationInWeeks ?? Course.defaultSemesterLength,
    );
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
  List<DateTime> datesSkipped;
  int durationInWeeks;

  Course({
    required this.title,
    required this.periodsPerWeekday,
    required this.datesSkipped,
    required this.durationInWeeks,
  });

  Course.fromEntry(Map<String, dynamic> entry) :
        title = entry['title'],
        periodsPerWeekday = List<int>.from(entry['periodsPerWeekday']),
        datesSkipped = List<String>.from(entry['datesSkipped'] ?? [])
            .map(DateTime.parse)
            .toList(),
        durationInWeeks = entry['durationInWeeks'];

  void setDatesSkipped(List<DateTime> newDatesSkipped) {
    log('[COURSES] updating list of skipped dates');
    datesSkipped = newDatesSkipped;
    Storage.saveCourses();
  }

  Map<String, dynamic> get entry => {
    'title': title,
    'periodsPerWeekday': periodsPerWeekday,
    'datesSkipped': datesSkipped
        .map((date) => date.toString())
        .toList(),
    'durationInWeeks': durationInWeeks,
  };

  /// A course is uniform if the amount of periods is the same in all class
  /// days. So for example if a course has two periods on Monday, Wednesday and
  /// Friday, it will be uniform. In contrast, if a course has two periods on
  /// Monday and three periods on Wednesday, it will NOT me uniform.
  bool get isUniform => periodsPerWeekday.toSet().length < 3
      && periodsPerWeekday.contains(0);
  // With .toSet(), we remove the duplicates in periodsPerWeekday. We expect to
  // have 0 (from the days that there is no class) and at least one other
  // number. If we have only one number other than 0, the course is uniform as
  // that is the amount of periods for all class days. It's probably never
  // going to be the case, but if a course has classes from Monday to Saturday,
  // a false positive would be returned unless we checked if periodsPerWeekday
  // contained 0.

  /// Number of periods in a class day. Valid only for 'uniform' courses.
  int get periodsPerClassDay {
    assert (isUniform);
    return periodsPerWeekday.firstWhere((periods) => periods > 0);
  }

  int get periodsSkipped {
    int n = 0;
    for (final skippedDay in datesSkipped) {
      n += periodsPerWeekday[skippedDay.weekday - 1]; // DateTime weekday is 1
      // for Monday and 6 to Saturday, so we have to discount 1 for it to serve
      // as an index.
    }
    return n;
  }

  /// The percentage of absences that already have been consumed for this
  /// course. It ranges between 0 and 1 (100%). If it is 100%, it means that
  /// the student has already used all of the tolerated absences, and therefore
  /// it should be reproved.
  double get burnAbsencesPercentage => (periodsSkipped / skippablePeriods)
      .clamp(0, 1.0);

  /// The amount of class periods that can be safely skipped by a student.
  int get skippablePeriods {
    final periodsPerWeek = periodsPerWeekday.reduce((acc, val) => acc + val);
    final totalPeriods = durationInWeeks * periodsPerWeek;
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
    return periodsSkipped ~/ periodsPerClassDay;
  }

  /// A course is in critical state if the student has burnt more than 80% of
  /// the courses absences.
  bool get isCritical => burnAbsencesPercentage > 0.8;

  /// The student has probably skipped more classes than it could, so its
  /// reprovation is almost certain.
  bool get isGameOver => burnAbsencesPercentage >= 1.0;

  /// Returns a list of weekdays in which this course has classes. 1 == monday,
  /// 6 == saturday.
  List<int> getWeekdaysWithClass() {
    final List<int> list = [];
    for (final (index, periods) in periodsPerWeekday.indexed) {
      if (periods != 0) {
        list.add(index + 1);
      }
    }
    return list;
  }
}

extension PercentageFormattingExtension on double {
  String get asPercentage => '${(this * 100).toInt()}%';
}

const weekdaysNames = ['Segunda-feira', 'Terça-feira', 'Quarta-feira',
  'Quinta-feira', 'Sexta-feira', 'Sábado'];
