import 'package:faltometro_ufrgs/src/course.dart';
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
            onPressed: () {},
            child: const Text('Registrar falta'),
          ),

          TextButton(
            onPressed: () {},
            child: const Text('Descontar faltas'),
          )
        ],
      )
    ],
    actionsPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
  );
}
