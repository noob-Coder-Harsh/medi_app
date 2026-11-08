import 'pos_product.dart';

/// Client-side POS catalog chip filter (no API).
sealed class PosCatalogFilter {
  const PosCatalogFilter();

  static const PosCatalogFilter all = PosFilterAll();
  static const PosCatalogFilter rx = PosFilterRx();
  static const PosCatalogFilter otc = PosFilterOtc();

  static PosCatalogFilter category(String name) => PosFilterCategory(name);
}

final class PosFilterAll extends PosCatalogFilter {
  const PosFilterAll();
}

final class PosFilterRx extends PosCatalogFilter {
  const PosFilterRx();
}

final class PosFilterOtc extends PosCatalogFilter {
  const PosFilterOtc();
}

final class PosFilterCategory extends PosCatalogFilter {
  const PosFilterCategory(this.name);

  final String name;

  @override
  bool operator ==(Object other) =>
      other is PosFilterCategory && other.name == name;

  @override
  int get hashCode => name.hashCode;
}

/// Applies [filter] to an already-loaded / searched product list.
List<PosProduct> filterPosProducts(
  List<PosProduct> products,
  PosCatalogFilter filter,
) {
  return switch (filter) {
    PosFilterAll() => List<PosProduct>.of(products),
    PosFilterRx() => products
        .where((PosProduct p) => p.requiresPrescription)
        .toList(growable: false),
    PosFilterOtc() => products
        .where((PosProduct p) => !p.requiresPrescription)
        .toList(growable: false),
    PosFilterCategory(:final name) => products
        .where(
          (PosProduct p) =>
              (p.categoryName ?? '').trim().toLowerCase() ==
              name.trim().toLowerCase(),
        )
        .toList(growable: false),
  };
}

/// Distinct non-empty category names from [products], sorted, capped at [limit].
List<String> posCategoryChipNames(
  List<PosProduct> products, {
  int limit = 4,
}) {
  final names = <String>{};
  for (final product in products) {
    final name = product.categoryName?.trim() ?? '';
    if (name.isNotEmpty) names.add(name);
  }
  final sorted = names.toList()..sort();
  if (sorted.length <= limit) return sorted;
  return sorted.sublist(0, limit);
}
