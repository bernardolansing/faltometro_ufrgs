import 'package:faltometro_ufrgs/src/course.dart';
import 'package:faltometro_ufrgs/src/screens/common.dart';
import 'package:faltometro_ufrgs/src/screens/course_screen.dart';
import 'package:faltometro_ufrgs/src/screens/explanation_screen.dart';
import 'package:faltometro_ufrgs/src/notifications.dart';
import 'package:faltometro_ufrgs/src/screens/register_absence_dialogs.dart';
import 'package:faltometro_ufrgs/src/screens/settings_screen.dart';
import 'package:faltometro_ufrgs/src/settings.dart';
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
    Courses.load();
    Settings.load();
    Notifications.initialize();
    setState(() => _loading = false);
  }

  Future<void> _openNewCourseScreen() async {
    final route = MaterialPageRoute<bool>(
        builder: (context) => const CourseScreen.newCourse()
    );
    final courseAdded = await Navigator.of(context).push(route);

    if (courseAdded == true && mounted) {
      setState(() {}); // Refresh the screen.

      if (Settings.notificationsEnabled) {
        // If notifications are enabled, we should check if we got permissions
        // to send them and if they're set up.

        // Check if the app has permission to send notifications. This may
        // trigger extra dialogs.
        final permissionsAreOk = await Notifications.checkPermissions(context);
        // If they are, make sure that they're properly scheduled.
        if (permissionsAreOk) { Notifications.updateSchedules(); }
      }
    }
  }

  Future<void> _openEditCourseScreen(Course course) async {
    final route = MaterialPageRoute<bool>(
        builder: (context) => CourseScreen.edit(course: course)
    );
    final shouldUpdate = await Navigator.of(context).push(route);
    if (shouldUpdate == true) { setState(() {}); }
  }

  Future<void> _openExplanationScreen() => Navigator.of(context)
      .push(MaterialPageRoute(builder: (context) => const ExplanationScreen()));

  void _openSettingsScreen() => Navigator.of(context)
      .push(MaterialPageRoute(builder: (context) => const SettingsScreen()));

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
      Notifications.updateSchedules();
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
      title: const Text('Faltômetro UFRGS'),
      actions: [
        IconButton(
            onPressed: _openExplanationScreen,
            icon: PhosphorIcon(PhosphorIcons.regular.question)
        ),

        IconButton(
          onPressed: _openSettingsScreen,
          icon: PhosphorIcon(PhosphorIcons.regular.gear),
        ),
      ],
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
              ),
              const SizedBox(height: 24),
              const Text(
                'Esclarecimentos importantes na página de ajuda, no canto '
                    'superior direito.',
                textAlign: TextAlign.center,
              )
            ],
          )
      )
  );

  Widget _buildCoursesList() => ListView(
    padding: const EdgeInsets.all(10),
    children: Courses.courses.map(_buildCourseCard).toList(growable: false),
  );

  Widget _buildCourseCard(Course course) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Row that displays the course name and the edit and delete buttons.
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                  child: Text(
                      course.title,
                      softWrap: true,
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.underline,
                          decorationColor: Theme.of(context)
                              .colorScheme.secondary,
                          decorationThickness: 2,
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

          buildCourseCardContent(course),

          const SizedBox(height: 8),

          // Button to open the register absence dialog.
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
                onPressed: () => _openRegisterAbsenceDialog(course),
                style: ButtonStyle(
                    shape: MaterialStatePropertyAll(buttonRoundBorder)
                ),
                child: const Text('Registrar falta')
            ),
          )
        ],
      ),
    ),
  );

  Widget buildCourseCardContent(Course course) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceAround,
    children: [
      Stack(
        alignment: Alignment.center,
        children: [
          SizedBox.fromSize(
            size: _circularProgressSize,
            child: CircularProgressIndicator(
              value: course.burnAbsencesPercentage,
              color: Theme.of(context).colorScheme.secondary,
              backgroundColor: Theme.of(context).colorScheme.background,
            ),
          ),

          Text(
            course.burnAbsencesPercentage.asPercentage,
            style: course.isCritical
                ? _circularProgressTextStyleCritical
                : _circularProgressTextStyle,
          ),
        ],
      ),

      const SizedBox(width: 12),

      Flexible(child: _mountCardText(course)),
    ],
  );

  Text _mountCardText(Course course) {
    if (course.periodsSkipped < 1) {
      return const Text(
        'Você ainda não faltou nenhuma vez nesta cadeira!',
        textAlign: TextAlign.center,
      );
    }

    if (course.isGameOver) {
      return const Text(
          'Conceito FF: Fez Fiasco!!!',
          textAlign: TextAlign.left,
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)
      );
    }

    if (course.isCritical) {
      return const Text(
        'Porcentagem crítica de faltas. Sua aprovação não é garantida. Evite '
            'ao máximo faltar novamente.',
        textAlign: TextAlign.center,
        style: TextStyle(fontWeight: FontWeight.w800),
      );
    }

    late final String text;

    if (course.isUniform) {
      final plural = course.skippedClasses > 1 ? 's' : '';
      text = 'Você faltou em ${course.skippedClasses} aula$plural desta '
          'disciplina. A tolerância é ${course.skippableClassDays} faltas.';
    }

    else {
      final remainingAbsences = course.skippablePeriods - course.periodsSkipped;
      text = 'Você queimou ${course.burnAbsencesPercentage.asPercentage} das '
          'faltas para esta disciplina. Pode faltar mais $remainingAbsences '
          'períodos.';
    }

    return Text(text);
  }
}

const _circularProgressSize = Size(100, 100);
const _circularProgressTextStyle = TextStyle(
    fontWeight: FontWeight.w800,
    fontSize: 24
);
const _circularProgressTextStyleCritical = TextStyle(
    fontWeight: FontWeight.w900,
    fontSize: 26,
    color: Colors.red
);
