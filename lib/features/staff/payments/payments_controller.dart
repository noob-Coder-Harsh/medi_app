import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/books_repository.dart';
import '../../../data/models/staff_books.dart';
import '../../../data/staff_api_client.dart';
import '../auth/staff_session.dart';

class PaymentsState {
  const PaymentsState({
    this.query = '',
    this.items = const <StaffPayment>[],
    this.customers = const <StaffCustomer>[],
    this.suppliers = const <StaffSupplier>[],
    this.loading = false,
    this.busy = false,
    this.error,
  });

  final String query;
  final List<StaffPayment> items;
  final List<StaffCustomer> customers;
  final List<StaffSupplier> suppliers;
  final bool loading;
  final bool busy;
  final String? error;

  PaymentsState copyWith({
    String? query,
    List<StaffPayment>? items,
    List<StaffCustomer>? customers,
    List<StaffSupplier>? suppliers,
    bool? loading,
    bool? busy,
    String? error,
    bool clearError = false,
  }) {
    return PaymentsState(
      query: query ?? this.query,
      items: items ?? this.items,
      customers: customers ?? this.customers,
      suppliers: suppliers ?? this.suppliers,
      loading: loading ?? this.loading,
      busy: busy ?? this.busy,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class PaymentsController extends Notifier<PaymentsState> {
  Timer? _debounce;
  int _requestId = 0;

  @override
  PaymentsState build() {
    ref.onDispose(() => _debounce?.cancel());
    Future<void>.microtask(refresh);
    return const PaymentsState(loading: true);
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
        items: const <StaffPayment>[],
        clearError: true,
      );
      return;
    }
    state = state.copyWith(loading: true, clearError: true);
    try {
      final results = await Future.wait<Object>([
        repo.listPayments(storeId: storeId, query: state.query),
        repo.listCustomers(storeId: storeId),
        repo.listSuppliers(storeId: storeId, activeOnly: true),
      ]);
      if (id != _requestId) return;
      state = state.copyWith(
        loading: false,
        items: results[0] as List<StaffPayment>,
        customers: results[1] as List<StaffCustomer>,
        suppliers: results[2] as List<StaffSupplier>,
        clearError: true,
      );
    } catch (error) {
      if (id != _requestId) return;
      state = state.copyWith(loading: false, error: '$error');
    }
  }

  Future<String?> settleCustomer(CustomerSettlementInput input) async {
    final token = ref.read(staffSessionProvider).session?.accessToken;
    if (token == null || token.isEmpty) return 'AUTH_SUPABASE_MISSING';
    state = state.copyWith(busy: true, clearError: true);
    try {
      await ref.read(staffWriteApiProvider).settleCustomerPayment(
            accessToken: token,
            input: input,
          );
      state = state.copyWith(busy: false);
      await refresh();
      return null;
    } catch (error) {
      state = state.copyWith(busy: false, error: '$error');
      return '$error';
    }
  }

  Future<String?> settleSupplier(SupplierSettlementInput input) async {
    final token = ref.read(staffSessionProvider).session?.accessToken;
    if (token == null || token.isEmpty) return 'AUTH_SUPABASE_MISSING';
    state = state.copyWith(busy: true, clearError: true);
    try {
      await ref.read(staffWriteApiProvider).settleSupplierPayment(
            accessToken: token,
            input: input,
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

final paymentsProvider =
    NotifierProvider<PaymentsController, PaymentsState>(
      PaymentsController.new,
    );
