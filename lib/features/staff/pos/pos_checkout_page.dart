import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/brand.dart';
import '../../../core/format.dart';
import '../../../core/i18n.dart';
import '../../../core/packaging.dart';
import '../../../core/routes.dart';
import '../../../core/theme.dart';
import '../../../data/api_client.dart';
import '../../../data/models/pos_checkout.dart';
import '../../../data/staff_api_client.dart';
import '../../account/customer_auth.dart';
import '../auth/staff_session.dart';
import '../shell/staff_app_bar.dart';
import '../shell/staff_pop_scope.dart';
import '../store_settings/store_settings_controller.dart';
import 'pos_cart_controller.dart';
import 'pos_catalog_controller.dart';
import 'pos_product.dart';
import 'pos_qty_sheet.dart';
import 'pos_receipt.dart';
import 'pos_recent_sales.dart';
import 'pos_success_sheet.dart';

/// Opens POS checkout as a full screen (kept for tests / callers).
Future<void> showPosChargeSheet(BuildContext context) {
  return Navigator.of(context).push<void>(
    MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (BuildContext _) => const PosCheckoutPage(),
    ),
  );
}

/// Full-screen POS checkout — cart lines, bill summary, payment, charge.
class PosCheckoutPage extends ConsumerStatefulWidget {
  const PosCheckoutPage({super.key});

  @override
  ConsumerState<PosCheckoutPage> createState() => _PosCheckoutPageState();
}

class _PosCheckoutPageState extends ConsumerState<PosCheckoutPage> {
  static const Color _mint = Color(0xFFE6F4F1);
  static const Color _label = Color(0xFF64748B);
  static const Color _ink = Color(0xFF0F172A);

  final _phone = TextEditingController();
  final _collect = TextEditingController();
  var _method = PosPaymentMethod.cash;
  var _busy = false;
  var _collectEdited = false;
  var _billingExpanded = true;
  double _lastSyncedTotal = -1;
  String? _error;
  PosCustomerCard? _customer;

  @override
  void dispose() {
    _phone.dispose();
    _collect.dispose();
    super.dispose();
  }

  void _syncCollectIfNeeded(double total) {
    if (_collectEdited) return;
    if (_lastSyncedTotal == total) return;
    _lastSyncedTotal = total;
    final text = total == total.roundToDouble()
        ? '${total.round()}'
        : total.toStringAsFixed(2);
    if (_collect.text == text) return;
    _collect.text = text;
  }

  double _parseCollect() {
    final raw = _collect.text.trim().replaceAll(',', '');
    final value = double.tryParse(raw);
    if (value == null || !value.isFinite || value < 0) return 0;
    return roundMoney(value);
  }

  ({double collect, double discount, double paid}) _amounts(double total) {
    if (_method == PosPaymentMethod.credit) {
      return (collect: 0, discount: 0, paid: 0);
    }
    final collect = _parseCollect();
    if (collect <= 0) {
      return (collect: total, discount: 0, paid: total);
    }
    if (collect >= total) {
      return (collect: collect, discount: 0, paid: total);
    }
    final discount = roundMoney(total - collect);
    return (collect: collect, discount: discount, paid: collect);
  }

  String _payLabel(PosPaymentMethod method) {
    return switch (method) {
      PosPaymentMethod.cash => t('STORE_FORM.POS_PAYMENT_CASH'),
      PosPaymentMethod.upi => t('STORE_FORM.POS_PAYMENT_UPI'),
      PosPaymentMethod.card => t('STORE_FORM.POS_PAYMENT_CARD'),
      PosPaymentMethod.credit => t('STORE_FORM.POS_PAYMENT_CREDIT_SHORT'),
      _ => t('STORE_FORM.POS_PAYMENT_CASH'),
    };
  }

