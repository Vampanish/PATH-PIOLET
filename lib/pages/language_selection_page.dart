import 'package:flutter/material.dart';
import '../theme_provider.dart';
import 'language_welcome_page.dart';

class LanguageSelectionPage extends StatelessWidget {
  final ThemeProvider themeProvider;
  final List<Map<String, String>> languages = [
    {'name': 'English', 'code': 'en'},
    {'name': 'हिन्दी', 'code': 'hi'},
    {'name': 'தமிழ்', 'code': 'ta'},
    {'name': 'বাংলা', 'code': 'bn'},
    {'name': 'తెలుగు', 'code': 'te'},
    {'name': 'मराठी', 'code': 'mr'},
    {'name': 'ગુજરાતી', 'code': 'gu'},
    {'name': 'ಕನ್ನಡ', 'code': 'kn'},
    {'name': 'മലയാളം', 'code': 'ml'},
    {'name': 'ਪੰਜਾਬੀ', 'code': 'pa'},
  ];

  LanguageSelectionPage({super.key, required this.themeProvider});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              themeProvider.value == ThemeMode.dark
                  ? Icons.dark_mode
                  : Icons.light_mode,
              color: Theme.of(context).colorScheme.onPrimary,
            ),
            onPressed: () {
              themeProvider.toggleTheme();
            },
            tooltip: 'Toggle Theme',
          ),
        ],
      ),
      extendBodyBehindAppBar: true,
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
                  'Choose Your Language',
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
                ...languages.map((lang) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00E5FF),
                        foregroundColor: const Color(0xFF0D47A1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        textStyle: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        elevation: 4,
                        shadowColor: Colors.cyanAccent.withOpacity(0.2),
                      ),
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => LanguageWelcomePage(
                              language: lang['name']!,
                              themeProvider: themeProvider,
                            ),
                          ),
                        );
                      },
                      child: Text(lang['name']!),
                    ),
                  ),
                )),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 