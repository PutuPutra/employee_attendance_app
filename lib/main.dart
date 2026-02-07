import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'UI/login_screen.dart';
import 'blocs/settings/settings_bloc.dart';
import 'blocs/settings/settings_event.dart';
import 'blocs/settings/settings_state.dart';
import 'repositories/settings_repository.dart';
import 'l10n/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize SharedPreferences
  final prefs = await SharedPreferences.getInstance();

  // Create repository
  final settingsRepository = SettingsRepository(prefs);

  runApp(MyApp(settingsRepository: settingsRepository));
}

class MyApp extends StatelessWidget {
  final SettingsRepository settingsRepository;

  const MyApp({super.key, required this.settingsRepository});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          SettingsBloc(settingsRepository)
            ..add(const LoadSettings()), // Load settings saat app start
      child: const _AppView(),
    );
  }
}

class _AppView extends StatelessWidget {
  const _AppView();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsBloc, SettingsState>(
      builder: (context, state) {
        // Default values jika settings belum loaded
        ThemeMode themeMode = ThemeMode.system;
        Locale? locale;
        String? fontFamily;

        // Update values jika settings sudah loaded
        if (state is SettingsLoaded) {
          themeMode = state.settings.flutterThemeMode;
          locale = state.settings.locale;
          fontFamily = state.settings.fontFamily;
        }

        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Gunas Employee Attendance',

          // Theme configuration
          theme: _buildThemeData(Brightness.light, fontFamily),
          darkTheme: _buildThemeData(Brightness.dark, fontFamily),
          themeMode: themeMode,

          // Localization configuration
          locale: locale,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,

          // Home screen
          home: const LoginScreen(),
        );
      },
    );
  }

  /// Build ThemeData dengan font family yang dipilih
  ThemeData _buildThemeData(Brightness brightness, String? fontFamily) {
    return ThemeData(
      brightness: brightness,
      fontFamily: fontFamily,
      // Customize theme sesuai kebutuhan
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.blue,
        brightness: brightness,
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        backgroundColor: brightness == Brightness.light
            ? Colors.white
            : Colors.grey[900],
        foregroundColor: brightness == Brightness.light
            ? Colors.black
            : Colors.white,
        titleTextStyle: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 18,
          fontFamily: fontFamily,
          color: brightness == Brightness.light ? Colors.black : Colors.white,
        ),
      ),
      scaffoldBackgroundColor: brightness == Brightness.light
          ? Colors.grey.shade100
          : Colors.grey[850],
    );
  }
}