  void _leave() {
    staffBack(context, fallback: Routes.staffPos);
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(localeProvider);
    final items = ref.watch(posCartProvider);
    final cart = ref.read(posCartProvider.notifier);
    final theme = Theme.of(context);
    final total = cart.subtotal;
    _syncCollectIfNeeded(total);
    final amounts = _amounts(total);
    final payable =
        _method == PosPaymentMethod.credit ? total : amounts.paid;
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;

    return Scaffold(
      backgroundColor: Brand.themeBackground,
      appBar: StaffAppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _leave,
        ),
        title: t('STORE_FORM.POS_CHECKOUT'),
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: items.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        t('STORE_FORM.POS_EMPTY_CART'),
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: _label,
                        ),
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (BuildContext context, int index) {
                      final item = items[index];
                      return _CheckoutLineRow(
                        item: item,
                        onIncrease: () {
                          cart.bump(item.storeProductId, increase: true);
                          setState(() {});
                        },
                        onDecrease: () {
                          cart.bump(item.storeProductId, increase: false);
                          setState(() {});
                        },
                        onRemove: () {
                          cart.remove(item.storeProductId);
                          setState(() {});
                        },
                        onEditTotal: () =>
                            showPosQtySheet(context, item.product),
                      );
                    },
                  ),
          ),
          Material(
            elevation: 8,
            shadowColor: Colors.black26,
            color: Colors.white,
            child: Padding(
              padding: EdgeInsets.only(bottom: keyboard > 0 ? keyboard : 0),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    _StickyBillingPanel(
                      expanded: _billingExpanded,
                      onToggle: () => setState(
                        () => _billingExpanded = !_billingExpanded,
                      ),
                      itemCount: items.length,
                      total: total,
                      payable: payable,
                      isCredit: _method == PosPaymentMethod.credit,
                      collect: _collect,
                      onCollectChanged: () {
                        _collectEdited = true;
                        setState(() => _error = null);
                      },
                      phone: _phone,
                      customerName: _customer?.name,
                      phoneError: _phoneError(),
                      onPhoneChanged: () {
                        setState(() {
                          _customer = null;
                          _error = null;
                        });
                      },
                      method: _method,
                      payLabel: _payLabel,
                      onMethodChanged: (PosPaymentMethod next) {
                        setState(() {
                          _method = next;
                          _error = null;
                        });
                      },
                      error: _error,
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                      child: SizedBox(
                        width: double.infinity,
                        height: AppTheme.chargeHeight,
                        child: FilledButton.icon(
                          onPressed: _busy
                              ? null
                              : () => _charge(
                                  items,
                                  total,
                                  amounts.paid,
                                  amounts.discount,
                                ),
                          style: AppTheme.charge,
                          icon: _busy
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(
                                  Icons.point_of_sale_outlined,
                                  size: 22,
                                ),
                          label: Text(
                            _busy
                                ? t('WRITE_LOADING')
                                : '${t('CHROME.CHARGE')} ${Format.rupee(payable)}',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String? _phoneError() {
    final digits = _phone.text.trim();
    if (digits.isEmpty) return null;
    if (normalizeIndianMobile(digits) == null) {
      return t('STORE_FORM.POS_PHONE_INVALID');
    }
    return null;
  }

  String? _validate(List<PosCartItem> items) {
    if (items.isEmpty) return t('STORE_FORM.POS_VALIDATION_CART');
    final phone = normalizeIndianMobile(_phone.text);
    if (phone == null) return t('STORE_FORM.POS_VALIDATION_CUSTOMER');
    final overStock = items.any(
      (PosCartItem item) => item.quantity > item.product.stockCount,
    );
    if (overStock) return t('STORE_FORM.POS_VALIDATION_STOCK');
    if (_method != PosPaymentMethod.credit && _parseCollect() <= 0) {
      return t('STORE_FORM.POS_VALIDATION_COLLECT');
    }
    return null;
  }

  Future<void> _charge(
    List<PosCartItem> items,
    double total,
    double paid,
    double discount,
  ) async {
    setState(() => _error = null);
    final validation = _validate(items);
    if (validation != null) {
      setState(() => _error = validation);
      return;
    }

    final phone = normalizeIndianMobile(_phone.text)!;
    final token = ref.read(staffSessionProvider).session?.accessToken;
    if (token == null || token.isEmpty) {
      setState(() => _error = t('AUTH_SUPABASE_MISSING'));
      return;
    }

    setState(() => _busy = true);
    try {
      final api = ref.read(staffWriteApiProvider);
      final customer =
          _customer ??
          await api.ensureCustomer(accessToken: token, phone: phone);
      _customer = customer;

      final result = await api.checkout(
        accessToken: token,
        input: PosCheckoutInput(
          customerId: customer.customerId,
          items: items
              .map(
                (PosCartItem item) => PosCheckoutLineInput(
                  storeProductId: item.storeProductId,
                  quantity: item.quantity.round(),
                  unitPrice: item.product.unitPrice,
                  unitMrp: item.product.mrp,
                ),
              )
              .toList(growable: false),
          paymentMethod: _method,
          paidAmount: paid,
          discountType: discount > 0 ? 'fixed' : 'none',
          discountValue: discount,
          taxAmount: 0,
        ),
      );

      final payable = result.totalAmount == 0
          ? roundMoney(total - discount)
          : result.totalAmount;
      final placedAt =
          DateTime.tryParse(result.placedAt ?? '') ?? DateTime.now();
      final receipt = PosReceiptSnapshot.fromCheckout(
        store: ref.read(storeSettingsProvider).store,
        billNumber: result.orderNumber,
        placedAt: placedAt,
        paymentMethod: _payLabel(_method),
        items: items,
        discount: discount,
        totalPayable: payable,
        customerPhone: result.customerPhone ?? customer.phone,
        customerName: customer.name,
      );

      ref.read(posCartProvider.notifier).clear();
      ref.read(posRecentSalesProvider.notifier).prepend(
            PosRecentSale(
              id: result.orderId,
              orderNumber: result.orderNumber,
              customerPhone: result.customerPhone ?? customer.phone,
              customerName: customer.name,
              itemCount: items.length,
              totalAmount: payable,
              placedAt: result.placedAt ?? '',
              source: 'pos',
            ),
          );
      unawaited(_refreshAfterSale());

      if (!mounted) return;
      await showPosSuccessSheet(
        context,
        result: result,
        receipt: receipt,
        onNewSale: () {},
      );
      if (mounted) _leave();
    } on AppApiException catch (error) {
      if (!mounted) return;
      setState(() => _error = error.message);
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = '$error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _refreshAfterSale() async {
    final query = ref.read(posCatalogProvider).query.trim();
    final catalog = ref.read(posCatalogProvider.notifier);
    if (query.isEmpty) {
      await catalog.loadHome();
    } else {
      await catalog.search(query);
    }
    await ref.read(posRecentSalesProvider.notifier).refresh();
  }
}

class _CheckoutLineRow extends StatelessWidget {
  const _CheckoutLineRow({
    required this.item,
    required this.onIncrease,
    required this.onDecrease,
    required this.onRemove,
    required this.onEditTotal,
  });

  final PosCartItem item;
  final VoidCallback onIncrease;
  final VoidCallback onDecrease;
  final VoidCallback onRemove;
  final VoidCallback onEditTotal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final product = item.product;
    final packaging = product.packaging;
    final over = item.quantity > product.stockCount;
    final pack = convertBaseToPackDisplay(item.quantity, packaging);
    final packMeta = pack.display.isNotEmpty
        ? pack.display
        : formatPosPackMeta(packaging);
    final line = lineAmount(product.unitPrice, item.quantity);
    final qty = item.quantity.floor();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: <Widget>[
          _Thumb(imageUrl: product.imageUrl),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  product.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: over ? AppTheme.error : _PosCheckoutPageState._ink,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  packMeta,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: over ? AppTheme.error : _PosCheckoutPageState._label,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          _QtyStepper(
            quantity: qty,
            onIncrease: onIncrease,
            onDecrease: onDecrease,
          ),
          const SizedBox(width: 6),
          InkWell(
            onTap: onEditTotal,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: _PosCheckoutPageState._mint,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Brand.themeColor.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    Format.rupee(line),
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: Brand.themeColor,
                    ),
                  ),
                  const SizedBox(width: 2),
                  Icon(
                    Icons.edit_outlined,
                    size: 12,
                    color: Brand.themeColor.withValues(alpha: 0.8),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 2),
          InkWell(
            onTap: onRemove,
            borderRadius: BorderRadius.circular(16),
            child: const SizedBox(
              width: 28,
              height: 28,
              child: Icon(Icons.close, size: 18, color: _PosCheckoutPageState._label),
            ),
          ),
        ],
      ),
    );
  }
}

class _QtyStepper extends StatelessWidget {
  const _QtyStepper({
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
      height: 30,
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          _StepBtn(icon: Icons.remove, onPressed: onDecrease),
          Text(
            '$quantity',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          _StepBtn(icon: Icons.add, onPressed: onIncrease),
        ],
      ),
    );
  }
}

class _StepBtn extends StatelessWidget {
  const _StepBtn({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: 28,
        height: 30,
        child: Icon(icon, size: 16, color: Brand.themeColor),
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({required this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final url = imageUrl?.trim() ?? '';
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: ColoredBox(
        color: _PosCheckoutPageState._mint,
        child: SizedBox(
          width: 40,
          height: 40,
          child: url.isEmpty
              ? Icon(
                  Icons.medication_outlined,
                  size: 20,
                  color: Brand.themeColor.withValues(alpha: 0.55),
                )
              : CachedNetworkImage(
                  imageUrl: url,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => Icon(
                    Icons.medication_outlined,
                    size: 20,
                    color: Brand.themeColor.withValues(alpha: 0.55),
                  ),
                ),
        ),
      ),
    );
  }
}

class _StickyBillingPanel extends StatelessWidget {
  const _StickyBillingPanel({
    required this.expanded,
    required this.onToggle,
    required this.itemCount,
    required this.total,
    required this.payable,
    required this.isCredit,
    required this.collect,
    required this.onCollectChanged,
    required this.phone,
    required this.customerName,
    required this.phoneError,
    required this.onPhoneChanged,
    required this.method,
    required this.payLabel,
    required this.onMethodChanged,
    required this.error,
  });

  final bool expanded;
  final VoidCallback onToggle;
  final int itemCount;
  final double total;
  final double payable;
  final bool isCredit;
  final TextEditingController collect;
  final VoidCallback onCollectChanged;
  final TextEditingController phone;
  final String? customerName;
  final String? phoneError;
  final VoidCallback onPhoneChanged;
  final PosPaymentMethod method;
  final String Function(PosPaymentMethod) payLabel;
  final ValueChanged<PosPaymentMethod> onMethodChanged;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        InkWell(
          onTap: onToggle,
          child: Container(
            width: double.infinity,
            color: _PosCheckoutPageState._mint,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: <Widget>[
                const Icon(
                  Icons.receipt_long_outlined,
                  size: 18,
                  color: Brand.themeColor,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    t('STORE_FORM.POS_BILLING'),
                    style: const TextStyle(
                      color: Brand.themeColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
                Text(
                  Format.rupee(isCredit ? total : payable),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: Brand.themeColor,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  expanded
                      ? Icons.keyboard_arrow_down_rounded
                      : Icons.keyboard_arrow_up_rounded,
                  color: Brand.themeColor,
                ),
              ],
            ),
          ),
        ),
        AnimatedCrossFade(
          firstChild: const SizedBox(width: double.infinity),
          secondChild: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                _BillingTotals(
                  itemCount: itemCount,
                  total: total,
                  payable: payable,
                  isCredit: isCredit,
                  collect: collect,
                  onCollectChanged: onCollectChanged,
                ),
                const SizedBox(height: 10),
                Text(
                  t('STORE_FORM.POS_CUSTOMER_PHONE'),
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: _PosCheckoutPageState._label,
                  ),
                ),
                const SizedBox(height: 6),
                _PhoneRow(
                  phone: phone,
                  customerName: customerName,
                  phoneError: phoneError,
                  onChanged: onPhoneChanged,
                ),
                const SizedBox(height: 10),
                Text(
                  t('STORE_FORM.POS_PAYMENT_METHOD'),
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: _PosCheckoutPageState._label,
                  ),
                ),
                const SizedBox(height: 6),
                _PaymentMethodRow(
                  method: method,
                  labelOf: payLabel,
                  onChanged: onMethodChanged,
                ),
                if (error != null) ...<Widget>[
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.error.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppTheme.error.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Text(
                      error!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.error,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          crossFadeState:
              expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 180),
          sizeCurve: Curves.easeOut,
        ),
      ],
    );
  }
}

