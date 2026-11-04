import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/env.dart';

/// Anon Supabase client. Listing RPCs only — no table writes.
abstract final class AppSupabase {
  static bool _initialized = false;

  static bool get isReady => _initialized;

  static Future<void> init() async {
    if (_initialized) return;
    if (!Env.hasSupabase) {
      debugPrint('Supabase skipped: SUPABASE_URL / SUPABASE_ANON_KEY empty.');
      return;
    }
    await Supabase.initialize(
      url: Env.supabaseUrl,
      publishableKey: Env.supabaseAnonKey,
    );
    _initialized = true;
  }

  static SupabaseClient get client {
    if (!_initialized) {
      throw StateError(
        'Supabase is not initialized. Set SUPABASE_URL and SUPABASE_ANON_KEY.',
      );
    }
    return Supabase.instance.client;
  }
}
