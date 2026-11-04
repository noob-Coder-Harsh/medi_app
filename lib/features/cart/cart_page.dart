import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/format.dart';
import '../../core/i18n.dart';
import '../../core/routes.dart';
import '../../core/theme.dart';
import '../../data/models/listing.dart';
import '../../data/models/local_cart.dart';
import '../location/store_resolver.dart';
import 'cart_controller.dart';
import 'cart_hydrate.dart';
import 'qty_stepper.dart';

/// Guest cart. Names/prices from `get_listing_cards`; qty from prefs. No place order.
class CartPage extends ConsumerWidget {
  const CartPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(localeProvider);
    final cart = ref.watch(cartProvider);
    final asyncCards = ref.watch(cartCardsProvider);
    final shop = ref.watch(activeShopProvider);

    return Scaffold(
      appBar: AppBar(title: Text(t('NAV.CART'))),
      body: cart.isEmpty
          ? _EmptyCart(shopSlug: shop?.slug)
          : asyncCards.when(
              loading: () => Center(child: Text(t('STOREFRONT.LOADING_CATALOG'))),
              error: (Object _, StackTrace __) => Center(
                child: Text(t('STOREFRONT.SEARCH_FAILED')),
              ),
              data: (List<ListingCard> cards) {
                return _CartBody(cart: cart, cards: cards);
              },
            ),
    );
  }
}

class _EmptyCart extends StatelessWidget {
  const _EmptyCart({this.shopSlug});

  final String? shopSlug;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              t('STOREFRONT.CART_EMPTY'),
              key: const Key('cart-empty'),
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              t('STOREFRONT.CART_EMPTY_HINT'),
              textAlign: TextAlign.center,
            ),
            if (shopSlug != null && shopSlug!.isNotEmpty) ...<Widget>[
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => context.go(Routes.shop(shopSlug!)),
                child: Text(t('STOREFRONT.CONTINUE_SHOPPING')),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CartBody extends ConsumerWidget {
  const _CartBody({required this.cart, required this.cards});

  final LocalCart cart;
  final List<ListingCard> cards;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final byId = <String, ListingCard>{
      for (final card in cards) card.id: card,
    };
    var subtotal = 0.0;
    for (final line in cart.items) {
      final card = byId[line.storeProductId];
      if (card == null) continue;
      subtotal += (card.sellingPrice ?? 0) * line.quantity;
    }

    return Column(
      children: <Widget>[
        Expanded(
          child: ListView.separated(
            key: const Key('cart-lines'),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            itemCount: cart.items.length,
            separatorBuilder: (BuildContext context, int _) {
              return const SizedBox(height: 8);
            },
            itemBuilder: (BuildContext context, int index) {
              final line = cart.items[index];
              return _CartLineTile(
                line: line,
                card: byId[line.storeProductId],
                storeId: cart.storeId ?? '',
              );
            },
          ),
        ),
        Material(
          color: Theme.of(context).scaffoldBackgroundColor,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        t('STOREFRONT.SUBTOTAL'),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    Text(
                      Format.rupee(subtotal),
                      key: const Key('cart-subtotal'),
                      style: AppTheme.rupee(
                        Theme.of(context).textTheme.titleMedium!,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: AppTheme.touchTarget,
                  child: FilledButton(
                    key: const Key('cart-checkout'),
                    onPressed: () => context.push(Routes.checkout),
                    child: Text(t('STOREFRONT.CHECKOUT')),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _CartLineTile extends ConsumerWidget {
  const _CartLineTile({
    required this.line,
    required this.card,
    required this.storeId,
  });

  final CartLine line;
  final ListingCard? card;
  final String storeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final missing = card == null;
    final name = card?.name ?? t('STOREFRONT.ITEM_UNAVAILABLE');
    final price = card?.sellingPrice ?? 0;
    final lineTotal = price * line.quantity;
    final url = card?.thumb ?? card?.imageUrl;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppTheme.borderRadius,
        border: Border.all(
          color: AppTheme.hairlineColor,
          width: AppTheme.hairline,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            SizedBox(
              width: 72,
              height: 72,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: AppTheme.borderRadius,
                  border: Border.all(
                    color: AppTheme.hairlineColor,
                    width: AppTheme.hairline,
                  ),
                ),
                child: url == null || url.isEmpty
                    ? const Icon(Icons.medication_outlined)
                    : CachedNetworkImage(
                        imageUrl: url,
                        fit: BoxFit.contain,
                        errorWidget: (BuildContext _, String __, Object ___) {
                          return const Icon(Icons.medication_outlined);
                        },
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(name, style: text.titleSmall),
                  if (card != null)
                    Text(card!.packLabel, style: text.bodySmall),
                  if (missing)
                    Text(
                      t('STOREFRONT.ITEM_UNAVAILABLE'),
                      style: text.bodySmall,
                    )
                  else
                    Text(
                      Format.rupee(lineTotal),
                      style: AppTheme.rupee(text.titleSmall!),
                    ),
                  const SizedBox(height: 8),
                  if (card != null)
                    CartAddControl(card: card!, storeId: storeId)
                  else
                    TextButton(
                      onPressed: () {
                        ref.read(cartProvider.notifier).setQuantity(
                          line.storeProductId,
                          0,
                        );
                      },
                      child: Text(t('STOREFRONT.REMOVE')),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
