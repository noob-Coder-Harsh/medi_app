import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/staff_store.dart';
import '../../../data/staff_api_client.dart';
import '../auth/staff_session.dart';
import '../auth/staff_user.dart';

class ProfileSettingsState {
  const ProfileSettingsState({
    this.user,
    this.loading = true,
    this.busy = false,
    this.error,
    this.saved = false,
  });

  final StaffUser? user;
  final bool loading;
  final bool busy;
  final String? error;
  final bool saved;

  ProfileSettingsState copyWith({
    StaffUser? user,
    bool? loading,
    bool? busy,
    String? error,
    bool? saved,
    bool clearError = false,
  }) {
    return ProfileSettingsState(
      user: user ?? this.user,
      loading: loading ?? this.loading,
      busy: busy ?? this.busy,
      error: clearError ? null : (error ?? this.error),
      saved: saved ?? this.saved,
    );
  }
}

class ProfileSettingsController extends Notifier<ProfileSettingsState> {
  @override
  ProfileSettingsState build() {
    final user = ref.watch(staffSessionProvider).storeUser;
    return ProfileSettingsState(user: user, loading: false);
  }

  Future<String?> save({required String fullName, required String phone}) async {
    final token = ref.read(staffSessionProvider).session?.accessToken;
    if (token == null || token.isEmpty) return 'AUTH_SUPABASE_MISSING';

    state = state.copyWith(busy: true, saved: false, clearError: true);
    try {
      await ref.read(staffWriteApiProvider).updateProfile(
            accessToken: token,
            input: UpdateProfileInput(
              fullName: fullName.trim(),
              phone: phone.trim(),
            ),
          );
      await ref.read(staffSessionProvider.notifier).refresh();
      state = state.copyWith(
        busy: false,
        user: ref.read(staffSessionProvider).storeUser,
        saved: true,
        clearError: true,
      );
      return null;
    } catch (error) {
      state = state.copyWith(busy: false, error: '$error');
      return '$error';
    }
  }
}

final profileSettingsProvider =
    NotifierProvider<ProfileSettingsController, ProfileSettingsState>(
      ProfileSettingsController.new,
    );
