import 'package:flutter/material.dart';
import '../main.dart';
import 'package:provider/provider.dart';

class LanguagePage extends StatefulWidget {
  const LanguagePage({Key? key}) : super(key: key);

  @override
  State<LanguagePage> createState() => _LanguagePageState();
}

class _LanguagePageState extends State<LanguagePage> {
  final List<Map<String, String>> languages = [
    {'label': 'English', 'code': 'en'},
    {'label': 'हिंदी (Hindi)', 'code': 'hi'},
    {'label': 'தமிழ் (Tamil)', 'code': 'ta'},
    {'label': 'বাংলা (Bengali)', 'code': 'bn'},
    {'label': 'తెలుగు (Telugu)', 'code': 'te'},
    {'label': 'मराठी (Marathi)', 'code': 'mr'},
    {'label': 'ગુજરાતી (Gujarati)', 'code': 'gu'},
  ];
  String? selectedCode;

  @override
  Widget build(BuildContext context) {
    final themeProvider = ThemeProvider.of(context);
    final bool isDarkMode = themeProvider.isDarkMode;
    final Color background = isDarkMode ? Colors.black : const Color(0xFF1976D2);
    final Color cardColor = isDarkMode ? const Color(0xFF212B50) : Colors.white.withOpacity(0.12);
    final Color textColor = Colors.white;
    final Color accent = const Color(0xFF00E5FF);
    final Color surface = const Color(0xFF212B50);

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Select Language', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
            child: FloatingActionButton(
              key: ValueKey(isDarkMode),
              mini: true,
              backgroundColor: isDarkMode ? surface : accent,
              onPressed: themeProvider.toggleTheme,
              child: Icon(
                isDarkMode ? Icons.wb_sunny_outlined : Icons.nightlight_round,
                color: Colors.white,
              ),
              elevation: 4,
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            Text(
              'Choose Your Language',
              style: TextStyle(
                color: textColor,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Select your preferred language for voice instructions',
              style: TextStyle(
                color: textColor.withOpacity(0.8),
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 18),
            Expanded(
              child: ListView.builder(
                itemCount: languages.length,
                itemBuilder: (context, index) {
                  final lang = languages[index];
                  final isSelected = selectedCode == lang['code'];
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedCode = lang['code'];
                      });
                      // Save language selection and go to home
                      Provider.of<LocaleProvider>(context, listen: false).setLocale(lang['code']!);
                      Navigator.of(context).pushReplacementNamed('/home');
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
                      decoration: BoxDecoration(
                        color: isSelected ? accent.withOpacity(0.25) : cardColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected ? accent : Colors.white24,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Text(
                        lang['label']!,
                        style: TextStyle(
                          color: textColor,
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
} 