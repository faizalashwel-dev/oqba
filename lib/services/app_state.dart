import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Global app state: theme mode and locale.
///
/// Persists user preferences to SharedPreferences.
/// Used via Provider at the root of the widget tree.
class AppState extends ChangeNotifier {
  static const String _themeKey = 'theme_mode';
  static const String _localeKey = 'locale';

  ThemeMode _themeMode = ThemeMode.dark;
  Locale _locale = const Locale('en');

  ThemeMode get themeMode => _themeMode;
  Locale get locale => _locale;

  /// Call once from main() before runApp.
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final themeStr = prefs.getString(_themeKey) ?? 'dark';
    _themeMode = switch (themeStr) {
      'light' => ThemeMode.light,
      'system' => ThemeMode.system,
      _ => ThemeMode.dark,
    };

    final localeStr = prefs.getString(_localeKey) ?? 'en';
    _locale = Locale(localeStr);
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    final str = switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.system => 'system',
      _ => 'dark',
    };
    await prefs.setString(_themeKey, str);
  }

  Future<void> setLocale(Locale locale) async {
    _locale = locale;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localeKey, locale.languageCode);
  }
}
