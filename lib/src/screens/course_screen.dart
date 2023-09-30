import 'dart:math';
import 'package:faltometro_ufrgs/src/course.dart';
import 'package:faltometro_ufrgs/src/screens/common.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// Screen for creating or editing course. If you want to create a new course,
/// use CourseScreen.newCourse() constructor. If you want to edit a course, use
/// CourseScreen.edit.
class CourseScreen extends StatefulWidget {
  final Course? courseToEdit;  // null if creating new course

  const CourseScreen.newCourse({super.key}) :
        courseToEdit = null;

  const CourseScreen.edit({super.key, required Course course}) :
        courseToEdit = course;

  @override
  State<CourseScreen> createState() => _CourseScreenState();
}

class _CourseScreenState extends State<CourseScreen> {
  late final TextEditingController _titleController;
  late final List<int> _periodsPerWeekday;
  late final AppBar _appBar;

  @override
  void initState() {
    // Creating new course
    if (widget.courseToEdit == null) {
      _titleController = TextEditingController();
      _periodsPerWeekday = [0, 0, 0, 0, 0];
      _appBar = AppBar(
          leading: PhosphorIcon(PhosphorIcons.bold.plus),
          title: const Text('Adicionar disciplina')
      );
    }

    // Editing course
    else {
      final course = widget.courseToEdit!;
      _titleController = TextEditingController(text: course.title);
      _periodsPerWeekday = course.periodsPerWeekday;
      _appBar = AppBar(
        leading: PhosphorIcon(PhosphorIcons.bold.pencil),
        title: const Text('Editar disciplina'),
      );
    }
    super.initState();
  }

  void _increasePeriods(int index) => setState(() => _periodsPerWeekday[index]++);

  void _decreasePeriods(int index) => setState(() {
    _periodsPerWeekday[index] = max(_periodsPerWeekday[index] - 1, 0);
  });

  bool get _buttonAvailable => _periodsPerWeekday.any((weekday) => weekday > 0)
      && _titleController.text.isNotEmpty;

  void _buttonAction() {
    // Creating new course
    if (widget.courseToEdit == null) {
      Courses.newCourse(
          title: _titleController.text,
          periodsPerWeekday: _periodsPerWeekday
      );
    }

    // Editing course
    else {
      Courses.editCourse(
          course: widget.courseToEdit!,
          title: _titleController.text,
          periodsPerWeekday: _periodsPerWeekday
      );
    }

    // Popping true will indicate that a new course has been created or edited.
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: _appBar,
      // A builder is necessary for us to know the height of the AppBar. We need
      // to know this so we can avoid overflow when the keyboard pops up.
      body: Builder(
        builder: (context) => SingleChildScrollView(
          padding: const EdgeInsets.all(_screenPadding),
          child: SizedBox(
            // This height must be exactly the height occupied by the child
            // Column, that contains all the widgets of the screen. We evaluate
            // it by taking all the screen height, subtracting the appBar and
            // status bar heights and the upper and lower paddings. This will
            // prevent the screen to be scrollable when there is enough space.
            // When the keyboard is opened or the screen height is very low, the
            // screen will turn scrollable, avoiding the vertical overflow.
            height: MediaQuery.of(context).size.height -
                (Scaffold.of(context).appBarMaxHeight ?? 0)
                - 2 * _screenPadding,
            child: Column(
              children: [
                TextField(
                  controller: _titleController,
                  // setState is needed to update the _buttonAvailable
                  // condition:
                  onChanged: (value) => setState(() {}),
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface
                  ),
                  decoration: const InputDecoration(
                      labelText: 'Nome da disciplina',
                      labelStyle: TextStyle(color: Colors.grey)
                  ),
                ),

                const Spacer(flex: 3),

                const Text(
                  'Marque a quantidade de períodos de aula por dia de semana.',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                const Text(
                    _periodsExplanationText,
                    textAlign: TextAlign.center
                ),

                const Spacer(),

                ...Iterable.generate(5, (index) => ListTile(
                  title: Text(weekdaysNames[index]),
                  visualDensity: VisualDensity.compact,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: () => _decreasePeriods(index),
                        icon: PhosphorIcon(PhosphorIcons.bold.minus),
                        splashRadius: 28,
                      ),
                      Text(_periodsPerWeekday[index].toString()),
                      IconButton(
                        onPressed: () => _increasePeriods(index),
                        icon: PhosphorIcon(PhosphorIcons.bold.plus),
                        splashRadius: 28,
                      ),
                    ],
                  ),
                )),

                const Spacer(flex: 3),

                SizedBox(
                    width: 200,
                    child: ElevatedButton(
                      onPressed: _buttonAvailable ? _buttonAction : null,
                      style: ButtonStyle(
                          shape: MaterialStateProperty.all(buttonRoundBorder)
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          PhosphorIcon(PhosphorIcons.regular.floppyDisk),
                          const Text('Salvar'),
                          const Icon(Icons.save, color: Colors.transparent)
                        ],
                      ),
                    )
                )
              ],
            ),
          ),
        ),
      )
  );
}

const _screenPadding = 16.0;

const _periodsExplanationText = 'Cada período corresponde a 50 minutos de '
    'aula. Se a sua aula começa, por exemplo, às 8:30 e termina às 10:10, '
    'então você tem dois períodos desta disciplina naquele dia.';




