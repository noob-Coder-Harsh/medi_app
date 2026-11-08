import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/format.dart';
import '../../../core/i18n.dart';
import '../../../core/packaging.dart';
import '../../../core/routes.dart';
import '../../../core/theme.dart';
import '../../../data/models/purchase.dart';
import '../shell/staff_app_bar.dart';
import 'purchase_product_picker.dart';
import 'purchases_controller.dart';

class PurchaseFormPage extends ConsumerStatefulWidget {
  const PurchaseFormPage({super.key});

  @override
  ConsumerState<PurchaseFormPage> createState() => _PurchaseFormPageState();
}

class _PurchaseFormPageState extends ConsumerState<PurchaseFormPage> {
  late final TextEditingController _invoice;
  late final TextEditingController _date;
  late final TextEditingController _paid;

  @override
  void initState() {
    super.initState();
    final form = ref.read(purchaseFormProvider);
    _invoice = TextEditingController(text: form.invoiceNumber);
    _date = TextEditingController(text: form.invoiceDate);
    _paid = TextEditingController(text: _trim(form.paidAmount));
  }

  @override
  void dispose() {
    _invoice.dispose();
    _date.dispose();
    _paid.dispose();
    super.dispose();
  }

  Future<void> _addProduct() async {
    final product = await showPurchaseProductPicker(context);
    if (product == null || !mounted) return;
    await _editLine(
      PurchaseFormLine(
        key: DateTime.now().microsecondsSinceEpoch.toString(),
        storeProductId: product.storeProductId,
        productName: product.name,
        batchNumber:
            'B-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
        quantity: getPosAddQuantity(product.packaging),
        purchasePrice: product.unitPrice > 0 ? product.unitPrice : 1,
        mrp: product.mrp ?? (product.unitPrice > 0 ? product.unitPrice : 1),
        sellingPrice: product.unitPrice > 0 ? product.unitPrice : 1,
        baseUnit: product.baseUnit,
        primaryPackType: product.primaryPackType,
        primaryPackQuantity: product.primaryPackQuantity,
        currentStock: product.stockCount,
      ),
      isNew: true,
    );
  }

