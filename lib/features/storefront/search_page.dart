import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/i18n.dart';
import '../../core/routes.dart';
import '../../core/medi_app_bar.dart';
import '../../core/theme.dart';
import '../../data/models/listing.dart';
import '../location/store_resolver.dart';
import 'catalog_controller.dart';
import 'product_card.dart';

/// Shop search. New RPC per query. Never filters a local catalog array.
class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  final TextEditingController _controller = TextEditingController();
  Timer? _debounce;
  String _debounced = '';
  String? _categoryId;
  bool _hydrating = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_hydrateShop());
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _hydrateShop() async {
    if (ref.read(activeShopProvider) != null) {
      if (mounted) setState(() => _hydrating = false);
      return;
    }
    final session = ref.read(shopSessionStoreProvider);
    final id = await session.readLastStoreId();
    final slug = await session.readLastSlug();
    if (!mounted) return;
    if (ref.read(activeShopProvider) == null &&
        id != null &&
        id.isNotEmpty &&
        slug != null &&
        slug.isNotEmpty) {
      ref.read(activeShopProvider.notifier).set(
        ActiveShop(storeId: id, slug: slug),
      );
    }
    if (mounted) setState(() => _hydrating = false);
  }

  void _onQueryChanged(String value) {
    setState(() {});
    _debounce?.cancel();
    _debounce = Timer(kSearchDebounce, () {
      if (!mounted) return;
      setState(() => _debounced = value.trim());
    });
  }

  void _clearQuery() {
    _debounce?.cancel();
    _controller.clear();
    setState(() => _debounced = '');
  }

  bool _canSearch(ActiveShop? shop) {
    if (shop == null) return false;
    if (_categoryId != null && _categoryId!.isNotEmpty) return true;
    return _debounced.length >= kSearchMinChars;
  }

  String get _rpcQuery {
    return _debounced.length >= kSearchMinChars ? _debounced : '';
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(localeProvider);
    final shop = ref.watch(activeShopProvider);
    final shell = shop == null
        ? null
        : ref.watch(storeShellProvider(shop.slug)).asData?.value;
    final categories = shell?.categories ?? const <Category>[];

    return Scaffold(
      appBar: MediAppBar(titleText: t('NAV.SEARCH')),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              key: const Key('shop-search-field'),
              controller: _controller,
              autofocus: true,
              textInputAction: TextInputAction.search,
              style: Theme.of(context).textTheme.bodyLarge,
              decoration: InputDecoration(
                hintText: t('STOREFRONT.SEARCH_PLACEHOLDER'),
                helperText: t('STOREFRONT.SEARCH_HINT'),
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _controller.text.isEmpty
                    ? null
                    : IconButton(
                        tooltip: t('STOREFRONT.CLEAR_SEARCH'),
                        onPressed: _clearQuery,
                        icon: const Icon(Icons.close),
                      ),
              ),
              onChanged: _onQueryChanged,
            ),
          ),
          if (categories.isNotEmpty)
            SizedBox(
              height: AppTheme.touchTarget + 8,
              child: ListView.separated(
                key: const Key('search-category-chips'),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: categories.length,
                separatorBuilder: (BuildContext context, int _) {
                  return const SizedBox(width: 8);
                },
                itemBuilder: (BuildContext context, int index) {
                  final category = categories[index];
                  final selected = _categoryId == category.id;
                  return FilterChip(
                    label: Text(category.name),
                    selected: selected,
                    onSelected: (bool on) {
                      setState(() {
                        _categoryId = on ? category.id : null;
                      });
                    },
                  );
                },
              ),
            ),
          Expanded(child: _body(shop)),
        ],
      ),
    );
  }

  Widget _body(ActiveShop? shop) {
    if (_hydrating) {
      return Center(child: Text(t('STOREFRONT.LOADING_CATALOG')));
    }
    if (shop == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            t('STOREFRONT.MARKETPLACE_SEARCH_NEED_LOCATION'),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    if (!_canSearch(shop)) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            t('STOREFRONT.SEARCH_START'),
            key: const Key('search-start'),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final asyncHits = ref.watch(
      shopSearchProvider(
        ShopSearchQuery(
          storeId: shop.storeId,
          query: _rpcQuery,
          categoryId: _categoryId,
        ),
      ),
    );

    return asyncHits.when(
      loading: () => Center(child: Text(t('STOREFRONT.LOADING_CATALOG'))),
      error: (Object _, StackTrace __) {
        return Center(child: Text(t('STOREFRONT.SEARCH_FAILED')));
      },
      data: (List<ListingCard> hits) {
        if (hits.isEmpty) {
          return Center(
            child: Text(
              t('STOREFRONT.SEARCH_EMPTY'),
              key: const Key('search-empty'),
              textAlign: TextAlign.center,
            ),
          );
        }
        return ListView.separated(
          key: const Key('search-results'),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          itemCount: hits.length,
          separatorBuilder: (BuildContext context, int _) {
            return const SizedBox(height: 8);
          },
          itemBuilder: (BuildContext context, int index) {
            final card = hits[index];
            return ProductCard(
              card: card,
              storeId: shop.storeId,
              onTap: () {
                final product = card.slug.isNotEmpty ? card.slug : card.id;
                context.push(Routes.product(shop.slug, product));
              },
            );
          },
        );
      },
    );
  }
}
