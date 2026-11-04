import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/env.dart';
import 'core/i18n.dart';
import 'core/theme.dart';
import 'data/firebase_client.dart';
import 'data/supabase_client.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Env.load();
  await I18n.load();
  await AppTheme.preloadFonts();
  await AppSupabase.init();
  await AppFirebase.init();
  runApp(const ProviderScope(child: MediApp()));
}
