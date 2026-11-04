import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/i18n.dart';
import '../../data/models/listing.dart';
import 'cart_controller.dart';

abstract final class CartActions {
  static Future<bool> confirmReplace(BuildContext context) async {
    final go = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(t('STOREFRONT.MULTI_STORE_TITLE')),
          content: Text(t('STOREFRONT.MULTI_STORE_BODY')),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(t('STOREFRONT.MULTI_STORE_CANCEL')),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(t('STOREFRONT.MULTI_STORE_CONFIRM')),
            ),
          ],
        );
      },
    );
    return go == true;
  }

  static Future<void> add(
    BuildContext context,
    WidgetRef ref, {
    required String storeId,
    required ListingCard card,
  }) async {
    if (storeId.isEmpty) return;
    final cart = ref.read(cartProvider.notifier);
    final result = await cart.tryAdd(storeId: storeId, card: card);
    if (result != CartAddResult.needsConfirm || !context.mounted) return;
    final replace = await confirmReplace(context);
    if (!replace || !context.mounted) return;
    await cart.replaceAndAdd(storeId: storeId, card: card);
  }
}
