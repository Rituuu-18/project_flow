import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>((ref) {
  return ThemeNotifier();
});

class ThemeNotifier extends StateNotifier<ThemeMode> {
  ThemeNotifier() : super(ThemeMode.system) {
    _loadTheme();
  }

  static const _key = 'theme_mode';

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final themeIndex = prefs.getInt(_key);
    if (themeIndex != null) {
      state = ThemeMode.values[themeIndex];
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_key, mode.index);
  }

  void toggleTheme() {
    final currentMode = state;
    if (currentMode == ThemeMode.light) {
      setThemeMode(ThemeMode.dark);
    } else if (currentMode == ThemeMode.dark) {
      setThemeMode(ThemeMode.light);
    } else {
      final systemBrightness =
          WidgetsBinding.instance.platformDispatcher.platformBrightness;
      if (systemBrightness == Brightness.dark) {
        setThemeMode(ThemeMode.light);
      } else {
        setThemeMode(ThemeMode.dark);
      }
    }
  }
}
