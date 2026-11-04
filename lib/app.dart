import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/brand.dart';
import 'core/i18n.dart';
import 'core/router.dart';
import 'core/theme.dart';

class MediApp extends ConsumerWidget {
  const MediApp({super.key, this.router});

  final GoRouter? router;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    return MaterialApp.router(
      title: Brand.appName,
      theme: AppTheme.light(locale),
      locale: locale.flutterLocale,
      supportedLocales: const <Locale>[
        Locale('en', 'IN'),
        Locale('hi', 'IN'),
      ],
      localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: router ?? appRouter,
    );
  }
}
