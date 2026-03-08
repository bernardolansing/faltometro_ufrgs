import '../storage_manager.dart';

/// Represents a course in which user is registered.
class UserCourse {
  static const defaultSemesterLength = 17; // Semesters usually have 17 weeks
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

  UserCourse({
    required this.title,
    required this.periodsPerWeekday,
    required this.skippedDates,
    required this.durationInWeeks,
  }) {
    _makeCalculations();
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

class UserCourseJsonConverter implements JsonConverter<UserCourse> {
  @override
  UserCourse fromJson(json) => UserCourse(
    title: json['title'],
    periodsPerWeekday: List<int>.from(json['periodsPerWeekday']),
    skippedDates: List<String>.from(json['skippedDates'] ?? [])
        .map(DateTime.parse)
        .toList(),
    durationInWeeks: json['durationInWeeks'],
  );

  @override
  toJson(UserCourse entry) => {
    'title': entry.title,
    'periodsPerWeekday': entry.periodsPerWeekday,
    'skippedDates': entry.skippedDates
        .map((date) => date.toString())
        .toList(),
    'durationInWeeks': entry.durationInWeeks,
  };
}
