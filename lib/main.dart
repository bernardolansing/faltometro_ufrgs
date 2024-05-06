import 'package:flutter/material.dart';

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
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Faltômetro UFRGS',
    theme: lightTheme,
    darkTheme: darkTheme,
    themeMode: Settings.themeMode,
    home: const Homepage(),
  );
}
