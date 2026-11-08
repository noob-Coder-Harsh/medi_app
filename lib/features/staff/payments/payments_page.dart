import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/format.dart';
import '../../../core/i18n.dart';
import '../../../core/theme.dart';
import '../../../data/models/staff_books.dart';
import '../shell/staff_app_bar.dart';
import '../shell/staff_pop_scope.dart';
import 'payments_controller.dart';

class PaymentsPage extends ConsumerStatefulWidget {
  const PaymentsPage({super.key});

  @override
  ConsumerState<PaymentsPage> createState() => _PaymentsPageState();
}

class _PaymentsPageState extends ConsumerState<PaymentsPage> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _addPayment() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (BuildContext context) => const _AddPaymentSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(localeProvider);
    final state = ref.watch(paymentsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: StaffAppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => staffBack(context),
        ),
        title: t('STORE_FORM.PAYMENTS_TITLE'),
        actions: <Widget>[
          StaffAppBarAction.refresh(
            onPressed: () => ref.read(paymentsProvider.notifier).refresh(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: state.busy ? null : _addPayment,
        icon: const Icon(Icons.add),
        label: Text(t('STORE_FORM.ADD_PAYMENT')),
      ),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                t('STORE_FORM.PAYMENTS_SUBTITLE'),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _search,
              onChanged: (String value) =>
                  ref.read(paymentsProvider.notifier).setQuery(value),
              decoration: InputDecoration(
                hintText: t('STORE_FORM.SEARCH_PAYMENTS'),
                prefixIcon: const Icon(Icons.search),
              ),
            ),
          ),
          if (state.error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                state.error!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.error,
                ),
              ),
            ),
          Expanded(
            child: state.loading && state.items.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : state.items.isEmpty
                    ? Center(child: Text(t('STORE_FORM.PAYMENTS_NO_RESULTS')))
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
                        itemCount: state.items.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 8),
                        itemBuilder: (BuildContext context, int index) {
                          final item = state.items[index];
                          return _PaymentTile(item: item);
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

class _PaymentTile extends StatelessWidget {
  const _PaymentTile({required this.item});

  final StaffPayment item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final party = item.customerName ??
        item.supplierName ??
        item.orderNo ??
        item.purchaseInvoice ??
        '—';
    final typeLabel = switch (item.paymentType) {
      'purchase' => t('STORE_FORM.PAYMENT_TYPE_PURCHASE'),
      'refund' => t('STORE_FORM.PAYMENT_TYPE_REFUND'),
      'supplier_settlement' => t('STORE_FORM.PAYMENT_TYPE_SETTLEMENT'),
      'adjustment' => t('STORE_FORM.PAYMENT_TYPE_ADJUSTMENT'),
      _ => t('STORE_FORM.PAYMENT_TYPE_SALE'),
    };
    final direction = item.paymentDirection == 'outflow'
        ? t('STORE_FORM.PAYMENT_DIRECTION_OUTFLOW')
        : t('STORE_FORM.PAYMENT_DIRECTION_INFLOW');

    return Material(
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: AppTheme.borderRadius,
        side: const BorderSide(color: AppTheme.hairlineColor),
      ),
      child: ListTile(
        title: Text('${Format.rupee(item.amount)} · $typeLabel'),
        subtitle: Text(
          '$party · $direction · ${item.method} · ${item.status}',
        ),
      ),
    );
  }
}

class _AddPaymentSheet extends ConsumerStatefulWidget {
  const _AddPaymentSheet();

  @override
  ConsumerState<_AddPaymentSheet> createState() => _AddPaymentSheetState();
}

