import 'package:faltometro_ufrgs/src/course.dart';
import 'package:faltometro_ufrgs/src/screens/common.dart';
import 'package:faltometro_ufrgs/src/screens/course_screen.dart';
import 'package:faltometro_ufrgs/src/screens/register_absence_dialogs.dart';
import 'package:faltometro_ufrgs/src/storage.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  bool _loading = true;

  @override
  void initState() {
    _initialize();
    super.initState();
  }

  Future<void> _initialize() async {
    await Storage.initialize();
    Courses.load(Storage.coursesEntry);
    setState(() => _loading = false);
  }

  Future<void> _openNewCourseScreen() async {
    final route = MaterialPageRoute<bool>(
        builder: (context) => const CourseScreen.newCourse()
    );
    final shouldUpdate = await Navigator.of(context).push(route);
    if (shouldUpdate == true) { setState(() {}); }
  }

  Future<void> _openEditCourseScreen(Course course) async {
    final route = MaterialPageRoute<bool>(
        builder: (context) => CourseScreen.edit(course: course)
    );
    final shouldUpdate = await Navigator.of(context).push(route);
    if (shouldUpdate == true) { setState(() {}); }
  }

  Future<void> _openRegisterAbsenceDialog(Course course) async {
    final shouldUpdate = await showDialog<bool>(
        context: context,
        builder: (context) => course.isUniform
            ? UniformCourseRegisterAbsenceDialog(course)
            : NonUniformCourseRegisterAbsenceDialog(course)
    );

    if (shouldUpdate == true) { setState(() {}); }
  }

  Future<void> _deleteCourse(Course course) async {
    final deletionConfirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Confirmar exclusão'),
          content: Text(
              'Você tem certeza de que quer excluir a disciplina '
                  '${course.title}?'
          ),
          actions: [
            TextButton(
                onPressed: Navigator.of(context).pop,
                child: const Text('Cancelar')
            ),
            ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Confirmar')
            )
          ],
        )
    );

    if (deletionConfirmed == true) {
      Courses.deleteCourse(course);
      setState(() {});
    }
  }

  Widget get _contentToDisplay {
    if (_loading) { return _buildLoading(); }
    if (Courses.courses.isNotEmpty) { return _buildCoursesList(); }
    return _buildEmptyList();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
        leading: PhosphorIcon(PhosphorIcons.bold.flame),
        title: const Text('Faltômetro UFRGS')
    ),
    body: SafeArea(
      child: _contentToDisplay,
    ),
    floatingActionButton: FloatingActionButton(
      onPressed: _openNewCourseScreen,
      backgroundColor: Theme.of(context).colorScheme.primary,
      child: PhosphorIcon(PhosphorIcons.bold.plus, size: 28),
    ),
  );

  Widget _buildLoading() => const Center(
    child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: 32, width: 32, child: CircularProgressIndicator()),
          SizedBox(height: 12),
          Text('Carregando...', style: TextStyle(fontSize: 16))
        ]
    ),
  );

  Widget _buildEmptyList() => Center(
      child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              PhosphorIcon(PhosphorIcons.regular.listPlus),
              const SizedBox(height: 16),
              const Text(
                'Nenhuma disciplina adicionada ainda. Adicione sua primeira!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18),
              )
            ],
          )
      )
  );

  Widget _buildCoursesList() => SingleChildScrollView(
    padding: const EdgeInsets.all(10),
    child: Column(
      children: Courses.courses.map((course) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                      child: Text(
                          course.title,
                          softWrap: true,
                          style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold
                          )
                      )
                  ),

                  Row(
                    children: [
                      IconButton(
                        onPressed: () => _openEditCourseScreen(course),
                        icon: PhosphorIcon(PhosphorIcons.regular.pencil),
                      ),
                      IconButton(
                          onPressed: () => _deleteCourse(course),
                          icon: PhosphorIcon(PhosphorIcons.regular.trash)
                      )
                    ],
                  )
                ],
              ),

              const SizedBox(height: 8),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                    onPressed: () => _openRegisterAbsenceDialog(course),
                    style: ButtonStyle(
                        backgroundColor: MaterialStateProperty
                            .all(Theme.of(context).colorScheme.secondary),
                        textStyle: MaterialStateProperty
                            .all(const TextStyle(fontSize: 16)),
                        shape: MaterialStateProperty.all(buttonRoundBorder)
                    ),
                    child: const Text('Registrar falta')
                ),
              )
            ],
          ),
        ),
      )).toList(growable: false),
    ),
  );
}
