import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/routes.dart';
import 'staff_auth_service.dart';
import 'staff_user.dart';

class StaffSessionState {
  const StaffSessionState({
    this.ready = false,
    this.session,
    this.storeUser,
  });

  final bool ready;
  final Session? session;
  final StaffUser? storeUser;

  bool get isSignedIn => session != null;
  bool get hasStore => storeUser?.hasStore ?? false;

  StaffSessionState copyWith({
    bool? ready,
    Session? session,
    StaffUser? storeUser,
    bool clearSession = false,
    bool clearStoreUser = false,
  }) {
    return StaffSessionState(
      ready: ready ?? this.ready,
      session: clearSession ? null : (session ?? this.session),
      storeUser: clearStoreUser ? null : (storeUser ?? this.storeUser),
    );
  }
}

class StaffSessionController extends Notifier<StaffSessionState> {
  StreamSubscription<AuthState>? _sub;
  bool _hydrating = false;

  @override
  StaffSessionState build() {
    ref.onDispose(() {
      unawaited(_sub?.cancel());
    });
    Future<void>.microtask(_hydrate);
    return const StaffSessionState();
  }

  StaffAuthService get _auth => ref.read(staffAuthServiceProvider);

  Future<void> _hydrate() async {
    if (_hydrating) return;
    _hydrating = true;
    try {
      await _refreshFromAuth();
      await _sub?.cancel();
      _sub = _auth.authStateChanges().listen((AuthState event) {
        unawaited(_onAuthEvent(event));
      });
    } finally {
      _hydrating = false;
    }
  }

  Future<void> _onAuthEvent(AuthState event) async {
    if (event.event == AuthChangeEvent.signedOut) {
      state = const StaffSessionState(ready: true);
      return;
    }
    await _refreshFromAuth();
  }

  Future<void> _refreshFromAuth() async {
    final session = _auth.currentSession;
    if (session == null) {
      state = const StaffSessionState(ready: true);
      return;
    }
    StaffUser? storeUser;
    try {
      storeUser = await _auth.ensureStoreUser();
    } catch (_) {
      storeUser = await _auth.loadStoreUser();
    }
    state = StaffSessionState(
      ready: true,
      session: session,
      storeUser: storeUser,
    );
  }

  /// Sign in, ensure `store_users`, update state. Caller navigates.
  Future<StaffUser> signIn({
    required String email,
    required String password,
  }) async {
    final result = await _auth.signIn(email: email, password: password);
    final session = result.session ?? _auth.currentSession;
    if (session == null) {
      throw StateError('Sign-in failed');
    }
    final storeUser = await _auth.ensureStoreUser();
    state = StaffSessionState(
      ready: true,
      session: session,
      storeUser: storeUser,
    );
    return storeUser;
  }

  /// Sign up, ensure profile, update state. Returns null storeUser if email
  /// confirm is required (no session yet).
  Future<StaffUser?> signUp({
    required String email,
    required String password,
    required String fullName,
    String? phone,
  }) async {
    final result = await _auth.signUp(
      email: email,
      password: password,
      fullName: fullName,
      phone: phone,
    );
    final session = result.session ?? _auth.currentSession;
    if (session == null) {
      state = const StaffSessionState(ready: true);
      return null;
    }
    final storeUser = await _auth.ensureStoreUser(
      fullName: fullName,
      phone: phone,
    );
    state = StaffSessionState(
      ready: true,
      session: session,
      storeUser: storeUser,
    );
    return storeUser;
  }

  Future<void> signOut() async {
    await _auth.signOut();
    state = const StaffSessionState(ready: true);
  }

  Future<void> resetPassword({required String email}) {
    return _auth.resetPassword(email: email);
  }

  void setStoreUser(StaffUser storeUser) {
    state = StaffSessionState(
      ready: true,
      session: state.session ?? _auth.currentSession,
      storeUser: storeUser,
    );
  }

  Future<void> refresh() => _refreshFromAuth();
}

final staffSessionProvider =
    NotifierProvider<StaffSessionController, StaffSessionState>(
      StaffSessionController.new,
    );

/// Post-auth destination: onboarding if no shop, else Today (dashboard).
String staffHomePath(StaffUser? user) {
  if (user != null && user.hasStore) {
    return Routes.staffToday;
  }
  return Routes.staffOnboarding;
}
