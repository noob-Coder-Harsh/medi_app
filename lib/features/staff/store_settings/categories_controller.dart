import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/staff_store.dart';
import '../../../data/staff_api_client.dart';
import '../../../data/store_settings_repository.dart';
import '../auth/staff_session.dart';

class CategoriesSettingsState {
  const CategoriesSettingsState({
    this.selected = const <StaffCategory>[],
    this.available = const <StaffCategory>[],
    this.query = '',
    this.loading = true,
    this.busy = false,
    this.error,
  });

  final List<StaffCategory> selected;
  final List<StaffCategory> available;
  final String query;
  final bool loading;
  final bool busy;
  final String? error;

  CategoriesSettingsState copyWith({
    List<StaffCategory>? selected,
    List<StaffCategory>? available,
    String? query,
    bool? loading,
    bool? busy,
    String? error,
    bool clearError = false,
  }) {
    return CategoriesSettingsState(
      selected: selected ?? this.selected,
      available: available ?? this.available,
      query: query ?? this.query,
      loading: loading ?? this.loading,
      busy: busy ?? this.busy,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class CategoriesSettingsController extends Notifier<CategoriesSettingsState> {
  Timer? _debounce;
  int _requestId = 0;

  @override
  CategoriesSettingsState build() {
    ref.onDispose(() => _debounce?.cancel());
    Future<void>.microtask(refresh);
    return const CategoriesSettingsState();
  }

  String? get _storeId => ref.read(staffSessionProvider).storeUser?.storeId;

  StoreSettingsRepository? get _repo =>
      ref.read(storeSettingsRepositoryProvider);

  void setQuery(String raw) {
    state = state.copyWith(query: raw, clearError: true);
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 280), () {
      unawaited(refresh());
    });
  }

  Future<void> refresh() async {
    final id = ++_requestId;
    final storeId = _storeId;
    final repo = _repo;
    if (storeId == null || repo == null) {
      state = state.copyWith(
        loading: false,
        selected: const <StaffCategory>[],
        available: const <StaffCategory>[],
        clearError: true,
      );
      return;
    }

    state = state.copyWith(loading: true, clearError: true);
    try {
      final selected = await repo.listStoreCategories(storeId: storeId);
      final available = await repo.listAvailableCategories(
        storeId: storeId,
        query: state.query,
      );
      if (id != _requestId) return;
      state = state.copyWith(
        loading: false,
        selected: selected,
        available: available,
        clearError: true,
      );
    } catch (error) {
      if (id != _requestId) return;
      state = state.copyWith(loading: false, error: '$error');
    }
  }

  Future<String?> attach(List<String> ids) async {
    if (ids.isEmpty) return null;
    final token = ref.read(staffSessionProvider).session?.accessToken;
    if (token == null || token.isEmpty) return 'AUTH_SUPABASE_MISSING';
    state = state.copyWith(busy: true, clearError: true);
    try {
      await ref.read(staffWriteApiProvider).attachCategories(
            accessToken: token,
            categoryIds: ids,
          );
      state = state.copyWith(busy: false);
      await refresh();
      return null;
    } catch (error) {
      state = state.copyWith(busy: false, error: '$error');
      return '$error';
    }
  }

  Future<String?> detach(List<String> ids) async {
    if (ids.isEmpty) return null;
    final token = ref.read(staffSessionProvider).session?.accessToken;
    if (token == null || token.isEmpty) return 'AUTH_SUPABASE_MISSING';
    state = state.copyWith(busy: true, clearError: true);
    try {
      await ref.read(staffWriteApiProvider).detachCategories(
            accessToken: token,
            categoryIds: ids,
          );
      state = state.copyWith(busy: false);
      await refresh();
      return null;
    } catch (error) {
      state = state.copyWith(busy: false, error: '$error');
      return '$error';
    }
  }

  Future<String?> createCustom(String name) async {
    final token = ref.read(staffSessionProvider).session?.accessToken;
    if (token == null || token.isEmpty) return 'AUTH_SUPABASE_MISSING';
    final trimmed = name.trim();
    if (trimmed.isEmpty) return 'STORE_FORM.CATEGORY_NAME';
    state = state.copyWith(busy: true, clearError: true);
    try {
      await ref.read(staffWriteApiProvider).createCategory(
            accessToken: token,
            name: trimmed,
          );
      state = state.copyWith(busy: false);
      await refresh();
      return null;
    } catch (error) {
      state = state.copyWith(busy: false, error: '$error');
      return '$error';
    }
  }

  Future<String?> renameCustom(String categoryId, String name) async {
    final token = ref.read(staffSessionProvider).session?.accessToken;
    if (token == null || token.isEmpty) return 'AUTH_SUPABASE_MISSING';
    final trimmed = name.trim();
    if (trimmed.isEmpty) return 'STORE_FORM.CATEGORY_NAME';
    state = state.copyWith(busy: true, clearError: true);
    try {
      await ref.read(staffWriteApiProvider).updateCategory(
            accessToken: token,
            categoryId: categoryId,
            name: trimmed,
          );
      state = state.copyWith(busy: false);
      await refresh();
      return null;
    } catch (error) {
      state = state.copyWith(busy: false, error: '$error');
      return '$error';
    }
  }

  Future<String?> deactivateCustom(String categoryId) async {
    final token = ref.read(staffSessionProvider).session?.accessToken;
    if (token == null || token.isEmpty) return 'AUTH_SUPABASE_MISSING';
    state = state.copyWith(busy: true, clearError: true);
    try {
      await ref.read(staffWriteApiProvider).updateCategory(
            accessToken: token,
            categoryId: categoryId,
            isActive: false,
          );
      state = state.copyWith(busy: false);
      await refresh();
      return null;
    } catch (error) {
      state = state.copyWith(busy: false, error: '$error');
      return '$error';
    }
  }
}

final categoriesSettingsProvider =
    NotifierProvider<CategoriesSettingsController, CategoriesSettingsState>(
      CategoriesSettingsController.new,
    );
