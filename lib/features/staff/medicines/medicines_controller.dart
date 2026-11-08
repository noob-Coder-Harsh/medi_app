import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/catalog_repository.dart';
import '../../../data/models/catalog_product.dart';
import '../../../data/staff_api_client.dart';
import '../auth/staff_session.dart';
import '../inventory/inventory_controller.dart';

/// Master-catalog browse + add-to-store (used by quick-add sheet / create).
class MedicinesState {
  const MedicinesState({
    this.query = '',
    this.catalog = const <CatalogProduct>[],
    this.loading = false,
    this.addingIds = const <String>{},
    this.error,
    this.busyWrite = false,
  });

  final String query;
  final List<CatalogProduct> catalog;
  final bool loading;
  final Set<String> addingIds;
  final String? error;
  final bool busyWrite;

  MedicinesState copyWith({
    String? query,
    List<CatalogProduct>? catalog,
    bool? loading,
    Set<String>? addingIds,
    String? error,
    bool? busyWrite,
    bool clearError = false,
  }) {
    return MedicinesState(
      query: query ?? this.query,
      catalog: catalog ?? this.catalog,
      loading: loading ?? this.loading,
      addingIds: addingIds ?? this.addingIds,
      error: clearError ? null : (error ?? this.error),
      busyWrite: busyWrite ?? this.busyWrite,
    );
  }
}

class MedicinesController extends Notifier<MedicinesState> {
  Timer? _debounce;
  int _requestId = 0;

  @override
  MedicinesState build() {
    ref.onDispose(() => _debounce?.cancel());
    return const MedicinesState();
  }

  String? get _storeId =>
      ref.read(staffSessionProvider).storeUser?.storeId;

  CatalogRepository? get _repo => ref.read(catalogRepositoryProvider);

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
        catalog: const <CatalogProduct>[],
        clearError: true,
      );
      return;
    }

    state = state.copyWith(loading: true, clearError: true);
    try {
      final query = state.query.trim();
      final catalog = query.isEmpty
          ? await repo.browseAvailable(storeId: storeId)
          : await repo.searchCatalog(storeId: storeId, query: query);
      if (id != _requestId) return;
      state = state.copyWith(
        loading: false,
        catalog: catalog,
        clearError: true,
      );
    } catch (error) {
      if (id != _requestId) return;
      state = state.copyWith(loading: false, error: '$error');
    }
  }

  Future<String?> addToStore(CatalogProduct product) async {
    if (product.isInStore) return null;
    final token = ref.read(staffSessionProvider).session?.accessToken;
    if (token == null || token.isEmpty) {
      return 'AUTH_SUPABASE_MISSING';
    }

    final nextAdding = Set<String>.from(state.addingIds)..add(product.id);
    state = state.copyWith(addingIds: nextAdding, clearError: true);
    try {
      await ref.read(staffWriteApiProvider).addCatalogProduct(
            accessToken: token,
            productId: product.id,
          );
      final catalog = state.catalog
          .map(
            (CatalogProduct row) => row.id == product.id
                ? row.copyWith(isInStore: true)
                : row,
          )
          .toList(growable: false);
      final done = Set<String>.from(state.addingIds)..remove(product.id);
      state = state.copyWith(catalog: catalog, addingIds: done);
      ref.invalidate(inventoryListProvider);
      return null;
    } catch (error) {
      final done = Set<String>.from(state.addingIds)..remove(product.id);
      state = state.copyWith(addingIds: done, error: '$error');
      return '$error';
    }
  }

  Future<String?> createCustom(CreateCustomProductInput input) async {
    final token = ref.read(staffSessionProvider).session?.accessToken;
    if (token == null || token.isEmpty) {
      return 'AUTH_SUPABASE_MISSING';
    }
    state = state.copyWith(busyWrite: true, clearError: true);
    try {
      await ref.read(staffWriteApiProvider).createCustomCatalogProduct(
            accessToken: token,
            input: input,
          );
      state = state.copyWith(busyWrite: false);
      ref.invalidate(inventoryListProvider);
      return null;
    } catch (error) {
      state = state.copyWith(busyWrite: false, error: '$error');
      return '$error';
    }
  }
}

final medicinesProvider =
    NotifierProvider<MedicinesController, MedicinesState>(
      MedicinesController.new,
    );