class _BillingTotals extends StatelessWidget {
  const _BillingTotals({
    required this.itemCount,
    required this.total,
    required this.payable,
    required this.isCredit,
    required this.collect,
    required this.onCollectChanged,
  });

  final int itemCount;
  final double total;
  final double payable;
  final bool isCredit;
  final TextEditingController collect;
  final VoidCallback onCollectChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                '${t('STORE_FORM.POS_ITEMS_TOTAL')} · ${t('STORE_FORM.POS_ITEMS_COUNT').replaceAll('{count}', '$itemCount')}',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: _PosCheckoutPageState._ink,
                ),
              ),
            ),
            if (isCredit)
              Text(
                Format.rupee(total),
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              )
            else
              SizedBox(
                width: 128,
                child: TextField(
                  controller: collect,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  textAlign: TextAlign.right,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: Brand.themeColor,
                  ),
                  inputFormatters: <TextInputFormatter>[
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                  ],
                  decoration: InputDecoration(
                    isDense: true,
                    prefixText: '₹ ',
                    prefixStyle: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: Brand.themeColor,
                    ),
                    suffixIcon: const Icon(
                      Icons.edit_outlined,
                      size: 14,
                      color: Brand.themeColor,
                    ),
                    suffixIconConstraints: const BoxConstraints(
                      minWidth: 24,
                      minHeight: 24,
                    ),
                    filled: true,
                    fillColor: _PosCheckoutPageState._mint,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: Brand.themeColor.withValues(alpha: 0.35),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                        color: Brand.themeColor,
                        width: 1.4,
                      ),
                    ),
                  ),
                  onChanged: (_) => onCollectChanged(),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                isCredit
                    ? t('STORE_FORM.POS_REMAINING_AMOUNT')
                    : t('STORE_FORM.POS_PAYABLE'),
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: isCredit ? AppTheme.amber : _PosCheckoutPageState._ink,
                ),
              ),
            ),
            Text(
              Format.rupee(isCredit ? total : payable),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: isCredit ? AppTheme.amber : Brand.themeColor,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _PhoneRow extends StatelessWidget {
  const _PhoneRow({
    required this.phone,
    required this.customerName,
    required this.phoneError,
    required this.onChanged,
  });

  final TextEditingController phone;
  final String? customerName;
  final String? phoneError;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          children: <Widget>[
            Container(
              height: 42,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Brand.themeBackground,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.hairlineColor),
              ),
              child: Text(
                '+91',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                key: const Key('pos-checkout-phone'),
                controller: phone,
                keyboardType: TextInputType.phone,
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10),
                ],
                decoration: InputDecoration(
                  isDense: true,
                  hintText: '9876543210',
                  errorText: phoneError,
                  filled: true,
                  fillColor: Brand.themeBackground,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 11,
                  ),
                ),
                onChanged: (_) => onChanged(),
              ),
            ),
          ],
        ),
        if (customerName != null && customerName!.isNotEmpty) ...<Widget>[
          const SizedBox(height: 4),
          Text(
            customerName!,
            style: theme.textTheme.labelMedium?.copyWith(
              color: Brand.themeColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }
}

class _PaymentMethodRow extends StatelessWidget {
  const _PaymentMethodRow({
    required this.method,
    required this.labelOf,
    required this.onChanged,
  });

  final PosPaymentMethod method;
  final String Function(PosPaymentMethod) labelOf;
  final ValueChanged<PosPaymentMethod> onChanged;

  static const List<PosPaymentMethod> _methods = <PosPaymentMethod>[
    PosPaymentMethod.cash,
    PosPaymentMethod.upi,
    PosPaymentMethod.card,
    PosPaymentMethod.credit,
  ];

  IconData _icon(PosPaymentMethod value) {
    return switch (value) {
      PosPaymentMethod.cash => Icons.payments_outlined,
      PosPaymentMethod.upi => Icons.qr_code_2_outlined,
      PosPaymentMethod.card => Icons.credit_card_outlined,
      PosPaymentMethod.credit => Icons.history_outlined,
      _ => Icons.payments_outlined,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: <Widget>[
        for (final value in _methods)
          _PayChip(
            label: labelOf(value),
            icon: _icon(value),
            selected: method == value,
            onTap: () => onChanged(value),
          ),
      ],
    );
  }
}

class _PayChip extends StatelessWidget {
  const _PayChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? _PosCheckoutPageState._mint : Brand.themeBackground,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? Brand.themeColor : AppTheme.hairlineColor,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                selected ? Icons.check_circle : icon,
                size: 15,
                color: selected ? Brand.themeColor : _PosCheckoutPageState._label,
              ),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  color: selected
                      ? Brand.themeColor
                      : _PosCheckoutPageState._ink,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
