import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/api_client.dart';
import '../../data/firebase_client.dart';
import '../../data/local/auth_token_store.dart';
import '../../data/models/checkout.dart';
import 'firebase_customer_auth.dart';

/// Phone OTP for customer writes. Real Firebase when [AppFirebase.isReady].
abstract class CustomerAuth {
  Future<void> sendOtp(String phoneE164);

  /// Returns Firebase idToken on success.
  Future<String> verifyOtp({required String phoneE164, required String code});
}

class UnconfiguredCustomerAuth implements CustomerAuth {
  const UnconfiguredCustomerAuth();

  @override
  Future<void> sendOtp(String phoneE164) async {
    throw StateError('Firebase OTP is not configured yet');
  }

  @override
  Future<String> verifyOtp({
    required String phoneE164,
    required String code,
  }) async {
    throw StateError('Firebase OTP is not configured yet');
  }
}

final customerAuthProvider = Provider<CustomerAuth>((Ref ref) {
  if (AppFirebase.isReady) {
    return FirebaseCustomerAuth();
  }
  return const UnconfiguredCustomerAuth();
});

class CustomerSessionState {
  const CustomerSessionState({this.profile, this.idToken});

  final CustomerProfile? profile;
  final String? idToken;

  bool get isSignedIn =>
      idToken != null &&
      idToken!.isNotEmpty &&
      profile != null &&
      profile!.customerId.isNotEmpty;
}

class CustomerSessionController extends Notifier<CustomerSessionState> {
  bool _ready = false;

  @override
  CustomerSessionState build() {
    Future<void>.microtask(_hydrate);
    return const CustomerSessionState();
  }

  Future<void> _hydrate() async {
    if (_ready) return;
    String? token;
    try {
      token = await ref.read(authTokenStoreProvider).read();
    } catch (_) {
      token = null;
    }
    if (_ready) return;
    _ready = true;
    if (token == null || token.isEmpty) return;
    try {
      final profile = await ref
          .read(appWriteApiProvider)
          .ensureSession(idToken: token);
      state = CustomerSessionState(profile: profile, idToken: token);
    } catch (_) {
      try {
        await ref.read(authTokenStoreProvider).clear();
      } catch (_) {}
    }
  }

  Future<void> signInWithIdToken(String idToken) async {
    final profile = await ref
        .read(appWriteApiProvider)
        .ensureSession(idToken: idToken);
    await ref.read(authTokenStoreProvider).write(idToken);
    state = CustomerSessionState(profile: profile, idToken: idToken);
  }

  Future<void> signOut() async {
    final auth = ref.read(customerAuthProvider);
    if (auth is FirebaseCustomerAuth) {
      try {
        await auth.signOut();
      } catch (_) {}
    }
    try {
      await ref.read(authTokenStoreProvider).clear();
    } catch (_) {}
    state = const CustomerSessionState();
  }
}

final customerSessionProvider =
    NotifierProvider<CustomerSessionController, CustomerSessionState>(
      CustomerSessionController.new,
    );

String? normalizeIndianMobile(String raw) {
  final digits = raw.replaceAll(RegExp(r'\D'), '');
  if (digits.length == 10) return '+91$digits';
  if (digits.length == 11 && digits.startsWith('0')) {
    return '+91${digits.substring(1)}';
  }
  if (digits.length == 12 && digits.startsWith('91')) return '+$digits';
  if (raw.trim().startsWith('+') && digits.length >= 10) return '+$digits';
  return null;
}

bool isValidOtpCode(String raw) => RegExp(r'^\d{6}$').hasMatch(raw.trim());