  Future<void> _editLine(PurchaseFormLine line, {required bool isNew}) async {
    final edited = await showModalBottomSheet<PurchaseFormLine>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (BuildContext context) => _LineEditorSheet(line: line),
    );
    if (edited == null || !mounted) return;
    final notifier = ref.read(purchaseFormProvider.notifier);
    if (isNew) {
      notifier.addLine(edited);
    } else {
      notifier.updateLine(edited);
    }
    _syncPaidField();
  }

  void _syncPaidField() {
    final paid = ref.read(purchaseFormProvider).paidAmount;
    if (_paid.text != _trim(paid)) {
      _paid.text = _trim(paid);
    }
  }

  Future<void> _quickSupplier() async {
    final nameController = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(t('STORE_FORM.ADD_SUPPLIER')),
          content: TextField(
            controller: nameController,
            autofocus: true,
            decoration: InputDecoration(
              labelText: t('STORE_FORM.SUPPLIER_NAME'),
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(t('CANCEL')),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.pop(context, nameController.text.trim()),
              child: Text(t('CONFIRM')),
            ),
          ],
        );
      },
    );
    nameController.dispose();
    if (name == null || name.isEmpty || !mounted) return;
    final error =
        await ref.read(purchaseFormProvider.notifier).createSupplierQuick(name);
    if (!mounted) return;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error == 'AUTH_SUPABASE_MISSING'
                ? t('AUTH_SUPABASE_MISSING')
                : error,
          ),
        ),
      );
    }
  }

  Future<void> _submit() async {
    final error =
        await ref.read(purchaseFormProvider.notifier).submitCompleted();
    if (!mounted) return;
    if (error != null) {
      final message = error.startsWith('STORE_FORM.')
          ? t(error)
          : error == 'AUTH_SUPABASE_MISSING'
              ? t('AUTH_SUPABASE_MISSING')
              : error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(t('STORE_FORM.PURCHASE_STATUS_COMPLETED'))),
    );
    context.go(Routes.staffPurchases);
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(localeProvider);
    final form = ref.watch(purchaseFormProvider);
    final theme = Theme.of(context);
    final totals = form.totals;

    ref.listen(purchaseFormProvider, (PurchaseFormState? prev, PurchaseFormState next) {
      if (prev?.paidAmount != next.paidAmount) {
        _syncPaidField();
      }
    });

    return Scaffold(
      appBar: StaffAppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(Routes.staffPurchases),
        ),
        title: t('STORE_FORM.ADD_PURCHASE'),
      ),
      body: form.loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        // ignore: deprecated_member_use
                        value: form.supplierId,
                        decoration: InputDecoration(
                          labelText: t('STORE_FORM.PURCHASE_SUPPLIER'),
                        ),
                        items: form.suppliers
                            .map(
                              (SupplierOption s) => DropdownMenuItem<String>(
                                value: s.id,
                                child: Text(s.name),
                              ),
                            )
                            .toList(growable: false),
                        onChanged: form.busy
                            ? null
                            : (String? value) => ref
                                .read(purchaseFormProvider.notifier)
                                .setSupplier(value),
                      ),
                    ),
                    IconButton(
                      tooltip: t('STORE_FORM.ADD_SUPPLIER'),
                      onPressed: form.busy ? null : _quickSupplier,
                      icon: const Icon(Icons.person_add_alt_1),
                    ),
                  ],
                ),
                if (form.suppliers.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      t('STORE_FORM.PURCHASE_SELECT_SUPPLIER'),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.error,
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
                TextField(
                  controller: _invoice,
                  onChanged: (String value) => ref
                      .read(purchaseFormProvider.notifier)
                      .setInvoiceNumber(value),
                  decoration: InputDecoration(
                    labelText: t('STORE_FORM.PURCHASE_INVOICE_NUMBER'),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _date,
                  onChanged: (String value) => ref
                      .read(purchaseFormProvider.notifier)
                      .setInvoiceDate(value),
                  decoration: InputDecoration(
                    labelText: t('STORE_FORM.PURCHASE_INVOICE_DATE'),
                    hintText: 'YYYY-MM-DD',
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        t('STORE_FORM.PURCHASE_ITEMS'),
                        style: theme.textTheme.titleMedium,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: form.busy ? null : _addProduct,
                      icon: const Icon(Icons.add),
                      label: Text(t('STORE_FORM.PURCHASE_ADD_PRODUCT')),
                    ),
                  ],
                ),
                if (form.lines.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      t('STORE_FORM.PURCHASE_ADD_PRODUCT'),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface
                            .withValues(alpha: 0.65),
                      ),
                    ),
                  )
                else
                  ...form.lines.map(
                    (PurchaseFormLine line) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _LineTile(
                        line: line,
                        onEdit: () => _editLine(line, isNew: false),
                        onRemove: () {
                          ref
                              .read(purchaseFormProvider.notifier)
                              .removeLine(line.key);
                          _syncPaidField();
                        },
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                Text(
                  t('STORE_FORM.PURCHASE_SUMMARY'),
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                _SummaryRow(
                  label: t('STORE_FORM.PURCHASE_SUBTOTAL'),
                  value: Format.rupee(totals.subtotal),
                ),
                _SummaryRow(
                  label: t('STORE_FORM.PURCHASE_GRAND_TOTAL'),
                  value: Format.rupee(totals.grandTotal),
                  bold: true,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  // ignore: deprecated_member_use
                  value: form.paymentStatus,
                  decoration: InputDecoration(
                    labelText: t('STORE_FORM.PURCHASE_PAYMENT_STATUS'),
                  ),
                  items: <DropdownMenuItem<String>>[
                    DropdownMenuItem(
                      value: 'paid',
                      child: Text(t('STORE_FORM.PURCHASE_PAYMENT_PAID')),
                    ),
                    DropdownMenuItem(
                      value: 'partial',
                      child: Text(t('STORE_FORM.PURCHASE_PAYMENT_PARTIAL')),
                    ),
                    DropdownMenuItem(
                      value: 'pending',
                      child: Text(t('STORE_FORM.PURCHASE_PAYMENT_PENDING')),
                    ),
                  ],
                  onChanged: form.busy
                      ? null
                      : (String? value) {
                          if (value == null) return;
                          ref
                              .read(purchaseFormProvider.notifier)
                              .setPaymentStatus(value);
                          _syncPaidField();
                        },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  // ignore: deprecated_member_use
                  value: form.paymentMethod,
                  decoration: InputDecoration(
                    labelText: t('STORE_FORM.PURCHASE_PAYMENT_METHOD'),
                  ),
                  items: <DropdownMenuItem<String>>[
                    DropdownMenuItem(
                      value: 'cash',
                      child: Text(
                        t('STORE_FORM.PURCHASE_PAYMENT_METHOD_CASH'),
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'upi',
                      child: Text(
                        t('STORE_FORM.PURCHASE_PAYMENT_METHOD_UPI'),
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'bank',
                      child: Text(
                        t('STORE_FORM.PURCHASE_PAYMENT_METHOD_BANK'),
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'credit',
                      child: Text(
                        t('STORE_FORM.PURCHASE_PAYMENT_METHOD_CREDIT'),
                      ),
                    ),
                  ],
                  onChanged: form.busy
                      ? null
                      : (String? value) {
                          if (value == null) return;
                          ref
                              .read(purchaseFormProvider.notifier)
                              .setPaymentMethod(value);
                        },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _paid,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  onChanged: (String value) {
                    final parsed = double.tryParse(value.trim()) ?? 0;
                    ref
                        .read(purchaseFormProvider.notifier)
                        .setPaidAmount(parsed);
                  },
                  decoration: InputDecoration(
                    labelText: t('STORE_FORM.PURCHASE_PAID_AMOUNT'),
                    helperText:
                        '${t('STORE_FORM.PURCHASE_DUE_AMOUNT')}: ${Format.rupee((totals.grandTotal - form.paidAmount).clamp(0, totals.grandTotal))}',
                  ),
                ),
                if (form.error != null) ...<Widget>[
                  const SizedBox(height: 8),
                  Text(
                    form.error!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.error,
                    ),
                  ),
                ],
              ],
            ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: FilledButton(
            onPressed: form.busy ? null : _submit,
            child: form.busy
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(t('STORE_FORM.PURCHASE_COMPLETE')),
          ),
        ),
      ),
    );
  }

  String _trim(num value) {
    if (value % 1 == 0) return value.toInt().toString();
    return value.toStringAsFixed(2);
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.bold = false,
  });

  final String label;
  final String value;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    final style = bold
        ? Theme.of(context).textTheme.titleSmall
        : Theme.of(context).textTheme.bodyMedium;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: <Widget>[
          Expanded(child: Text(label, style: style)),
          Text(value, style: style),
        ],
      ),
    );
  }
}

