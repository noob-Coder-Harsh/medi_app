import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/staff_store.dart';
import '../../../data/staff_api_client.dart';
import '../../../data/store_settings_repository.dart';
import '../auth/staff_session.dart';

class StoreSettingsState {
  const StoreSettingsState({
    this.store,
    this.loading = true,
    this.busy = false,
    this.error,
    this.saved = false,
  });

  final StaffStore? store;
  final bool loading;
  final bool busy;
  final String? error;
  final bool saved;

  StoreSettingsState copyWith({
    StaffStore? store,
    bool? loading,
    bool? busy,
    String? error,
    bool? saved,
    bool clearError = false,
    bool clearStore = false,
  }) {
    return StoreSettingsState(
      store: clearStore ? null : (store ?? this.store),
      loading: loading ?? this.loading,
      busy: busy ?? this.busy,
      error: clearError ? null : (error ?? this.error),
      saved: saved ?? this.saved,
    );
  }
}

class StoreSettingsController extends Notifier<StoreSettingsState> {
  @override
  StoreSettingsState build() {
    Future<void>.microtask(refresh);
    return const StoreSettingsState();
  }

  String? get _storeId => ref.read(staffSessionProvider).storeUser?.storeId;

  StoreSettingsRepository? get _repo =>
      ref.read(storeSettingsRepositoryProvider);

  Future<void> refresh() async {
    final storeId = _storeId;
    final repo = _repo;
    if (storeId == null || repo == null) {
      state = state.copyWith(
        loading: false,
        clearStore: true,
        clearError: true,
      );
      return;
    }
    state = state.copyWith(loading: true, saved: false, clearError: true);
    try {
      final store = await repo.getStore(storeId: storeId);
      state = state.copyWith(
        loading: false,
        store: store,
        clearError: true,
      );
    } catch (error) {
      state = state.copyWith(loading: false, error: '$error');
    }
  }

  Future<String?> save(UpdateStoreInput input) async {
    final token = ref.read(staffSessionProvider).session?.accessToken;
    if (token == null || token.isEmpty) return 'AUTH_SUPABASE_MISSING';

    state = state.copyWith(busy: true, saved: false, clearError: true);
    try {
      final updated = await ref.read(staffWriteApiProvider).updateStore(
            accessToken: token,
            input: input,
          );
      state = state.copyWith(
        busy: false,
        store: updated,
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

final storeSettingsProvider =
    NotifierProvider<StoreSettingsController, StoreSettingsState>(
      StoreSettingsController.new,
    );
