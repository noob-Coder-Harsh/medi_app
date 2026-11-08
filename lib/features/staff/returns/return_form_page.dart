import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/format.dart';
import '../../../core/i18n.dart';
import '../../../core/routes.dart';
import '../../../core/theme.dart';
import '../../../data/models/staff_order.dart';
import '../shell/staff_app_bar.dart';
import 'returns_controller.dart';

class ReturnFormPage extends ConsumerStatefulWidget {
  const ReturnFormPage({super.key, this.prefillOrderId});

  final String? prefillOrderId;

  @override
  ConsumerState<ReturnFormPage> createState() => _ReturnFormPageState();
}

class _ReturnFormPageState extends ConsumerState<ReturnFormPage> {
  final _reason = TextEditingController();
  final _notes = TextEditingController();
  final _orderSearch = TextEditingController();
  var _prefillTried = false;

  @override
  void dispose() {
    _reason.dispose();
    _notes.dispose();
    _orderSearch.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(localeProvider);
    final state = ref.watch(returnFormProvider);
    final theme = Theme.of(context);

    final prefill = widget.prefillOrderId;
    if (!_prefillTried &&
        prefill != null &&
        prefill.isNotEmpty &&
        state.orderId == null &&
        !state.loading) {
      _prefillTried = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(returnFormProvider.notifier).selectOrder(prefill);
      });
    }

    return Scaffold(
      appBar: StaffAppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(Routes.staffReturns),
        ),
        title: t('STORE_FORM.ADD_RETURN'),
      ),
      body: state.loading && state.orderDetail == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: <Widget>[
                if (state.error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      _localizeError(state.error!),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.error,
                      ),
                    ),
                  ),
                if (state.orderDetail == null) ...<Widget>[
                  Text(
                    t('STORE_FORM.RETURN_FROM_ORDER'),
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _orderSearch,
                    onChanged: (String value) => ref
                        .read(returnFormProvider.notifier)
                        .setOrderQuery(value),
                    decoration: InputDecoration(
                      hintText: t('STORE_FORM.SEARCH_ORDERS'),
                      prefixIcon: const Icon(Icons.search),
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (state.deliveredOrders.isEmpty)
                    Text(t('STORE_FORM.ORDERS_NO_RESULTS'))
                  else
                    ...state.deliveredOrders.map((StaffOrderListItem order) {
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text('#${order.orderNumber}'),
                        subtitle: Text(
                          '${order.displayCustomer} · ${Format.rupee(order.totalAmount)}',
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => ref
                            .read(returnFormProvider.notifier)
                            .selectOrder(order.id),
                      );
                    }),
                ] else ...<Widget>[
                  Material(
                    color: theme.colorScheme.surface,
                    shape: RoundedRectangleBorder(
                      borderRadius: AppTheme.borderRadius,
                      side: const BorderSide(color: AppTheme.hairlineColor),
                    ),
                    child: ListTile(
                      title: Text(
                        '${t('STORE_FORM.RETURN_FROM_ORDER')} '
                        '#${state.orderDetail!.orderNumber}',
                      ),
                      subtitle: Text(state.orderDetail!.displayCustomer),
                      trailing: TextButton(
                        onPressed: state.busy
                            ? null
                            : () =>
                                ref.read(returnFormProvider.notifier).clearOrder(),
                        child: Text(t('CANCEL')),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    t('STORE_FORM.RETURN_SELECT_ITEMS'),
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    t('STORE_FORM.RETURN_SELECT_HINT'),
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 8),
                  ...state.lines.map((ReturnFormLine line) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Material(
                        color: theme.colorScheme.surface,
                        shape: RoundedRectangleBorder(
                          borderRadius: AppTheme.borderRadius,
                          side: const BorderSide(color: AppTheme.hairlineColor),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              CheckboxListTile(
                                contentPadding: EdgeInsets.zero,
                                value: line.selected,
                                onChanged: state.busy
                                    ? null
                                    : (bool? value) => ref
                                        .read(returnFormProvider.notifier)
                                        .toggleLine(
                                          line.orderItemId,
                                          value ?? false,
                                        ),
                                title: Text(line.productName),
                                subtitle: Text(
                                  '${t('STORE_FORM.RETURN_SOLD_QTY')}: ${line.soldQty}'
                                  ' · ${Format.rupee(line.unitPrice)}',
                                ),
                              ),
                              if (line.selected) ...<Widget>[
                                Row(
                                  children: <Widget>[
                                    Text('${t('STORE_FORM.RETURN_QTY')}:'),
                                    const SizedBox(width: 12),
                                    IconButton(
                                      onPressed: state.busy || line.quantity <= 1
                                          ? null
                                          : () => ref
                                              .read(returnFormProvider.notifier)
                                              .setLineQty(
                                                line.orderItemId,
                                                line.quantity - 1,
                                              ),
                                      icon: const Icon(Icons.remove),
                                    ),
                                    Text('${line.quantity}'),
                                    IconButton(
                                      onPressed: state.busy ||
                                              line.quantity >= line.soldQty
                                          ? null
                                          : () => ref
                                              .read(returnFormProvider.notifier)
                                              .setLineQty(
                                                line.orderItemId,
                                                line.quantity + 1,
                                              ),
                                      icon: const Icon(Icons.add),
                                    ),
                                  ],
                                ),
                                DropdownButtonFormField<String>(
                                  // ignore: deprecated_member_use
                                  value: line.condition,
                                  decoration: InputDecoration(
                                    labelText: t('STORE_FORM.RETURN_CONDITION'),
                                  ),
                                  items: <DropdownMenuItem<String>>[
                                    DropdownMenuItem(
                                      value: 'sealed',
                                      child: Text(
                                        t('STORE_FORM.RETURN_CONDITION_SEALED'),
                                      ),
                                    ),
                                    DropdownMenuItem(
                                      value: 'opened',
                                      child: Text(
                                        t('STORE_FORM.RETURN_CONDITION_OPENED'),
                                      ),
                                    ),
                                    DropdownMenuItem(
                                      value: 'damaged',
                                      child: Text(
                                        t('STORE_FORM.RETURN_CONDITION_DAMAGED'),
                                      ),
                                    ),
                                    DropdownMenuItem(
                                      value: 'expired',
                                      child: Text(
                                        t('STORE_FORM.RETURN_CONDITION_EXPIRED'),
                                      ),
                                    ),
                                  ],
                                  onChanged: state.busy
                                      ? null
                                      : (String? value) {
                                          if (value == null) return;
                                          ref
                                              .read(returnFormProvider.notifier)
                                              .setLineCondition(
                                                line.orderItemId,
                                                value,
                                              );
                                        },
                                ),
                                const SizedBox(height: 8),
                                DropdownButtonFormField<String>(
                                  // ignore: deprecated_member_use
                                  value: line.restockAction,
                                  decoration: InputDecoration(
                                    labelText:
                                        t('STORE_FORM.RETURN_RESTOCK_ACTION'),
                                  ),
                                  items: <DropdownMenuItem<String>>[
                                    DropdownMenuItem(
                                      value: 'restock',
                                      child: Text(t('STORE_FORM.RETURN_RESTOCK')),
                                    ),
                                    DropdownMenuItem(
                                      value: 'dispose',
                                      child: Text(t('STORE_FORM.RETURN_DISPOSE')),
                                    ),
                                    DropdownMenuItem(
                                      value: 'supplier_return',
                                      child: Text(
                                        t('STORE_FORM.RETURN_SUPPLIER_RETURN'),
                                      ),
                                    ),
                                  ],
                                  onChanged: state.busy
                                      ? null
                                      : (String? value) {
                                          if (value == null) return;
                                          ref
                                              .read(returnFormProvider.notifier)
                                              .setLineRestock(
                                                line.orderItemId,
                                                value,
                                              );
                                        },
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _reason,
                    onChanged: (String value) =>
                        ref.read(returnFormProvider.notifier).setReason(value),
                    decoration: InputDecoration(
                      labelText: t('STORE_FORM.RETURN_REASON'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _notes,
                    onChanged: (String value) =>
                        ref.read(returnFormProvider.notifier).setNotes(value),
                    decoration: InputDecoration(
                      labelText: t('STORE_FORM.RETURN_NOTES'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${t('STORE_FORM.RETURN_REFUND_AMOUNT')}: '
                    '${Format.rupee(state.refundEstimate)}',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: state.busy ? null : () => _submit(context),
                    child: state.busy
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(t('STORE_FORM.RETURN_SUBMIT')),
                  ),
                ],
              ],
            ),
    );
  }

  String _localizeError(String raw) {
    if (raw.startsWith('STORE_FORM.')) {
      final label = t(raw);
      return label == raw ? raw : label;
    }
    return raw;
  }

  Future<void> _submit(BuildContext context) async {
    final error = await ref.read(returnFormProvider.notifier).submit();
    if (!context.mounted) return;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_localizeError(error))),
      );
      return;
    }
    final id = ref.read(returnFormProvider).createdReturnId;
    if (id == null || id.isEmpty) return;
    context.go(Routes.staffReturn(id));
  }
}
