import 'package:flutter/material.dart';
import 'pages/login_page.dart';
import 'theme_provider.dart';

final ThemeData lightTheme = ThemeData(
  brightness: Brightness.light,
  primaryColor: const Color(0xFF0D47A1),
  scaffoldBackgroundColor: const Color(0xFFE3F2FD),
  colorScheme: ColorScheme.light(
    primary: const Color(0xFF0D47A1),
    secondary: const Color(0xFF1976D2),
    background: const Color(0xFFE3F2FD),
    surface: const Color(0xFFB3E5FC),
    onPrimary: Colors.white,
    onSecondary: Colors.white,
    onBackground: Colors.black,
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
  colorScheme: ColorScheme.dark(
    primary: const Color(0xFF0D47A1),
    secondary: const Color(0xFF1976D2),
    background: const Color(0xFF1A237E),
    surface: const Color(0xFF212B50),
    onPrimary: Colors.white,
    onSecondary: Colors.white,
    onBackground: Colors.white,
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

void main() {
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
        );
      },
    );
  }
}
