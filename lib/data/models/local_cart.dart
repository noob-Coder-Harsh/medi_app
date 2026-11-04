class CartLine {
  const CartLine({required this.storeProductId, required this.quantity});

  final String storeProductId;
  final double quantity;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'storeProductId': storeProductId,
      'quantity': quantity,
    };
  }

  static CartLine? fromJson(Object? value) {
    if (value is! Map) return null;
    final id = value['storeProductId'];
    if (id is! String || id.isEmpty) return null;
    final rawQty = value['quantity'];
    final quantity = rawQty is num
        ? rawQty.toDouble()
        : double.tryParse('$rawQty') ?? 0;
    if (quantity <= 0) return null;
    return CartLine(storeProductId: id, quantity: quantity);
  }
}

class LocalCart {
  const LocalCart({this.storeId, this.items = const <CartLine>[]});

  static const empty = LocalCart();

  final String? storeId;
  final List<CartLine> items;

  bool get isEmpty => items.isEmpty;

  int get totalUnits {
    var sum = 0;
    for (final line in items) {
      sum += line.quantity.ceil();
    }
    return sum;
  }

  double qtyOf(String storeProductId) {
    for (final line in items) {
      if (line.storeProductId == storeProductId) return line.quantity;
    }
    return 0;
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'storeId': storeId,
      'items': items.map((CartLine line) => line.toJson()).toList(),
    };
  }

  static LocalCart fromJson(Object? value) {
    if (value is! Map) return empty;
    final storeId = value['storeId'];
    final itemsRaw = value['items'];
    final items = <CartLine>[];
    if (itemsRaw is List) {
      for (final entry in itemsRaw) {
        final line = CartLine.fromJson(entry);
        if (line != null) items.add(line);
      }
    }
    if (items.isEmpty) return empty;
    return LocalCart(
      storeId: storeId is String && storeId.isNotEmpty ? storeId : null,
      items: items,
    );
  }
}
