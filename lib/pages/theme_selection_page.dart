import 'package:flutter/material.dart';
import '../theme_provider.dart';
import '../main.dart';

class ThemeSelectionPage extends StatelessWidget {
  final ThemeProvider themeProvider;
  const ThemeSelectionPage({super.key, required this.themeProvider});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1A237E),
              Color(0xFF0D47A1),
              Color(0xFF00E5FF),
            ],
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Choose Theme',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.95),
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1,
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 6,
                        offset: Offset(2, 2),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildThemeButton(
                      context,
                      themeProvider,
                      ThemeMode.light,
                      Icons.wb_sunny,
                      'Light',
                    ),
                    const SizedBox(width: 32),
                    _buildThemeButton(
                      context,
                      themeProvider,
                      ThemeMode.dark,
                      Icons.nightlight_round,
                      'Dark',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildThemeButton(BuildContext context, ThemeProvider provider, ThemeMode mode, IconData icon, String label) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: mode == ThemeMode.light ? Colors.white : const Color(0xFF212B50),
        foregroundColor: mode == ThemeMode.light ? const Color(0xFF0D47A1) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 32),
        elevation: 4,
        shadowColor: Colors.cyanAccent.withOpacity(0.2),
      ),
      onPressed: () {
        provider.setTheme(mode);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const MapsHomePage(),
          ),
        );
      },
      child: Column(
        children: [
          Icon(icon, size: 40),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
} 