import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/rpc/pos_rpc.dart';
import '../../../data/supabase_client.dart';
import 'pos_product.dart';

class PosCatalogState {
  const PosCatalogState({
    this.query = '',
    this.products = const <PosProduct>[],
    this.loading = false,
    this.error,
  });

  final String query;
  final List<PosProduct> products;
  final bool loading;
  final String? error;

  PosCatalogState copyWith({
    String? query,
    List<PosProduct>? products,
    bool? loading,
    String? error,
    bool clearError = false,
  }) {
    return PosCatalogState(
      query: query ?? this.query,
      products: products ?? this.products,
      loading: loading ?? this.loading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class PosCatalogController extends Notifier<PosCatalogState> {
  Timer? _debounce;
  int _requestId = 0;

  @override
  PosCatalogState build() {
    ref.onDispose(() => _debounce?.cancel());
    Future<void>.microtask(() => loadHome());
    return const PosCatalogState(loading: true);
  }

  PosRpc? get _rpc {
    if (!AppSupabase.isReady) return null;
    return ref.read(posRpcProvider);
  }

  void setQuery(String raw) {
    final query = raw.trim();
    state = state.copyWith(query: raw, clearError: true);
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () {
      if (query.isEmpty) {
        unawaited(loadHome());
      } else {
        unawaited(search(query));
      }
    });
  }

  Future<void> loadHome() async {
    final id = ++_requestId;
    final rpc = _rpc;
    if (rpc == null) {
      state = state.copyWith(
        loading: false,
        products: const <PosProduct>[],
        clearError: true,
      );
      return;
    }
    state = state.copyWith(loading: true, clearError: true);
    try {
      final products = await rpc.getPosHome();
      if (id != _requestId) return;
      state = state.copyWith(loading: false, products: products, clearError: true);
    } catch (error) {
      if (id != _requestId) return;
      state = state.copyWith(loading: false, error: '$error');
    }
  }

  Future<void> search(String query) async {
    final id = ++_requestId;
    final rpc = _rpc;
    if (rpc == null) {
      state = state.copyWith(
        loading: false,
        products: const <PosProduct>[],
        clearError: true,
      );
      return;
    }
    state = state.copyWith(loading: true, clearError: true);
    try {
      final products = await rpc.searchPosCatalog(query: query);
      if (id != _requestId) return;
      state = state.copyWith(loading: false, products: products, clearError: true);
    } catch (error) {
      if (id != _requestId) return;
      state = state.copyWith(loading: false, error: '$error');
    }
  }
}

final posCatalogProvider =
    NotifierProvider<PosCatalogController, PosCatalogState>(
      PosCatalogController.new,
    );
