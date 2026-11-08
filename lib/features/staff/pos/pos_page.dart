import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/brand.dart';
import '../../../core/format.dart';
import '../../../core/i18n.dart';
import '../../../core/routes.dart';
import '../../../core/theme.dart';
import '../shell/staff_app_bar.dart';
import 'pos_cart_controller.dart';
import 'pos_catalog_controller.dart';
import 'pos_catalog_filter.dart';
import 'pos_product.dart';
import 'pos_product_tile.dart';
import 'pos_qty_sheet.dart';
import 'pos_recent_sales.dart';

class PosPage extends ConsumerStatefulWidget {
  const PosPage({super.key});

  @override
  ConsumerState<PosPage> createState() => _PosPageState();
}

class _PosPageState extends ConsumerState<PosPage> {
  final _search = TextEditingController();
  PosCatalogFilter _filter = PosCatalogFilter.all;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _openQty(PosProduct product) async {
    final before = ref
        .read(posCartProvider.notifier)
        .quantityOf(product.storeProductId);
    await showPosQtySheet(context, product);
    if (!mounted) return;
    final after = ref
        .read(posCartProvider.notifier)
        .quantityOf(product.storeProductId);
    if (after != before && _search.text.isNotEmpty) {
      _search.clear();
      ref.read(posCatalogProvider.notifier).setQuery('');
      setState(() {});
    }
  }

  String _filterLabel(PosCatalogFilter filter) {
    return switch (filter) {
      PosFilterAll() => t('STORE_FORM.POS_FILTER_ALL'),
      PosFilterRx() => t('STORE_FORM.POS_FILTER_RX'),
      PosFilterOtc() => t('STORE_FORM.POS_FILTER_OTC'),
      PosFilterCategory(:final name) => name,
    };
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(localeProvider);
    final catalog = ref.watch(posCatalogProvider);
    final cartItems = ref.watch(posCartProvider);
    final cart = ref.read(posCartProvider.notifier);
    final theme = Theme.of(context);
    final hasCart = cartItems.isNotEmpty;
    final visible = filterPosProducts(catalog.products, _filter);
    final categoryNames = posCategoryChipNames(catalog.products);
    final filterOptions = <PosCatalogFilter>[
      PosCatalogFilter.all,
      PosCatalogFilter.rx,
      PosCatalogFilter.otc,
      for (final name in categoryNames) PosCatalogFilter.category(name),
    ];

    return Scaffold(
      appBar: StaffAppBar(
        title: t('STORE_FORM.POS_TITLE'),
        actions: const <Widget>[PosRecentSalesButton()],
      ),
      body: Stack(
        children: <Widget>[
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: TextField(
                        controller: _search,
                        textInputAction: TextInputAction.search,
                        onChanged: (String value) {
                          ref.read(posCatalogProvider.notifier).setQuery(value);
                          setState(() {});
                        },
                        decoration: InputDecoration(
                          isDense: true,
                          hintText: t('STORE_FORM.POS_SEARCH_PLACEHOLDER'),
                          prefixIcon: const Icon(Icons.search, size: 20),
                          suffixIcon: catalog.loading
                              ? const Padding(
                                  padding: EdgeInsets.all(12),
                                  child: SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                )
                              : (_search.text.isEmpty
                                    ? null
                                    : IconButton(
                                        onPressed: () {
                                          _search.clear();
                                          ref
                                              .read(posCatalogProvider.notifier)
                                              .setQuery('');
                                          setState(() {});
                                        },
                                        icon: const Icon(Icons.close, size: 18),
                                      )),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 118,
                      child: DropdownButtonFormField<PosCatalogFilter>(
                        value: filterOptions.contains(_filter)
                            ? _filter
                            : PosCatalogFilter.all,
                        isDense: true,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 10,
                          ),
                        ),
                        items: [
                          for (final option in filterOptions)
                            DropdownMenuItem<PosCatalogFilter>(
                              value: option,
                              child: Text(
                                _filterLabel(option),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                        ],
                        onChanged: (PosCatalogFilter? next) {
                          if (next == null) return;
                          setState(() => _filter = next);
                        },
                      ),
                    ),
                  ],
                ),
              ),
              if (catalog.error != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    catalog.error!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.error,
                    ),
                  ),
                ),
              Expanded(
                child: _buildGrid(
                  catalog: catalog,
                  products: visible,
                  cart: cart,
                  bottomPad: hasCart ? 96 : 12,
                ),
              ),
            ],
          ),
          if (hasCart)
            Positioned(
              left: 12,
              right: 12,
              bottom: 0,
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _PosFloatingCartBar(
                    itemCount: cartItems.length,
                    total: cart.subtotal,
                    onOpenCart: () => context.push(Routes.staffPosCheckout),
                    onCheckout: () => context.push(Routes.staffPosCheckout),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildGrid({
    required PosCatalogState catalog,
    required List<PosProduct> products,
    required PosCartController cart,
    required double bottomPad,
  }) {
    if (catalog.loading && catalog.products.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (products.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            t('STORE_FORM.POS_NO_PRODUCTS'),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final crossAxisCount = _posGridColumns(constraints.maxWidth);
        return GridView.builder(
          padding: EdgeInsets.fromLTRB(8, 0, 8, bottomPad),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: crossAxisCount >= 4 ? 0.78 : 0.72,
          ),
          itemCount: products.length,
          itemBuilder: (BuildContext context, int index) {
            final product = products[index];
            return PosProductTile(
              product: product,
              quantityInCart: cart.quantityOf(product.storeProductId),
              onAdd: () => _openQty(product),
            );
          },
        );
      },
    );
  }
}

int _posGridColumns(double width) {
  if (width >= 900) return 5;
  if (width >= 600) return 4;
  return 3;
}

class _PosFloatingCartBar extends StatelessWidget {
  const _PosFloatingCartBar({
    required this.itemCount,
    required this.total,
    required this.onOpenCart,
    required this.onCheckout,
  });

  final int itemCount;
  final double total;
  final VoidCallback onOpenCart;
  final VoidCallback onCheckout;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      elevation: 6,
      shadowColor: Colors.black26,
      borderRadius: BorderRadius.circular(16),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
        child: Row(
          children: <Widget>[
            Expanded(
              child: InkWell(
                onTap: onOpenCart,
                borderRadius: AppTheme.borderRadius,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 4,
                  ),
                  child: Row(
                    children: <Widget>[
                      Icon(
                        Icons.shopping_cart_outlined,
                        color: Brand.themeColor,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Text(
                              '$itemCount ${t('STORE_FORM.POS_ITEMS')}',
                              style: theme.textTheme.labelLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              Format.rupee(total),
                              style: theme.textTheme.titleSmall?.copyWith(
                                color: Brand.themeColor,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: onCheckout,
              style: AppTheme.charge.copyWith(
                minimumSize: const WidgetStatePropertyAll(
                  Size(0, AppTheme.chargeHeight),
                ),
                padding: const WidgetStatePropertyAll(
                  EdgeInsets.symmetric(horizontal: 18),
                ),
                shape: WidgetStatePropertyAll(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
              child: Text(
                '${t('STORE_FORM.POS_CHECKOUT')} →',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
