import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Firebase idToken for customer writes. Not the cart.
class AuthTokenStore {
  AuthTokenStore({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const prefsKey = 'customer_id_token';

  final FlutterSecureStorage _storage;

  Future<String?> read() => _storage.read(key: prefsKey);

  Future<void> write(String token) => _storage.write(key: prefsKey, value: token);

  Future<void> clear() => _storage.delete(key: prefsKey);
}

final authTokenStoreProvider = Provider<AuthTokenStore>(
  (Ref ref) => AuthTokenStore(),
);