class _LineTile extends StatelessWidget {
  const _LineTile({
    required this.line,
    required this.onEdit,
    required this.onRemove,
  });

  final PurchaseFormLine line;
  final VoidCallback onEdit;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: AppTheme.borderRadius,
        side: const BorderSide(color: AppTheme.hairlineColor),
      ),
      child: ListTile(
        title: Text(line.productName),
        subtitle: Text(
          '${line.batchNumber} · qty ${line.quantity} · ${Format.rupee(line.purchasePrice)}',
        ),
        onTap: onEdit,
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline),
          onPressed: onRemove,
        ),
      ),
    );
  }
}

class _LineEditorSheet extends StatefulWidget {
  const _LineEditorSheet({required this.line});

  final PurchaseFormLine line;

  @override
  State<_LineEditorSheet> createState() => _LineEditorSheetState();
}

class _LineEditorSheetState extends State<_LineEditorSheet> {
  late final TextEditingController _batch;
  late final TextEditingController _packs;
  late final TextEditingController _units;
  late final TextEditingController _purchase;
  late final TextEditingController _mrp;
  late final TextEditingController _selling;
  late final TextEditingController _expires;
  late bool _usePacks;
  String? _error;

  PackagingInfo get _packaging => PackagingInfo(
        baseUnit: widget.line.baseUnit,
        primaryPackType: widget.line.primaryPackType,
        primaryPackQuantity: widget.line.primaryPackQuantity,
      );

