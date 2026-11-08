import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/brand.dart';
import '../../core/i18n.dart';
import '../../core/link_opener.dart';
import '../../core/routes.dart';
import '../../core/theme.dart';
import '../../core/whatsapp.dart';
import '../../data/models/listing.dart';
import '../cart/cart_actions.dart';
import '../cart/cart_controller.dart';
import '../location/store_resolver.dart';
import 'product_card.dart';
import 'store_copy.dart';
import 'store_home_controller.dart';

/// Merchandising slices for one shop. Guest. No catalog dump, no cart prefs.
class ShopHomePage extends ConsumerStatefulWidget {
  const ShopHomePage({super.key, required this.slug});

  final String slug;

  @override
  ConsumerState<ShopHomePage> createState() => _ShopHomePageState();
}

class _ShopHomePageState extends ConsumerState<ShopHomePage>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_hydrateNearby());
    });
  }

  @override
  void didUpdateWidget(covariant ShopHomePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.slug != widget.slug) {
      unawaited(_hydrateNearby());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    final source = ref.read(storeHomeSourceProvider);
    if (source is CachedStoreHomeSource && source.isStale(widget.slug)) {
      source.invalidate(widget.slug);
      ref.invalidate(storeHomeProvider(widget.slug));
    }
  }

  Future<void> _hydrateNearby() async {
    if (ref.read(nearbyShopsProvider).isNotEmpty) return;
    final saved = await ref.read(shopSessionStoreProvider).readNearby();
    if (!mounted || saved.isEmpty) return;
    if (ref.read(nearbyShopsProvider).isNotEmpty) return;
    ref.read(nearbyShopsProvider.notifier).replace(saved);
  }

  PublicStore? _shellStore(StoreHomePayload? home, List<NearbyStore> nearby) {
    if (home?.store != null) return home!.store;
    for (final item in nearby) {
      if (item.store.slug == widget.slug) return item.store;
    }
    return null;
  }

  Future<void> _openSearch() async {
    context.go(Routes.search);
  }

  Future<void> _openCategory(Category category) async {
    final cat = category.slug.isNotEmpty ? category.slug : category.id;
    context.push(Routes.category(widget.slug, cat));
  }

  Future<void> _seeAll(List<Category> categories) async {
    if (categories.isNotEmpty) {
      await _openCategory(categories.first);
      return;
    }
    await _openSearch();
  }

  Future<void> _openProduct(ListingCard card) async {
    final product = card.slug.isNotEmpty ? card.slug : card.id;
    context.push(Routes.product(widget.slug, product));
  }

  Future<void> _rememberShop(PublicStore store) async {
    ref.read(activeShopProvider.notifier).set(
      ActiveShop(
        storeId: store.id,
        slug: store.slug,
        name: store.name,
      ),
    );
    final nearby = ref.read(nearbyShopsProvider);
    await ref.read(shopSessionStoreProvider).save(
      storeId: store.id,
      slug: store.slug,
      nearby: nearby,
    );
  }

  Future<void> _switchShop(NearbyStore shop) async {
    final cart = ref.read(cartProvider);
    if (cart.items.isNotEmpty &&
        cart.storeId != null &&
        cart.storeId != shop.store.id) {
      final replace = await CartActions.confirmReplace(context);
      if (!replace || !mounted) return;
      await ref.read(cartProvider.notifier).clear();
    }
    await _rememberShop(shop.store);
    if (!mounted) return;
    context.go(Routes.shop(shop.store.slug));
  }

  Future<void> _whatsApp(PublicStore? store) async {
    final uri = whatsAppUri(number: store?.whatsappNumber);
    if (uri == null) {
      _snack(t('STOREFRONT.PRESCRIPTION_NO_WHATSAPP'));
      return;
    }
    final ok = await ref.read(linkOpenerProvider).open(uri);
    if (!ok && mounted) {
      _snack(t('STOREFRONT.PRESCRIPTION_NO_WHATSAPP'));
    }
  }

  Future<void> _openInfo() async {
    context.push(Routes.shopInfo(widget.slug));
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(localeProvider);
    final nearby = ref.watch(nearbyShopsProvider);
    final asyncHome = ref.watch(storeHomeProvider(widget.slug));
    final home = asyncHome.asData?.value;
    final store = _shellStore(home, nearby);
    if (store != null) {
      final active = ref.read(activeShopProvider);
      if (active?.storeId != store.id) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          unawaited(_rememberShop(store));
        });
      }
    }
    final title = (store != null && store.name.isNotEmpty)
        ? store.name
        : widget.slug;
    final categories = home?.categories ?? const <Category>[];
    final featured = home?.featured ?? const <ListingCard>[];
    final products = home?.products ?? const <ListingCard>[];
    final tiles = categories.take(12).toList();

    return Scaffold(
      key: Key('shop-home-${widget.slug}'),
      backgroundColor: Brand.themeBackground,
      body: SafeArea(
        child: Column(
          children: <Widget>[
            _ShopHeader(
              title: title,
              slug: widget.slug,
              store: store,
              nearby: nearby,
              onSwitch: _switchShop,
              onInfo: _openInfo,
            ),
            if (store != null && !store.isOpen)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Text(
                  t('STOREFRONT.CLOSED_BANNER'),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            _StickySearch(
              hint: t('STOREFRONT.SEARCH_PLACEHOLDER'),
              onTap: _openSearch,
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.zero,
                child: Column(
                  children: <Widget>[
                  _JobsRow(onWhatsApp: () => _whatsApp(store)),
                  if (tiles.isNotEmpty)
                    _CategoryStrip(
                      categories: tiles,
                      onTap: _openCategory,
                    ),
                  if (asyncHome.isLoading && home == null)
                    const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    ),
                  if (asyncHome.hasError && home == null)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        t('STOREFRONT.SEARCH_FAILED'),
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  if (featured.isNotEmpty)
                    _FeaturedRail(
                      cards: featured,
                      storeId: store?.id ?? '',
                      onOpen: _openProduct,
                    ),
                  if (products.isNotEmpty)
                    _SectionHeading(
                      title: t('STOREFRONT.ALL_PRODUCTS'),
                      action: t('STOREFRONT.VIEW_ALL'),
                      onAction: () => _seeAll(categories),
                    ),
                  if (products.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Column(
                        children: <Widget>[
                          for (final card in products) ...<Widget>[
                            ProductCard(
                              card: card,
                              storeId: store?.id ?? '',
                              onTap: () => _openProduct(card),
                            ),
                            const SizedBox(height: 8),
                          ],
                        ],
                      ),
                    ),
                  _TrustRow(store: store),
                  const SizedBox(height: 24),
                ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShopHeader extends StatelessWidget {
  const _ShopHeader({
    required this.title,
    required this.slug,
    required this.store,
    required this.nearby,
    required this.onSwitch,
    required this.onInfo,
  });

  final String title;
  final String slug;
  final PublicStore? store;
  final List<NearbyStore> nearby;
  final ValueChanged<NearbyStore> onSwitch;
  final VoidCallback onInfo;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final open = store?.isOpen ?? true;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _Logo(url: store?.logoUrl),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: InkWell(
                        onTap: onInfo,
                        child: Text(
                          title,
                          key: const Key('shop-header'),
                          style: text.titleLarge,
                        ),
                      ),
                    ),
                    if (nearby.length > 1)
                      _ShopSwitcher(
                        nearby: nearby,
                        currentSlug: store?.slug ?? slug,
                        onSwitch: onSwitch,
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: <Widget>[
                    _Pill(
                      label: open ? t('STOREFRONT.OPEN') : t('STOREFRONT.CLOSED'),
                    ),
                    if (store?.modulePickup == true)
                      _Pill(label: t('STOREFRONT.FULFILLMENT_PICKUP_SHORT')),
                    if (store?.moduleDelivery == true)
                      _Pill(label: t('STOREFRONT.FULFILLMENT_DELIVERY_SHORT')),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  const _Logo({this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: AppTheme.touchTarget,
      height: AppTheme.touchTarget,
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
          child: url == null || url!.isEmpty
              ? const Icon(Icons.local_pharmacy_outlined)
              : CachedNetworkImage(
                  imageUrl: url!,
                  fit: BoxFit.cover,
                  errorWidget: (BuildContext context, String _, Object __) {
                    return const Icon(Icons.local_pharmacy_outlined);
                  },
                ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: AppTheme.borderRadius,
        border: Border.all(
          color: AppTheme.hairlineColor,
          width: AppTheme.hairline,
        ),
      ),
      child: Text(label, style: Theme.of(context).textTheme.labelSmall),
    );
  }
}

class _ShopSwitcher extends StatelessWidget {
  const _ShopSwitcher({
    required this.nearby,
    required this.currentSlug,
    required this.onSwitch,
  });

  final List<NearbyStore> nearby;
  final String currentSlug;
  final ValueChanged<NearbyStore> onSwitch;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      key: const Key('shop-switcher'),
      tooltip: t('STOREFRONT.STORE_INFO'),
      onPressed: () async {
        final chosen = await showModalBottomSheet<NearbyStore>(
          context: context,
          builder: (BuildContext sheet) {
            return SafeArea(
              child: ListView(
                shrinkWrap: true,
                children: nearby.map((NearbyStore shop) {
                  final km = shop.distanceKm.toStringAsFixed(
                    shop.distanceKm >= 10 ? 0 : 1,
                  );
                  return ListTile(
                    enabled: shop.store.slug != currentSlug,
                    title: Text(
                      '${shop.store.name} · $km ${t('STOREFRONT.DISTANCE_KM')}',
                    ),
                    onTap: shop.store.slug == currentSlug
                        ? null
                        : () => Navigator.pop(sheet, shop),
                  );
                }).toList(),
              ),
            );
          },
        );
        if (chosen != null) onSwitch(chosen);
      },
      icon: const Icon(Icons.expand_more),
    );
  }
}

class _StickySearch extends StatelessWidget {
  const _StickySearch({required this.hint, required this.onTap});

  final String hint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Brand.themeBackground,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: InkWell(
          key: const Key('home-search'),
          onTap: onTap,
          borderRadius: AppTheme.borderRadius,
          child: Ink(
            height: AppTheme.touchTarget,
            decoration: BoxDecoration(
              color: Brand.themeBackground,
              borderRadius: AppTheme.borderRadius,
              border: Border.all(
                color: AppTheme.hairlineColor,
                width: AppTheme.hairline,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: <Widget>[
                  const Icon(Icons.search),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      hint,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _JobsRow extends StatelessWidget {
  const _JobsRow({required this.onWhatsApp});

  final VoidCallback onWhatsApp;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        key: const Key('home-jobs'),
        children: <Widget>[
          Expanded(
            child: OutlinedButton(
              onPressed: () => context.push(Routes.prescription),
              child: Text(
                t('STOREFRONT.JOB_RX'),
                textAlign: TextAlign.center,
                maxLines: 2,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: OutlinedButton(
              onPressed: onWhatsApp,
              child: Text(
                t('STOREFRONT.JOB_WHATSAPP'),
                textAlign: TextAlign.center,
                maxLines: 2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryStrip extends StatelessWidget {
  const _CategoryStrip({
    required this.categories,
    required this.onTap,
  });

  final List<Category> categories;
  final ValueChanged<Category> onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        key: const Key('home-categories'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            t('STOREFRONT.CATEGORIES'),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: categories.map((Category category) {
              return SizedBox(
                height: AppTheme.touchTarget,
                child: OutlinedButton(
                  onPressed: () => onTap(category),
                  child: Text(category.name),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({
    required this.title,
    this.action,
    this.onAction,
  });

  final String title;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(title, style: Theme.of(context).textTheme.titleMedium),
          ),
          if (action != null)
            TextButton(onPressed: onAction, child: Text(action!)),
        ],
      ),
    );
  }
}

class _FeaturedRail extends StatelessWidget {
  const _FeaturedRail({
    required this.cards,
    required this.storeId,
    required this.onOpen,
  });

  final List<ListingCard> cards;
  final String storeId;
  final ValueChanged<ListingCard> onOpen;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const Key('home-featured'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _SectionHeading(title: t('STOREFRONT.FEATURED')),
        SizedBox(
          height: 236,
          child: ListView.separated(
            clipBehavior: Clip.hardEdge,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: cards.length,
            separatorBuilder: (BuildContext context, int _) {
              return const SizedBox(width: 8);
            },
            itemBuilder: (BuildContext context, int index) {
              final card = cards[index];
              return SizedBox(
                width: 196,
                height: 220,
                child: ProductCard(
                  card: card,
                  storeId: storeId,
                  compact: true,
                  onTap: () => onOpen(card),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _TrustRow extends StatelessWidget {
  const _TrustRow({required this.store});

  final PublicStore? store;

  @override
  Widget build(BuildContext context) {
    final parts = <String>[];
    final hours = storeHoursLabel(store);
    if (hours != null) {
      parts.add('${t('STOREFRONT.HOURS')} $hours');
    }
    parts.add(t('STOREFRONT.TRUST_LICENSED'));
    parts.add(t('STOREFRONT.POS_RECEIPT_INVOICE'));
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Text(
        parts.join(' · '),
        key: const Key('home-trust'),
        style: Theme.of(context).textTheme.bodySmall,
      ),
    );
  }
}
