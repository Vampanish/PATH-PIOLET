import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../theme_provider.dart';
import '../main.dart'; // For MapsHomePage

class VoiceInstructionPage extends StatefulWidget {
  final ThemeProvider themeProvider;
  final String initialLanguage;

  const VoiceInstructionPage({
    super.key,
    required this.themeProvider,
    required this.initialLanguage,
  });

  @override
  State<VoiceInstructionPage> createState() => _VoiceInstructionPageState();
}

class _VoiceInstructionPageState extends State<VoiceInstructionPage> {
  late FlutterTts flutterTts;
  String currentLanguage = 'en';
  bool isSpeaking = false;
  bool languageSupported = true;
  List<dynamic> availableVoices = [];
  String selectedVoice = '';

  final Map<String, String> welcomeMessages = {
    'en': 'Welcome! We will guide you in English.',
    'hi': 'स्वागत है! हम आपको हिंदी में मार्गदर्शन करेंगे।',
    'ta': 'வரவேற்கிறோம்! நாங்கள் தமிழில் உங்களுக்கு வழிகாட்டுவோம்.',
    'bn': 'স্বাগতম! আমরা বাংলায় আপনাকে গাইড করব।',
    'te': 'స్వాగతం! మేము తెలుగులో మీకు మార్గనిర్దేశం చేస్తాము.',
    'mr': 'स्वागत आहे! आम्ही मराठीत तुम्हाला मार्गदर्शन करू.',
    'gu': 'સ્વાગત છે! અમે ગુજરાતીમાં તમને માર્ગદર્શન આપીશું.',
    'kn': 'ಸ್ವಾಗತ! ನಾವು ಕನ್ನಡದಲ್ಲಿ ನಿಮಗೆ ಮಾರ್ಗದರ್ಶನ ನೀಡುತ್ತೇವೆ.',
    'ml': 'സ്വാഗതം! നമ്മൾ മലയാളത്തിൽ നിങ്ങളെ നയിക്കും.',
    'pa': 'ਜੀ ਆਇਆਂ ਨੂੰ! ਅਸੀਂ ਪੰਜਾਬੀ ਵਿੱਚ ਤੁਹਾਨੂੰ ਮਾਰਗਦਰਸ਼ਨ ਕਰਾਂਗੇ।',
  };

  final Map<String, String> languageCodes = {
    'en': 'en-US',
    'hi': 'hi-IN',
    'ta': 'ta-IN',
    'bn': 'bn-IN',
    'te': 'te-IN',
    'mr': 'mr-IN',
    'gu': 'gu-IN',
    'kn': 'kn-IN',
    'ml': 'ml-IN',
    'pa': 'pa-IN',
  };

  @override
  void initState() {
    super.initState();
    currentLanguage = widget.initialLanguage;
    flutterTts = FlutterTts();
    _initTts();
  }

  Future<void> _initTts() async {
    try {
      await flutterTts.awaitSpeakCompletion(true);
      await flutterTts.awaitSynthCompletion(true);
      availableVoices = await flutterTts.getVoices;
      await flutterTts.setSpeechRate(0.5);
      await flutterTts.setVolume(1.0);
      await flutterTts.setPitch(1.0);
      flutterTts.setCompletionHandler(() {
        setState(() {
          isSpeaking = false;
        });
      });
      flutterTts.setErrorHandler((msg) {
        setState(() {
          isSpeaking = false;
        });
      });
      flutterTts.setStartHandler(() {
        setState(() {
          isSpeaking = true;
        });
      });
      await _setLanguage(currentLanguage);
      await _speak(welcomeMessages[currentLanguage] ?? welcomeMessages['en']!);
    } catch (e) {
      print('Error initializing TTS: $e');
    }
  }

  Future<void> _setLanguage(String language) async {
    String ttsLanguage = languageCodes[language] ?? 'en-US';
    var result = await flutterTts.setLanguage(ttsLanguage);
    if (result == 1) {
      setState(() {
        languageSupported = true;
      });
      print('TTS language set to $ttsLanguage');
    } else {
      // Fallback to English
      await flutterTts.setLanguage('en-US');
      setState(() {
        currentLanguage = 'en';
        languageSupported = false;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Selected language is not supported for voice. Falling back to English.'),
            backgroundColor: Colors.red,
          ),
        );
      });
      print('TTS language $ttsLanguage not available, falling back to English');
    }
  }

  Future<void> _speak(String text) async {
    try {
      final result = await flutterTts.speak(text);
      if (result != 1 && currentLanguage != 'en') {
        await flutterTts.setLanguage('en-US');
        await flutterTts.speak(welcomeMessages['en']!);
      }
    } catch (e) {
      try {
        await flutterTts.setLanguage('en-US');
        await flutterTts.speak(welcomeMessages['en']!);
      } catch (e) {
        print('Error in English fallback: $e');
      }
    }
  }

  @override
  void dispose() {
    flutterTts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.themeProvider.isDarkMode;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: isDark ? Colors.grey[900] : Colors.blue[900],
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Voice Instructions',
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
              setState(() {
                widget.themeProvider.toggleTheme();
              });
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
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDark 
                      ? Colors.grey[800]!.withOpacity(0.5)
                      : Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark 
                        ? Colors.grey[700]!.withOpacity(0.5)
                        : Colors.white.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        welcomeMessages[currentLanguage] ?? welcomeMessages['en']!,
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.white.withOpacity(0.95),
                          fontSize: 20,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          IconButton(
                            icon: Icon(
                              isSpeaking ? Icons.stop : Icons.play_arrow,
                              color: Colors.white,
                              size: 32,
                            ),
                            onPressed: () {
                              if (isSpeaking) {
                                flutterTts.stop();
                              } else {
                                _speak(welcomeMessages[currentLanguage] ?? welcomeMessages['en']!);
                              }
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Available Voices:',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.95),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: ListView.builder(
                    itemCount: availableVoices.length,
                    itemBuilder: (context, index) {
                      final voice = Map<String, dynamic>.from(availableVoices[index]);
                      return Card(
                        color: isDark 
                          ? Colors.grey[800]!.withOpacity(0.5)
                          : Colors.white.withOpacity(0.1),
                        child: ListTile(
                          title: Text(
                            '${voice['name']} (${voice['locale']})',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.95),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00E5FF),
                      foregroundColor: const Color(0xFF0D47A1),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const MapsHomePage(),
                        ),
                      );
                    },
                    child: const Text(
                      'Continue to Map',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 