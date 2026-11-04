import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Device locale code: `en` or `hi`.
class LocaleStore {
  static const prefsKey = 'locale';

  Future<String> read() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(prefsKey);
    if (raw == 'hi') return 'hi';
    return 'en';
  }

  Future<void> write(String code) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(prefsKey, code == 'hi' ? 'hi' : 'en');
  }
}

final localeStoreProvider = Provider<LocaleStore>(
  (Ref ref) => LocaleStore(),
);
