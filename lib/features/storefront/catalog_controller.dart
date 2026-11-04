import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/listing.dart';
import '../../data/rpc/listing_rpc.dart';
import '../../data/supabase_client.dart';

const int kCategoryPageSize = 24;
const int kRelatedLimit = 8;
const int kSearchLimit = 20;
const int kSearchMinChars = 2;
const Duration kSearchDebounce = Duration(milliseconds: 250);

/// Query key for category / search: `['search', storeId, q, categoryId]`.
List<Object?> searchQueryKey({
  required String storeId,
  String query = '',
  String? categoryId,
}) {
  return <Object?>['search', storeId, query, categoryId];
}

/// Query key for PDP: `['product', storeId, slug]`.
List<Object> productQueryKey(String storeId, String slug) {
  return <Object>['product', storeId, slug];
}

class CategoryQuery {
  const CategoryQuery({required this.slug, required this.cat});

  final String slug;
  final String cat;

  @override
  bool operator ==(Object other) {
    return other is CategoryQuery && other.slug == slug && other.cat == cat;
  }

  @override
  int get hashCode => Object.hash(slug, cat);
}

class ShopSearchQuery {
  const ShopSearchQuery({
    required this.storeId,
    required this.query,
    this.categoryId,
  });

  final String storeId;
  final String query;
  final String? categoryId;

  @override
  bool operator ==(Object other) {
    return other is ShopSearchQuery &&
        other.storeId == storeId &&
        other.query == query &&
        other.categoryId == categoryId;
  }

  @override
  int get hashCode => Object.hash(storeId, query, categoryId);
}

class ProductQuery {
  const ProductQuery({required this.shopSlug, required this.productSlug});

  final String shopSlug;
  final String productSlug;

  @override
  bool operator ==(Object other) {
    return other is ProductQuery &&
        other.shopSlug == shopSlug &&
        other.productSlug == productSlug;
  }

  @override
  int get hashCode => Object.hash(shopSlug, productSlug);
}

class CategoryListing {
  const CategoryListing({
    required this.store,
    required this.category,
    required this.cards,
  });

  final PublicStore? store;
  final Category? category;
  final List<ListingCard> cards;
}

class ProductPageData {
  const ProductPageData({
    required this.store,
    required this.product,
    required this.related,
  });

  final PublicStore? store;
  final ListingCard? product;
  final List<ListingCard> related;
}

class ListingCatalogSource implements CatalogSource {
  const ListingCatalogSource();

  @override
  Future<StoreShellPayload> getStoreShell({
    String? slug,
    String? storeId,
  }) async {
    if (!AppSupabase.isReady) {
      return StoreShellPayload.empty;
    }
    return ListingRpc(
      AppSupabase.client,
    ).getStoreShell(slug: slug, storeId: storeId);
  }

  @override
  Future<List<ListingCard>> searchStoreCatalog({
    required String storeId,
    String query = '',
    String? categoryId,
    int limit = 20,
  }) async {
    if (!AppSupabase.isReady) return const <ListingCard>[];
    return ListingRpc(AppSupabase.client).searchStoreCatalog(
      storeId: storeId,
      query: query,
      categoryId: categoryId,
      limit: limit,
    );
  }

  @override
  Future<ListingCard?> getStoreProduct({
    required String storeId,
    required String slug,
  }) async {
    if (!AppSupabase.isReady) return null;
    return ListingRpc(
      AppSupabase.client,
    ).getStoreProduct(storeId: storeId, slug: slug);
  }

  @override
  Future<List<ListingCard>> getListingCards({
    required String storeId,
    required List<String> ids,
  }) async {
    if (!AppSupabase.isReady || ids.isEmpty) return const <ListingCard>[];
    return ListingRpc(
      AppSupabase.client,
    ).getListingCards(storeId: storeId, ids: ids);
  }
}

final catalogSourceProvider = Provider<CatalogSource>(
  (Ref ref) => const ListingCatalogSource(),
);

final storeShellProvider = FutureProvider.family<StoreShellPayload, String>((
  ref,
  slug,
) {
  return ref.watch(catalogSourceProvider).getStoreShell(slug: slug);
});

final shopSearchProvider =
    FutureProvider.autoDispose.family<List<ListingCard>, ShopSearchQuery>((
      ref,
      query,
    ) {
      return ref
          .watch(catalogSourceProvider)
          .searchStoreCatalog(
            storeId: query.storeId,
            query: query.query,
            categoryId: query.categoryId,
            limit: kSearchLimit,
          );
    });

final categoryListingProvider =
    FutureProvider.autoDispose.family<CategoryListing, CategoryQuery>((
      ref,
      query,
    ) async {
      final shell = await ref.watch(storeShellProvider(query.slug).future);
      final store = shell.store;
      if (store == null) {
        return const CategoryListing(
          store: null,
          category: null,
          cards: <ListingCard>[],
        );
      }

      Category? category;
      for (final item in shell.categories) {
        if (item.slug == query.cat || item.id == query.cat) {
          category = item;
          break;
        }
      }
      final categoryId = category?.id ?? query.cat;
      final cards = await ref
          .watch(catalogSourceProvider)
          .searchStoreCatalog(
            storeId: store.id,
            query: '',
            categoryId: categoryId,
            limit: kCategoryPageSize,
          );
      return CategoryListing(store: store, category: category, cards: cards);
    });

final productPageProvider =
    FutureProvider.autoDispose.family<ProductPageData, ProductQuery>((
      ref,
      query,
    ) async {
      final shell = await ref.watch(storeShellProvider(query.shopSlug).future);
      final store = shell.store;
      if (store == null) {
        return const ProductPageData(
          store: null,
          product: null,
          related: <ListingCard>[],
        );
      }

      final source = ref.watch(catalogSourceProvider);
      final product = await source.getStoreProduct(
        storeId: store.id,
        slug: query.productSlug,
      );
      var related = const <ListingCard>[];
      final categoryId = product?.categoryId;
      if (categoryId != null && categoryId.isNotEmpty) {
        final hits = await source.searchStoreCatalog(
          storeId: store.id,
          query: '',
          categoryId: categoryId,
          limit: kRelatedLimit,
        );
        related = hits
            .where(
              (ListingCard card) =>
                  card.id != product!.id && card.slug != product.slug,
            )
            .toList();
      }
      return ProductPageData(store: store, product: product, related: related);
    });
