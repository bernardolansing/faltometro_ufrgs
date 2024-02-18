import 'package:faltometro_ufrgs/src/screens/homepage.dart';
import 'package:faltometro_ufrgs/src/theme.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Faltômetro UFRGS',
    theme: theme,
    home: const Homepage(),
  );
}
