import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'translations.dart';

final localeProvider = StateNotifierProvider<LocaleNotifier, String>((ref) {
  return LocaleNotifier();
});

class LocaleNotifier extends StateNotifier<String> {
  LocaleNotifier() : super('en') {
    _loadLocale();
  }

  static const _localeKey = 'app_locale';

  Future<void> _loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLocale = prefs.getString(_localeKey);
    if (savedLocale != null && (savedLocale == 'en' || savedLocale == 'nl' || savedLocale == 'de')) {
      state = savedLocale;
    }
  }

  Future<void> setLocale(String locale) async {
    if (locale == 'en' || locale == 'nl' || locale == 'de') {
      state = locale;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_localeKey, locale);
    }
  }

  String t(String key, [Map<String, String>? params]) {
    final langMap = translations[state] ?? translations['en']!;
    var text = langMap[key] ?? translations['en']![key] ?? key;
    if (params != null) {
      params.forEach((k, v) {
        text = text.replaceAll('{$k}', v);
      });
    }
    return text;
  }
}
