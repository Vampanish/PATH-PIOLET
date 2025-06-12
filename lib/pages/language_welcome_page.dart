import 'package:flutter/material.dart';
import '../theme_provider.dart';

class LanguageWelcomePage extends StatelessWidget {
  final String language;
  final ThemeProvider themeProvider;
  const LanguageWelcomePage({super.key, required this.language, required this.themeProvider});

  String getWelcomeMessage() {
    switch (language) {
      case 'हिन्दी':
        return 'स्वागत है!';
      case 'தமிழ்':
        return 'வரவேற்கிறோம்!';
      case 'বাংলা':
        return 'স্বাগতম!';
      case 'తెలుగు':
        return 'స్వాగతం!';
      case 'मराठी':
        return 'स्वागत आहे!';
      case 'ગુજરાતી':
        return 'સ્વાગત છે!';
      case 'ಕನ್ನಡ':
        return 'ಸ್ವಾಗತ!';
      case 'മലയാളം':
        return 'സ്വാഗതം!';
      case 'ਪੰਜਾਬੀ':
        return 'ਸੁਆਗਤ ਹੈ!';
      default:
        return 'Welcome!';
    }
  }

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
              themeProvider.setTheme(
                themeProvider.value == ThemeMode.dark
                    ? ThemeMode.light
                    : ThemeMode.dark,
              );
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
                  getWelcomeMessage(),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.95),
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 8,
                        offset: Offset(2, 2),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Text(
                  'You have selected: $language',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 18,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00E5FF),
                    foregroundColor: const Color(0xFF0D47A1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                    textStyle: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    elevation: 4,
                    shadowColor: Colors.cyanAccent.withOpacity(0.2),
                  ),
                  onPressed: () {
                    // TODO: Navigate to main app or pop to previous
                    Navigator.pop(context);
                  },
                  child: const Text('Continue'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 