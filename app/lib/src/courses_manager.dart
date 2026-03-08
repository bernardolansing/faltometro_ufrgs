import 'dart:developer';

import 'models/user_course.dart';
import 'storage_manager.dart';

class CoursesManager {
  static late List<UserCourse> courses;
  static late StorageEntry<List<UserCourse>> _storageEntry;

  /// Relies on having [StorageManager] already initialized.
  static Future<void> initialize() async {
    final jsonConverter = _CoursesManagerJsonConverter();
    _storageEntry = StorageManager.getEntry('courses', jsonConverter);
    try {
      log('[CoursesManager] fetching courses from storage');
      courses = await _storageEntry.load();
    }
    on MissingStorageEntry {
      log('[CoursesManager] no courses found in the storage');
      courses = [];
    }
  }

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

  static void createCourse({
    required String title,
    required List<int> periodsPerWeekday,
    int? durationInWeeks,
  }) {
    assert (periodsPerWeekday.length == 6);
    assert (periodsPerWeekday.any((element) => element > 0));
    assert (title.isNotEmpty);

    log('[CoursesManager] creating new course now');
    final newCourse = UserCourse(
      title: title,
      periodsPerWeekday: periodsPerWeekday,
      skippedDates: [],
      durationInWeeks: durationInWeeks ?? UserCourse.defaultSemesterLength,
    );
    courses.add(newCourse);
    _storageEntry.store(courses);
  }

  /// Edits the attributes of the referred [UserCourse]. Note that this is not
  /// the appropriate method for registering absences; for that use
  /// [setSkippedDatesForCourse].
  static void editCourse({
    required UserCourse course,
    String? title,
    List<int>? periodsPerWeekday,
    int? durationInWeeks,
  }) {
    log('[CoursesManager] editing course "${course.title}" now');
    assert (courses.contains(course));
    course
      ..title = title ?? course.title
      ..periodsPerWeekday = periodsPerWeekday ?? course.periodsPerWeekday
      ..durationInWeeks = durationInWeeks ?? course.durationInWeeks;
    _storageEntry.store(courses);
  }

  static void setSkippedDatesForCourse(
      UserCourse course,
      List<DateTime> skippedDates) {
    log('[CoursesManager] altering skipped dates for course "${course.title}"');
    course.skippedDates = skippedDates;
    _storageEntry.store(courses);
  }

  static void deleteCourse(UserCourse course) {
    log('[CoursesManager] deleting course "${course.title}" now');
    courses.remove(course);
    _storageEntry.store(courses);
  }

  static void deleteAllCourses() {
    log('[CoursesManager] deleting all courses now');
    courses.clear();
    _storageEntry.store(courses);
  }
}

class _CoursesManagerJsonConverter implements JsonConverter<List<UserCourse>> {
  static final _courseConverter = UserCourseJsonConverter();

  @override
  List<UserCourse> fromJson(json) => List<dynamic>.from(json)
      .map(_courseConverter.fromJson)
      .toList();

  @override
  toJson(List<UserCourse> entry) => entry.map(_courseConverter.toJson)
      .toList();
}
