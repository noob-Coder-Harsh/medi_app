import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/books_repository.dart';
import '../../../data/models/staff_books.dart';
import '../../../data/staff_api_client.dart';
import '../auth/staff_session.dart';

enum CustomerDueFilter { all, due, clear }

enum CustomerSort { highestDue, lowestDue, nameAsc, recent }

class CustomersState {
  const CustomersState({
    this.query = '',
    this.items = const <StaffCustomer>[],
    this.filter = CustomerDueFilter.all,
    this.sort = CustomerSort.highestDue,
    this.loading = false,
    this.busy = false,
    this.error,
  });

  final String query;
  final List<StaffCustomer> items;
  final CustomerDueFilter filter;
  final CustomerSort sort;
  final bool loading;
  final bool busy;
  final String? error;

  int get totalCount => items.length;

  int get dueCount =>
      items.where((StaffCustomer c) => c.currentBalance > 0).length;

  int get clearCount => totalCount - dueCount;

  List<StaffCustomer> get visibleItems {
    Iterable<StaffCustomer> list = items;
    switch (filter) {
      case CustomerDueFilter.all:
        break;
      case CustomerDueFilter.due:
        list = list.where((StaffCustomer c) => c.currentBalance > 0);
      case CustomerDueFilter.clear:
        list = list.where((StaffCustomer c) => c.currentBalance <= 0);
    }
    final out = list.toList();
    switch (sort) {
      case CustomerSort.highestDue:
        out.sort((StaffCustomer a, StaffCustomer b) {
          final byDue = b.currentBalance.compareTo(a.currentBalance);
          if (byDue != 0) return byDue;
          return a.displayName
              .toLowerCase()
              .compareTo(b.displayName.toLowerCase());
        });
      case CustomerSort.lowestDue:
        out.sort((StaffCustomer a, StaffCustomer b) {
          final byDue = a.currentBalance.compareTo(b.currentBalance);
          if (byDue != 0) return byDue;
          return a.displayName
              .toLowerCase()
              .compareTo(b.displayName.toLowerCase());
        });
      case CustomerSort.nameAsc:
        out.sort(
          (StaffCustomer a, StaffCustomer b) => a.displayName
              .toLowerCase()
              .compareTo(b.displayName.toLowerCase()),
        );
      case CustomerSort.recent:
        out.sort((StaffCustomer a, StaffCustomer b) {
          final aAt = a.lastOrderAt ?? '';
          final bAt = b.lastOrderAt ?? '';
          final byDate = bAt.compareTo(aAt);
          if (byDate != 0) return byDate;
          return a.displayName
              .toLowerCase()
              .compareTo(b.displayName.toLowerCase());
        });
    }
    return out;
  }

  CustomersState copyWith({
    String? query,
    List<StaffCustomer>? items,
    CustomerDueFilter? filter,
    CustomerSort? sort,
    bool? loading,
    bool? busy,
    String? error,
    bool clearError = false,
  }) {
    return CustomersState(
      query: query ?? this.query,
      items: items ?? this.items,
      filter: filter ?? this.filter,
      sort: sort ?? this.sort,
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

  void setFilter(CustomerDueFilter filter) {
    if (state.filter == filter) return;
    state = state.copyWith(filter: filter, clearError: true);
  }

  void setSort(CustomerSort sort) {
    if (state.sort == sort) return;
    state = state.copyWith(sort: sort, clearError: true);
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
