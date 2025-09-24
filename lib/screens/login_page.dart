import 'package:flutter/material.dart';
import '../main.dart';
import '../theme_provider.dart';
import 'package:provider/provider.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  late AnimationController _logoController;
  late Animation<double> _logoScale;
  late AnimationController _fieldsController;
  late Animation<Offset> _fieldsOffset;
  late AnimationController _buttonController;
  late Animation<double> _buttonOpacity;

  @override
  void initState() {
    super.initState();
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _logoScale = CurvedAnimation(
      parent: _logoController,
      curve: Curves.elasticOut,
    );
    _fieldsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fieldsOffset = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _fieldsController,
      curve: Curves.easeOut,
    ));
    _buttonController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _buttonOpacity = CurvedAnimation(
      parent: _buttonController,
      curve: Curves.easeIn,
    );
    _startAnimations();
  }

  void _startAnimations() async {
    await Future.delayed(const Duration(milliseconds: 200));
    _logoController.forward();
    await Future.delayed(const Duration(milliseconds: 300));
    _fieldsController.forward();
    await Future.delayed(const Duration(milliseconds: 200));
    _buttonController.forward();
  }

  @override
  void dispose() {
    _logoController.dispose();
    _fieldsController.dispose();
    _buttonController.dispose();
    super.dispose();
  }

  // Sample authentication (replace with real backend logic)
  Future<bool> _authenticate(String email, String password) async {
    await Future.delayed(const Duration(seconds: 1));
    // Dummy: Accept any non-empty email/password
    return email.isNotEmpty && password.isNotEmpty;
  }

  void _login() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final success = await _authenticate(email, password);
    setState(() {
      _isLoading = false;
      _errorMessage = success ? null : 'Invalid email or password';
    });
    if (success) {
      // Navigate to language selection page after login
      Navigator.of(context).pushReplacementNamed('/language');
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final bool isDarkMode = themeProvider.isDarkMode;
    final Color primary = const Color(0xFF0D47A1);
    final Color secondary = const Color(0xFF1976D2);
    final Color accent = const Color(0xFF00E5FF);
    final Color background = isDarkMode ? Colors.black : const Color(0xFF1976D2);
    final Color surface = const Color(0xFF212B50);
    final Color textColor = Colors.white;
    final Color fieldBg = isDarkMode ? surface.withOpacity(0.7) : Colors.white.withOpacity(0.2);
    final Color iconColor = accent;

    return Scaffold(
      backgroundColor: background,
      body: Stack(
        children: [
          // Animated theme toggle button
          Positioned(
            top: 24,
            right: 24,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
              child: FloatingActionButton(
                key: ValueKey(isDarkMode),
                mini: true,
                backgroundColor: isDarkMode ? surface : accent,
                onPressed: () => themeProvider.toggleTheme(),
                child: Icon(
                  isDarkMode ? Icons.wb_sunny_outlined : Icons.nightlight_round,
                  color: Colors.white,
                ),
                elevation: 4,
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Animated logo
                    ScaleTransition(
                      scale: _logoScale,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFF9800), Color(0xFF4CAF50), Color(0xFF00BCD4)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Icon(Icons.alt_route, color: Colors.white, size: 60), // Replace with your logo if available
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    FadeTransition(
                      opacity: _logoScale,
                      child: Column(
                        children: [
                          Text(
                            'Path Piolet',
                            style: TextStyle(
                              color: textColor,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Smart Traffic Solutions',
                            style: TextStyle(
                              color: textColor.withOpacity(0.8),
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                              letterSpacing: 1.1,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Animated fields
                    SlideTransition(
                      position: _fieldsOffset,
                      child: Column(
                        children: [
                          // Email field
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
                            decoration: BoxDecoration(
                              color: fieldBg,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: accent.withOpacity(0.3)),
                            ),
                            child: TextField(
                              controller: _emailController,
                              style: TextStyle(color: textColor),
                              decoration: InputDecoration(
                                prefixIcon: Icon(Icons.email, color: iconColor),
                                hintText: 'Email',
                                hintStyle: TextStyle(color: textColor.withOpacity(0.7)),
                                border: InputBorder.none,
                              ),
                              keyboardType: TextInputType.emailAddress,
                            ),
                          ),
                          // Password field
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
                            decoration: BoxDecoration(
                              color: fieldBg,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: accent.withOpacity(0.3)),
                            ),
                            child: TextField(
                              controller: _passwordController,
                              style: TextStyle(color: textColor),
                              obscureText: _obscurePassword,
                              decoration: InputDecoration(
                                prefixIcon: Icon(Icons.lock, color: iconColor),
                                hintText: 'Password',
                                hintStyle: TextStyle(color: textColor.withOpacity(0.7)),
                                border: InputBorder.none,
                                suffixIcon: IconButton(
                                  icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: iconColor),
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.redAccent, fontSize: 14),
                        ),
                      ),
                    const SizedBox(height: 24),
                    // Animated login button
                    FadeTransition(
                      opacity: _buttonOpacity,
                      child: Container(
                        width: double.infinity,
                        margin: const EdgeInsets.symmetric(horizontal: 32),
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            padding: EdgeInsets.zero,
                            elevation: 4,
                            backgroundColor: primary,
                          ),
                          onPressed: _isLoading ? null : _login,
                          child: _isLoading
                              ? const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.white))
                              : const Text('Login', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
} 