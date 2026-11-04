import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../core/i18n.dart';
import '../../core/theme.dart';
import '../../data/models/listing.dart';
import 'cart_actions.dart';
import 'cart_controller.dart';

/// 48dp − / qty / +. Does not show warehouse remaining.
class QtyStepper extends StatelessWidget {
  const QtyStepper({
    super.key,
    required this.quantity,
    required this.onDecrease,
    required this.onIncrease,
    this.increaseEnabled = true,
    this.compact = false,
  });

  final double quantity;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;
  final bool increaseEnabled;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _iconButton(
          key: const Key('qty-decrease'),
          tooltip: t('STOREFRONT.DECREASE_QUANTITY'),
          icon: Icons.remove,
          onPressed: onDecrease,
        ),
        ConstrainedBox(
          constraints: BoxConstraints(minWidth: compact ? 24 : 32),
          child: Text(
            Format.stock(quantity),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ),
        _iconButton(
          key: const Key('qty-increase'),
          tooltip: t('STOREFRONT.INCREASE_QUANTITY'),
          icon: Icons.add,
          onPressed: increaseEnabled ? onIncrease : null,
        ),
      ],
    );
  }

  Widget _iconButton({
    required Key key,
    required String tooltip,
    required IconData icon,
    required VoidCallback? onPressed,
  }) {
    return SizedBox(
      width: AppTheme.touchTarget,
      height: AppTheme.touchTarget,
      child: IconButton(
        key: key,
        tooltip: tooltip,
        onPressed: onPressed,
        icon: Icon(icon),
        style: IconButton.styleFrom(
          minimumSize: const Size(AppTheme.touchTarget, AppTheme.touchTarget),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          padding: EdgeInsets.zero,
        ),
      ),
    );
  }
}

/// Add or stepper bound to the local cart. No RPC.
class CartAddControl extends ConsumerWidget {
  const CartAddControl({
    super.key,
    required this.card,
    required this.storeId,
    this.expanded = false,
    this.compact = false,
  });

  final ListingCard card;
  final String storeId;
  final bool expanded;
  final bool compact;

  bool get _out => !card.inStock || card.availableQuantity <= 0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quantity = ref.watch(
      cartProvider.select((cart) => cart.qtyOf(card.id)),
    );
    if (quantity > 0) {
      return QtyStepper(
        quantity: quantity,
        compact: compact,
        increaseEnabled: canIncrease(card, quantity),
        onDecrease: () {
          ref.read(cartProvider.notifier).decrease(card);
        },
        onIncrease: () {
          ref.read(cartProvider.notifier).increase(card);
        },
      );
    }

    final button = FilledButton(
      onPressed: _out
          ? null
          : () {
              CartActions.add(context, ref, storeId: storeId, card: card);
            },
      style: FilledButton.styleFrom(
        minimumSize: Size(
          expanded ? 48 : AppTheme.touchTarget,
          AppTheme.touchTarget,
        ),
        padding: expanded ? const EdgeInsets.symmetric(horizontal: 16) : EdgeInsets.zero,
        tapTargetSize: compact
            ? MaterialTapTargetSize.shrinkWrap
            : MaterialTapTargetSize.padded,
      ),
      child: Text(t('STOREFRONT.ADD_TO_CART')),
    );

    if (expanded) {
      return SizedBox(
        width: double.infinity,
        height: AppTheme.touchTarget,
        child: button,
      );
    }
    return SizedBox(
      width: AppTheme.touchTarget,
      height: AppTheme.touchTarget,
      child: button,
    );
  }
}

