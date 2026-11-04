import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/format.dart';
import '../../core/i18n.dart';
import '../../core/routes.dart';
import '../../core/theme.dart';
import '../../data/api_client.dart';
import '../../data/models/checkout.dart';
import '../../data/models/listing.dart';
import '../../data/models/local_cart.dart';
import '../account/customer_auth.dart';
import '../account/otp_sheet.dart';
import '../cart/cart_controller.dart';
import '../location/store_resolver.dart';
import '../storefront/store_home_controller.dart';

/// Guest checkout. Revalidate + place order via `/api/app`. No Razorpay.
class CheckoutPage extends ConsumerStatefulWidget {
  const CheckoutPage({super.key});

  @override
  ConsumerState<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends ConsumerState<CheckoutPage> {
  final _addressLine = TextEditingController();
  final _landmark = TextEditingController();
  final _city = TextEditingController();
  final _state = TextEditingController();
  final _pincode = TextEditingController();

  String? _fulfillment; // pickup | delivery
  String? _payment; // cod | upi
  var _busy = false;
  String? _error;
  PlaceOnlineOrderResult? _placed;

  @override
  void dispose() {
    _addressLine.dispose();
    _landmark.dispose();
    _city.dispose();
    _state.dispose();
    _pincode.dispose();
    super.dispose();
  }

  PublicStore? _store(LocalCart cart) {
    final active = ref.read(activeShopProvider);
    final nearby = ref.read(nearbyShopsProvider);
    if (active != null) {
      for (final item in nearby) {
        if (item.store.id == active.storeId || item.store.slug == active.slug) {
          return item.store;
        }
      }
      return ref.read(storeHomeProvider(active.slug)).asData?.value.store;
    }
    if (cart.storeId != null) {
      for (final item in nearby) {
        if (item.store.id == cart.storeId) return item.store;
      }
    }
    return null;
  }

  String? _defaultFulfillment(PublicStore? store) {
    if (_fulfillment != null) return _fulfillment;
    if (store == null) return 'delivery';
    if (store.moduleDelivery) return 'delivery';
    if (store.modulePickup) return 'pickup';
    return null;
  }

  String? _defaultPayment(PublicStore? store) {
    if (_payment != null) return _payment;
    if (store == null) return 'cod';
    if (store.allowCod) return 'cod';
    if (store.allowManualUpi) return 'upi';
    return null;
  }

  String? _validate(PublicStore? store) {
    if (_fulfillment == null) return t('STOREFRONT.VALIDATION_FULFILLMENT');
    if (_payment == null) return t('STOREFRONT.VALIDATION_PAYMENT');
    if (_fulfillment == 'delivery') {
      if (_addressLine.text.trim().isEmpty) {
        return t('STOREFRONT.VALIDATION_ADDRESS_LINE');
      }
      if (_city.text.trim().isEmpty) return t('STOREFRONT.VALIDATION_CITY');
      if (_state.text.trim().isEmpty) return t('STOREFRONT.VALIDATION_STATE');
      final pin = _pincode.text.trim();
      if (!RegExp(r'^\d{6}$').hasMatch(pin)) {
        return t('STOREFRONT.VALIDATION_PINCODE');
      }
    }
    if (store != null && !store.isOpen) {
      return t('STOREFRONT.VALIDATION_STORE_CLOSED');
    }
    return null;
  }

  Future<void> _place() async {
    final cart = ref.read(cartProvider);
    if (cart.isEmpty || cart.storeId == null) {
      setState(() => _error = t('STOREFRONT.EMPTY_CART_CHECKOUT'));
      return;
    }
    final store = _store(cart);
    _fulfillment ??= _defaultFulfillment(store);
    _payment ??= _defaultPayment(store);
    final validation = _validate(store);
    if (validation != null) {
      setState(() => _error = validation);
      return;
    }

    var session = ref.read(customerSessionProvider);
    if (!session.isSignedIn) {
      final ok = await showOtpSheet(context);
      if (!ok || !mounted) return;
      session = ref.read(customerSessionProvider);
      if (!session.isSignedIn) {
        setState(() => _error = t('STOREFRONT.VALIDATION_AUTH'));
        return;
      }
    }

    setState(() {
      _busy = true;
      _error = null;
    });

    final token = session.idToken!;
    final items = cart.items
        .map(
          (CartLine line) => RevalidateCartLineInput(
            storeProductId: line.storeProductId,
            quantity: line.quantity,
          ),
        )
        .toList();

    try {
      final api = ref.read(appWriteApiProvider);
      final revalidated = await api.revalidateCart(
        idToken: token,
        storeId: cart.storeId!,
        items: items,
      );
      if (!revalidated.ok) {
        setState(() {
          _busy = false;
          _error = revalidated.messages.isNotEmpty
              ? revalidated.messages.first
              : t('STOREFRONT.VALIDATION_CART');
        });
        return;
      }

      final address = _fulfillment == 'delivery'
          ? CheckoutAddress(
              addressLine1: _addressLine.text.trim(),
              addressLine2: _landmark.text.trim().isEmpty
                  ? null
                  : _landmark.text.trim(),
              city: _city.text.trim(),
              state: _state.text.trim(),
              pincode: _pincode.text.trim(),
            )
          : null;

      final placed = await api.placeOrder(
        idToken: token,
        input: PlaceOnlineOrderInput(
          storeId: cart.storeId!,
          items: items,
          fulfillmentType: _fulfillment!,
          paymentMethod: _payment!,
          address: address,
          saveAddress: false,
        ),
      );
      await ref.read(cartProvider.notifier).clear();
      if (!mounted) return;
      setState(() {
        _busy = false;
        _placed = placed;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = '$error';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(localeProvider);
    final cart = ref.watch(cartProvider);
    final store = _store(cart);
    final fulfillment = _defaultFulfillment(store);
    final payment = _defaultPayment(store);

    if (_placed != null) {
      return _SuccessBody(result: _placed!);
    }

    return Scaffold(
      appBar: AppBar(title: Text(t('CUSTOMER_CHECKOUT'))),
      body: !ref.watch(cartReadyProvider)
          ? Center(child: Text(t('STOREFRONT.LOADING_CATALOG')))
          : cart.isEmpty
          ? Center(
              child: Text(
                t('STOREFRONT.EMPTY_CART_CHECKOUT'),
                key: const Key('checkout-empty'),
              ),
            )
          : Column(
              children: <Widget>[
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                Text(
                  t('STOREFRONT.FULFILLMENT'),
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                RadioGroup<String>(
                  groupValue: fulfillment,
                  onChanged: _busy
                      ? (_) {}
                      : (String? value) => setState(() => _fulfillment = value),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      if (store?.moduleDelivery != false)
                        RadioListTile<String>(
                          key: const Key('fulfillment-delivery'),
                          title: Text(t('STOREFRONT.FULFILLMENT_DELIVERY')),
                          value: 'delivery',
                        ),
                      if (store?.modulePickup == true)
                        RadioListTile<String>(
                          key: const Key('fulfillment-pickup'),
                          title: Text(t('STOREFRONT.FULFILLMENT_PICKUP')),
                          value: 'pickup',
                        ),
                    ],
                  ),
                ),
                if (fulfillment == 'delivery') ...<Widget>[
                  const SizedBox(height: 8),
                  Text(
                    t('STOREFRONT.DELIVERY_ADDRESS'),
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  TextField(
                    key: const Key('checkout-address'),
                    controller: _addressLine,
                    enabled: !_busy,
                    decoration: InputDecoration(
                      labelText: t('STOREFRONT.ADDRESS_LINE'),
                    ),
                  ),
                  TextField(
                    controller: _landmark,
                    enabled: !_busy,
                    decoration: InputDecoration(
                      labelText: t('STOREFRONT.ADDRESS_LINE_2'),
                    ),
                  ),
                  TextField(
                    key: const Key('checkout-city'),
                    controller: _city,
                    enabled: !_busy,
                    decoration: InputDecoration(
                      labelText: t('STOREFRONT.CITY'),
                    ),
                  ),
                  TextField(
                    key: const Key('checkout-state'),
                    controller: _state,
                    enabled: !_busy,
                    decoration: InputDecoration(
                      labelText: t('STOREFRONT.STATE'),
                    ),
                  ),
                  TextField(
                    key: const Key('checkout-pincode'),
                    controller: _pincode,
                    enabled: !_busy,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: t('STOREFRONT.PINCODE'),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Text(
                  t('STOREFRONT.PAYMENT'),
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                RadioGroup<String>(
                  groupValue: payment,
                  onChanged: _busy
                      ? (_) {}
                      : (String? value) => setState(() => _payment = value),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      if (store?.allowCod != false)
                        RadioListTile<String>(
                          key: const Key('payment-cod'),
                          title: Text(t('STOREFRONT.PAYMENT_COD')),
                          value: 'cod',
                        ),
                      if (store?.allowManualUpi == true)
                        RadioListTile<String>(
                          key: const Key('payment-upi'),
                          title: Text(t('STOREFRONT.PAYMENT_UPI')),
                          value: 'upi',
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  t('STOREFRONT.ORDER_SUMMARY'),
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                Text(
                  '${cart.totalUnits} · ${cart.storeId}',
                  key: const Key('checkout-summary'),
                ),
                      ],
                    ),
                  ),
                ),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: Text(
                      _error!,
                      key: const Key('checkout-error'),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.error,
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: SizedBox(
                    width: double.infinity,
                    height: AppTheme.touchTarget,
                    child: FilledButton(
                      key: const Key('checkout-place-order'),
                      onPressed: _busy ? null : _place,
                      child: Text(
                        _busy
                            ? t('STOREFRONT.PLACING_ORDER')
                            : t('STOREFRONT.PLACE_ORDER'),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _SuccessBody extends StatelessWidget {
  const _SuccessBody({required this.result});

  final PlaceOnlineOrderResult result;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(t('STOREFRONT.ORDER_PLACED'))),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              t('STOREFRONT.ORDER_PLACED'),
              key: const Key('checkout-success'),
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              t('STOREFRONT.ORDER_PLACED_HINT'),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              Format.rupee(result.totalAmount),
              textAlign: TextAlign.center,
              style: AppTheme.rupee(Theme.of(context).textTheme.titleMedium!),
            ),
            if (result.orderNumber != null)
              Text(
                '${t('STOREFRONT.ORDER_NUMBER')} #${result.orderNumber}',
                textAlign: TextAlign.center,
              ),
            const SizedBox(height: 24),
            FilledButton(
              key: const Key('checkout-view-order'),
              onPressed: () => context.go(Routes.order(result.orderId)),
              child: Text(t('STOREFRONT.VIEW_ORDER')),
            ),
            TextButton(
              onPressed: () => context.go(Routes.orders),
              child: Text(t('STOREFRONT.ORDER_BACK')),
            ),
          ],
        ),
      ),
    );
  }
}
