import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/format.dart';
import '../../core/i18n.dart';
import '../../core/routes.dart';
import '../../core/theme.dart';
import '../../data/models/listing.dart';
import '../cart/qty_stepper.dart';
import 'catalog_controller.dart';
import 'product_card.dart';

/// One medicine. Guest. Fresh `get_store_product` + related aisle, no warehouse.
class ProductPage extends ConsumerWidget {
  const ProductPage({
    super.key,
    required this.shopSlug,
    required this.productSlug,
  });

  final String shopSlug;
  final String productSlug;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(localeProvider);
    final query = ProductQuery(shopSlug: shopSlug, productSlug: productSlug);
    final asyncPage = ref.watch(productPageProvider(query));

    return Scaffold(
      appBar: AppBar(
        title: Text(
          asyncPage.asData?.value.product?.name ?? productSlug,
        ),
      ),
      body: asyncPage.when(
        loading: () => Center(child: Text(t('STOREFRONT.LOADING_CATALOG'))),
        error: (Object _, StackTrace __) => Center(
          child: Text(t('STOREFRONT.SEARCH_FAILED')),
        ),
        data: (ProductPageData data) {
          final product = data.product;
          if (product == null) {
            return Center(child: Text(t('STOREFRONT.EMPTY_CATALOG')));
          }
          return SingleChildScrollView(
            key: const Key('product-page'),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _Hero(card: product),
                const SizedBox(height: 16),
                _Details(card: product),
                const SizedBox(height: 16),
                CartAddControl(
                  card: product,
                  storeId: data.store?.id ?? product.storeId,
                  expanded: true,
                ),
                if (data.related.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 24),
                  Text(
                    t('STOREFRONT.RELATED'),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 236,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: data.related.length,
                      separatorBuilder: (BuildContext context, int _) {
                        return const SizedBox(width: 8);
                      },
                      itemBuilder: (BuildContext context, int index) {
                        final card = data.related[index];
                        return SizedBox(
                          width: 196,
                          height: 220,
                          child: ProductCard(
                            card: card,
                            storeId: data.store?.id ?? product.storeId,
                            compact: true,
                            onTap: () {
                              final next = card.slug.isNotEmpty
                                  ? card.slug
                                  : card.id;
                              context.push(Routes.product(shopSlug, next));
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.card});

  final ListingCard card;

  @override
  Widget build(BuildContext context) {
    final url = card.thumb ?? card.imageUrl;
    return AspectRatio(
      aspectRatio: 1.2,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: AppTheme.borderRadius,
          border: Border.all(
            color: AppTheme.hairlineColor,
            width: AppTheme.hairline,
          ),
        ),
        child: ClipRRect(
          borderRadius: AppTheme.borderRadius,
          child: url == null || url.isEmpty
              ? const Icon(Icons.medication_outlined, size: 72)
              : CachedNetworkImage(
                  imageUrl: url,
                  fit: BoxFit.contain,
                  errorWidget: (BuildContext context, String _, Object __) {
                    return const Icon(Icons.medication_outlined, size: 72);
                  },
                ),
        ),
      ),
    );
  }
}

class _Details extends StatelessWidget {
  const _Details({required this.card});

  final ListingCard card;

  bool get _out => !card.inStock || card.availableQuantity <= 0;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final price = card.sellingPrice ?? 0;
    final mrp = card.mrp;
    final strike = mrp != null && mrp > price;
    final bits = <String>[
      if (card.strength != null && card.strength!.isNotEmpty) card.strength!,
      if (card.dosageForm != null && card.dosageForm!.isNotEmpty)
        card.dosageForm!,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(card.name, style: text.titleLarge),
        if (bits.isNotEmpty)
          Text(bits.join(' · '), style: text.bodyMedium),
        if (card.genericName != null && card.genericName!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              '${t('STOREFRONT.PRODUCT_GENERIC')}: ${card.genericName}',
              style: text.bodyMedium,
            ),
          ),
        Text(
          '${t('STOREFRONT.PRODUCT_PACK')}: ${card.packLabel}',
          style: text.bodyMedium,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: <Widget>[
            Text(Format.rupee(price), style: AppTheme.rupee(text.titleLarge!)),
            if (strike)
              Text(
                Format.rupee(mrp),
                style: AppTheme.rupee(text.bodyMedium!).copyWith(
                  decoration: TextDecoration.lineThrough,
                ),
              ),
          ],
        ),
        if (card.requiresPrescription)
          Text(t('STOREFRONT.REQUIRES_RX'), style: text.titleSmall),
        if (_out) Text(Format.stock(0), style: text.titleSmall),
        if (card.salePolicy == 'pack_only')
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(t('STOREFRONT.PACK_ONLY_HINT'), style: text.bodySmall),
          ),
        if (card.salePolicy == 'whole_only')
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(t('STOREFRONT.WHOLE_ONLY_HINT'), style: text.bodySmall),
          ),
        if (card.manufacturer != null && card.manufacturer!.isNotEmpty) ...<
          Widget
        >[
          const SizedBox(height: 16),
          Text(t('STOREFRONT.PRODUCT_DETAILS'), style: text.titleMedium),
          Text(
            '${t('STOREFRONT.PRODUCT_MANUFACTURER')}: ${card.manufacturer}',
            style: text.bodyMedium,
          ),
        ],
        if (card.description != null && card.description!.isNotEmpty) ...<
          Widget
        >[
          const SizedBox(height: 16),
          Text(t('STOREFRONT.PRODUCT_DESCRIPTION'), style: text.titleMedium),
          Text(card.description!, style: text.bodyMedium),
        ],
      ],
    );
  }
}
