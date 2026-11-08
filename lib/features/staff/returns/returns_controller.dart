import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/staff_order.dart';
import '../../../data/models/staff_return.dart';
import '../../../data/orders_repository.dart';
import '../../../data/returns_repository.dart';
import '../../../data/staff_api_client.dart';
import '../auth/staff_session.dart';

class ReturnsListState {
  const ReturnsListState({
    this.query = '',
    this.status = 'all',
    this.items = const <StaffReturnListItem>[],
    this.loading = false,
    this.error,
  });

  final String query;
  final String status;
  final List<StaffReturnListItem> items;
  final bool loading;
  final String? error;

  ReturnsListState copyWith({
    String? query,
    String? status,
    List<StaffReturnListItem>? items,
    bool? loading,
    String? error,
    bool clearError = false,
  }) {
    return ReturnsListState(
      query: query ?? this.query,
      status: status ?? this.status,
      items: items ?? this.items,
      loading: loading ?? this.loading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class ReturnsListController extends Notifier<ReturnsListState> {
  Timer? _debounce;
  int _requestId = 0;

  @override
  ReturnsListState build() {
    ref.onDispose(() => _debounce?.cancel());
    Future<void>.microtask(refresh);
    return const ReturnsListState(loading: true);
  }

  String? get _storeId => ref.read(staffSessionProvider).storeUser?.storeId;

  ReturnsRepository? get _repo => ref.read(returnsRepositoryProvider);

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

  Future<void> refresh() async {
    final id = ++_requestId;
    final storeId = _storeId;
    final repo = _repo;
    if (storeId == null || storeId.isEmpty || repo == null) {
      state = state.copyWith(
        loading: false,
        items: const <StaffReturnListItem>[],
        clearError: true,
      );
      return;
    }

    state = state.copyWith(loading: true, clearError: true);
    try {
      final items = await repo.listReturns(
        storeId: storeId,
        query: state.query,
        status: state.status,
      );
      if (id != _requestId) return;
      state = state.copyWith(loading: false, items: items, clearError: true);
    } catch (error) {
      if (id != _requestId) return;
      state = state.copyWith(loading: false, error: '$error');
    }
  }
}

final returnsListProvider =
    NotifierProvider<ReturnsListController, ReturnsListState>(
      ReturnsListController.new,
    );

class ReturnFormLine {
  ReturnFormLine({
    required this.orderItemId,
    required this.productName,
    required this.soldQty,
    required this.unitPrice,
    this.selected = false,
    this.quantity = 1,
    this.condition = 'sealed',
    this.restockAction = 'restock',
  });

  final String orderItemId;
  final String productName;
  final int soldQty;
  final double unitPrice;
  bool selected;
  int quantity;
  String condition;
  String restockAction;
}

class ReturnFormState {
  const ReturnFormState({
    this.deliveredOrders = const <StaffOrderListItem>[],
    this.orderId,
    this.orderDetail,
    this.lines = const <ReturnFormLine>[],
    this.reason = '',
    this.notes = '',
    this.orderQuery = '',
    this.createdReturnId,
    this.loading = false,
    this.busy = false,
    this.error,
  });

  final List<StaffOrderListItem> deliveredOrders;
  final String? orderId;
  final StaffOrderDetail? orderDetail;
  final List<ReturnFormLine> lines;
  final String reason;
  final String notes;
  final String orderQuery;
  final String? createdReturnId;
  final bool loading;
  final bool busy;
  final String? error;

  double get refundEstimate {
    var total = 0.0;
    for (final line in lines) {
      if (!line.selected || line.quantity < 1) continue;
      total += line.unitPrice * line.quantity;
    }
    return total;
  }

  ReturnFormState copyWith({
    List<StaffOrderListItem>? deliveredOrders,
    String? orderId,
    StaffOrderDetail? orderDetail,
    List<ReturnFormLine>? lines,
    String? reason,
    String? notes,
    String? orderQuery,
    String? createdReturnId,
    bool? loading,
    bool? busy,
    String? error,
    bool clearError = false,
    bool clearOrder = false,
  }) {
    return ReturnFormState(
      deliveredOrders: deliveredOrders ?? this.deliveredOrders,
      orderId: clearOrder ? null : (orderId ?? this.orderId),
      orderDetail: clearOrder ? null : (orderDetail ?? this.orderDetail),
      lines: clearOrder ? const <ReturnFormLine>[] : (lines ?? this.lines),
      reason: reason ?? this.reason,
      notes: notes ?? this.notes,
      orderQuery: orderQuery ?? this.orderQuery,
      createdReturnId: createdReturnId ?? this.createdReturnId,
      loading: loading ?? this.loading,
      busy: busy ?? this.busy,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class ReturnFormController extends Notifier<ReturnFormState> {
  Timer? _debounce;

  @override
  ReturnFormState build() {
    ref.onDispose(() => _debounce?.cancel());
    Future<void>.microtask(loadDeliveredOrders);
    return const ReturnFormState(loading: true);
  }

  String? get _storeId => ref.read(staffSessionProvider).storeUser?.storeId;

  OrdersRepository? get _orders => ref.read(ordersRepositoryProvider);

  Future<void> loadDeliveredOrders() async {
    final storeId = _storeId;
    final repo = _orders;
    if (storeId == null || repo == null) {
      state = state.copyWith(loading: false, clearError: true);
      return;
    }
    state = state.copyWith(loading: true, clearError: true);
    try {
      final orders = await repo.listDeliveredOrders(
        storeId: storeId,
        query: state.orderQuery,
      );
      state = state.copyWith(
        loading: false,
        deliveredOrders: orders,
        clearError: true,
      );
    } catch (error) {
      state = state.copyWith(loading: false, error: '$error');
    }
  }

  void setOrderQuery(String raw) {
    state = state.copyWith(orderQuery: raw, clearError: true);
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 280), () {
      unawaited(loadDeliveredOrders());
    });
  }

  Future<void> selectOrder(String orderId) async {
    final storeId = _storeId;
    final repo = _orders;
    if (storeId == null || repo == null) return;

    state = state.copyWith(loading: true, clearError: true);
    try {
      final detail = await repo.getOrder(storeId: storeId, orderId: orderId);
      if (detail == null || detail.status != 'delivered') {
        state = state.copyWith(
          loading: false,
          error: 'STORE_FORM.RETURN_ORDER_NOT_ELIGIBLE',
        );
        return;
      }
      final lines = detail.items
          .map(
            (StaffOrderLine item) => ReturnFormLine(
              orderItemId: item.id,
              productName: item.productName,
              soldQty: item.quantity,
              unitPrice: item.unitPrice,
              quantity: item.quantity < 1 ? 1 : item.quantity,
            ),
          )
          .toList(growable: false);
      state = state.copyWith(
        loading: false,
        orderId: orderId,
        orderDetail: detail,
        lines: lines,
        clearError: true,
      );
    } catch (error) {
      state = state.copyWith(loading: false, error: '$error');
    }
  }

  void clearOrder() {
    state = state.copyWith(clearOrder: true, clearError: true);
  }

  void setReason(String value) {
    state = state.copyWith(reason: value, clearError: true);
  }

  void setNotes(String value) {
    state = state.copyWith(notes: value, clearError: true);
  }

  void toggleLine(String orderItemId, bool selected) {
    state = state.copyWith(
      lines: state.lines
          .map((ReturnFormLine line) {
            if (line.orderItemId != orderItemId) return line;
            line.selected = selected;
            return line;
          })
          .toList(growable: false),
      clearError: true,
    );
  }

  void setLineQty(String orderItemId, int qty) {
    state = state.copyWith(
      lines: state.lines
          .map((ReturnFormLine line) {
            if (line.orderItemId != orderItemId) return line;
            line.quantity = qty.clamp(1, line.soldQty);
            return line;
          })
          .toList(growable: false),
      clearError: true,
    );
  }

  void setLineCondition(String orderItemId, String condition) {
    state = state.copyWith(
      lines: state.lines
          .map((ReturnFormLine line) {
            if (line.orderItemId != orderItemId) return line;
            line.condition = condition;
            return line;
          })
          .toList(growable: false),
      clearError: true,
    );
  }

  void setLineRestock(String orderItemId, String action) {
    state = state.copyWith(
      lines: state.lines
          .map((ReturnFormLine line) {
            if (line.orderItemId != orderItemId) return line;
            line.restockAction = action;
            return line;
          })
          .toList(growable: false),
      clearError: true,
    );
  }

  Future<String?> submit() async {
    final token = ref.read(staffSessionProvider).session?.accessToken;
    if (token == null || token.isEmpty) return 'AUTH_SUPABASE_MISSING';

    final orderId = state.orderId;
    if (orderId == null || orderId.isEmpty) {
      return 'STORE_FORM.RETURN_ORDER_NOT_ELIGIBLE';
    }

    final selected = state.lines
        .where((ReturnFormLine line) => line.selected && line.quantity > 0)
        .toList(growable: false);
    if (selected.isEmpty) return 'STORE_FORM.RETURN_NO_ITEMS';

    for (final line in selected) {
      if (line.quantity > line.soldQty) {
        return 'STORE_FORM.RETURN_QUANTITY_EXCEEDS';
      }
    }

    state = state.copyWith(busy: true, clearError: true);
    try {
      final created = await ref.read(staffWriteApiProvider).createReturn(
            accessToken: token,
            input: CreateReturnInput(
              orderId: orderId,
              reason: state.reason.trim().isEmpty ? null : state.reason.trim(),
              notes: state.notes.trim().isEmpty ? null : state.notes.trim(),
              items: selected
                  .map(
                    (ReturnFormLine line) => CreateReturnItemInput(
                      orderItemId: line.orderItemId,
                      quantity: line.quantity,
                      condition: line.condition,
                      restockAction: line.restockAction,
                    ),
                  )
                  .toList(growable: false),
            ),
          );
      state = state.copyWith(
        busy: false,
        createdReturnId: created.id,
        clearError: true,
      );
      unawaited(ref.read(returnsListProvider.notifier).refresh());
      return null;
    } catch (error) {
      state = state.copyWith(busy: false, error: '$error');
      return '$error';
    }
  }
}

final returnFormProvider =
    NotifierProvider.autoDispose<ReturnFormController, ReturnFormState>(
      ReturnFormController.new,
    );

class ReturnDetailState {
  const ReturnDetailState({
    this.detail,
    this.loading = true,
    this.busy = false,
    this.error,
  });

  final StaffReturnDetail? detail;
  final bool loading;
  final bool busy;
  final String? error;

  ReturnDetailState copyWith({
    StaffReturnDetail? detail,
    bool? loading,
    bool? busy,
    String? error,
    bool clearError = false,
    bool clearDetail = false,
  }) {
    return ReturnDetailState(
      detail: clearDetail ? null : (detail ?? this.detail),
      loading: loading ?? this.loading,
      busy: busy ?? this.busy,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class ReturnDetailController extends Notifier<ReturnDetailState> {
  ReturnDetailController(this.returnId);

  final String returnId;

  @override
  ReturnDetailState build() {
    Future<void>.microtask(refresh);
    return const ReturnDetailState();
  }

  Future<void> refresh() async {
    final storeId = ref.read(staffSessionProvider).storeUser?.storeId;
    final repo = ref.read(returnsRepositoryProvider);
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
      final detail = await repo.getReturn(
        storeId: storeId,
        returnId: returnId,
      );
      state = state.copyWith(
        loading: false,
        detail: detail,
        clearError: true,
      );
    } catch (error) {
      state = state.copyWith(loading: false, error: '$error');
    }
  }

  Future<String?> approve({String? notes}) async {
    final token = ref.read(staffSessionProvider).session?.accessToken;
    if (token == null || token.isEmpty) return 'AUTH_SUPABASE_MISSING';
    state = state.copyWith(busy: true, clearError: true);
    try {
      final updated = await ref.read(staffWriteApiProvider).approveReturn(
            accessToken: token,
            returnId: returnId,
            notes: notes,
          );
      state = state.copyWith(busy: false, detail: updated, clearError: true);
      unawaited(ref.read(returnsListProvider.notifier).refresh());
      return null;
    } catch (error) {
      state = state.copyWith(busy: false, error: '$error');
      return '$error';
    }
  }

  Future<String?> reject({String? notes}) async {
    final token = ref.read(staffSessionProvider).session?.accessToken;
    if (token == null || token.isEmpty) return 'AUTH_SUPABASE_MISSING';
    state = state.copyWith(busy: true, clearError: true);
    try {
      final updated = await ref.read(staffWriteApiProvider).rejectReturn(
            accessToken: token,
            returnId: returnId,
            notes: notes,
          );
      state = state.copyWith(busy: false, detail: updated, clearError: true);
      unawaited(ref.read(returnsListProvider.notifier).refresh());
      return null;
    } catch (error) {
      state = state.copyWith(busy: false, error: '$error');
      return '$error';
    }
  }
}

final returnDetailProvider = NotifierProvider.family<
  ReturnDetailController,
  ReturnDetailState,
  String
>(ReturnDetailController.new);
