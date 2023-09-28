import 'package:faltometro_ufrgs/src/homepage.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Faltômetro UFRGS',
    theme: _theme,
    home: const Homepage(),
  );
}

final _theme = ThemeData(
  colorScheme: const ColorScheme(
    brightness: Brightness.light,
    primary: Color.fromRGBO(229, 34, 21, 1.0),
    onPrimary: Colors.white,
    secondary: Color.fromRGBO(0, 100, 146, 1.0),
    onSecondary: Colors.white,
    error: Color.fromRGBO(200, 62, 77, 1.0),
    onError: Colors.white,
    background: Color.fromRGBO(224, 225, 232, 1.0),
    onBackground: Colors.black,
    surface: Color.fromRGBO(218, 227, 231, 1.0),
    onSurface: Colors.black
  )
);
