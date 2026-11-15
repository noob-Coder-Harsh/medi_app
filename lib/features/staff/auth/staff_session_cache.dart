import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/routes.dart';
import '../../../data/supabase_client.dart';
import 'staff_user.dart';

/// Local launch hints so cold start skips the login flash when a session exists.
abstract final class StaffSessionCache {
  static const _signedInKey = 'staff_signed_in';
  static const _hasStoreKey = 'staff_has_store';

  static Future<void> persist({
    required bool signedIn,
    required bool hasStore,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    if (!signedIn) {
      await prefs.remove(_signedInKey);
      await prefs.remove(_hasStoreKey);
      return;
    }
    await prefs.setBool(_signedInKey, true);
    await prefs.setBool(_hasStoreKey, hasStore);
  }

  static Future<void> persistUser(StaffUser? user) {
    return persist(
      signedIn: true,
      hasStore: user?.hasStore ?? false,
    );
  }

  static Future<void> clear() => persist(signedIn: false, hasStore: false);

  /// Prefer live Supabase session; fall back to prefs only for hasStore.
  static Future<String> resolveInitialLocation() async {
    if (AppSupabase.isReady) {
      final session = AppSupabase.client.auth.currentSession;
      if (session != null) {
        final prefs = await SharedPreferences.getInstance();
        final hasStore = prefs.getBool(_hasStoreKey);
        if (hasStore == false) return Routes.staffOnboarding;
        return Routes.staffToday;
      }
    }

    final prefs = await SharedPreferences.getInstance();
    // Stale flags without a live session — clear and open login.
    if (prefs.getBool(_signedInKey) == true) {
      await clear();
    }
    return Routes.staffLogin;
  }
}
