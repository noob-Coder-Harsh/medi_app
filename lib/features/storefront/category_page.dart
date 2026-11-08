import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/i18n.dart';
import '../../core/medi_app_bar.dart';
import '../../core/routes.dart';
import '../../data/models/listing.dart';
import 'catalog_controller.dart';
import 'product_card.dart';

/// First page of one aisle. Guest. New `search_store_catalog` query, not a dump.
class CategoryPage extends ConsumerWidget {
  const CategoryPage({
    super.key,
    required this.slug,
    required this.cat,
  });

  final String slug;
  final String cat;

  Future<void> _openProduct(BuildContext context, ListingCard card) async {
    final product = card.slug.isNotEmpty ? card.slug : card.id;
    context.push(Routes.product(slug, product));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(localeProvider);
    final asyncListing = ref.watch(
      categoryListingProvider(CategoryQuery(slug: slug, cat: cat)),
    );

    return Scaffold(
      appBar: MediAppBar(
        titleText: asyncListing.asData?.value.category?.name ?? cat,
      ),
      body: asyncListing.when(
        loading: () => Center(child: Text(t('STOREFRONT.LOADING_CATALOG'))),
        error: (Object _, StackTrace __) => Center(
          child: Text(t('STOREFRONT.SEARCH_FAILED')),
        ),
        data: (CategoryListing listing) {
          if (listing.store == null) {
            return Center(child: Text(t('STOREFRONT.STORE_NOT_FOUND')));
          }
          if (listing.cards.isEmpty) {
            return Center(
              child: Text(
                t('STOREFRONT.EMPTY_CATEGORY'),
                key: const Key('category-empty'),
                textAlign: TextAlign.center,
              ),
            );
          }
          return GridView.builder(
            key: const Key('category-grid'),
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisExtent: 236,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
            ),
            itemCount: listing.cards.length,
            itemBuilder: (BuildContext context, int index) {
              final card = listing.cards[index];
              return ProductCard(
                card: card,
                storeId: listing.store?.id ?? '',
                compact: true,
                onTap: () => _openProduct(context, card),
              );
            },
          );
        },
      ),
    );
  }
}
