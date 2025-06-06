import 'package:flutter/material.dart';

class ThemeProvider extends ValueNotifier<ThemeMode> {
  ThemeProvider() : super(ThemeMode.dark);

  void setTheme(ThemeMode mode) {
    value = mode;
  }
} 