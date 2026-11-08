import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/inventory_repository.dart';
import '../../../data/models/inventory_batch.dart';
import '../../../data/models/listing.dart';
import '../../../data/staff_api_client.dart';
import '../auth/staff_session.dart';

class InventoryDetailState {
  const InventoryDetailState({
    this.product,
    this.batches = const <InventoryBatch>[],
    this.allowsOpeningStock = false,
    this.loading = true,
    this.busy = false,
    this.error,
  });

  final ListingCard? product;
  final List<InventoryBatch> batches;
  final bool allowsOpeningStock;
  final bool loading;
  final bool busy;
  final String? error;

  InventoryDetailState copyWith({
    ListingCard? product,
    List<InventoryBatch>? batches,
    bool? allowsOpeningStock,
    bool? loading,
    bool? busy,
    String? error,
    bool clearError = false,
    bool clearProduct = false,
  }) {
    return InventoryDetailState(
      product: clearProduct ? null : (product ?? this.product),
      batches: batches ?? this.batches,
      allowsOpeningStock: allowsOpeningStock ?? this.allowsOpeningStock,
      loading: loading ?? this.loading,
      busy: busy ?? this.busy,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class InventoryDetailController extends Notifier<InventoryDetailState> {
  InventoryDetailController(this.storeProductId);

  final String storeProductId;

  @override
  InventoryDetailState build() {
    Future<void>.microtask(refresh);
    return const InventoryDetailState();
  }

  InventoryRepository? get _repo => ref.read(inventoryRepositoryProvider);

  Future<void> refresh() async {
    final repo = _repo;
    final storeId = ref.read(staffSessionProvider).storeUser?.storeId;
    if (repo == null) {
      state = state.copyWith(
        loading: false,
        clearProduct: true,
        batches: const <InventoryBatch>[],
        clearError: true,
      );
      return;
    }

    state = state.copyWith(loading: true, clearError: true);
    try {
      final product = await repo.getListingCard(storeProductId);
      final batches = await repo.listBatches(storeProductId);
      final allows = storeId == null || storeId.isEmpty
          ? false
          : await repo.allowsOpeningStock(storeId);
      state = state.copyWith(
        loading: false,
        product: product,
        batches: batches,
        allowsOpeningStock: allows,
        clearError: true,
      );
    } catch (error) {
      state = state.copyWith(loading: false, error: '$error');
    }
  }

  Future<String?> saveListing(UpdateStoreProductInput input) async {
    final token = ref.read(staffSessionProvider).session?.accessToken;
    if (token == null || token.isEmpty) return 'AUTH_SUPABASE_MISSING';
    state = state.copyWith(busy: true, clearError: true);
    try {
      await ref.read(staffWriteApiProvider).updateStoreProduct(
            accessToken: token,
            storeProductId: storeProductId,
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

  Future<String?> addOpeningBatch(OpeningBatchInput input) async {
    final token = ref.read(staffSessionProvider).session?.accessToken;
    if (token == null || token.isEmpty) return 'AUTH_SUPABASE_MISSING';
    state = state.copyWith(busy: true, clearError: true);
    try {
      await ref.read(staffWriteApiProvider).addProductBatch(
            accessToken: token,
            storeProductId: storeProductId,
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

  Future<String?> updateSellingPrice({
    required String batchId,
    required double sellingPrice,
  }) async {
    final token = ref.read(staffSessionProvider).session?.accessToken;
    if (token == null || token.isEmpty) return 'AUTH_SUPABASE_MISSING';
    state = state.copyWith(busy: true, clearError: true);
    try {
      final updated = await ref.read(staffWriteApiProvider).updateProductBatch(
            accessToken: token,
            storeProductId: storeProductId,
            batchId: batchId,
            patch: <String, Object?>{'selling_price': sellingPrice},
          );
      final batches = state.batches
          .map(
            (InventoryBatch batch) =>
                batch.id == batchId ? updated : batch,
          )
          .toList(growable: false);
      state = state.copyWith(busy: false, batches: batches, clearError: true);
      await refresh();
      return null;
    } catch (error) {
      state = state.copyWith(busy: false, error: '$error');
      return '$error';
    }
  }
}

final inventoryDetailProvider = NotifierProvider.family<
  InventoryDetailController,
  InventoryDetailState,
  String
>(InventoryDetailController.new);
