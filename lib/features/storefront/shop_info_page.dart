import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../core/i18n.dart';
import '../../core/link_opener.dart';
import '../../core/medi_app_bar.dart';
import '../../core/theme.dart';
import '../../core/whatsapp.dart';
import '../../data/models/listing.dart';
import '../location/store_resolver.dart';
import 'store_copy.dart';
import 'store_home_controller.dart';

/// Public shop details. WhatsApp is a URL, not a write.
class ShopInfoPage extends ConsumerWidget {
  const ShopInfoPage({super.key, required this.slug});

  final String slug;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(localeProvider);
    final nearby = ref.watch(nearbyShopsProvider);
    final asyncHome = ref.watch(storeHomeProvider(slug));
    final home = asyncHome.asData?.value;
    PublicStore? found = home?.store;
    if (found == null) {
      for (final item in nearby) {
        if (item.store.slug == slug) {
          found = item.store;
          break;
        }
      }
    }
    final store = found;

    Widget body;
    if (asyncHome.isLoading && store == null) {
      body = Center(child: Text(t('STOREFRONT.LOADING_CATALOG')));
    } else if (store == null) {
      body = Center(child: Text(t('STOREFRONT.STORE_NOT_FOUND')));
    } else {
      final shop = store;
      final address = storeAddressLabel(shop);
      final hours = storeHoursLabel(shop);
      final phone = shop.phone;
      body = ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: <Widget>[
          Text(shop.name, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: <Widget>[
              _Pill(
                label: shop.isOpen
                    ? t('STOREFRONT.OPEN')
                    : t('STOREFRONT.CLOSED'),
              ),
              if (shop.modulePickup)
                _Pill(label: t('STOREFRONT.FULFILLMENT_PICKUP_SHORT')),
              if (shop.moduleDelivery)
                _Pill(label: t('STOREFRONT.FULFILLMENT_DELIVERY_SHORT')),
            ],
          ),
          if (address.isNotEmpty)
            _Fact(label: t('STOREFRONT.ADDRESS'), value: address),
          if (hours != null) _Fact(label: t('STOREFRONT.HOURS'), value: hours),
          if (phone != null && phone.isNotEmpty)
            _ActionTile(
              tileKey: const Key('shop-info-call'),
              label: phone,
              icon: Icons.call_outlined,
              onTap: () {
                final digits = phone.replaceAll(RegExp(r'\D'), '');
                if (digits.isEmpty) return;
                ref.read(linkOpenerProvider).open(Uri.parse('tel:$digits'));
              },
            ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: AppTheme.touchTarget,
            child: FilledButton(
              key: const Key('shop-info-whatsapp'),
              onPressed: () => _whatsApp(context, ref, shop),
              child: Text(t('STOREFRONT.JOB_WHATSAPP')),
            ),
          ),
          if (shop.minimumOrderAmount > 0)
            _Fact(
              label: t('STOREFRONT.MIN_ORDER'),
              value: Format.rupee(shop.minimumOrderAmount),
            ),
          if (shop.moduleDelivery && shop.serviceRadiusKm > 0)
            _Fact(
              label: t('STOREFRONT.SERVICE_RADIUS'),
              value:
                  '${Format.stock(shop.serviceRadiusKm)} ${t('STOREFRONT.DISTANCE_KM')}',
            ),
          if (shop.allowCod)
            _Fact(
              label: t('STOREFRONT.PAYMENT'),
              value: t('STOREFRONT.PAYMENT_COD'),
            ),
        ],
      );
    }

    return Scaffold(
      appBar: MediAppBar(titleText: t('STOREFRONT.STORE_INFO')),
      body: body,
    );
  }

  Future<void> _whatsApp(
    BuildContext context,
    WidgetRef ref,
    PublicStore store,
  ) async {
    final uri = whatsAppUri(number: store.whatsappNumber);
    if (uri == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t('STOREFRONT.PRESCRIPTION_NO_WHATSAPP'))),
      );
      return;
    }
    final ok = await ref.read(linkOpenerProvider).open(uri);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t('STOREFRONT.PRESCRIPTION_NO_WHATSAPP'))),
      );
    }
  }
}

class _Fact extends StatelessWidget {
  const _Fact({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(label, style: text.titleSmall),
          const SizedBox(height: 4),
          Text(value, style: text.bodyLarge),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.tileKey,
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final Key tileKey;
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      key: tileKey,
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon),
      title: Text(label),
      onTap: onTap,
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
