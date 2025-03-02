import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../course.dart';

class RegisterAbsenceScreen extends StatefulWidget {
  final Course _course;

  const RegisterAbsenceScreen(this._course, {super.key});

  @override
  State<RegisterAbsenceScreen> createState() => _RegisterAbsenceScreenState();
}

class _RegisterAbsenceScreenState extends State<RegisterAbsenceScreen> {
  late List<DateTime> _dates;

  @override
  void initState() {
    super.initState();
    _dates = widget._course.skippedDates;
  }

  CalendarDatePicker2Config get _calendarConfig {
    final theme = Theme.of(context);
    final themeIsDark = theme.brightness == Brightness.dark;
    final textStyle = themeIsDark ? const TextStyle(color: Colors.white) : null;

    return CalendarDatePicker2Config(
      calendarType: CalendarDatePicker2Type.multi,
      calendarViewMode: CalendarDatePicker2Mode.scroll,
      lastDate: DateTime.now(),
      // For DateTime weekdays, Monday has index 1. For course.weekdaysWithClass
      // it has index 0, so it's required to decrement date.weekday in order to
      // match them.
      selectableDayPredicate: (date) => widget._course.weekdaysWithClass
          .contains(date.weekday - 1),
      hideScrollViewTopHeader: true,
      selectedDayHighlightColor: themeIsDark
          ? theme.colorScheme.secondary.withAlpha(175)
          : null,
      controlsTextStyle: textStyle,
      dayTextStyle: textStyle,
      monthTextStyle: textStyle,
      yearTextStyle: textStyle,
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Registrar faltas')),
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text('Selecione os dias em que você faltou:'),

            Flexible(
              child: CalendarDatePicker2(
                value: _dates,
                onValueChanged: (newDates) => setState(() => _dates = newDates),
                config: _calendarConfig,
              ),
            ),

            ElevatedButton.icon(
              onPressed: () {
                widget._course.setDatesSkipped(_dates);
                Navigator.of(context).pop();
              },
              icon: Icon(PhosphorIcons.regular.checkCircle),
              label: const Text('Confirmar'),
            ),
          ],
        ),
      ),
    ),
  );
}
