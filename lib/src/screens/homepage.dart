import 'package:faltometro_ufrgs/src/course.dart';
import 'package:faltometro_ufrgs/src/screens/new_course.dart';
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

  Future<void> openNewCourseScreen() => Navigator.of(context)
      .push(MaterialPageRoute(builder: (context) => const NewCourseScreen()));

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
        leading: PhosphorIcon(PhosphorIcons.bold.flame),
        title: const Text('Faltômetro UFRGS')
    ),
    body: SafeArea(
      child: buildEmptyList(),
    ),
    floatingActionButton: FloatingActionButton(
      onPressed: openNewCourseScreen,
      backgroundColor: Theme.of(context).colorScheme.primary,
      child: PhosphorIcon(PhosphorIcons.bold.plus, size: 28),
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

  Widget buildCoursesList() => Container();
}
