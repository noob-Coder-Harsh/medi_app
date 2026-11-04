import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/local/cart_store.dart';
import '../../data/models/listing.dart';
import '../../data/models/local_cart.dart';

enum CartAddResult { added, needsConfirm, blocked }

/// Pack-aware step. Caps stay on [ListingCard.availableQuantity] without showing it.
double cartStep(ListingCard card) {
  var policy = card.salePolicy;
  if (policy == 'inherit') {
    policy = card.kind == 'tablet_capsule' ? 'loose_allowed' : 'whole_only';
  }
  if (policy == 'pack_only' || policy == 'whole_only') {
    final pack = card.primaryPackQuantity;
    if (pack != null && pack > 0) return pack;
  }
  return 1;
}

bool canIncrease(ListingCard card, double quantity) {
  if (!card.inStock || card.availableQuantity <= 0) return false;
  return quantity + cartStep(card) <= card.availableQuantity + 1e-9;
}

final cartStoreProvider = Provider<CartStore>((Ref ref) => CartStore());

final cartProvider = NotifierProvider<CartController, LocalCart>(
  CartController.new,
);

final cartReadyProvider = Provider<bool>((Ref ref) {
  ref.watch(cartProvider);
  return ref.read(cartProvider.notifier).isReady;
});

class CartController extends Notifier<LocalCart> {
  bool _ready = false;

  bool get isReady => _ready;

  @override
  LocalCart build() {
    Future<void>.microtask(_ensureReady);
    return LocalCart.empty;
  }

  Future<void> _ensureReady() async {
    if (_ready) return;
    final loaded = await ref.read(cartStoreProvider).read();
    if (_ready) return;
    _ready = true;
    // New instance so listeners rebuild even when the cart is still empty.
    state = LocalCart(storeId: loaded.storeId, items: List<CartLine>.from(loaded.items));
  }

  Future<void> _commit(LocalCart next) async {
    state = next;
    await ref.read(cartStoreProvider).write(next);
  }

  Future<CartAddResult> tryAdd({
    required String storeId,
    required ListingCard card,
  }) async {
    await _ensureReady();
    if (storeId.isEmpty) return CartAddResult.blocked;
    if (!card.inStock || card.availableQuantity <= 0) {
      return CartAddResult.blocked;
    }
    if (state.items.isNotEmpty &&
        state.storeId != null &&
        state.storeId != storeId) {
      return CartAddResult.needsConfirm;
    }
    await _applyAdd(storeId: storeId, card: card);
    return CartAddResult.added;
  }

  Future<void> replaceAndAdd({
    required String storeId,
    required ListingCard card,
  }) async {
    await _ensureReady();
    await _commit(LocalCart.empty);
    await _applyAdd(storeId: storeId, card: card);
  }

  Future<void> increase(ListingCard card) async {
    await _ensureReady();
    if (state.storeId == null) return;
    await _applyAdd(storeId: state.storeId!, card: card);
  }

  Future<void> decrease(ListingCard card) async {
    await _ensureReady();
    final current = state.qtyOf(card.id);
    if (current <= 0) return;
    await setQuantity(card.id, current - cartStep(card));
  }

  Future<void> setQuantity(String storeProductId, double quantity) async {
    await _ensureReady();
    if (quantity <= 0) {
      final remaining = state.items
          .where((CartLine line) => line.storeProductId != storeProductId)
          .toList();
      await _commit(
        remaining.isEmpty
            ? LocalCart.empty
            : LocalCart(storeId: state.storeId, items: remaining),
      );
      return;
    }
    final items = <CartLine>[];
    var found = false;
    for (final line in state.items) {
      if (line.storeProductId == storeProductId) {
        items.add(CartLine(storeProductId: storeProductId, quantity: quantity));
        found = true;
      } else {
        items.add(line);
      }
    }
    if (!found) {
      items.add(CartLine(storeProductId: storeProductId, quantity: quantity));
    }
    await _commit(LocalCart(storeId: state.storeId, items: items));
  }

  Future<void> clear() async {
    await _ensureReady();
    await _commit(LocalCart.empty);
  }

  Future<void> _applyAdd({
    required String storeId,
    required ListingCard card,
  }) async {
    final step = cartStep(card);
    final current = state.storeId == storeId ? state.qtyOf(card.id) : 0;
    final nextQty = current + step;
    if (nextQty > card.availableQuantity + 1e-9) return;

    final items = <CartLine>[];
    var found = false;
    if (state.storeId == storeId) {
      for (final line in state.items) {
        if (line.storeProductId == card.id) {
          items.add(CartLine(storeProductId: card.id, quantity: nextQty));
          found = true;
        } else {
          items.add(line);
        }
      }
    }
    if (!found) {
      items.add(CartLine(storeProductId: card.id, quantity: nextQty));
    }
    await _commit(LocalCart(storeId: storeId, items: items));
  }
}
