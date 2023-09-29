import 'package:faltometro_ufrgs/src/course.dart';
import 'package:faltometro_ufrgs/src/screens/course_screen.dart';
import 'package:faltometro_ufrgs/src/storage.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  bool loading = true;

  @override
  void initState() {
    initialize();
    super.initState();
  }

  Future<void> initialize() async {
    await Storage.initialize();
    Courses.load(Storage.coursesEntry);
    setState(() => loading = false);
  }

  Future<void> openNewCourseScreen() async {
    final route = MaterialPageRoute<bool>(
        builder: (context) => const CourseScreen.newCourse()
    );
    final shouldUpdate = await Navigator.of(context).push(route);
    if (shouldUpdate == true) { setState(() {}); }
  }

  Future<void> openEditCourseScreen(Course course) async {
    final route = MaterialPageRoute<bool>(
        builder: (context) => CourseScreen.edit(course: course)
    );
    final shouldUpdate = await Navigator.of(context).push(route);
    if (shouldUpdate == true) { setState(() {}); }
  }

  Future<void> deleteCourse(Course course) async {
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
    if (loading) { return buildLoading(); }
    if (Courses.courses.isNotEmpty) { return buildCoursesList(); }
    return buildEmptyList();
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
      onPressed: openNewCourseScreen,
      backgroundColor: Theme.of(context).colorScheme.primary,
      child: PhosphorIcon(PhosphorIcons.bold.plus, size: 28),
    ),
  );

  Widget buildLoading() => const Center(
    child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: 32, width: 32, child: CircularProgressIndicator()),
          SizedBox(height: 12),
          Text('Carregando...', style: TextStyle(fontSize: 16))
        ]
    ),
  );

  Widget buildEmptyList() => Center(
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

  Widget buildCoursesList() => SingleChildScrollView(
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
                        onPressed: () => openEditCourseScreen(course),
                        icon: PhosphorIcon(PhosphorIcons.regular.pencil),
                      ),
                      IconButton(
                          onPressed: () => deleteCourse(course),
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
                    onPressed: () {},
                    style: ButtonStyle(
                        backgroundColor: MaterialStateProperty
                            .all(Theme.of(context).colorScheme.secondary),
                        textStyle: MaterialStateProperty
                            .all(const TextStyle(fontSize: 16))
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
