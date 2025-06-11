import 'package:flutter/material.dart';
import 'pages/login_page.dart';
import 'pages/language_selection_page.dart';
import 'pages/language_welcome_page.dart';
import 'pages/traffic_condition_page.dart';
import 'pages/reward_page.dart';
import 'theme_provider.dart';

final ThemeData lightTheme = ThemeData(
  brightness: Brightness.light,
  primaryColor: const Color(0xFF0D47A1),
  scaffoldBackgroundColor: const Color(0xFFE3F2FD),
  colorScheme: const ColorScheme.light(
    primary: Color(0xFF0D47A1),
    secondary: Color(0xFF1976D2),
    background: Color(0xFFE3F2FD),
    surface: Color(0xFFB3E5FC),
    onPrimary: Colors.white,
    onSecondary: Colors.white,
    onSurface: Colors.black,
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: const Color(0xFFB3E5FC),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFF00E5FF)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFF00E5FF), width: 2),
    ),
    hintStyle: TextStyle(color: const Color(0xFF00E5FF).withOpacity(0.7)),
    labelStyle: const TextStyle(color: Color(0xFF00E5FF)),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFF00E5FF),
      foregroundColor: const Color(0xFF0D47A1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
    ),
  ),
);

final ThemeData darkTheme = ThemeData(
  brightness: Brightness.dark,
  primaryColor: const Color(0xFF0D47A1),
  scaffoldBackgroundColor: const Color(0xFF1A237E),
  colorScheme: const ColorScheme.dark(
    primary: Color(0xFF0D47A1),
    secondary: Color(0xFF1976D2),
    background: Color(0xFF1A237E),
    surface: Color(0xFF212B50),
    onPrimary: Colors.white,
    onSecondary: Colors.white,
    onSurface: Colors.white,
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: const Color(0xFF212B50),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFF00E5FF)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFF00E5FF), width: 2),
    ),
    hintStyle: TextStyle(color: const Color(0xFF00E5FF).withOpacity(0.7)),
    labelStyle: const TextStyle(color: Color(0xFF00E5FF)),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFF00E5FF),
      foregroundColor: const Color(0xFF0D47A1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
    ),
  ),
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final themeProvider = ThemeProvider();
  runApp(MyApp(themeProvider: themeProvider));
}

class MyApp extends StatelessWidget {
  final ThemeProvider themeProvider;
  const MyApp({super.key, required this.themeProvider});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeProvider,
      builder: (context, mode, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Smart Route App',
          theme: lightTheme,
          darkTheme: darkTheme,
          themeMode: mode,
          home: AnimatedLoginPage(themeProvider: themeProvider),
          routes: {
            '/language-selection': (context) => LanguageSelectionPage(themeProvider: themeProvider),
            '/language-welcome': (context) => LanguageWelcomePage(language: 'English', themeProvider: themeProvider),
            '/traffic-condition': (context) => TrafficConditionPage(themeProvider: themeProvider),
            '/rewards': (context) => RewardPage(
                  points: 1500,
                  trafficAvoided: 45,
                  alternateRoutes: 12,
                  userName: 'John.D',
                  themeProvider: themeProvider,
                ),
          },
        );
      },
    );
  }
}
