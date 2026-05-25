import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleService extends ChangeNotifier {
  LocaleService(this._prefs);

  static const _key = 'trail.locale';
  final SharedPreferences _prefs;

  Locale _locale = const Locale('ar');
  Locale get locale => _locale;

  bool get isRtl => _locale.languageCode == 'ar';

  Future<void> hydrate() async {
    final saved = _prefs.getString(_key);
    if (saved != null) {
      _locale = Locale(saved);
      notifyListeners();
    }
  }

  Future<void> setLocale(Locale locale) async {
    if (_locale == locale) return;
    _locale = locale;
    await _prefs.setString(_key, locale.languageCode);
    notifyListeners();
  }

  Future<void> toggle() async {
    await setLocale(_locale.languageCode == 'ar' ? const Locale('en') : const Locale('ar'));
  }
}
