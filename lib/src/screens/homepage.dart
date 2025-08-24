import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../course.dart';
import '../notifications.dart';
import '../settings.dart';
import '../storage.dart';
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
        if (permissionsAreOk) {
          Notifications.updateSchedules();
        }
      }
    }
  }

  Future<void> _openEditCourseScreen(Course course) async {
    final route = MaterialPageRoute<bool>(
      builder: (context) => CourseScreen.edit(course: course),
    );
    final shouldUpdate = await Navigator.of(context).push(route);
    if (shouldUpdate == true) {
      setState(() {});
    }
  }

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

  Future<void> _openRestaurantTicketDialog() async {
    final ticketChanged = await showDialog(
      context: context,
      builder: (context) => const _RestaurantTicketDialog(),
    );
    if (ticketChanged == true) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    floatingActionButton: AnimatedSlide(
      offset: _fabVisible ? Offset.zero : const Offset(0, 3),
      duration: const Duration(milliseconds: 300),
      child: FloatingActionButton(
        onPressed: _openNewCourseScreen,
        child: PhosphorIcon(PhosphorIcons.bold.plus, size: 28),
      ),
    ),
    body: NotificationListener<UserScrollNotification>(
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
      child: SafeArea(
        child: Column(
          children: [
            _Navbar(onOpenSettings: _openSettingsScreen),
            const Divider(color: Colors.black26, height: 1),

            if (Courses.courses.isEmpty)
              const Expanded(child: _EmptyListVariant())
            else
              Expanded(
                child: _RegularVariant(
                  onRestaurantTicketTap: _openRestaurantTicketDialog,
                  onRegisterAbsence: _openRegisterAbsenceScreen,
                  onEditCourse: _openEditCourseScreen,
                  onDeleteCourse: _deleteCourse,
                ),
              ),
          ],
        ),
      ),
    ),
  );
}

class _Navbar extends StatelessWidget {
  final void Function() onOpenSettings;

  const _Navbar({required this.onOpenSettings});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.brightness == Brightness.light
        ? theme.colorScheme.primary
        : theme.colorScheme.secondary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Image.asset(
            'assets/white-logo.png',
            width: 24,
            color: color,
          ),
          const SizedBox(width: 8),
          Image.asset(
            'assets/white-mark.png',
            height: 24,
            color: color,
          ),

          const Spacer(),

          IconButton(
            onPressed: () {
              final route = MaterialPageRoute(
                builder: (context) => ExplanationScreen(),
              );
              Navigator.of(context).push(route);
            },
            style: ButtonStyle(iconColor: WidgetStatePropertyAll(color)),
            icon: PhosphorIcon(PhosphorIcons.regular.question),
          ),
          IconButton(
            onPressed: onOpenSettings,
            style: ButtonStyle(iconColor: WidgetStatePropertyAll(color)),
            icon: PhosphorIcon(PhosphorIcons.regular.gear),
          ),
        ],
      ),
    );
  }
}


class _RegularVariant extends StatelessWidget {
  final void Function() onRestaurantTicketTap;
  final void Function(Course) onRegisterAbsence;
  final void Function(Course) onEditCourse;
  final void Function(Course) onDeleteCourse;

  const _RegularVariant({
    required this.onRestaurantTicketTap,
    required this.onRegisterAbsence,
    required this.onEditCourse,
    required this.onDeleteCourse,
  });

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(8),
    children: [
      InkWell(
        onTap: onRestaurantTicketTap,
        child: Chip(
          avatar: PhosphorIcon(PhosphorIcons.regular.ticket),
          label: Storage.restaurantTicket != null
              ? Text('Ticket RU: ${Storage.restaurantTicket}')
              : const Text('Adicionar ticket RU'),
        ),
      ),

      ...Courses.courses.map((c) => _CourseCard(
        course: c,
        onAbsence: () => onRegisterAbsence(c),
        onEdit: () => onEditCourse(c),
        onDelete: () => onDeleteCourse(c),
      )),
    ],
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        spacing: 8,
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            title: Text(
              course.title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                decoration: TextDecoration.underline,
                decorationColor: Theme.of(context).colorScheme.secondary,
                decorationThickness: 2,
              ),
            ),
            subtitle: Text(
              '${course.hoursOfClass} horas • ${course.credits} créditos',
            ),
            titleAlignment: ListTileTitleAlignment.top,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
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
            ),
          ),

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

          // Button to open the register absence dialog.
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onAbsence,
              child: const Text('Registrar falta'),
            ),
          ),
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
      ),
    ],
  );
}

class _RestaurantTicketDialog extends StatefulWidget {
  const _RestaurantTicketDialog();

  @override
  State<_RestaurantTicketDialog> createState() =>
      _RestaurantTicketDialogState();
}

class _RestaurantTicketDialogState extends State<_RestaurantTicketDialog> {
  final _inputController = TextEditingController();

  bool _invalidInput = false;

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Definir ticket RU'),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      spacing: 8,
      children: [
        const Text(_message, textAlign: TextAlign.justify),
        TextField(
          controller: _inputController,
          keyboardType: TextInputType.number,
          maxLength: 6,
          onChanged: (value) => setState(() => _invalidInput = false),
          decoration: InputDecoration(
            filled: true,
            hintText: 'Digite o seu ticket',
            errorText: _invalidInput ? 'O ticket digitado não é válido' : null,
          ),
        ),
      ],
    ),
    actions: [
      TextButton(
        onPressed: Navigator.of(context).pop,
        child: const Text('Cancelar'),
      ),
      ElevatedButton(
        onPressed: () {
          if (_inputController.text.isEmpty) {
            Storage.setRestaurantTicket(null);
          }
          else {
            final digitRegex = RegExp(r'^\d{6}$');
            if (! digitRegex.hasMatch(_inputController.text)) {
              return setState(() => _invalidInput = true);
            }
            Storage.setRestaurantTicket(_inputController.text);
          }

          Navigator.of(context).pop(true);
        },
        child: const Text('Confirmar'),
      ),
    ],
  );

  static const _message = 'Você pode anotar o seu ticket do RU aqui, para não '
      'ter que entrar no portal do aluno caso se esqueça dele.';
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
