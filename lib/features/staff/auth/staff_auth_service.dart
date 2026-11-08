import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../data/supabase_client.dart';
import 'staff_user.dart';

/// Supabase email/password for store owners. Customer Firebase stays separate.
class StaffAuthService {
  StaffAuthService({SupabaseClient? client}) : _client = client;

  final SupabaseClient? _client;

  SupabaseClient get _supabase {
    final injected = _client;
    if (injected != null) return injected;
    return AppSupabase.client;
  }

  bool get isConfigured => _client != null || AppSupabase.isReady;

  Session? get currentSession {
    if (!isConfigured) return null;
    return _supabase.auth.currentSession;
  }

  User? get currentUser {
    if (!isConfigured) return null;
    return _supabase.auth.currentUser;
  }

  Stream<AuthState> authStateChanges() {
    if (!isConfigured) return const Stream<AuthState>.empty();
    return _supabase.auth.onAuthStateChange;
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) {
    _requireConfigured();
    return _supabase.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
    String? phone,
  }) {
    _requireConfigured();
    return _supabase.auth.signUp(
      email: email.trim(),
      password: password,
      data: <String, dynamic>{
        'role': 'owner',
        'full_name': fullName.trim(),
        if (phone != null && phone.trim().isNotEmpty) 'phone': phone.trim(),
      },
    );
  }

  Future<void> signOut() async {
    if (!isConfigured) return;
    await _supabase.auth.signOut();
  }

  Future<void> resetPassword({required String email}) {
    _requireConfigured();
    return _supabase.auth.resetPasswordForEmail(email.trim());
  }

  /// Same job as web `ensureStoreUserAction`: own `store_users` row under RLS.
  Future<StaffUser> ensureStoreUser({String? fullName, String? phone}) async {
    _requireConfigured();
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw StateError('Unauthorized');
    }

    final existing = await _findByAuthUserId(user.id);
    if (existing != null) {
      final needsProfile =
          (fullName != null &&
              fullName.trim().isNotEmpty &&
              (existing.fullName == null || existing.fullName!.isEmpty)) ||
          (phone != null &&
              phone.trim().isNotEmpty &&
              (existing.phone == null || existing.phone!.isEmpty));
      if (!needsProfile) return existing;
      return _updateProfile(
        existing.id,
        fullName: fullName,
        phone: phone,
      );
    }

    try {
      final inserted = await _supabase
          .from('store_users')
          .insert(<String, dynamic>{
            'auth_user_id': user.id,
            'email': user.email,
            'role': 'owner',
            if (fullName != null && fullName.trim().isNotEmpty)
              'full_name': fullName.trim(),
            if (phone != null && phone.trim().isNotEmpty) 'phone': phone.trim(),
          })
          .select()
          .single();
      return StaffUser.fromJson(Map<String, dynamic>.from(inserted as Map));
    } on PostgrestException catch (error) {
      // Unique race — another ensure won; re-read.
      if (error.code == '23505') {
        final again = await _findByAuthUserId(user.id);
        if (again != null) return again;
      }
      rethrow;
    }
  }

  Future<StaffUser?> loadStoreUser() async {
    if (!isConfigured) return null;
    final user = _supabase.auth.currentUser;
    if (user == null) return null;
    return _findByAuthUserId(user.id);
  }

  Future<StaffUser?> _findByAuthUserId(String authUserId) async {
    final row = await _supabase
        .from('store_users')
        .select()
        .eq('auth_user_id', authUserId)
        .maybeSingle();
    if (row == null) return null;
    return StaffUser.fromJson(Map<String, dynamic>.from(row as Map));
  }

  Future<StaffUser> _updateProfile(
    String id, {
    String? fullName,
    String? phone,
  }) async {
    final patch = <String, dynamic>{};
    if (fullName != null && fullName.trim().isNotEmpty) {
      patch['full_name'] = fullName.trim();
    }
    if (phone != null && phone.trim().isNotEmpty) {
      patch['phone'] = phone.trim();
    }
    if (patch.isEmpty) {
      final current = await _supabase
          .from('store_users')
          .select()
          .eq('id', id)
          .single();
      return StaffUser.fromJson(Map<String, dynamic>.from(current as Map));
    }
    final updated = await _supabase
        .from('store_users')
        .update(patch)
        .eq('id', id)
        .select()
        .single();
    return StaffUser.fromJson(Map<String, dynamic>.from(updated as Map));
  }

  void _requireConfigured() {
    if (!isConfigured) {
      throw StateError('Staff sign-in is not configured');
    }
  }
}

final staffAuthServiceProvider = Provider<StaffAuthService>(
  (Ref ref) => StaffAuthService(),
);
