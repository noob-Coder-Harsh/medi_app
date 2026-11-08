import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/listing.dart';
import '../../../data/models/staff_store.dart';
import '../../../data/rpc/inventory_rpc.dart';
import '../../../data/store_settings_repository.dart';
import '../auth/staff_session.dart';

class InventoryStats {
  const InventoryStats({
    this.total = 0,
    this.inStock = 0,
    this.lowStock = 0,
    this.outOfStock = 0,
  });

  final int total;
  final int inStock;
  final int lowStock;
  final int outOfStock;
}

class InventoryListState {
  const InventoryListState({
    this.query = '',
    this.stock = 'all',
    this.status = 'all',
    this.categoryId,
    this.categories = const <StaffCategory>[],
    this.items = const <ListingCard>[],
    this.total = 0,
    this.offset = 0,
    this.stats = const InventoryStats(),
    this.loading = false,
    this.loadingMore = false,
    this.statsLoading = false,
    this.error,
  });

  final String query;
  final String stock;
  final String status;
  final String? categoryId;
  final List<StaffCategory> categories;
  final List<ListingCard> items;
  final int total;
  final int offset;
  final InventoryStats stats;
  final bool loading;
  final bool loadingMore;
  final bool statsLoading;
  final String? error;

  bool get hasMore => items.length < total;

  InventoryListState copyWith({
    String? query,
    String? stock,
    String? status,
    String? categoryId,
    bool clearCategoryId = false,
    List<StaffCategory>? categories,
    List<ListingCard>? items,
    int? total,
    int? offset,
    InventoryStats? stats,
    bool? loading,
    bool? loadingMore,
    bool? statsLoading,
    String? error,
    bool clearError = false,
  }) {
    return InventoryListState(
      query: query ?? this.query,
      stock: stock ?? this.stock,
      status: status ?? this.status,
      categoryId: clearCategoryId ? null : (categoryId ?? this.categoryId),
      categories: categories ?? this.categories,
      items: items ?? this.items,
      total: total ?? this.total,
      offset: offset ?? this.offset,
      stats: stats ?? this.stats,
      loading: loading ?? this.loading,
      loadingMore: loadingMore ?? this.loadingMore,
      statsLoading: statsLoading ?? this.statsLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class InventoryListController extends Notifier<InventoryListState> {
  static const pageSize = 25;

  Timer? _debounce;
  int _requestId = 0;
  var _categoriesLoaded = false;

  @override
  InventoryListState build() {
    ref.onDispose(() => _debounce?.cancel());
    Future<void>.microtask(refresh);
    return const InventoryListState(loading: true, statsLoading: true);
  }

  InventoryRpc? get _rpc => ref.read(inventoryRpcProvider);

  String? get _storeId =>
      ref.read(staffSessionProvider).storeUser?.storeId;

  void setQuery(String raw) {
    state = state.copyWith(query: raw, clearError: true);
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 280), () {
      unawaited(refresh());
    });
  }

  void setStock(String stock) {
    if (state.stock == stock) return;
    state = state.copyWith(stock: stock, clearError: true);
    unawaited(refresh(reloadStats: false));
  }

  void setStatus(String status) {
    if (state.status == status) return;
    state = state.copyWith(status: status, clearError: true);
    unawaited(refresh(reloadStats: false));
  }

  void setCategoryId(String? categoryId) {
    final next = categoryId == null || categoryId.isEmpty ? null : categoryId;
    if (state.categoryId == next) return;
    state = state.copyWith(
      clearCategoryId: next == null,
      categoryId: next,
      clearError: true,
    );
    unawaited(refresh());
  }

  Future<void> refresh({bool reloadStats = true}) async {
    final id = ++_requestId;
    final rpc = _rpc;
    if (rpc == null) {
      state = state.copyWith(
        loading: false,
        statsLoading: false,
        items: const <ListingCard>[],
        total: 0,
        offset: 0,
        stats: const InventoryStats(),
        clearError: true,
      );
      return;
    }

    state = state.copyWith(
      loading: true,
      statsLoading: reloadStats || state.statsLoading,
      clearError: true,
    );

    try {
      if (!_categoriesLoaded) {
        await _loadCategories();
      }

      final pageFuture = rpc.listStoreInventory(
        query: state.query.trim(),
        categoryId: state.categoryId,
        stock: state.stock,
        status: state.status,
        offset: 0,
        limit: pageSize,
      );
      final statsFuture =
          reloadStats ? _loadStats(rpc) : Future<InventoryStats>.value(state.stats);

      final page = await pageFuture;
      final stats = await statsFuture;
      if (id != _requestId) return;

      state = state.copyWith(
        loading: false,
        statsLoading: false,
        items: page.items,
        total: page.total,
        offset: page.items.length,
        stats: stats,
        clearError: true,
      );
    } catch (error) {
      if (id != _requestId) return;
      state = state.copyWith(
        loading: false,
        statsLoading: false,
        error: '$error',
      );
    }
  }

  Future<void> loadMore() async {
    if (!state.hasMore || state.loading || state.loadingMore) return;
    final id = ++_requestId;
    final rpc = _rpc;
    if (rpc == null) return;

    state = state.copyWith(loadingMore: true, clearError: true);
    try {
      final page = await rpc.listStoreInventory(
        query: state.query.trim(),
        categoryId: state.categoryId,
        stock: state.stock,
        status: state.status,
        offset: state.offset,
        limit: pageSize,
      );
      if (id != _requestId) return;
      state = state.copyWith(
        loadingMore: false,
        items: <ListingCard>[...state.items, ...page.items],
        total: page.total,
        offset: state.offset + page.items.length,
        clearError: true,
      );
    } catch (error) {
      if (id != _requestId) return;
      state = state.copyWith(loadingMore: false, error: '$error');
    }
  }

  Future<void> _loadCategories() async {
    final storeId = _storeId;
    final repo = ref.read(storeSettingsRepositoryProvider);
    if (storeId == null || storeId.isEmpty || repo == null) {
      _categoriesLoaded = true;
      return;
    }
    try {
      final categories = await repo.listStoreCategories(storeId: storeId);
      state = state.copyWith(categories: categories);
      _categoriesLoaded = true;
    } catch (_) {
      _categoriesLoaded = true;
    }
  }

  Future<InventoryStats> _loadStats(InventoryRpc rpc) async {
    Future<int> count(String stock) async {
      final page = await rpc.listStoreInventory(
        categoryId: state.categoryId,
        stock: stock,
        status: 'all',
        offset: 0,
        limit: 1,
      );
      return page.total;
    }

    final counts = await Future.wait(<Future<int>>[
      count('all'),
      count('in_stock'),
      count('low_stock'),
      count('out_of_stock'),
    ]);
    return InventoryStats(
      total: counts[0],
      inStock: counts[1],
      lowStock: counts[2],
      outOfStock: counts[3],
    );
  }
}

final inventoryListProvider =
    NotifierProvider<InventoryListController, InventoryListState>(
      InventoryListController.new,
    );
