import 'package:flutter/material.dart';

const _primaryColor = Color(0xFF29166F);
const _secondaryColor = Color(0xFF43F4B5);
const _errorColor = Color(0xFFC83E4D);

final lightTheme = ThemeData(
    colorScheme: const ColorScheme(
      brightness: Brightness.light,
      primary: _primaryColor,
      onPrimary: Colors.white,
      secondary: _secondaryColor,
      onSecondary: Colors.white,
      error: _errorColor,
      onError: Colors.white,
      background: Color(0xFFE0E1E8),
      onBackground: Colors.black,
      surface: Color(0xFFDAE3E7),
      onSurface: Colors.black,
    ),
    scaffoldBackgroundColor: const Color.fromRGBO(238, 238, 238, 1.0),
    appBarTheme: const AppBarTheme(
      color: _primaryColor,
      foregroundColor: Colors.white,
    ),
    cardTheme: const CardTheme(
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ButtonStyle(
        backgroundColor: const MaterialStatePropertyAll(_primaryColor),
        surfaceTintColor: const MaterialStatePropertyAll(Colors.transparent),
        foregroundColor: const MaterialStatePropertyAll(Colors.white),
        shape: MaterialStatePropertyAll(RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        )),
      ),
    ),
    dialogTheme: const DialogTheme(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
    )
);

final darkTheme = ThemeData(
  colorScheme: const ColorScheme(
    brightness: Brightness.dark,
    primary: _primaryColor,
    onPrimary: Colors.white,
    secondary: _secondaryColor,
    onSecondary: Colors.white,
    error: _errorColor,
    onError: Colors.white,
    background: Color(0xFF5F5E5E),
    onBackground: Color(0xFFC5C5C5),
    surface: Color(0xFF6C6C6C),
    onSurface: Color(0xFFC5C5C5),
  ),
  scaffoldBackgroundColor: const Color(0xFF3D3D3D),
  appBarTheme: const AppBarTheme(
    color: Colors.black87,
    foregroundColor: Color(0xFFCBCBCB),
  ),
  cardTheme: const CardTheme(
    color: Colors.black54,
    surfaceTintColor: Colors.transparent,
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ButtonStyle(
      backgroundColor: const MaterialStatePropertyAll(_primaryColor),
      surfaceTintColor: const MaterialStatePropertyAll(Colors.transparent),
      foregroundColor: const MaterialStatePropertyAll(Colors.white),
      shape: MaterialStatePropertyAll(RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      )),
    ),
  ),
  textButtonTheme: const TextButtonThemeData(
    style: ButtonStyle(
      textStyle: MaterialStatePropertyAll(TextStyle(
        shadows: [
          Shadow(blurRadius: 18.0, color: Colors.white),
        ],
      )),
    ),
  ),
  dialogTheme: const DialogTheme(
    backgroundColor: Color(0xFF4C4C4C),
  ),
);
