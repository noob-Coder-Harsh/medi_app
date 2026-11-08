import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/brand.dart';
import '../../../core/format.dart';
import '../../../core/i18n.dart';
import '../../../core/packaging.dart';
import '../../../core/theme.dart';
import 'pos_cart_controller.dart';
import 'pos_product.dart';

Future<void> showPosQtySheet(BuildContext context, PosProduct product) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: Brand.themeBackground,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (BuildContext sheet) {
      return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(sheet).bottom,
        ),
        child: PosQtySheet(product: product),
      );
    },
  );
}

class PosQtySheet extends ConsumerStatefulWidget {
  const PosQtySheet({super.key, required this.product});

  final PosProduct product;

  @override
  ConsumerState<PosQtySheet> createState() => _PosQtySheetState();
}

class _PosQtySheetState extends ConsumerState<PosQtySheet> {
  static const List<int> _quickCounts = <int>[1, 3, 5, 10];
  static const Color _mint = Color(0xFFE6F4F1);
  static const Color _label = Color(0xFF64748B);
  static const Color _value = Color(0xFF0F172A);

  late final TextEditingController _qtyController;
  var _ready = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_ready) return;
    _ready = true;
    final existing = ref
        .read(posCartProvider.notifier)
        .quantityOf(widget.product.storeProductId);
    final initial = existing > 0
        ? existing
        : getPosAddQuantity(widget.product.packaging);
    _qtyController = TextEditingController(text: '$initial');
  }

  @override
  void dispose() {
    if (_ready) _qtyController.dispose();
    super.dispose();
  }

  int get _step => getSaleStepQuantity(
    widget.product.salePolicy,
    widget.product.packaging,
  );

  double get _quantity {
    final parsed = double.tryParse(_qtyController.text.trim());
    if (parsed == null || !parsed.isFinite || parsed < 0) return 0;
    return parsed;
  }

  bool get _updating =>
      ref
          .read(posCartProvider.notifier)
          .quantityOf(widget.product.storeProductId) >
      0;

  void _setQuantity(num value) {
    final next = value.isFinite ? value.floor().clamp(1, 1 << 30) : 1;
    _qtyController.text = '$next';
    _qtyController.selection = TextSelection.collapsed(
      offset: _qtyController.text.length,
    );
    setState(() {});
  }

  void _bump({required bool increase}) {
    final current = _quantity < 1 ? _step.toDouble() : _quantity;
    final next = increase ? current + _step : current - _step;
    if (next < 1) return;
    final stock = widget.product.stockCount;
    if (increase && stock > 0 && next > stock) {
      _setQuantity(stock);
      return;
    }
    _setQuantity(next);
  }

  String _packSubtitle(PackagingInfo packaging) {
    if (!hasRetailPack(packaging)) return formatPosPackMeta(packaging);
    final packLabel = getPrimaryPackTypeLabel(packaging.primaryPackType);
    return '1 $packLabel (${formatPosPackMeta(packaging)})';
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(localeProvider);
    final theme = Theme.of(context);
    final product = widget.product;
    final packaging = product.packaging;
    final listedPrice = hasRetailPack(packaging)
        ? calculatePackPrice(product.unitPrice, packaging)
        : product.unitPrice;
    final qty = _quantity;
    final line = lineAmount(product.unitPrice, qty);
    final overStock = qty > product.stockCount;
    final display = convertBaseToPackDisplay(qty, packaging);
    final count = qty.floor();
    final actionLabel = _updating
        ? '${t('STORE_FORM.POS_UPDATE_SALE')} ($count)'
        : '${t('STORE_FORM.POS_ADD_TO_SALE')} ($count)';
    final selectedQuick = _quickCounts.contains(count) ? count : null;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            _ProductHeader(
              product: product,
              packSubtitle: _packSubtitle(packaging),
              listedPrice: listedPrice,
              overStock: overStock,
              theme: theme,
            ),
            const SizedBox(height: 16),
            const Divider(height: 1, color: AppTheme.hairlineColor),
            const SizedBox(height: 16),
            Text(
              t('STORE_FORM.POS_SELECT_QUANTITY'),
              style: theme.textTheme.titleSmall?.copyWith(
                color: _value,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: <Widget>[
                _CircleStepperButton(
                  icon: Icons.remove,
                  onPressed: qty <= 1 ? null : () => _bump(increase: false),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppTheme.hairlineColor,
                        width: AppTheme.hairline,
                      ),
                    ),
                    child: Column(
                      children: <Widget>[
                        TextField(
                          controller: _qtyController,
                          textAlign: TextAlign.center,
                          keyboardType: TextInputType.number,
                          inputFormatters: <TextInputFormatter>[
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(6),
                          ],
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: _value,
                            height: 1.1,
                          ),
                          decoration: const InputDecoration(
                            isDense: true,
                            filled: false,
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          display.display,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: _label,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                _CircleStepperButton(
                  icon: Icons.add,
                  onPressed: () => _bump(increase: true),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: _quickCounts.map((int value) {
                final selected = selectedQuick == value;
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: value == _quickCounts.last ? 0 : 8,
                    ),
                    child: _QuickChip(
                      label: '$value',
                      selected: selected,
                      onTap: () => _setQuantity(value),
                    ),
                  ),
                );
              }).toList(growable: false),
            ),
            if (overStock) ...<Widget>[
              const SizedBox(height: 12),
              Text(
                t('STORE_FORM.POS_VALIDATION_STOCK'),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.error,
                ),
              ),
            ],
            const SizedBox(height: 16),
            const Divider(height: 1, color: AppTheme.hairlineColor),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                color: _mint,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: <Widget>[
                  const Icon(
                    Icons.calculate_outlined,
                    size: 20,
                    color: Brand.themeColor,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      t('STORE_FORM.POS_TOTAL_AMOUNT'),
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: _value,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    Format.rupee(line),
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Brand.themeColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: AppTheme.chargeHeight,
              child: FilledButton.icon(
                onPressed: overStock || qty < 1
                    ? null
                    : () {
                        ref
                            .read(posCartProvider.notifier)
                            .putProduct(product, qty);
                        Navigator.of(context).pop();
                      },
                style: AppTheme.charge.copyWith(
                  shape: const WidgetStatePropertyAll(
                    StadiumBorder(),
                  ),
                ),
                icon: const Icon(Icons.add_shopping_cart_outlined, size: 20),
                label: Text(actionLabel),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductHeader extends StatelessWidget {
  const _ProductHeader({
    required this.product,
    required this.packSubtitle,
    required this.listedPrice,
    required this.overStock,
    required this.theme,
  });

  final PosProduct product;
  final String packSubtitle;
  final double listedPrice;
  final bool overStock;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _ProductThumb(imageUrl: product.imageUrl, name: product.name),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                product.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: _PosQtySheetState._value,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                packSubtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: _PosQtySheetState._label,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _PosQtySheetState._mint,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Icon(
                      Icons.inventory_2_outlined,
                      size: 14,
                      color: overStock ? AppTheme.error : Brand.themeColor,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${t('STORE_FORM.POS_IN_STOCK')}: ${Format.stock(product.stockCount)}',
                      style: TextStyle(
                        color: overStock ? AppTheme.error : Brand.themeColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                Format.rupee(listedPrice),
                style: theme.textTheme.titleLarge?.copyWith(
                  color: Brand.themeColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProductThumb extends StatelessWidget {
  const _ProductThumb({required this.imageUrl, required this.name});

  final String? imageUrl;
  final String name;

  @override
  Widget build(BuildContext context) {
    final url = imageUrl?.trim() ?? '';
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppTheme.hairlineColor,
          width: AppTheme.hairline,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: url.isEmpty
          ? _initials()
          : CachedNetworkImage(
              imageUrl: url,
              fit: BoxFit.contain,
              errorWidget: (BuildContext context, String _, Object __) {
                return _initials();
              },
            ),
    );
  }

  Widget _initials() {
    final trimmed = name.trim();
    final letters = trimmed.isEmpty
        ? '?'
        : trimmed.substring(0, trimmed.length >= 2 ? 2 : 1);
    return Center(
      child: Text(
        letters.toUpperCase(),
        style: const TextStyle(
          color: Brand.themeColor,
          fontWeight: FontWeight.w700,
          fontSize: 18,
        ),
      ),
    );
  }
}

class _CircleStepperButton extends StatelessWidget {
  const _CircleStepperButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: Ink(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: enabled
                ? const RadialGradient(
                    colors: <Color>[
                      Colors.white,
                      _PosQtySheetState._mint,
                    ],
                  )
                : null,
            color: enabled ? null : AppTheme.hairlineColor.withValues(alpha: 0.45),
            border: Border.all(
              color: enabled
                  ? Brand.themeColor.withValues(alpha: 0.18)
                  : AppTheme.hairlineColor,
              width: AppTheme.hairline,
            ),
          ),
          child: Icon(
            icon,
            size: 24,
            color: enabled
                ? Brand.themeColor
                : AppTheme.ink.withValues(alpha: 0.35),
          ),
        ),
      ),
    );
  }
}

class _QuickChip extends StatelessWidget {
  const _QuickChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? Brand.themeColor : Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: selected
                ? null
                : Border.all(
                    color: AppTheme.hairlineColor,
                    width: AppTheme.hairline,
                  ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : _PosQtySheetState._value,
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
        ),
      ),
    );
  }
}
