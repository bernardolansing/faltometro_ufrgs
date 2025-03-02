import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../course.dart';
import '../notifications.dart';
import '../settings.dart';
import 'course_screen.dart';
import 'explanation_screen.dart';
import 'register_absence_screen.dart';
import 'settings_screen.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  bool _fabVisible = true;

  Future<void> _openNewCourseScreen() async {
    final route = MaterialPageRoute<bool>(
      builder: (context) => const CourseScreen.newCourse(),
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
      builder: (context) => CourseScreen.edit(course: course),
    );
    final shouldUpdate = await Navigator.of(context).push(route);
    if (shouldUpdate == true) { setState(() {}); }
  }

  Future<void> _openExplanationScreen() => Navigator.of(context)
      .push(MaterialPageRoute(builder: (context) => ExplanationScreen()));

  void _openSettingsScreen() async {
    final route = MaterialPageRoute<bool>(
      builder: (context) => const SettingsScreen(),
    );
    final shouldRefresh = await Navigator.of(context).push(route);
    if (shouldRefresh == true) { setState(() {}); }
  }

  Future<void> _openRegisterAbsenceScreen(Course course) async {
    final route = MaterialPageRoute(
      builder: (context) => RegisterAbsenceScreen(course),
    );
    await Navigator.of(context).push(route);
    setState(() {});
  }

  Future<void> _deleteCourse(Course course) async {
    final deletionConfirmed = await showDialog<bool>(
      context: context,
      builder: (context) => _ConfirmCourseDeletionDialog(course),
    );

    if (deletionConfirmed == true) {
      Courses.deleteCourse(course);
      Notifications.updateSchedules();
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      leading: Image.asset('assets/white-logo.png'),
      title: const Text('Faltômetro UFRGS'),
      actions: [
        IconButton(
          onPressed: _openExplanationScreen,
          icon: PhosphorIcon(PhosphorIcons.regular.question),
        ),
        IconButton(
          onPressed: _openSettingsScreen,
          icon: PhosphorIcon(PhosphorIcons.regular.gear),
        ),
      ],
    ),
    body: SafeArea(
      child: Courses.courses.isNotEmpty
          ? _buildCoursesList()
          : const _EmptyListVariant(),
    ),
    floatingActionButton: AnimatedSlide(
      offset: _fabVisible ? Offset.zero : const Offset(0, 3),
      duration: const Duration(milliseconds: 300),
      child: FloatingActionButton(
        onPressed: _openNewCourseScreen,
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: PhosphorIcon(PhosphorIcons.bold.plus, size: 28),
      ),
    ),
  );

  Widget _buildCoursesList() => NotificationListener<UserScrollNotification>(
    onNotification: (scroll) {
      setState(() {
        if (scroll.direction == ScrollDirection.forward) {
          _fabVisible = true;
        } else if (scroll.direction == ScrollDirection.reverse) {
          _fabVisible = false;
        }
      });
      return false; // Return false to stop the notification bubbling.
    },
    child: ListView(
      padding: const EdgeInsets.all(10),
      children: Courses.courses.map((c) => _CourseCard(
        course: c,
        onAbsence: () => _openRegisterAbsenceScreen(c),
        onEdit: () => _openEditCourseScreen(c),
        onDelete: () => _deleteCourse(c),
      )).toList(growable: false),
    ),
  );
}

class _EmptyListVariant extends StatelessWidget {
  const _EmptyListVariant();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(16),
    child: Column(
      children: [
        const Spacer(flex: 1),

        Image.asset('assets/front.png'),
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
        ),

        const Spacer(flex: 2),
      ],
    ),
  );
}

class _CourseCard extends StatelessWidget {
  final Course course;
  final void Function() onAbsence;
  final void Function() onEdit;
  final void Function() onDelete;

  const _CourseCard({
    required this.course,
    required this.onAbsence,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) => Card(
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
                  ),
                ),
              ),

              Row(
                children: [
                  IconButton(
                    onPressed: onEdit,
                    icon: PhosphorIcon(PhosphorIcons.regular.pencil),
                  ),
                  IconButton(
                    onPressed: onDelete,
                    icon: PhosphorIcon(PhosphorIcons.regular.trash),
                  ),
                ],
              )
            ],
          ),

          const SizedBox(height: 8),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox.fromSize(
                    size: _circularProgressSize,
                    child: CircularProgressIndicator(
                      value: course.burntAbsencesPercentage,
                      color: Theme.of(context).colorScheme.secondary,
                      backgroundColor: Theme.of(context).colorScheme.surface,
                    ),
                  ),

                  Text(
                    course.burntAbsencesPercentage.asPercentage,
                    style: course.isCritical
                        ? _circularProgressTextStyleCritical
                        : _circularProgressTextStyle,
                  ),
                ],
              ),

              const SizedBox(width: 12),

              Flexible(child: _cardText),
            ],
          ),

          const SizedBox(height: 8),

          // Button to open the register absence dialog.
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onAbsence,
              child: const Text('Registrar falta'),
            ),
          )
        ],
      ),
    ),
  );

  Text get _cardText {
    if (course.skippedPeriods < 1) {
      return const Text(
        'Você ainda não faltou nenhuma vez nesta cadeira!',
        textAlign: TextAlign.center,
      );
    }

    if (course.isGameOver) {
      return const Text(
        'Conceito FF: Fez Fiasco!!!',
        textAlign: TextAlign.left,
        style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
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
      final remainingAbsences = course.skippablePeriods - course.skippedPeriods;
      text = 'Você queimou ${course.burntAbsencesPercentage.asPercentage} das '
          'faltas para esta disciplina. Pode faltar mais $remainingAbsences '
          'períodos.';
    }

    return Text(text);
  }
}

class _ConfirmCourseDeletionDialog extends StatelessWidget {
  final Course _course;

  const _ConfirmCourseDeletionDialog(this._course);

  String get _dialogText => 'Você tem certeza de que quer excluir a disciplina '
      '${_course.title}?';

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Confirmar exclusão'),
    content: Text(_dialogText),
    actions: [
      TextButton(
        onPressed: Navigator.of(context).pop,
        child: const Text('Cancelar'),
      ),
      ElevatedButton(
        onPressed: () => Navigator.of(context).pop(true),
        child: const Text('Confirmar'),
      )
    ],
  );
}

const _circularProgressSize = Size(100, 100);
const _circularProgressTextStyle = TextStyle(
  fontWeight: FontWeight.w800,
  fontSize: 24,
);
const _circularProgressTextStyleCritical = TextStyle(
  fontWeight: FontWeight.w900,
  fontSize: 26,
  color: Colors.red,
);
