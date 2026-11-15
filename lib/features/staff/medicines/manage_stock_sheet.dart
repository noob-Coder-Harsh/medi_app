import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/brand.dart';
import '../../../core/i18n.dart';
import '../../../core/theme.dart';
import '../../../data/models/listing.dart';
import '../../../data/rpc/staff_write_rpc.dart';
import '../inventory/inventory_detail_controller.dart';

Future<bool> showManageStockSheet(
  BuildContext context, {
  required String storeProductId,
  required ListingCard product,
}) async {
  final saved = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    builder: (BuildContext context) {
      return ManageStockSheet(
        storeProductId: storeProductId,
        product: product,
      );
    },
  );
  return saved == true;
}

class ManageStockSheet extends ConsumerStatefulWidget {
  const ManageStockSheet({
    super.key,
    required this.storeProductId,
    required this.product,
  });

  final String storeProductId;
  final ListingCard product;

  @override
  ConsumerState<ManageStockSheet> createState() => _ManageStockSheetState();
}

class _ManageStockSheetState extends ConsumerState<ManageStockSheet> {
  final _formKey = GlobalKey<FormState>();
  final _quantity = TextEditingController(text: '1');
  final _batchNo = TextEditingController();
  final _purchase = TextEditingController();
  final _mrp = TextEditingController();
  final _selling = TextEditingController();
  final _notes = TextEditingController();

  var _direction = 'add';
  var _reason = 'purchase';
  String? _error;

  static const _addReasons = <String>[
    'purchase',
    'opening',
    'return_in',
    'adjustment',
  ];
  static const _reduceReasons = <String>[
    'damage',
    'expiry',
    'theft',
    'adjustment',
  ];

  static const EdgeInsets _densePad = EdgeInsets.symmetric(
    horizontal: 12,
    vertical: 12,
  );

  @override
  void initState() {
    super.initState();
    if (widget.product.mrp != null) {
      _mrp.text = _trimNum(widget.product.mrp!);
    }
    if (widget.product.sellingPrice != null) {
      _selling.text = _trimNum(widget.product.sellingPrice!);
    }
    _batchNo.text =
        'B-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
  }

  @override
  void dispose() {
    _quantity.dispose();
    _batchNo.dispose();
    _purchase.dispose();
    _mrp.dispose();
    _selling.dispose();
    _notes.dispose();
    super.dispose();
  }

  String _trimNum(double value) {
    if (value == value.roundToDouble()) return '${value.round()}';
    return value.toStringAsFixed(2);
  }

  List<String> get _reasons =>
      _direction == 'add' ? _addReasons : _reduceReasons;

  String _reasonLabel(String reason) {
    switch (reason) {
      case 'purchase':
        return t('STORE_FORM.STOCK_REASON_PURCHASE');
      case 'opening':
        return t('STORE_FORM.STOCK_REASON_OPENING');
      case 'return_in':
        return t('STORE_FORM.STOCK_REASON_RETURN_IN');
      case 'damage':
        return t('STORE_FORM.STOCK_REASON_DAMAGE');
      case 'expiry':
        return t('STORE_FORM.STOCK_REASON_EXPIRY');
      case 'theft':
        return t('STORE_FORM.STOCK_REASON_THEFT');
      default:
        return t('STORE_FORM.STOCK_REASON_ADJUSTMENT');
    }
  }

