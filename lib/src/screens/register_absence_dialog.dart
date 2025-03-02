import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'package:flutter/material.dart';

import '../course.dart';

/// Shows a dialog with a date picker, allowing user to select which days they
/// skipped class. Unless user cancels the action, this function will always
/// update the stashed data, even if no change was made. After it is resolved,
/// the UI should be refreshed.
Future<void> showRegisterAbsenceDialog(BuildContext context,
    Course course) async {
  final theme = Theme.of(context);
  final themeIsDark = theme.brightness == Brightness.dark;
  final textStyle = themeIsDark ? const TextStyle(color: Colors.white) : null;

  final selectedDates = await showCalendarDatePicker2Dialog(
    context: context,
    value: course.skippedDates,
    config: CalendarDatePicker2WithActionButtonsConfig(
      calendarType: CalendarDatePicker2Type.multi,
      lastDate: DateTime.now(),
      // For DateTime weekdays, Monday has index 1. For course.weekdaysWithClass
      // it has index 0, so it's required to decrement date.weekday in order
      // to match them.
      selectableDayPredicate: (date) => course.weekdaysWithClass
          .contains(date.weekday - 1),
      selectedDayHighlightColor: themeIsDark
          ? theme.colorScheme.secondary.withAlpha(175)
          : null,
      controlsTextStyle: textStyle,
      dayTextStyle: textStyle,
      monthTextStyle: textStyle,
      yearTextStyle: textStyle,
      okButton: const Text('Confirmar'),
      cancelButton: const Text('Cancelar'),
    ),
    dialogSize: const Size(370, 424),
  );

  if (selectedDates != null) {
    // I couldn't find out why the returned date objects are nullable. It should
    // be safe to assert them anyway.
    final asserted = selectedDates.map((nullable) => nullable!).toList();
    course.setDatesSkipped(asserted);
  }
}
