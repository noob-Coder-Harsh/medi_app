import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/brand.dart';
import 'core/deep_links.dart';
import 'core/i18n.dart';
import 'core/router.dart';
import 'core/theme.dart';

class MediApp extends ConsumerStatefulWidget {
  const MediApp({super.key, this.router, this.enableDeepLinks = true});

  final GoRouter? router;

  /// Tests pass `false` so AppLinks does not bind during widget tests.
  final bool enableDeepLinks;

  @override
  ConsumerState<MediApp> createState() => _MediAppState();
}

class _MediAppState extends ConsumerState<MediApp> {
  DeepLinkController? _deepLinks;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = widget.router ?? appRouter;
    if (widget.enableDeepLinks && widget.router == null) {
      _deepLinks = DeepLinkController(router: _router);
      // ignore: discarded_futures
      _deepLinks!.start();
    }
  }

  @override
  void dispose() {
    // ignore: discarded_futures
    _deepLinks?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
      builder: (BuildContext context, Widget? child) {
        return DecoratedBox(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage(AppTheme.pageBackgroundAsset),
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
            ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
      routerConfig: _router,
    );
  }
}
