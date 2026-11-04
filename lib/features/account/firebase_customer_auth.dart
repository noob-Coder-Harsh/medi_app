import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';

import 'customer_auth.dart';

/// Real Firebase phone OTP (IN +91 E.164).
class FirebaseCustomerAuth implements CustomerAuth {
  FirebaseCustomerAuth({FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;
  String? _verificationId;
  String? _autoIdToken;
  int? _resendToken;

  @override
  Future<void> sendOtp(String phoneE164) async {
    _autoIdToken = null;
    final completer = Completer<void>();

    await _auth.verifyPhoneNumber(
      phoneNumber: phoneE164,
      timeout: const Duration(seconds: 60),
      forceResendingToken: _resendToken,
      verificationCompleted: (PhoneAuthCredential credential) async {
        try {
          final result = await _auth.signInWithCredential(credential);
          _autoIdToken = await result.user?.getIdToken();
          if (!completer.isCompleted) completer.complete();
        } catch (error) {
          if (!completer.isCompleted) completer.completeError(error);
        }
      },
      verificationFailed: (FirebaseAuthException error) {
        if (!completer.isCompleted) {
          completer.completeError(
            StateError(error.message ?? error.code),
          );
        }
      },
      codeSent: (String verificationId, int? resendToken) {
        _verificationId = verificationId;
        _resendToken = resendToken;
        if (!completer.isCompleted) completer.complete();
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        _verificationId = verificationId;
      },
    );

    await completer.future;
  }

  @override
  Future<String> verifyOtp({
    required String phoneE164,
    required String code,
  }) async {
    final auto = _autoIdToken;
    if (auto != null && auto.isNotEmpty) {
      _autoIdToken = null;
      return auto;
    }
    final verificationId = _verificationId;
    if (verificationId == null || verificationId.isEmpty) {
      throw StateError('Send OTP before verifying');
    }
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: code,
    );
    final result = await _auth.signInWithCredential(credential);
    final token = await result.user?.getIdToken();
    if (token == null || token.isEmpty) {
      throw StateError('Firebase did not return an idToken');
    }
    return token;
  }

  Future<void> signOut() => _auth.signOut();
}
