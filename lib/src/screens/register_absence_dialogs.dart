import 'package:faltometro_ufrgs/src/course.dart';
import 'package:faltometro_ufrgs/src/screens/common.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// Dialog for courses that have the same amout of periods in all class days.
class UniformCourseRegisterAbsenceDialog extends StatefulWidget {
  final Course _course;

  const UniformCourseRegisterAbsenceDialog(this._course, {super.key});

  @override
  State<UniformCourseRegisterAbsenceDialog> createState() =>
      _UniformCourseRegisterAbsenceDialogState();
}

class _UniformCourseRegisterAbsenceDialogState
    extends State<UniformCourseRegisterAbsenceDialog> {
  int _daysAbsent = 1;

  @override
  void initState() {
    assert (widget._course.isUniform);
    super.initState();
  }

  void _registerAbsences() {
    Courses.registerAbsences(widget._course, absences: _daysAbsent);
    Navigator.of(context).pop(true); // Popping true will indicate that a
    // refresh is needed.
  }

  void _discountAbsences() {
    Courses.discountAbsences(widget._course, absences: _daysAbsent);
    Navigator.of(context).pop(true); // Popping true will indicate that a
    // refresh is needed.
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Registrar falta'),
    content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Dias de falta'),
          Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                IconButton.filled(
                    onPressed: _daysAbsent > 1
                        ? () => setState(() => _daysAbsent--)
                        : null,

                    icon: PhosphorIcon(PhosphorIcons.bold.minus)
                ),

                Text(
                    _daysAbsent.toString(),
                    style: const TextStyle(fontSize: 48)
                ),

                IconButton.filled(
                  onPressed: () => setState(() => _daysAbsent++),
                  icon: PhosphorIcon(PhosphorIcons.bold.plus),
                ),
              ]
          )
        ]
    ),
    actions: [
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ElevatedButton(
            onPressed: _registerAbsences,
            style: ButtonStyle(
              shape: MaterialStateProperty.all(buttonRoundBorder)
            ),
            child: Text('Registrar falta${_daysAbsent > 1 ? 's' : ''}'),
          ),

          TextButton(
            onPressed: _discountAbsences,
            child: Text('Descontar falta${_daysAbsent > 1 ? 's' : ''}'),
          )
        ],
      )
    ],
    actionsPadding: _actionsPadding,
  );
}

/// Dialog for courses that have different amount of periods according to the
/// weekday.
class NonUniformCourseRegisterAbsenceDialog extends StatefulWidget {
  final Course _course;

  const NonUniformCourseRegisterAbsenceDialog(this._course, {super.key});

  @override
  State<NonUniformCourseRegisterAbsenceDialog> createState() =>
      _NonUniformCourseRegisterAbsenceDialogState();
}

class _NonUniformCourseRegisterAbsenceDialogState
    extends State<NonUniformCourseRegisterAbsenceDialog> {
  late final List<int> _weekdaysWithClass;

  int? _selectedWeekday;

  @override
  void initState() {
    assert (! widget._course.isUniform);
    _weekdaysWithClass = [];
    for (int i = 0; i < 5; i++) {
      if (widget._course.periodsPerWeekday[i] > 0) {
        _weekdaysWithClass.add(i);
      }
    }
    super.initState();
  }

  void _tileTapAction(int weekday) => setState(() {
    _selectedWeekday = _selectedWeekday == weekday
        ? _selectedWeekday = null
        : _selectedWeekday = weekday;
  });

  void _registerAbsences() {
    assert (_selectedWeekday != null);
    Courses.registerAbsences(widget._course, weekday: _selectedWeekday);
    Navigator.of(context).pop(true); // Popping true will indicate that a
    // refresh is needed.
  }

  void _discountAbsences() {
    assert (_selectedWeekday != null);
    Courses.discountAbsences(widget._course, weekday: _selectedWeekday);
    Navigator.of(context).pop(true); // Popping true will indicate that a
    // refresh is needed.
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Registrar faltas'),
    content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
              'Marque o dia da semana em que você faltou:',
              textAlign: TextAlign.center
          ),

          ListBody(
            children: _weekdaysWithClass.map((weekday) => ListTile(
              title: Text(weekdaysNames[weekday]),
              selected: weekday == _selectedWeekday,
              selectedColor: Theme.of(context).colorScheme.secondary,
              visualDensity: VisualDensity.compact,
              onTap: () => _tileTapAction(weekday),
              trailing: Radio(
                groupValue: _selectedWeekday,
                value: weekday,
                onChanged: (value) => _tileTapAction(weekday),
              ),
            )).toList(growable: false),
          ),
        ]
    ),
    actions: [
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ElevatedButton(
              onPressed: _selectedWeekday != null ? _registerAbsences : null,
              style: ButtonStyle(
                shape: MaterialStateProperty.all(buttonRoundBorder)
              ),
              child: const Text('Registrar falta')
          ),

          TextButton(
              onPressed: _selectedWeekday != null ? _discountAbsences : null,
              child: const Text('Descontar falta')
          )
        ],
      )
    ],
    actionsPadding: _actionsPadding,
  );
}

const _actionsPadding = EdgeInsets.symmetric(horizontal: 24, vertical: 8);
