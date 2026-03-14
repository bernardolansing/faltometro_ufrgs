import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'src/settings_manager.dart';
import 'src/courses_manager.dart';
import 'src/restaurant_manager.dart';
import 'src/storage_manager.dart';
import 'src/theme.dart';
import 'src/notifications.dart';
import 'src/screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const _Faltometro());
}

class _Faltometro extends StatefulWidget {
  const _Faltometro();

  @override
  State<_Faltometro> createState() => _FaltometroState();
}

class _FaltometroState extends State<_Faltometro> {
  bool _loading = true;

  @override
  void initState() {
    _initApp();
    super.initState();
  }

  void _initApp() async {
    await StorageManager.initialize();
    await Future.wait([
      CoursesManager.initialize(),
      RestaurantManager.initialize(),
      SettingsManager.initialize(),
      Notifications.initialize(),
    ]);
    if (mounted) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) =>
      NotificationListener<ThemeModeChangedNotification>(
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
          themeMode: _loading ? ThemeMode.system : SettingsManager.themeMode,
          home: _loading ? const _LoadingVariant() : const HomeScreen(),
        ),
      );
}

class _LoadingVariant extends StatelessWidget {
  const _LoadingVariant();

  @override
  Widget build(BuildContext context) => const Scaffold(
    body: SafeArea(
      child: Center(
        child: SizedBox(
          height: 32,
          width: 32,
          child: CircularProgressIndicator(),
        ),
      ),
    ),
  );
}

extension PercentageFormattingExtension on double {
  String get asPercentage => '${(this * 100).toInt()}%';
}
