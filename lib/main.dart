import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'src/theme.dart';
import 'src/storage.dart';
import 'src/course.dart';
import 'src/settings.dart';
import 'src/notifications.dart';
import 'src/screens/homepage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Storage.initialize();
  Courses.load();
  Settings.load();
  Notifications.initialize();
  runApp(const Faltometro());
}

class Faltometro extends StatefulWidget {
  const Faltometro({super.key});

  @override
  State<Faltometro> createState() => FaltometroState();
}

class FaltometroState extends State<Faltometro> {
  @override
  Widget build(BuildContext context) {

    return NotificationListener<ThemeModeChangedNotification>(
        onNotification: (_) {
          // App's theme has changed, so we have to refresh it.
          setState(() {});
          return false;
        },
        child: MaterialApp(
          title: 'Faltômetro UFRGS',
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          supportedLocales: const [
            Locale('pt', 'BR'),
          ],
          theme: lightTheme,
          darkTheme: darkTheme,
          themeMode: Settings.themeMode,
          home: const Homepage(),
        )
    );
  }
}
