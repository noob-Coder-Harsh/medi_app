import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/format.dart';
import '../../../core/i18n.dart';
import '../../../core/theme.dart';
import '../../../data/models/staff_books.dart';
import '../../account/customer_auth.dart';
import '../shell/staff_app_bar.dart';
import '../shell/staff_pop_scope.dart';
import 'customers_controller.dart';

class CustomersPage extends ConsumerStatefulWidget {
  const CustomersPage({super.key});

  @override
  ConsumerState<CustomersPage> createState() => _CustomersPageState();
}

class _CustomersPageState extends ConsumerState<CustomersPage> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _add() async {
    final phoneController = TextEditingController();
    final phone = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(t('STORE_FORM.ADD_CUSTOMER')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(t('STORE_FORM.ADD_CUSTOMER_BY_PHONE_HELP')),
              const SizedBox(height: 12),
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: t('STORE_FORM.CUSTOMER_PHONE'),
                ),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(t('CANCEL')),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.pop(context, phoneController.text.trim()),
              child: Text(t('CONFIRM')),
            ),
          ],
        );
      },
    );
    phoneController.dispose();
    if (phone == null || phone.isEmpty || !mounted) return;
    final e164 = normalizeIndianMobile(phone);
    if (e164 == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t('STORE_FORM.POS_PHONE_INVALID'))),
      );
      return;
    }
    final error = await ref.read(customersProvider.notifier).addByPhone(e164);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          error == null
              ? t('STORE_FORM.ADD_CUSTOMER')
              : (error == 'AUTH_SUPABASE_MISSING'
                  ? t('AUTH_SUPABASE_MISSING')
                  : error),
        ),
      ),
    );
  }

  Future<void> _openCustomer(StaffCustomer customer) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (BuildContext context) => _CustomerSheet(customer: customer),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(localeProvider);
    final state = ref.watch(customersProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: StaffAppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => staffBack(context),
        ),
        title: t('STORE_FORM.CUSTOMERS_TITLE'),
        actions: <Widget>[
          StaffAppBarAction.refresh(
            onPressed: () => ref.read(customersProvider.notifier).refresh(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: state.busy ? null : _add,
        icon: const Icon(Icons.add),
        label: Text(t('STORE_FORM.ADD_CUSTOMER')),
      ),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _search,
              onChanged: (String value) =>
                  ref.read(customersProvider.notifier).setQuery(value),
              decoration: InputDecoration(
                hintText: t('STORE_FORM.SEARCH_CUSTOMERS'),
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
                    ? Center(child: Text(t('STORE_FORM.CUSTOMERS_NO_RESULTS')))
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
                        itemCount: state.items.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 8),
                        itemBuilder: (BuildContext context, int index) {
                          final item = state.items[index];
                          return Material(
                            color: theme.colorScheme.surface,
                            shape: RoundedRectangleBorder(
                              borderRadius: AppTheme.borderRadius,
                              side: const BorderSide(
                                color: AppTheme.hairlineColor,
                              ),
                            ),
                            child: ListTile(
                              title: Text(item.displayName),
                              subtitle: Text(
                                '${item.phone} · ${t('STORE_FORM.PAYMENT_CUSTOMER_BALANCE')} ${Format.rupee(item.currentBalance)}',
                              ),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () => _openCustomer(item),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

class _CustomerSheet extends ConsumerStatefulWidget {
  const _CustomerSheet({required this.customer});

  final StaffCustomer customer;

  @override
  ConsumerState<_CustomerSheet> createState() => _CustomerSheetState();
}

class _CustomerSheetState extends ConsumerState<_CustomerSheet> {
  late final TextEditingController _notes =
      TextEditingController(text: widget.customer.notes ?? '');
  late final TextEditingController _loyalty = TextEditingController(
    text: '${widget.customer.loyaltyPoints}',
  );
  late final TextEditingController _amount = TextEditingController();
  String _method = 'cash';
  String? _error;

  @override
  void dispose() {
    _notes.dispose();
    _loyalty.dispose();
    _amount.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _error = null);
    final loyalty = int.tryParse(_loyalty.text.trim()) ?? 0;
    final error = await ref.read(customersProvider.notifier).updateNotes(
          storeCustomerId: widget.customer.id,
          notes: _notes.text.trim(),
          loyaltyPoints: loyalty,
        );
    if (!mounted) return;
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    Navigator.pop(context);
  }

  Future<void> _collect() async {
    setState(() => _error = null);
    final amount = double.tryParse(_amount.text.trim());
    if (amount == null || amount <= 0) {
      setState(() => _error = t('STORE_FORM.PAYMENT_AMOUNT'));
      return;
    }
    if (amount > widget.customer.currentBalance) {
      setState(
        () => _error = t('STORE_FORM.PAYMENT_SETTLEMENT_EXCEEDS_CUSTOMER_BALANCE'),
      );
      return;
    }
    final error = await ref.read(customersProvider.notifier).collectDues(
          customerId: widget.customer.customerId,
          amount: amount,
          method: _method,
        );
    if (!mounted) return;
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final busy = ref.watch(customersProvider).busy;
    final theme = Theme.of(context);
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    final customer = widget.customer;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 16 + bottom),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(customer.displayName, style: theme.textTheme.titleLarge),
            Text(customer.phone),
            const SizedBox(height: 8),
            Text(
              '${t('STORE_FORM.PAYMENT_CUSTOMER_BALANCE')}: ${Format.rupee(customer.currentBalance)}'
              ' · ${t('STORE_FORM.ORDERS_COUNT')}: ${customer.totalOrders}',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _notes,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: t('STORE_FORM.CUSTOMER_NOTES'),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _loyalty,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: t('STORE_FORM.LOYALTY_POINTS'),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.tonal(
              onPressed: busy ? null : _save,
              child: Text(t('STORE_FORM.EDIT_CUSTOMER')),
            ),
            if (customer.currentBalance > 0) ...<Widget>[
              const SizedBox(height: 20),
              Text(
                t('STORE_FORM.PAYMENT_COLLECT_DUES'),
                style: theme.textTheme.titleMedium,
              ),
              Text(
                t('STORE_FORM.PAYMENT_CUSTOMER_SETTLEMENT_HELP'),
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _amount,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: t('STORE_FORM.PAYMENT_AMOUNT'),
                ),
              ),
              const SizedBox(height: 8),
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
                onChanged: busy
                    ? null
                    : (String? value) {
                        if (value == null) return;
                        setState(() => _method = value);
                      },
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: busy ? null : _collect,
                child: Text(t('STORE_FORM.PAYMENT_ADD_CUSTOMER')),
              ),
            ],
            if (_error != null) ...<Widget>[
              const SizedBox(height: 8),
              Text(
                _error!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.error,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
