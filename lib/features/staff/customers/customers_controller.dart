import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/books_repository.dart';
import '../../../data/models/staff_books.dart';
import '../../../data/staff_api_client.dart';
import '../auth/staff_session.dart';

class CustomersState {
  const CustomersState({
    this.query = '',
    this.items = const <StaffCustomer>[],
    this.loading = false,
    this.busy = false,
    this.error,
  });

  final String query;
  final List<StaffCustomer> items;
  final bool loading;
  final bool busy;
  final String? error;

  CustomersState copyWith({
    String? query,
    List<StaffCustomer>? items,
    bool? loading,
    bool? busy,
    String? error,
    bool clearError = false,
  }) {
    return CustomersState(
      query: query ?? this.query,
      items: items ?? this.items,
      loading: loading ?? this.loading,
      busy: busy ?? this.busy,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class CustomersController extends Notifier<CustomersState> {
  Timer? _debounce;
  int _requestId = 0;

  @override
  CustomersState build() {
    ref.onDispose(() => _debounce?.cancel());
    Future<void>.microtask(refresh);
    return const CustomersState(loading: true);
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
        items: const <StaffCustomer>[],
        clearError: true,
      );
      return;
    }
    state = state.copyWith(loading: true, clearError: true);
    try {
      final items = await repo.listCustomers(
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

  Future<String?> addByPhone(String phone) async {
    final token = ref.read(staffSessionProvider).session?.accessToken;
    if (token == null || token.isEmpty) return 'AUTH_SUPABASE_MISSING';
    state = state.copyWith(busy: true, clearError: true);
    try {
      await ref.read(staffWriteApiProvider).ensureStoreCustomer(
            accessToken: token,
            phone: phone,
          );
      state = state.copyWith(busy: false);
      await refresh();
      return null;
    } catch (error) {
      state = state.copyWith(busy: false, error: '$error');
      return '$error';
    }
  }

  Future<String?> updateNotes({
    required String storeCustomerId,
    required String notes,
    required int loyaltyPoints,
  }) async {
    final token = ref.read(staffSessionProvider).session?.accessToken;
    if (token == null || token.isEmpty) return 'AUTH_SUPABASE_MISSING';
    state = state.copyWith(busy: true, clearError: true);
    try {
      await ref.read(staffWriteApiProvider).updateStoreCustomer(
            accessToken: token,
            storeCustomerId: storeCustomerId,
            notes: notes,
            loyaltyPoints: loyaltyPoints,
          );
      state = state.copyWith(busy: false);
      await refresh();
      return null;
    } catch (error) {
      state = state.copyWith(busy: false, error: '$error');
      return '$error';
    }
  }

  Future<String?> collectDues({
    required String customerId,
    required double amount,
    required String method,
    String? notes,
  }) async {
    final token = ref.read(staffSessionProvider).session?.accessToken;
    if (token == null || token.isEmpty) return 'AUTH_SUPABASE_MISSING';
    state = state.copyWith(busy: true, clearError: true);
    try {
      await ref.read(staffWriteApiProvider).settleCustomerPayment(
            accessToken: token,
            input: CustomerSettlementInput(
              customerId: customerId,
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

final customersProvider =
    NotifierProvider<CustomersController, CustomersState>(
      CustomersController.new,
    );
