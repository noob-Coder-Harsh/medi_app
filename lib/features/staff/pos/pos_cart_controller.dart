import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/packaging.dart';
import 'pos_product.dart';

class PosCartController extends Notifier<List<PosCartItem>> {
  @override
  List<PosCartItem> build() => const <PosCartItem>[];

  void clear() => state = const <PosCartItem>[];

  void addProduct(PosProduct product, {int? quantity}) {
    if (!product.hasStock) return;
    final addQty = quantity ?? getPosAddQuantity(product.packaging);
    final step = addQty < 1 ? 1 : addQty;

    final existingIndex = state.indexWhere(
      (PosCartItem item) => item.storeProductId == product.storeProductId,
    );
    if (existingIndex < 0) {
      state = <PosCartItem>[
        ...state,
        PosCartItem(product: product, quantity: step.toDouble()),
      ];
      return;
    }

    final next = List<PosCartItem>.from(state);
    final current = next[existingIndex];
    next[existingIndex] = current.copyWith(
      product: product,
      quantity: current.quantity + step,
    );
    state = next;
  }

  /// Sets absolute cart qty for [product] (creates the line if missing).
  void putProduct(PosProduct product, double quantity) {
    if (!product.hasStock) return;
    if (!quantity.isFinite || quantity < 1) return;

    final step = getSaleStepQuantity(
      product.salePolicy,
      product.packaging,
    ).toDouble();
    var nextQty = quantity;
    if (step > 1) {
      nextQty = (nextQty / step).round() * step;
      if (nextQty < step) nextQty = step;
    } else {
      nextQty = nextQty.floorToDouble();
    }

    final existingIndex = state.indexWhere(
      (PosCartItem item) => item.storeProductId == product.storeProductId,
    );
    if (existingIndex < 0) {
      state = <PosCartItem>[
        ...state,
        PosCartItem(product: product, quantity: nextQty),
      ];
      return;
    }

    final next = List<PosCartItem>.from(state);
    next[existingIndex] = next[existingIndex].copyWith(
      product: product,
      quantity: nextQty,
    );
    state = next;
  }

  void setQuantity(String storeProductId, double quantity) {
    final index = state.indexWhere(
      (PosCartItem item) => item.storeProductId == storeProductId,
    );
    if (index < 0) return;

    final item = state[index];
    final step = getSaleStepQuantity(item.product.salePolicy, item.product.packaging);
    var nextQty = quantity;
    if (!nextQty.isFinite || nextQty < step) {
      remove(storeProductId);
      return;
    }
    if (step > 1) {
      nextQty = (nextQty / step).round() * step.toDouble();
      if (nextQty < step) nextQty = step.toDouble();
    } else {
      nextQty = nextQty.floorToDouble();
    }

    final next = List<PosCartItem>.from(state);
    next[index] = item.copyWith(quantity: nextQty);
    state = next;
  }

  void bump(String storeProductId, {required bool increase}) {
    final index = state.indexWhere(
      (PosCartItem item) => item.storeProductId == storeProductId,
    );
    if (index < 0) return;
    final item = state[index];
    final step = getSaleStepQuantity(
      item.product.salePolicy,
      item.product.packaging,
    ).toDouble();
    if (increase) {
      setQuantity(storeProductId, item.quantity + step);
      return;
    }
    final next = item.quantity - step;
    if (next < step) {
      remove(storeProductId);
      return;
    }
    setQuantity(storeProductId, next);
  }

  void remove(String storeProductId) {
    state = state
        .where((PosCartItem item) => item.storeProductId != storeProductId)
        .toList(growable: false);
  }

  double get subtotal {
    return cartSubtotal(
      state.map(
        (PosCartItem item) => (
          unitPrice: item.product.unitPrice,
          quantity: item.quantity,
        ),
      ),
    );
  }

  int quantityOf(String storeProductId) {
    for (final item in state) {
      if (item.storeProductId == storeProductId) {
        return item.quantity.floor();
      }
    }
    return 0;
  }
}

final posCartProvider =
    NotifierProvider<PosCartController, List<PosCartItem>>(PosCartController.new);
