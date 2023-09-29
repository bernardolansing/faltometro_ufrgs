import 'dart:math';
import 'package:faltometro_ufrgs/src/course.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class NewCourseScreen extends StatefulWidget {
  const NewCourseScreen({super.key});

  @override
  State<NewCourseScreen> createState() => _NewCourseScreenState();
}

class _NewCourseScreenState extends State<NewCourseScreen> {
  final _titleController = TextEditingController();
  final _periodsPerWeek = [0, 0, 0, 0, 0];

  void _increasePeriods(int index) => setState(() => _periodsPerWeek[index]++);

  void _decreasePeriods(int index) => setState(() {
    _periodsPerWeek[index] = max(_periodsPerWeek[index] - 1, 0);
  });

  bool get _buttonAvailable => _periodsPerWeek.any((weekday) => weekday > 0)
      && _titleController.text.isNotEmpty;

  void _newCourse() {
    Courses.newCourse(
        title: _titleController.text,
        periodsPerWeekday: _periodsPerWeek
    );
    // Popping true will indicate that a new course has been created.
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(
          leading: PhosphorIcon(PhosphorIcons.bold.plus),
          title: const Text('Adicionar disciplina')
      ),
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
                  title: Text(_weekdaysNames[index]),
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
                      Text(_periodsPerWeek[index].toString()),
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
                      onPressed: _buttonAvailable ? _newCourse : null,
                      style: ButtonStyle(
                          shape: MaterialStateProperty.all(_buttonBorder)
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

const _weekdaysNames = [
  'Segunda-feira', 'Terça-feira', 'Quarta-feira', 'Quinta-feira', 'Sexta-feira'
];

final _buttonBorder = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(16)
);
