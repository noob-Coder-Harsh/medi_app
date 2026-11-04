import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../data/local/locale_store.dart';

enum AppLocale {
  en,
  hi;

  Locale get flutterLocale => switch (this) {
    AppLocale.en => const Locale('en', 'IN'),
    AppLocale.hi => const Locale('hi', 'IN'),
  };

  String get intlName => switch (this) {
    AppLocale.en => 'en_IN',
    AppLocale.hi => 'hi_IN',
  };
}

final localeProvider = NotifierProvider<LocaleController, AppLocale>(
  LocaleController.new,
);

class LocaleController extends Notifier<AppLocale> {
  bool _ready = false;

  @override
  AppLocale build() {
    Future<void>.microtask(_ensureReady);
    I18n.current = AppLocale.en;
    return AppLocale.en;
  }

  Future<void> _ensureReady() async {
    if (_ready) return;
    final code = await ref.read(localeStoreProvider).read();
    if (_ready) return;
    final locale = code == 'hi' ? AppLocale.hi : AppLocale.en;
    I18n.current = locale;
    state = locale;
    _ready = true;
  }

  void set(AppLocale locale) {
    I18n.current = locale;
    state = locale;
    unawaited(ref.read(localeStoreProvider).write(locale.name));
  }
}

/// Nested lookup into `assets/locales/{en,hi}.json`.
/// Chrome copy only — identity stays in [Brand].
abstract final class I18n {
  static AppLocale current = AppLocale.en;
  static Map<String, dynamic> _en = <String, dynamic>{};
  static Map<String, dynamic> _hi = <String, dynamic>{};

  static Future<void> load() async {
    final enRaw = await rootBundle.loadString('assets/locales/en.json');
    final hiRaw = await rootBundle.loadString('assets/locales/hi.json');
    _en = jsonDecode(enRaw) as Map<String, dynamic>;
    _hi = jsonDecode(hiRaw) as Map<String, dynamic>;
    await initializeDateFormatting('en_IN');
    await initializeDateFormatting('hi_IN');
  }

  static String t(String key, {AppLocale? locale}) {
    final chosen = locale ?? current;
    return _lookup(chosen == AppLocale.hi ? _hi : _en, key) ??
        _lookup(_en, key) ??
        key;
  }

  static String? _lookup(Map<String, dynamic> tree, String path) {
    Object? current = tree;
    for (final segment in path.split('.')) {
      if (current is Map && current.containsKey(segment)) {
        current = current[segment];
      } else {
        return null;
      }
    }
    return current is String ? current : null;
  }
}

/// Looks up chrome copy. Example: `t('NAV.HOME')` → `Home` / `होम`.
String t(String key, {AppLocale? locale}) => I18n.t(key, locale: locale);
