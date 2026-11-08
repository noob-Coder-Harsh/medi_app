import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/books_repository.dart';
import '../../../data/models/staff_books.dart';
import '../../../data/staff_api_client.dart';
import '../auth/staff_session.dart';

class SuppliersState {
  const SuppliersState({
    this.query = '',
    this.items = const <StaffSupplier>[],
    this.loading = false,
    this.busy = false,
    this.error,
  });

  final String query;
  final List<StaffSupplier> items;
  final bool loading;
  final bool busy;
  final String? error;

  SuppliersState copyWith({
    String? query,
    List<StaffSupplier>? items,
    bool? loading,
    bool? busy,
    String? error,
    bool clearError = false,
  }) {
    return SuppliersState(
      query: query ?? this.query,
      items: items ?? this.items,
      loading: loading ?? this.loading,
      busy: busy ?? this.busy,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class SuppliersController extends Notifier<SuppliersState> {
  Timer? _debounce;
  int _requestId = 0;

  @override
  SuppliersState build() {
    ref.onDispose(() => _debounce?.cancel());
    Future<void>.microtask(refresh);
    return const SuppliersState(loading: true);
  }

  String? get _storeId => ref.read(staffSessionProvider).storeUser?.storeId;
  BooksRepository? get _repo => ref.read(booksRepositoryProvider);

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
        items: const <StaffSupplier>[],
        clearError: true,
      );
      return;
    }
    state = state.copyWith(loading: true, clearError: true);
    try {
      final items = await repo.listSuppliers(
        storeId: storeId,
        query: state.query,
      );
      if (id != _requestId) return;
      state = state.copyWith(loading: false, items: items, clearError: true);
    } catch (error) {
      if (id != _requestId) return;
      state = state.copyWith(loading: false, error: '$error');
    }
  }

  Future<String?> save(SaveSupplierInput input, {String? supplierId}) async {
    final token = ref.read(staffSessionProvider).session?.accessToken;
    if (token == null || token.isEmpty) return 'AUTH_SUPABASE_MISSING';
    state = state.copyWith(busy: true, clearError: true);
    try {
      final api = ref.read(staffWriteApiProvider);
      if (supplierId == null) {
        await api.createSupplier(
          accessToken: token,
          name: input.name,
          phone: input.phone,
          contactPerson: input.contactPerson,
          notes: input.notes,
          openingBalance: input.openingBalance,
        );
      } else {
        await api.updateSupplier(
          accessToken: token,
          supplierId: supplierId,
          input: input,
        );
      }
      state = state.copyWith(busy: false);
      await refresh();
      return null;
    } catch (error) {
      state = state.copyWith(busy: false, error: '$error');
      return '$error';
    }
  }

  Future<String?> setActive(String supplierId, bool isActive) async {
    final token = ref.read(staffSessionProvider).session?.accessToken;
    if (token == null || token.isEmpty) return 'AUTH_SUPABASE_MISSING';
    state = state.copyWith(busy: true, clearError: true);
    try {
      await ref.read(staffWriteApiProvider).setSupplierActive(
            accessToken: token,
            supplierId: supplierId,
            isActive: isActive,
          );
      state = state.copyWith(busy: false);
      await refresh();
      return null;
    } catch (error) {
      state = state.copyWith(busy: false, error: '$error');
      return '$error';
    }
  }

  Future<String?> settle({
    required String supplierId,
    required double amount,
    required String method,
    String? notes,
  }) async {
    final token = ref.read(staffSessionProvider).session?.accessToken;
    if (token == null || token.isEmpty) return 'AUTH_SUPABASE_MISSING';
    state = state.copyWith(busy: true, clearError: true);
    try {
      await ref.read(staffWriteApiProvider).settleSupplierPayment(
            accessToken: token,
            input: SupplierSettlementInput(
              supplierId: supplierId,
              amount: amount,
              method: method,
              notes: notes,
            ),
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

final suppliersProvider =
    NotifierProvider<SuppliersController, SuppliersState>(
      SuppliersController.new,
    );
