import 'package:flutter/material.dart';

const _primaryColor = Color(0xFF29166F);
const _secondaryColor = Color(0xFF43F4B5);
const _errorColor = Color(0xFFC83E4D);
const _backgroundColor = Color(0xFFE0E1E8);
const _surfaceColor = Color(0xFFDAE3E7);

final theme = ThemeData(
  colorScheme: const ColorScheme(
      brightness: Brightness.light,
      primary: _primaryColor,
      onPrimary: Colors.white,
      secondary: _secondaryColor,
      onSecondary: Colors.white,
      error: _errorColor,
      onError: Colors.white,
      background: _backgroundColor,
      onBackground: Colors.black,
      surface: _surfaceColor,
      onSurface: Colors.black
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
          borderRadius: BorderRadius.circular(16)
      ))
    )
  ),
  dialogTheme: const DialogTheme(
    backgroundColor: Colors.white,
    surfaceTintColor: Colors.transparent,
  )
);
