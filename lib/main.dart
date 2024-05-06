import 'package:flutter/material.dart';

import 'src/theme.dart';
import 'src/screens/homepage.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Faltômetro UFRGS',
    theme: darkTheme,
    // darkTheme: darkTheme,
    home: const Homepage(),
  );
}
