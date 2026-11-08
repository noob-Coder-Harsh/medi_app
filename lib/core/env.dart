import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Reads config from a gitignored `.env` or `--dart-define`.
class Env {
  Env._();

  static const _supabaseUrlDefine = String.fromEnvironment('SUPABASE_URL');
  static const _supabaseAnonKeyDefine = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
  );
  static const _apiBaseUrlDefine = String.fromEnvironment('API_BASE_URL');
  static const _firebaseApiKeyDefine = String.fromEnvironment('FIREBASE_API_KEY');
  static const _firebaseAuthDomainDefine = String.fromEnvironment(
    'FIREBASE_AUTH_DOMAIN',
  );
  static const _firebaseProjectIdDefine = String.fromEnvironment(
    'FIREBASE_PROJECT_ID',
  );
  static const _firebaseAppIdDefine = String.fromEnvironment('FIREBASE_APP_ID');
  static const _firebaseMessagingSenderIdDefine = String.fromEnvironment(
    'FIREBASE_MESSAGING_SENDER_ID',
  );
  static const _firebaseStorageBucketDefine = String.fromEnvironment(
    'FIREBASE_STORAGE_BUCKET',
  );

  static Future<void> load() async {
    await dotenv.load(
      fileName: '.env.example',
      overrideWithFiles: const ['.env', '.env.local'],
      isOptional: true,
    );
  }

  static String _value(String key, String fromDefine, {List<String> also = const <String>[]}) {
    try {
      final fromFile = dotenv.maybeGet(key);
      if (fromFile != null && fromFile.isNotEmpty) {
        return fromFile;
      }
      for (final alt in also) {
        final value = dotenv.maybeGet(alt);
        if (value != null && value.isNotEmpty) {
          return value;
        }
      }
    } catch (_) {
      // dotenv not loaded — dart-define still applies.
    }
    return fromDefine;
  }

  static String get supabaseUrl => _value(
    'SUPABASE_URL',
    _supabaseUrlDefine,
    also: const <String>['NEXT_PUBLIC_SUPABASE_URL'],
  );

  static String get supabaseAnonKey => _value(
    'SUPABASE_ANON_KEY',
    _supabaseAnonKeyDefine,
    also: const <String>['NEXT_PUBLIC_SUPABASE_ANON_KEY'],
  );

  static bool get hasSupabase =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  /// Deployed web/API origin (no trailing slash). Used for `/api/app/*` and public pages.
  static String get apiBaseUrl {
    final raw = _value('API_BASE_URL', _apiBaseUrlDefine).trim();
    if (raw.isEmpty) return '';
    return raw.endsWith('/') ? raw.substring(0, raw.length - 1) : raw;
  }

  /// Host of [apiBaseUrl], e.g. `medsahayta-iota.vercel.app`.
  static String get apiBaseHost {
    final base = apiBaseUrl;
    if (base.isEmpty) return '';
    return Uri.tryParse(base)?.host ?? '';
  }

  static String get firebaseApiKey => _value(
    'FIREBASE_API_KEY',
    _firebaseApiKeyDefine,
    also: const <String>['NEXT_PUBLIC_FIREBASE_API_KEY'],
  );

  static String get firebaseAuthDomain => _value(
    'FIREBASE_AUTH_DOMAIN',
    _firebaseAuthDomainDefine,
    also: const <String>['NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN'],
  );

  static String get firebaseProjectId => _value(
    'FIREBASE_PROJECT_ID',
    _firebaseProjectIdDefine,
    also: const <String>['NEXT_PUBLIC_FIREBASE_PROJECT_ID'],
  );

  static String get firebaseAppId => _value(
    'FIREBASE_APP_ID',
    _firebaseAppIdDefine,
    also: const <String>['NEXT_PUBLIC_FIREBASE_APP_ID'],
  );

  static String get firebaseMessagingSenderId => _value(
    'FIREBASE_MESSAGING_SENDER_ID',
    _firebaseMessagingSenderIdDefine,
    also: const <String>['NEXT_PUBLIC_FIREBASE_MESSAGING_SENDER_ID'],
  );

  static String get firebaseStorageBucket => _value(
    'FIREBASE_STORAGE_BUCKET',
    _firebaseStorageBucketDefine,
    also: const <String>['NEXT_PUBLIC_FIREBASE_STORAGE_BUCKET'],
  );

  static bool get hasFirebase =>
      firebaseApiKey.isNotEmpty &&
      firebaseAppId.isNotEmpty &&
      firebaseProjectId.isNotEmpty &&
      firebaseMessagingSenderId.isNotEmpty;
}
