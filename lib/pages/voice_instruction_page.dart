import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../theme_provider.dart';
import 'traffic_condition_page.dart';

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

  // Map of language codes to their TTS codes
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
      // Initialize TTS engine
      await flutterTts.awaitSpeakCompletion(true);
      await flutterTts.awaitSynthCompletion(true);
      
      // Get available voices
      availableVoices = await flutterTts.getVoices;
      print('Available voices: $availableVoices');

      // Set up TTS with platform-specific settings
      await flutterTts.setSpeechRate(0.5);
      await flutterTts.setVolume(1.0);
      await flutterTts.setPitch(1.0);

      // Set completion handler
      flutterTts.setCompletionHandler(() {
        print('TTS completed');
        setState(() {
          isSpeaking = false;
        });
      });

      // Set error handler
      flutterTts.setErrorHandler((msg) {
        print('TTS Error: $msg');
        setState(() {
          isSpeaking = false;
        });
      });

      // Set start handler
      flutterTts.setStartHandler(() {
        print('TTS started');
        setState(() {
          isSpeaking = true;
        });
      });

      // Try to set language
      await _setLanguage(currentLanguage);
      
      // Speak welcome message
      await _speak(welcomeMessages[currentLanguage] ?? welcomeMessages['en']!);
    } catch (e) {
      print('Error initializing TTS: $e');
    }
  }

  Future<void> _setLanguage(String language) async {
    try {
      String ttsLanguage = languageCodes[language] ?? 'en-US';
      print('Setting language to: $ttsLanguage');
      
      // First try to set the language directly
      var result = await flutterTts.setLanguage(ttsLanguage);
      print('Language set result: $result');
      
      // Get available voices
      availableVoices = await flutterTts.getVoices;
      
      // Try to find a matching voice
      var matchingVoices = availableVoices.where((voice) {
        final voiceMap = Map<String, dynamic>.from(voice);
        String voiceLocale = voiceMap['locale']?.toString().toLowerCase() ?? '';
        String voiceName = voiceMap['name']?.toString().toLowerCase() ?? '';
        String languageCode = language.toLowerCase();
        
        print('Checking voice: $voiceName ($voiceLocale)');
        
        // Check for exact locale match first
        if (voiceLocale == ttsLanguage.toLowerCase()) {
          return true;
        }
        
        // Then check for partial matches
        return voiceLocale.contains(languageCode) || 
               voiceLocale.contains(ttsLanguage.toLowerCase()) ||
               voiceName.contains(languageCode);
      }).toList();

      if (matchingVoices.isNotEmpty) {
        final voice = Map<String, dynamic>.from(matchingVoices.first);
        String voiceName = voice['name']?.toString() ?? '';
        String voiceLocale = voice['locale']?.toString() ?? ttsLanguage;
        
        if (voiceName.isNotEmpty) {
          selectedVoice = voiceName;
          var voiceResult = await flutterTts.setVoice({"name": voiceName, "locale": voiceLocale});
          print('Voice set result: $voiceResult');
          print('Selected voice: $selectedVoice for language: $ttsLanguage');
        }
      } else {
        print('No matching voice found for: $ttsLanguage, using default');
        // Try to set the language without a specific voice
        await flutterTts.setLanguage(ttsLanguage);
      }
    } catch (e) {
      print('Error setting language: $e');
      // Fallback to English
      await flutterTts.setLanguage('en-US');
    }
  }

  Future<void> _setVoice() async {
    try {
      final voices = await flutterTts.getVoices;
      print('Available voices: $voices');
      
      // First try to set the language
      final languageResult = await flutterTts.setLanguage(currentLanguage);
      print('Language set result: $languageResult');
      
      if (languageResult == 1) {
        // Try to find a voice for the current language
        bool voiceFound = false;
        if (voices != null) {
          for (var voice in voices) {
            print('Checking voice: ${voice['name']} (${voice['locale']})');
            if (voice['locale'].toString().toLowerCase().startsWith(currentLanguage.toLowerCase())) {
              final result = await flutterTts.setVoice({"name": voice['name'], "locale": voice['locale']});
              if (result == 1) {
                print('Selected voice: ${voice['name']} for language: $currentLanguage');
                voiceFound = true;
                break;
              }
            }
          }
        }
        
        // If no voice found for current language, fallback to English
        if (!voiceFound) {
          print('No voice found for $currentLanguage, falling back to English');
          await flutterTts.setLanguage('en-US');
          // Try to find an English voice
          if (voices != null) {
            for (var voice in voices) {
              if (voice['locale'].toString().toLowerCase().startsWith('en-')) {
                final result = await flutterTts.setVoice({"name": voice['name'], "locale": voice['locale']});
                if (result == 1) {
                  print('Selected fallback voice: ${voice['name']} for language: en-US');
                  break;
                }
              }
            }
          }
        }
      }
    } catch (e) {
      print('Error setting voice: $e');
      // Fallback to English if there's an error
      await flutterTts.setLanguage('en-US');
    }
  }

  Future<void> _speak(String text) async {
    try {
      print('TTS started');
      final result = await flutterTts.speak(text);
      print('Speak result: $result');
      
      if (result != 1) {
        print('Failed to speak in current language, trying English fallback');
        // If current language is not English, try English as fallback
        if (currentLanguage != 'en-US') {
          await flutterTts.setLanguage('en-US');
          await flutterTts.speak(text);
        }
      }
    } catch (e) {
      print('Error in _speak: $e');
      // If there's an error, try English as a last resort
      try {
        await flutterTts.setLanguage('en-US');
        await flutterTts.speak(text);
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
              widget.themeProvider.toggleTheme();
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
                          builder: (context) => TrafficConditionPage(
                            themeProvider: widget.themeProvider,
                            initialLanguage: currentLanguage,
                          ),
                        ),
                      );
                    },
                    child: const Text(
                      'Continue to Traffic Conditions',
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