class _AddPaymentSheetState extends ConsumerState<_AddPaymentSheet> {
  bool _customerMode = true;
  String? _customerId;
  String? _supplierId;
  String _method = 'cash';
  final _amount = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _error = null);
    final amount = double.tryParse(_amount.text.trim());
    if (amount == null || amount <= 0) {
      setState(() => _error = t('STORE_FORM.PAYMENT_AMOUNT'));
      return;
    }

    final notifier = ref.read(paymentsProvider.notifier);
    final String? error;
    if (_customerMode) {
      final customerId = _customerId;
      if (customerId == null) {
        setState(() => _error = t('STORE_FORM.PAYMENT_SELECT_CUSTOMER'));
        return;
      }
      error = await notifier.settleCustomer(
        CustomerSettlementInput(
          customerId: customerId,
          amount: amount,
          method: _method,
        ),
      );
    } else {
      final supplierId = _supplierId;
      if (supplierId == null) {
        setState(() => _error = t('STORE_FORM.PAYMENT_SELECT_SUPPLIER'));
        return;
      }
      error = await notifier.settleSupplier(
        SupplierSettlementInput(
          supplierId: supplierId,
          amount: amount,
          method: _method,
        ),
      );
    }

    if (!mounted) return;
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(paymentsProvider);
    final theme = Theme.of(context);
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    final dueCustomers =
        state.customers.where((StaffCustomer c) => c.currentBalance > 0).toList();
    final dueSuppliers =
        state.suppliers.where((StaffSupplier s) => s.currentBalance > 0).toList();

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 16 + bottom),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(t('STORE_FORM.ADD_PAYMENT'), style: theme.textTheme.titleLarge),
            const SizedBox(height: 12),
            SegmentedButton<bool>(
              segments: <ButtonSegment<bool>>[
                ButtonSegment(
                  value: true,
                  label: Text(t('STORE_FORM.PAYMENT_ADD_CUSTOMER')),
                ),
                ButtonSegment(
                  value: false,
                  label: Text(t('STORE_FORM.PAYMENT_ADD_SUPPLIER')),
                ),
              ],
              selected: <bool>{_customerMode},
              onSelectionChanged: (Set<bool> next) {
                setState(() {
                  _customerMode = next.first;
                  _error = null;
                });
              },
            ),
            const SizedBox(height: 12),
            if (_customerMode)
              DropdownButtonFormField<String>(
                // ignore: deprecated_member_use
                value: _customerId,
                decoration: InputDecoration(
                  labelText: t('STORE_FORM.PAYMENT_SELECT_CUSTOMER'),
                ),
                items: dueCustomers
                    .map(
                      (StaffCustomer c) => DropdownMenuItem<String>(
                        value: c.customerId,
                        child: Text(
                          '${c.displayName} (${Format.rupee(c.currentBalance)})',
                        ),
                      ),
                    )
                    .toList(growable: false),
                onChanged: state.busy
                    ? null
                    : (String? value) => setState(() => _customerId = value),
              )
            else
              DropdownButtonFormField<String>(
                // ignore: deprecated_member_use
                value: _supplierId,
                decoration: InputDecoration(
                  labelText: t('STORE_FORM.PAYMENT_SELECT_SUPPLIER'),
                ),
                items: dueSuppliers
                    .map(
                      (StaffSupplier s) => DropdownMenuItem<String>(
                        value: s.id,
                        child: Text(
                          '${s.name} (${Format.rupee(s.currentBalance)})',
                        ),
                      ),
                    )
                    .toList(growable: false),
                onChanged: state.busy
                    ? null
                    : (String? value) => setState(() => _supplierId = value),
              ),
            if ((_customerMode && dueCustomers.isEmpty) ||
                (!_customerMode && dueSuppliers.isEmpty))
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  t('STORE_FORM.PAYMENTS_NO_RESULTS'),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                  ),
                ),
              ),
            const SizedBox(height: 12),
            TextField(
              controller: _amount,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: t('STORE_FORM.PAYMENT_AMOUNT'),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              // ignore: deprecated_member_use
              value: _method,
              decoration: InputDecoration(
                labelText: t('STORE_FORM.PAYMENT_METHOD'),
              ),
              items: <DropdownMenuItem<String>>[
                DropdownMenuItem(
                  value: 'cash',
                  child: Text(t('STORE_FORM.PAYMENT_METHOD_CASH')),
                ),
                DropdownMenuItem(
                  value: 'upi',
                  child: Text(t('STORE_FORM.PAYMENT_METHOD_UPI')),
                ),
                DropdownMenuItem(
                  value: 'bank_transfer',
                  child: Text(t('STORE_FORM.PAYMENT_METHOD_BANK')),
                ),
              ],
              onChanged: state.busy
                  ? null
                  : (String? value) {
                      if (value == null) return;
                      setState(() => _method = value);
                    },
            ),
            if (_error != null) ...<Widget>[
              const SizedBox(height: 8),
              Text(
                _error!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.error,
                ),
              ),
            ],
            const SizedBox(height: 16),
            FilledButton(
              onPressed: state.busy ? null : _submit,
              child: state.busy
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(t('STORE_FORM.ADD_PAYMENT')),
            ),
          ],
        ),
      ),
    );
  }
}
