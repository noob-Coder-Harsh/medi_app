import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/purchase.dart';
import '../../../data/purchase_repository.dart';
import '../../../data/staff_api_client.dart';
import '../auth/staff_session.dart';

class PurchasesListState {
  const PurchasesListState({
    this.query = '',
    this.items = const <PurchaseListItem>[],
    this.loading = false,
    this.error,
  });

  final String query;
  final List<PurchaseListItem> items;
  final bool loading;
  final String? error;

  PurchasesListState copyWith({
    String? query,
    List<PurchaseListItem>? items,
    bool? loading,
    String? error,
    bool clearError = false,
  }) {
    return PurchasesListState(
      query: query ?? this.query,
      items: items ?? this.items,
      loading: loading ?? this.loading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class PurchasesListController extends Notifier<PurchasesListState> {
  Timer? _debounce;
  int _requestId = 0;

  @override
  PurchasesListState build() {
    ref.onDispose(() => _debounce?.cancel());
    Future<void>.microtask(refresh);
    return const PurchasesListState(loading: true);
  }

  String? get _storeId => ref.read(staffSessionProvider).storeUser?.storeId;

  PurchaseRepository? get _repo => ref.read(purchaseRepositoryProvider);

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
    if (storeId == null || storeId.isEmpty || repo == null) {
      state = state.copyWith(
        loading: false,
        items: const <PurchaseListItem>[],
        clearError: true,
      );
      return;
    }

    state = state.copyWith(loading: true, clearError: true);
    try {
      final items = await repo.listPurchases(
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
}

final purchasesListProvider =
    NotifierProvider<PurchasesListController, PurchasesListState>(
      PurchasesListController.new,
    );

class PurchaseFormLine {
  PurchaseFormLine({
    required this.key,
    required this.storeProductId,
    required this.productName,
    required this.batchNumber,
    required this.quantity,
    required this.purchasePrice,
    required this.mrp,
    required this.sellingPrice,
    this.baseUnit,
    this.primaryPackType,
    this.primaryPackQuantity,
    this.expiresAt = '',
    this.currentStock = 0,
  });

  final String key;
  final String storeProductId;
  final String productName;
  String batchNumber;
  int quantity;
  double purchasePrice;
  double mrp;
  double sellingPrice;
  final String? baseUnit;
  final String? primaryPackType;
  final double? primaryPackQuantity;
  String expiresAt;
  final double currentStock;

  PurchaseItemInput toInput() {
    return PurchaseItemInput(
      storeProductId: storeProductId,
      batchNumber: batchNumber,
      quantity: quantity,
      purchasePrice: purchasePrice,
      mrp: mrp,
      sellingPrice: sellingPrice,
      expiresAt: expiresAt,
    );
  }
}

class PurchaseFormState {
  const PurchaseFormState({
    this.suppliers = const <SupplierOption>[],
    this.supplierId,
    this.invoiceNumber = '',
    this.invoiceDate = '',
    this.lines = const <PurchaseFormLine>[],
    this.paymentStatus = 'paid',
    this.paymentMethod = 'cash',
    this.paidAmount = 0,
    this.discountAmount = 0,
    this.otherCharges = 0,
    this.loading = false,
    this.busy = false,
    this.error,
  });

  final List<SupplierOption> suppliers;
  final String? supplierId;
  final String invoiceNumber;
  final String invoiceDate;
  final List<PurchaseFormLine> lines;
  final String paymentStatus;
  final String paymentMethod;
  final double paidAmount;
  final double discountAmount;
  final double otherCharges;
  final bool loading;
  final bool busy;
  final String? error;

  PurchaseTotals get totals => calculatePurchaseTotals(
        items: lines.map((PurchaseFormLine l) => l.toInput()).toList(),
        discountAmount: discountAmount,
        otherCharges: otherCharges,
      );

  PurchaseFormState copyWith({
    List<SupplierOption>? suppliers,
    String? supplierId,
    String? invoiceNumber,
    String? invoiceDate,
    List<PurchaseFormLine>? lines,
    String? paymentStatus,
    String? paymentMethod,
    double? paidAmount,
    double? discountAmount,
    double? otherCharges,
    bool? loading,
    bool? busy,
    String? error,
    bool clearError = false,
    bool clearSupplier = false,
  }) {
    return PurchaseFormState(
      suppliers: suppliers ?? this.suppliers,
      supplierId: clearSupplier ? null : (supplierId ?? this.supplierId),
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      invoiceDate: invoiceDate ?? this.invoiceDate,
      lines: lines ?? this.lines,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paidAmount: paidAmount ?? this.paidAmount,
      discountAmount: discountAmount ?? this.discountAmount,
      otherCharges: otherCharges ?? this.otherCharges,
      loading: loading ?? this.loading,
      busy: busy ?? this.busy,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class PurchaseFormController extends Notifier<PurchaseFormState> {
  @override
  PurchaseFormState build() {
    Future<void>.microtask(loadSuppliers);
    final today = DateTime.now();
    final date =
        '${today.year.toString().padLeft(4, '0')}-'
        '${today.month.toString().padLeft(2, '0')}-'
        '${today.day.toString().padLeft(2, '0')}';
    return PurchaseFormState(
      loading: true,
      invoiceDate: date,
      invoiceNumber: 'INV-${today.millisecondsSinceEpoch.toString().substring(7)}',
    );
  }

  String? get _storeId => ref.read(staffSessionProvider).storeUser?.storeId;

  PurchaseRepository? get _repo => ref.read(purchaseRepositoryProvider);

  Future<void> loadSuppliers() async {
    final storeId = _storeId;
    final repo = _repo;
    if (storeId == null || repo == null) {
      state = state.copyWith(loading: false, clearError: true);
      return;
    }
    state = state.copyWith(loading: true, clearError: true);
    try {
      final suppliers = await repo.listSuppliers(storeId: storeId);
      state = state.copyWith(
        loading: false,
        suppliers: suppliers,
        supplierId: state.supplierId ??
            (suppliers.isEmpty ? null : suppliers.first.id),
        clearError: true,
      );
    } catch (error) {
      state = state.copyWith(loading: false, error: '$error');
    }
  }

  void setSupplier(String? id) {
    state = state.copyWith(supplierId: id, clearError: true);
  }

  void setInvoiceNumber(String value) {
    state = state.copyWith(invoiceNumber: value, clearError: true);
  }

  void setInvoiceDate(String value) {
    state = state.copyWith(invoiceDate: value, clearError: true);
  }

  void setPaymentStatus(String value) {
    final totals = state.totals;
    final paid = value == 'paid'
        ? totals.grandTotal
        : value == 'pending'
            ? 0.0
            : state.paidAmount;
    state = state.copyWith(
      paymentStatus: value,
      paidAmount: paid,
      clearError: true,
    );
  }

  void setPaymentMethod(String value) {
    state = state.copyWith(paymentMethod: value, clearError: true);
  }

  void setPaidAmount(double value) {
    state = state.copyWith(paidAmount: value, clearError: true);
  }

  void addLine(PurchaseFormLine line) {
    state = state.copyWith(
      lines: <PurchaseFormLine>[...state.lines, line],
      clearError: true,
    );
    if (state.paymentStatus == 'paid') {
      state = state.copyWith(paidAmount: state.totals.grandTotal);
    }
  }

  void updateLine(PurchaseFormLine line) {
    state = state.copyWith(
      lines: state.lines
          .map((PurchaseFormLine row) => row.key == line.key ? line : row)
          .toList(growable: false),
      clearError: true,
    );
    if (state.paymentStatus == 'paid') {
      state = state.copyWith(paidAmount: state.totals.grandTotal);
    }
  }

  void removeLine(String key) {
    state = state.copyWith(
      lines: state.lines
          .where((PurchaseFormLine row) => row.key != key)
          .toList(growable: false),
      clearError: true,
    );
    if (state.paymentStatus == 'paid') {
      state = state.copyWith(paidAmount: state.totals.grandTotal);
    }
  }

  Future<String?> createSupplierQuick(String name) async {
    final token = ref.read(staffSessionProvider).session?.accessToken;
    if (token == null || token.isEmpty) return 'AUTH_SUPABASE_MISSING';
    state = state.copyWith(busy: true, clearError: true);
    try {
      final created = await ref.read(staffWriteApiProvider).createSupplier(
            accessToken: token,
            name: name,
          );
      final suppliers = <SupplierOption>[created, ...state.suppliers];
      state = state.copyWith(
        busy: false,
        suppliers: suppliers,
        supplierId: created.id,
        clearError: true,
      );
      return null;
    } catch (error) {
      state = state.copyWith(busy: false, error: '$error');
      return '$error';
    }
  }

  Future<String?> submitCompleted() async {
    final token = ref.read(staffSessionProvider).session?.accessToken;
    if (token == null || token.isEmpty) return 'AUTH_SUPABASE_MISSING';

    final supplierId = state.supplierId;
    if (supplierId == null || supplierId.isEmpty) {
      return tKey('STORE_FORM.PURCHASE_SELECT_SUPPLIER');
    }
    if (state.invoiceNumber.trim().isEmpty) {
      return tKey('STORE_FORM.PURCHASE_INVOICE_NUMBER');
    }
    if (state.lines.isEmpty) {
      return tKey('STORE_FORM.PURCHASE_ADD_PRODUCT');
    }
    for (final line in state.lines) {
      if (line.batchNumber.trim().isEmpty) {
        return tKey('STORE_FORM.PURCHASE_BATCH_NUMBER');
      }
      if (line.quantity < 1 ||
          line.purchasePrice <= 0 ||
          line.mrp <= 0 ||
          line.sellingPrice <= 0) {
        return tKey('STORE_FORM.PURCHASE_ITEMS');
      }
      if (line.sellingPrice > line.mrp) {
        return 'Selling price cannot exceed MRP';
      }
    }

    final totals = state.totals;
    final paid = state.paidAmount.clamp(0, totals.grandTotal).toDouble();
    final due = (totals.grandTotal - paid).clamp(0, totals.grandTotal).toDouble();

    state = state.copyWith(busy: true, clearError: true);
    try {
      await ref.read(staffWriteApiProvider).createPurchase(
            accessToken: token,
            input: SavePurchaseInput(
              supplierId: supplierId,
              invoiceNumber: state.invoiceNumber,
              invoiceDate: state.invoiceDate,
              items: state.lines.map((PurchaseFormLine l) => l.toInput()).toList(),
              subtotal: totals.subtotal,
              discountAmount: totals.discountAmount,
              taxAmount: totals.taxAmount,
              otherCharges: totals.otherCharges,
              roundOffAmount: totals.roundOffAmount,
              grandTotal: totals.grandTotal,
              paymentStatus: state.paymentStatus,
              paymentMethod: state.paymentMethod,
              paidAmount: paid,
              dueAmount: due,
              status: 'completed',
            ),
          );
      state = state.copyWith(busy: false);
      return null;
    } catch (error) {
      state = state.copyWith(busy: false, error: '$error');
      return '$error';
    }
  }

  /// Avoid importing i18n in controller; callers translate known keys.
  String tKey(String key) => key;
}

final purchaseFormProvider =
    NotifierProvider.autoDispose<PurchaseFormController, PurchaseFormState>(
      PurchaseFormController.new,
    );

class PurchaseDetailState {
  const PurchaseDetailState({
    this.detail,
    this.loading = true,
    this.error,
  });

  final PurchaseDetail? detail;
  final bool loading;
  final String? error;

  PurchaseDetailState copyWith({
    PurchaseDetail? detail,
    bool? loading,
    String? error,
    bool clearError = false,
    bool clearDetail = false,
  }) {
    return PurchaseDetailState(
      detail: clearDetail ? null : (detail ?? this.detail),
      loading: loading ?? this.loading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class PurchaseDetailController extends Notifier<PurchaseDetailState> {
  PurchaseDetailController(this.purchaseOrderId);

  final String purchaseOrderId;

  @override
  PurchaseDetailState build() {
    Future<void>.microtask(refresh);
    return const PurchaseDetailState();
  }

  Future<void> refresh() async {
    final storeId = ref.read(staffSessionProvider).storeUser?.storeId;
    final repo = ref.read(purchaseRepositoryProvider);
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
      final detail = await repo.getPurchase(
        storeId: storeId,
        purchaseOrderId: purchaseOrderId,
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
}

final purchaseDetailProvider = NotifierProvider.family<
  PurchaseDetailController,
  PurchaseDetailState,
  String
>(PurchaseDetailController.new);
