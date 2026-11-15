import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/env.dart';
import 'core/i18n.dart';
import 'core/router.dart';
import 'core/theme.dart';
import 'data/firebase_client.dart';
import 'data/supabase_client.dart';
import 'features/staff/auth/staff_session_cache.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Env.load();
  await I18n.load();
  await AppTheme.preloadFonts();
  await AppSupabase.init();
  await AppFirebase.init();
  final initialLocation = await StaffSessionCache.resolveInitialLocation();
  runApp(
    ProviderScope(
      child: MediApp(
        router: createAppRouter(initialLocation: initialLocation),
      ),
    ),
  );
}
