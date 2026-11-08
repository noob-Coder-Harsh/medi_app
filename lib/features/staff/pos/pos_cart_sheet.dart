import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/brand.dart';
import '../../../core/format.dart';
import '../../../core/i18n.dart';
import '../../../core/packaging.dart';
import '../../../core/routes.dart';
import '../../../core/theme.dart';
import 'pos_cart_controller.dart';
import 'pos_product.dart';

/// Quick-view cart sheet (~50% height) for reviewing / editing line items.
Future<void> showPosCartSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (BuildContext sheet) {
      return const PosCartSheet();
    },
  );
}

class PosCartSheet extends ConsumerWidget {
  const PosCartSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(localeProvider);
    final items = ref.watch(posCartProvider);
    final cart = ref.read(posCartProvider.notifier);
    final theme = Theme.of(context);
    final height = MediaQuery.sizeOf(context).height * 0.52;

    return SizedBox(
      height: height,
      child: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 8, 8),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    t('STORE_FORM.POS_CART'),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: t('CHROME.CLOSE_MORE'),
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: items.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        t('STORE_FORM.POS_EMPTY_CART'),
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.65,
                          ),
                        ),
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    itemCount: items.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (BuildContext context, int index) {
                      final item = items[index];
                      return _CartLine(
                        item: item,
                        onIncrease: () =>
                            cart.bump(item.storeProductId, increase: true),
                        onDecrease: () =>
                            cart.bump(item.storeProductId, increase: false),
                        onRemove: () => cart.remove(item.storeProductId),
                      );
                    },
                  ),
          ),
          const Divider(height: 1),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Text(
                        t('STORE_FORM.POS_TOTAL_AMOUNT'),
                        style: theme.textTheme.titleMedium,
                      ),
                      const Spacer(),
                      Text(
                        Format.rupee(cart.subtotal),
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: Brand.themeColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: OutlinedButton(
                          onPressed: items.isEmpty ? null : () => cart.clear(),
                          child: Text(t('STORE_FORM.POS_CLEAR_CART')),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: FilledButton(
                          onPressed: items.isEmpty
                              ? null
                              : () {
                                  Navigator.of(context).pop();
                                  context.push(Routes.staffPosCheckout);
                                },
                          style: AppTheme.charge,
                          child: Text(t('CHROME.CHARGE')),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CartLine extends StatelessWidget {
  const _CartLine({
    required this.item,
    required this.onIncrease,
    required this.onDecrease,
    required this.onRemove,
  });

  final PosCartItem item;
  final VoidCallback onIncrease;
  final VoidCallback onDecrease;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final packaging = item.product.packaging;
    final packDisplay = convertBaseToPackDisplay(item.quantity, packaging);
    final overStock = item.quantity > item.product.stockCount;
    final line = lineAmount(item.product.unitPrice, item.quantity);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  item.product.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: 2),
                Text(
                  packDisplay.display,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                  ),
                ),
                if (overStock)
                  Text(
                    '${t('STORE_FORM.POS_STOCK')} ${Format.stock(item.product.stockCount)}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppTheme.error,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _QtyChip(
            quantity: item.quantity.floor(),
            onIncrease: onIncrease,
            onDecrease: onDecrease,
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 64,
            child: Text(
              Format.rupee(line),
              textAlign: TextAlign.right,
              style: theme.textTheme.titleSmall,
            ),
          ),
          IconButton(
            onPressed: onRemove,
            icon: const Icon(Icons.close, size: 18),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}

class _QtyChip extends StatelessWidget {
  const _QtyChip({
    required this.quantity,
    required this.onIncrease,
    required this.onDecrease,
  });

  final int quantity;
  final VoidCallback onIncrease;
  final VoidCallback onDecrease;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: AppTheme.touchTarget,
      decoration: BoxDecoration(
        borderRadius: AppTheme.borderRadius,
        border: Border.all(color: AppTheme.hairlineColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          IconButton(
            onPressed: onDecrease,
            icon: const Icon(Icons.remove, size: 20),
            constraints: const BoxConstraints(
              minWidth: AppTheme.touchTarget,
              minHeight: AppTheme.touchTarget,
            ),
          ),
          Text('$quantity', style: Theme.of(context).textTheme.labelLarge),
          IconButton(
            onPressed: onIncrease,
            icon: const Icon(Icons.add, size: 20),
            constraints: const BoxConstraints(
              minWidth: AppTheme.touchTarget,
              minHeight: AppTheme.touchTarget,
            ),
          ),
        ],
      ),
    );
  }
}
