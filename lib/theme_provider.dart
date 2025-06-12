import 'package:flutter/material.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;

  ThemeMode get value => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  static ThemeProvider of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<_ThemeProviderInherited>()!.themeProvider;
  }

  void setTheme(ThemeMode mode) {
    _themeMode = mode;
    notifyListeners();
  }

  void toggleTheme() {
    _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }
}

class _ThemeProviderInherited extends InheritedWidget {
  final ThemeProvider themeProvider;

  const _ThemeProviderInherited({
    required this.themeProvider,
    required Widget child,
  }) : super(child: child);

  @override
  bool updateShouldNotify(_ThemeProviderInherited oldWidget) {
    return themeProvider != oldWidget.themeProvider;
  }
}

class ThemeProviderWidget extends StatelessWidget {
  final ThemeProvider themeProvider;
  final Widget child;

  const ThemeProviderWidget({
    super.key,
    required this.themeProvider,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return _ThemeProviderInherited(
      themeProvider: themeProvider,
      child: child,
    );
  }
} 