  InputDecoration _deco({
    String? hint,
    Widget? prefixIcon,
    Widget? suffixIcon,
    Color? fillColor,
  }) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      isDense: true,
      filled: fillColor != null,
      fillColor: fillColor,
      contentPadding: _densePad,
      hintStyle: TextStyle(
        fontSize: 13,
        color: AppTheme.ink.withValues(alpha: 0.38),
      ),
    );
  }

  Future<void> _submit() async {
    setState(() => _error = null);
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final qty = int.tryParse(_quantity.text.trim());
    if (qty == null || qty <= 0) {
      setState(() => _error = t('STORE_FORM.QUANTITY'));
      return;
    }

    double? mrp;
    double? selling;
    double? purchase;
    if (_direction == 'add') {
      mrp = double.tryParse(_mrp.text.trim());
      selling = double.tryParse(_selling.text.trim());
      purchase = double.tryParse(_purchase.text.trim()) ?? 0;
      if (mrp == null || selling == null) {
        setState(() => _error = t('STORE_FORM.PRICING_SECTION'));
        return;
      }
    }

    final error = await ref
        .read(inventoryDetailProvider(widget.storeProductId).notifier)
        .adjustStock(
          AdjustStockInput(
            direction: _direction,
            quantity: qty,
            reason: _reason,
            batchNo: _direction == 'add' ? _batchNo.text : null,
            mrp: mrp,
            sellingPrice: selling,
            purchasePrice: purchase,
            notes: _notes.text,
          ),
        );

    if (!mounted) return;
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(localeProvider);
    final theme = Theme.of(context);
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    final busy = ref.watch(inventoryDetailProvider(widget.storeProductId)).busy;
    final isAdd = _direction == 'add';

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Brand.themeColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.inventory_2_outlined,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          t('STORE_FORM.MANAGE_STOCK'),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.product.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppTheme.ink.withValues(alpha: 0.6),
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    SegmentedButton<String>(
                      segments: <ButtonSegment<String>>[
                        ButtonSegment<String>(
                          value: 'add',
                          label: Text(t('STORE_FORM.STOCK_ADD')),
                          icon: const Icon(Icons.add_rounded, size: 18),
                        ),
                        ButtonSegment<String>(
                          value: 'reduce',
                          label: Text(t('STORE_FORM.STOCK_REDUCE')),
                          icon: const Icon(Icons.remove_rounded, size: 18),
                        ),
                      ],
                      selected: <String>{_direction},
                      onSelectionChanged: (Set<String> next) {
                        final value = next.first;
                        setState(() {
                          _direction = value;
                          _reason = _reasons.first;
                        });
                      },
                    ),
                    const SizedBox(height: 14),
                    _Labeled(
                      label: t('STORE_FORM.STOCK_REASON'),
                      child: InputDecorator(
                        decoration: _deco(
                          prefixIcon: const Icon(Icons.flag_outlined),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            isExpanded: true,
                            isDense: true,
                            value: _reason,
                            items: _reasons
                                .map(
                                  (String r) => DropdownMenuItem<String>(
                                    value: r,
                                    child: Text(_reasonLabel(r)),
                                  ),
                                )
                                .toList(growable: false),
                            onChanged: (String? value) {
                              if (value == null) return;
                              setState(() => _reason = value);
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (isAdd)
                      _TwoCol(
                        left: _Labeled(
                          label: t('STORE_FORM.QUANTITY'),
                          required: true,
                          child: TextFormField(
                            controller: _quantity,
                            keyboardType: TextInputType.number,
                            inputFormatters: <TextInputFormatter>[
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            decoration: _deco(
                              prefixIcon:
                                  const Icon(Icons.warehouse_outlined),
                            ),
                            validator: (String? value) {
                              final n = int.tryParse(value?.trim() ?? '');
                              if (n == null || n <= 0) {
                                return t('STORE_FORM.QUANTITY');
                              }
                              return null;
                            },
                          ),
                        ),
                        right: _Labeled(
                          label: t('STORE_FORM.BATCH_NO'),
                          child: TextFormField(
                            controller: _batchNo,
                            decoration: _deco(
                              prefixIcon:
                                  const Icon(Icons.qr_code_2_outlined),
                            ),
                          ),
                        ),
                      )
                    else
                      _Labeled(
                        label: t('STORE_FORM.QUANTITY'),
                        required: true,
                        child: TextFormField(
                          controller: _quantity,
                          keyboardType: TextInputType.number,
                          inputFormatters: <TextInputFormatter>[
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          decoration: _deco(
                            prefixIcon:
                                const Icon(Icons.warehouse_outlined),
                          ),
                          validator: (String? value) {
                            final n = int.tryParse(value?.trim() ?? '');
                            if (n == null || n <= 0) {
                              return t('STORE_FORM.QUANTITY');
                            }
                            return null;
                          },
                        ),
                      ),
                    if (isAdd) ...<Widget>[
                      const SizedBox(height: 12),
                      _Labeled(
                        label: t('STORE_FORM.PURCHASE_PRICE'),
                        child: TextFormField(
                          controller: _purchase,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: _deco(
                            prefixIcon: const Icon(Icons.currency_rupee),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _TwoCol(
                        left: _Labeled(
                          label: t('STORE_FORM.MRP'),
                          required: true,
                          child: TextFormField(
                            controller: _mrp,
                            keyboardType:
                                const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: _deco(
                              prefixIcon: const Icon(Icons.currency_rupee),
                            ),
                            validator: (String? value) {
                              if (!isAdd) return null;
                              if (double.tryParse(value?.trim() ?? '') ==
                                  null) {
                                return t('STORE_FORM.MRP');
                              }
                              return null;
                            },
                          ),
                        ),
                        right: _Labeled(
                          label: t('STORE_FORM.SELLING_PRICE'),
                          required: true,
                          child: TextFormField(
                            controller: _selling,
                            keyboardType:
                                const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: _deco(
                              prefixIcon: const Icon(Icons.currency_rupee),
                              fillColor: const Color(0xFFF0FDFA),
                            ),
                            validator: (String? value) {
                              if (!isAdd) return null;
                              if (double.tryParse(value?.trim() ?? '') ==
                                  null) {
                                return t('STORE_FORM.SELLING_PRICE');
                              }
                              return null;
                            },
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    _Labeled(
                      label: t('STORE_FORM.STOCK_NOTES'),
                      child: TextFormField(
                        controller: _notes,
                        maxLines: 2,
                        decoration: _deco(
                          prefixIcon: const Icon(Icons.notes_outlined),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (_error != null) ...<Widget>[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              SizedBox(
                height: AppTheme.chargeHeight,
                child: FilledButton.icon(
                  onPressed: busy ? null : _submit,
                  icon: busy
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Icon(
                          isAdd ? Icons.add_rounded : Icons.remove_rounded,
                          size: 20,
                        ),
                  label: Text(
                    busy
                        ? t('WRITE_LOADING_SAVE')
                        : t('STORE_FORM.SAVE'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Labeled extends StatelessWidget {
  const _Labeled({
    required this.label,
    required this.child,
    this.required = false,
  });

  final String label;
  final Widget child;
  final bool required;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text.rich(
          TextSpan(
            text: label,
            style: theme.textTheme.labelLarge?.copyWith(
              color: AppTheme.ink.withValues(alpha: 0.72),
              fontWeight: FontWeight.w600,
              fontSize: 12.5,
            ),
            children: required
                ? const <InlineSpan>[
                    TextSpan(
                      text: ' *',
                      style: TextStyle(
                        color: AppTheme.error,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ]
                : null,
          ),
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}

class _TwoCol extends StatelessWidget {
  const _TwoCol({required this.left, required this.right});

  final Widget left;
  final Widget right;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(child: left),
        const SizedBox(width: 10),
        Expanded(child: right),
      ],
    );
  }
}
