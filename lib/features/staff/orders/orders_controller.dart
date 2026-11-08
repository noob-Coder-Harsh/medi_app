import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/staff_order.dart';
import '../../../data/orders_repository.dart';
import '../../../data/staff_api_client.dart';
import '../auth/staff_session.dart';

class OrdersListState {
  const OrdersListState({
    this.query = '',
    this.status = 'all',
    this.source = 'all',
    this.items = const <StaffOrderListItem>[],
    this.loading = false,
    this.error,
  });

  final String query;
  final String status;
  final String source;
  final List<StaffOrderListItem> items;
  final bool loading;
  final String? error;

  OrdersListState copyWith({
    String? query,
    String? status,
    String? source,
    List<StaffOrderListItem>? items,
    bool? loading,
    String? error,
    bool clearError = false,
  }) {
    return OrdersListState(
      query: query ?? this.query,
      status: status ?? this.status,
      source: source ?? this.source,
      items: items ?? this.items,
      loading: loading ?? this.loading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class OrdersListController extends Notifier<OrdersListState> {
  Timer? _debounce;
  int _requestId = 0;

  @override
  OrdersListState build() {
    ref.onDispose(() => _debounce?.cancel());
    Future<void>.microtask(refresh);
    return const OrdersListState(loading: true);
  }

  String? get _storeId => ref.read(staffSessionProvider).storeUser?.storeId;

  OrdersRepository? get _repo => ref.read(ordersRepositoryProvider);

  void setQuery(String raw) {
    state = state.copyWith(query: raw, clearError: true);
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 280), () {
      unawaited(refresh());
    });
  }

  void setStatus(String status) {
    state = state.copyWith(status: status, clearError: true);
    unawaited(refresh());
  }

  void setSource(String source) {
    state = state.copyWith(source: source, clearError: true);
    unawaited(refresh());
  }

  Future<void> refresh() async {
    final id = ++_requestId;
    final storeId = _storeId;
    final repo = _repo;
    if (storeId == null || storeId.isEmpty || repo == null) {
      state = state.copyWith(
        loading: false,
        items: const <StaffOrderListItem>[],
        clearError: true,
      );
      return;
    }

    state = state.copyWith(loading: true, clearError: true);
    try {
      final items = await repo.listOrders(
        storeId: storeId,
        query: state.query,
        status: state.status,
        source: state.source,
      );
      if (id != _requestId) return;
      state = state.copyWith(loading: false, items: items, clearError: true);
    } catch (error) {
      if (id != _requestId) return;
      state = state.copyWith(loading: false, error: '$error');
    }
  }
}

final ordersListProvider =
    NotifierProvider<OrdersListController, OrdersListState>(
      OrdersListController.new,
    );

class OrderDetailState {
  const OrderDetailState({
    this.detail,
    this.loading = true,
    this.busy = false,
    this.error,
  });

  final StaffOrderDetail? detail;
  final bool loading;
  final bool busy;
  final String? error;

  OrderDetailState copyWith({
    StaffOrderDetail? detail,
    bool? loading,
    bool? busy,
    String? error,
    bool clearError = false,
    bool clearDetail = false,
  }) {
    return OrderDetailState(
      detail: clearDetail ? null : (detail ?? this.detail),
      loading: loading ?? this.loading,
      busy: busy ?? this.busy,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class OrderDetailController extends Notifier<OrderDetailState> {
  OrderDetailController(this.orderId);

  final String orderId;

  @override
  OrderDetailState build() {
    Future<void>.microtask(refresh);
    return const OrderDetailState();
  }

  Future<void> refresh() async {
    final storeId = ref.read(staffSessionProvider).storeUser?.storeId;
    final repo = ref.read(ordersRepositoryProvider);
    if (storeId == null || repo == null) {
      state = state.copyWith(
        loading: false,
        clearDetail: true,
        clearError: true,
      );
      return;
    }
    state = state.copyWith(loading: true, clearError: true);
    try {
      final detail = await repo.getOrder(storeId: storeId, orderId: orderId);
      state = state.copyWith(
        loading: false,
        detail: detail,
        clearError: true,
      );
    } catch (error) {
      state = state.copyWith(loading: false, error: '$error');
    }
  }

  Future<String?> changeStatus(String toStatus, {String? notes}) async {
    final token = ref.read(staffSessionProvider).session?.accessToken;
    if (token == null || token.isEmpty) return 'AUTH_SUPABASE_MISSING';

    state = state.copyWith(busy: true, clearError: true);
    try {
      final updated = await ref.read(staffWriteApiProvider).updateOrderStatus(
            accessToken: token,
            orderId: orderId,
            toStatus: toStatus,
            notes: notes,
          );
      state = state.copyWith(busy: false, detail: updated, clearError: true);
      // Keep board fresh when returning.
      unawaited(ref.read(ordersListProvider.notifier).refresh());
      return null;
    } catch (error) {
      state = state.copyWith(busy: false, error: '$error');
      return '$error';
    }
  }
}

final staffOrderDetailProvider = NotifierProvider.family<
  OrderDetailController,
  OrderDetailState,
  String
>(OrderDetailController.new);