  @override
  void initState() {
    super.initState();
    _usePacks = hasRetailPack(_packaging);
    _batch = TextEditingController(text: widget.line.batchNumber);
    final packQty = normalizePackQuantity(_packaging.primaryPackQuantity);
    if (_usePacks && packQty > 1 && widget.line.quantity % packQty == 0) {
      _packs = TextEditingController(
        text: (widget.line.quantity ~/ packQty).toString(),
      );
      _units = TextEditingController(text: '${widget.line.quantity}');
    } else {
      _usePacks = false;
      _packs = TextEditingController(text: '1');
      _units = TextEditingController(text: '${widget.line.quantity}');
    }
    _purchase = TextEditingController(text: _trim(widget.line.purchasePrice));
    _mrp = TextEditingController(text: _trim(widget.line.mrp));
    _selling = TextEditingController(text: _trim(widget.line.sellingPrice));
    _expires = TextEditingController(text: widget.line.expiresAt);
  }

  @override
  void dispose() {
    _batch.dispose();
    _packs.dispose();
    _units.dispose();
    _purchase.dispose();
    _mrp.dispose();
    _selling.dispose();
    _expires.dispose();
    super.dispose();
  }

  int? _qty() {
    if (_usePacks) {
      final packs = int.tryParse(_packs.text.trim());
      if (packs == null || packs < 1) return null;
      return convertPackToBaseQuantity(packs, _packaging);
    }
    return int.tryParse(_units.text.trim());
  }

  void _save() {
    setState(() => _error = null);
    final qty = _qty();
    final purchase = double.tryParse(_purchase.text.trim());
    final mrp = double.tryParse(_mrp.text.trim());
    final selling = double.tryParse(_selling.text.trim());
    if (_batch.text.trim().isEmpty) {
      setState(() => _error = t('STORE_FORM.PURCHASE_BATCH_NUMBER'));
      return;
    }
    if (qty == null || qty < 1) {
      setState(() => _error = t('STORE_FORM.QUANTITY'));
      return;
    }
    if (purchase == null || purchase <= 0 || mrp == null || mrp <= 0 || selling == null || selling <= 0) {
      setState(() => _error = t('STORE_FORM.PURCHASE_ITEMS'));
      return;
    }
    if (selling > mrp) {
      setState(() => _error = 'Selling price cannot exceed MRP');
      return;
    }
    Navigator.of(context).pop(
      PurchaseFormLine(
        key: widget.line.key,
        storeProductId: widget.line.storeProductId,
        productName: widget.line.productName,
        batchNumber: _batch.text,
        quantity: qty,
        purchasePrice: purchase,
        mrp: mrp,
        sellingPrice: selling,
        baseUnit: widget.line.baseUnit,
        primaryPackType: widget.line.primaryPackType,
        primaryPackQuantity: widget.line.primaryPackQuantity,
        expiresAt: _expires.text.trim(),
        currentStock: widget.line.currentStock,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    final qty = _qty();

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 16 + bottom),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(widget.line.productName, style: theme.textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(
              t('STORE_FORM.STOCK_CALC_DESC'),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _batch,
              decoration: InputDecoration(
                labelText: t('STORE_FORM.PURCHASE_BATCH_NUMBER'),
              ),
            ),
            const SizedBox(height: 12),
            if (hasRetailPack(_packaging))
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(t('STORE_FORM.PURCHASE_PACKS')),
                value: _usePacks,
                onChanged: (bool value) => setState(() => _usePacks = value),
              ),
            if (_usePacks)
              TextField(
                controller: _packs,
                keyboardType: TextInputType.number,
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.digitsOnly,
                ],
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  labelText: t('STORE_FORM.PURCHASE_PACKS'),
                  helperText: qty == null
                      ? null
                      : '= $qty ${getBaseUnitLabel(_packaging.baseUnit)}',
                ),
              )
            else
              TextField(
                controller: _units,
                keyboardType: TextInputType.number,
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.digitsOnly,
                ],
                decoration: InputDecoration(
                  labelText: t('STORE_FORM.QUANTITY'),
                ),
              ),
            const SizedBox(height: 12),
            TextField(
              controller: _purchase,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: t('STORE_FORM.PURCHASE_PRICE'),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _mrp,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(labelText: t('STORE_FORM.MRP')),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _selling,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: t('STORE_FORM.SELLING_PRICE'),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _expires,
              decoration: InputDecoration(
                labelText: t('STORE_FORM.EXPIRES_AT'),
                hintText: 'YYYY-MM-DD',
              ),
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
              onPressed: _save,
              child: Text(t('CONFIRM')),
            ),
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
