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
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        return states.contains(WidgetState.disabled)
            ? const Color(0xFFBDC2C2)
            : _primaryColor;
      }),
      surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
      foregroundColor: const WidgetStatePropertyAll(Colors.white),
      iconColor: const WidgetStatePropertyAll(Colors.white),
      shape: WidgetStatePropertyAll(RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      )),
    ),
  ),
  dialogTheme: const DialogTheme(
    backgroundColor: Colors.white,
    surfaceTintColor: Colors.transparent,
  ),
  scrollbarTheme: const ScrollbarThemeData(
    crossAxisMargin: 2,
    thickness: WidgetStatePropertyAll(4),
    radius: Radius.circular(4),
    thumbColor: WidgetStatePropertyAll(_primaryColor),
  ),
  segmentedButtonTheme: SegmentedButtonThemeData(
    style: ButtonStyle(
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        return states.contains(WidgetState.selected) ? _primaryColor : null;
      }),
      iconColor: const WidgetStatePropertyAll(Colors.white),
    ),
  ),
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
    surface: Color(0xFF6C6C6C),
    onSurface: Color(0xFFE1DEDE),
  ),
  scaffoldBackgroundColor: const Color(0xFF2F2F2F),
  appBarTheme: const AppBarTheme(
    color: Colors.black87,
    foregroundColor: Colors.white,
  ),
  cardTheme: const CardTheme(
    color: Colors.black54,
    surfaceTintColor: Colors.transparent,
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ButtonStyle(
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        return states.contains(WidgetState.disabled)
            ? const Color(0xFF888A8A)
            : _primaryColor;
      }),
      surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
      foregroundColor: const WidgetStatePropertyAll(Colors.white),
      iconColor: const WidgetStatePropertyAll(Colors.white),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
  ),
  textButtonTheme: const TextButtonThemeData(
    style: ButtonStyle(foregroundColor: WidgetStatePropertyAll(Colors.white)),
  ),
  dialogTheme: const DialogTheme(
    titleTextStyle: TextStyle(color: Colors.white, fontSize: 22),
    backgroundColor: Color(0xFF4C4C4C),
  ),
  segmentedButtonTheme: const SegmentedButtonThemeData(
    style: ButtonStyle(
      iconColor: WidgetStatePropertyAll(Colors.white),
    ),
  ),
);

/// Dispatched when user changes the theme mode.
class ThemeModeChangedNotification extends Notification {}
