import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/format.dart';
import '../../../core/i18n.dart';
import '../../../core/theme.dart';
import '../../../data/models/staff_books.dart';
import '../shell/staff_app_bar.dart';
import '../shell/staff_pop_scope.dart';
import 'suppliers_controller.dart';

class SuppliersPage extends ConsumerStatefulWidget {
  const SuppliersPage({super.key});

  @override
  ConsumerState<SuppliersPage> createState() => _SuppliersPageState();
}

class _SuppliersPageState extends ConsumerState<SuppliersPage> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _edit([StaffSupplier? existing]) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (BuildContext context) => _SupplierEditor(existing: existing),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(localeProvider);
    final state = ref.watch(suppliersProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: StaffAppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => staffBack(context),
        ),
        title: t('STORE_FORM.SUPPLIERS_TITLE'),
        actions: <Widget>[
          StaffAppBarAction.refresh(
            onPressed: () => ref.read(suppliersProvider.notifier).refresh(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: state.busy ? null : () => _edit(),
        icon: const Icon(Icons.add),
        label: Text(t('STORE_FORM.ADD_SUPPLIER')),
      ),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _search,
              onChanged: (String value) =>
                  ref.read(suppliersProvider.notifier).setQuery(value),
              decoration: InputDecoration(
                hintText: t('STORE_FORM.SEARCH_SUPPLIERS'),
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
                    ? Center(child: Text(t('STORE_FORM.SUPPLIERS_NO_RESULTS')))
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
                              title: Text(item.name),
                              subtitle: Text(
                                '${item.phone ?? t('STORE_FORM.NOT_PROVIDED')} · '
                                '${t('STORE_FORM.SUPPLIER_CURRENT_BALANCE')} ${Format.rupee(item.currentBalance)}'
                                '${item.isActive ? '' : ' · ${t('STORE_FORM.SUPPLIER_STATUS_INACTIVE')}'}',
                              ),
                              onTap: () => _edit(item),
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

class _SupplierEditor extends ConsumerStatefulWidget {
  const _SupplierEditor({this.existing});

  final StaffSupplier? existing;

  @override
  ConsumerState<_SupplierEditor> createState() => _SupplierEditorState();
}

class _SupplierEditorState extends ConsumerState<_SupplierEditor> {
  late final TextEditingController _name =
      TextEditingController(text: widget.existing?.name ?? '');
  late final TextEditingController _contact =
      TextEditingController(text: widget.existing?.contactPerson ?? '');
  late final TextEditingController _phone =
      TextEditingController(text: widget.existing?.phone ?? '');
  late final TextEditingController _notes =
      TextEditingController(text: widget.existing?.notes ?? '');
  late final TextEditingController _opening = TextEditingController(
    text: widget.existing == null
        ? '0'
        : _trim(widget.existing!.openingBalance),
  );
  late final TextEditingController _settle = TextEditingController();
  String _method = 'cash';
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _contact.dispose();
    _phone.dispose();
    _notes.dispose();
    _opening.dispose();
    _settle.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _error = null);
    if (_name.text.trim().isEmpty) {
      setState(() => _error = t('STORE_FORM.SUPPLIER_NAME'));
      return;
    }
    final error = await ref.read(suppliersProvider.notifier).save(
          SaveSupplierInput(
            name: _name.text,
            contactPerson: _contact.text.trim().isEmpty
                ? null
                : _contact.text.trim(),
            phone: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
            notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
            openingBalance: widget.existing == null
                ? double.tryParse(_opening.text.trim())
                : null,
          ),
          supplierId: widget.existing?.id,
        );
    if (!mounted) return;
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    Navigator.pop(context);
  }

  Future<void> _toggleActive() async {
    final existing = widget.existing;
    if (existing == null) return;
    final error = await ref.read(suppliersProvider.notifier).setActive(
          existing.id,
          !existing.isActive,
        );
    if (!mounted) return;
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    Navigator.pop(context);
  }

  Future<void> _settleBalance() async {
    final existing = widget.existing;
    if (existing == null) return;
    setState(() => _error = null);
    final amount = double.tryParse(_settle.text.trim());
    if (amount == null || amount <= 0) {
      setState(() => _error = t('STORE_FORM.PAYMENT_AMOUNT'));
      return;
    }
    if (amount > existing.currentBalance) {
      setState(
        () => _error = t('STORE_FORM.PAYMENT_SETTLEMENT_EXCEEDS_BALANCE'),
      );
      return;
    }
    final error = await ref.read(suppliersProvider.notifier).settle(
          supplierId: existing.id,
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
    final busy = ref.watch(suppliersProvider).busy;
    final theme = Theme.of(context);
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    final existing = widget.existing;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 16 + bottom),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              existing == null
                  ? t('STORE_FORM.ADD_SUPPLIER')
                  : t('STORE_FORM.EDIT_SUPPLIER'),
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _name,
              decoration: InputDecoration(
                labelText: t('STORE_FORM.SUPPLIER_NAME'),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _contact,
              decoration: InputDecoration(
                labelText: t('STORE_FORM.SUPPLIER_CONTACT_PERSON'),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: t('STORE_FORM.SUPPLIER_PHONE'),
              ),
            ),
            if (existing == null) ...<Widget>[
              const SizedBox(height: 12),
              TextField(
                controller: _opening,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: t('STORE_FORM.SUPPLIER_OPENING_BALANCE'),
                ),
              ),
            ],
            const SizedBox(height: 12),
            TextField(
              controller: _notes,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: t('STORE_FORM.SUPPLIER_NOTES'),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: busy ? null : _save,
              child: Text(
                existing == null
                    ? t('STORE_FORM.ADD_SUPPLIER')
                    : t('CONFIRM'),
              ),
            ),
            if (existing != null) ...<Widget>[
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: busy ? null : _toggleActive,
                child: Text(
                  existing.isActive
                      ? t('STORE_FORM.SUPPLIER_DEACTIVATE')
                      : t('STORE_FORM.SUPPLIER_ACTIVATE'),
                ),
              ),
              if (existing.currentBalance > 0) ...<Widget>[
                const SizedBox(height: 20),
                Text(
                  t('STORE_FORM.PAYMENT_ADD_SUPPLIER'),
                  style: theme.textTheme.titleMedium,
                ),
                Text(
                  '${t('STORE_FORM.SUPPLIER_CURRENT_BALANCE')}: ${Format.rupee(existing.currentBalance)}',
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _settle,
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
                FilledButton.tonal(
                  onPressed: busy ? null : _settleBalance,
                  child: Text(t('STORE_FORM.PAYMENT_ADD_SUPPLIER')),
                ),
              ],
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

  String _trim(num value) {
    if (value % 1 == 0) return value.toInt().toString();
    return value.toStringAsFixed(2);
  }
}
