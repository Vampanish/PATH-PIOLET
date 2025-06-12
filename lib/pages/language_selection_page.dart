import 'package:flutter/material.dart';
import '../theme_provider.dart';
import 'theme_selection_page.dart';

class LanguageSelectionPage extends StatelessWidget {
  final ThemeProvider themeProvider;

  const LanguageSelectionPage({
    super.key,
    required this.themeProvider,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = themeProvider.isDarkMode;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: isDark ? Colors.grey[900] : Colors.blue[900],
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Select Language',
          style: TextStyle(
            color: Colors.white.withOpacity(0.95),
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              isDark ? Icons.light_mode : Icons.dark_mode,
              color: Colors.white,
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
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark 
              ? [
                  Colors.grey[900]!,
                  Colors.grey[800]!,
                ]
              : [
                  const Color(0xFF0D47A1),
                  const Color(0xFF0D47A1).withOpacity(0.8),
                ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),
                Text(
                  'Choose Your Language',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.95),
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Select your preferred language for voice instructions',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: ListView(
                    children: [
                      _buildLanguageCard(context, 'English', 'en', isDark),
                      _buildLanguageCard(context, 'हिंदी (Hindi)', 'hi', isDark),
                      _buildLanguageCard(context, 'தமிழ் (Tamil)', 'ta', isDark),
                      _buildLanguageCard(context, 'বাংলা (Bengali)', 'bn', isDark),
                      _buildLanguageCard(context, 'తెలుగు (Telugu)', 'te', isDark),
                      _buildLanguageCard(context, 'मराठी (Marathi)', 'mr', isDark),
                      _buildLanguageCard(context, 'ગુજરાતી (Gujarati)', 'gu', isDark),
                      _buildLanguageCard(context, 'ಕನ್ನಡ (Kannada)', 'kn', isDark),
                      _buildLanguageCard(context, 'മലയാളം (Malayalam)', 'ml', isDark),
                      _buildLanguageCard(context, 'ਪੰਜਾਬੀ (Punjabi)', 'pa', isDark),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageCard(BuildContext context, String languageName, String languageCode, bool isDark) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: isDark 
        ? Colors.grey[800]!.withOpacity(0.5)
        : Colors.white.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isDark 
            ? Colors.grey[700]!.withOpacity(0.5)
            : Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        title: Text(
          languageName,
          style: TextStyle(
            color: Colors.white.withOpacity(0.95),
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        onTap: () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => ThemeSelectionPage(
                themeProvider: themeProvider,
              ),
            ),
          );
        },
      ),
    );
  }
} 