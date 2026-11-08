import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/format.dart';
import '../../../core/i18n.dart';
import '../../../core/routes.dart';
import '../../../core/theme.dart';
import '../../../data/models/staff_return.dart';
import '../shell/staff_app_bar.dart';
import 'returns_controller.dart';

class ReturnDetailPage extends ConsumerWidget {
  const ReturnDetailPage({super.key, required this.returnId});

  final String returnId;

  String _statusLabel(String status) {
    final key = staffReturnStatusLabelKey(status);
    final label = t(key);
    return label == key ? status : label;
  }

  String _refundLabel(String status) {
    final key = staffRefundStatusLabelKey(status);
    final label = t(key);
    return label == key ? status : label;
  }

  Future<void> _approve(BuildContext context, WidgetRef ref) async {
    final error =
        await ref.read(returnDetailProvider(returnId).notifier).approve();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error ?? t('STORE_FORM.RETURN_APPROVE')),
      ),
    );
  }

  Future<void> _reject(BuildContext context, WidgetRef ref) async {
    final error =
        await ref.read(returnDetailProvider(returnId).notifier).reject();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error ?? t('STORE_FORM.RETURN_REJECT')),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(localeProvider);
    final state = ref.watch(returnDetailProvider(returnId));
    final theme = Theme.of(context);
    final detail = state.detail;

    return Scaffold(
      appBar: StaffAppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(Routes.staffReturns),
        ),
        title: detail == null
            ? t('STORE_FORM.RETURN_VIEW')
            : detail.orderNumber == null
                ? t('STORE_FORM.RETURN_VIEW')
                : '${t('STORE_FORM.RETURN_ORDER')} #${detail.orderNumber}',
        actions: <Widget>[
          StaffAppBarAction.refresh(
            enabled: !state.busy,
            onPressed: () => ref
                .read(returnDetailProvider(returnId).notifier)
                .refresh(),
          ),
        ],
      ),
      body: state.loading && detail == null
          ? const Center(child: CircularProgressIndicator())
          : detail == null
              ? Center(
                  child: Text(
                    state.error ?? t('STORE_FORM.RETURN_NOT_FOUND'),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                  children: <Widget>[
                    Material(
                      color: theme.colorScheme.surface,
                      shape: RoundedRectangleBorder(
                        borderRadius: AppTheme.borderRadius,
                        side: const BorderSide(color: AppTheme.hairlineColor),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              t('STORE_FORM.RETURN_SUMMARY'),
                              style: theme.textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            Text(detail.customerName ?? detail.customerPhone),
                            if (detail.customerPhone.isNotEmpty)
                              Text(
                                detail.customerPhone,
                                style: theme.textTheme.bodySmall,
                              ),
                            const SizedBox(height: 8),
                            Text(
                              '${_statusLabel(detail.status)} · '
                              '${t('STORE_FORM.RETURN_REFUND_STATUS')}: '
                              '${_refundLabel(detail.refundStatus)}',
                              style: theme.textTheme.labelLarge,
                            ),
                            Text(
                              '${t('STORE_FORM.RETURN_REFUND_AMOUNT')}: '
                              '${Format.rupee(detail.refundAmount)}',
                            ),
                            if (detail.reason != null &&
                                detail.reason!.isNotEmpty)
                              Text(
                                '${t('STORE_FORM.RETURN_REASON')}: ${detail.reason}',
                              ),
                          ],
                        ),
                      ),
                    ),
                    if (state.error != null) ...<Widget>[
                      const SizedBox(height: 8),
                      Text(
                        state.error!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppTheme.error,
                        ),
                      ),
                    ],
                    if (detail.canApprove || detail.canReject) ...<Widget>[
                      const SizedBox(height: 16),
                      if (detail.canApprove)
                        FilledButton(
                          onPressed: state.busy
                              ? null
                              : () => _approve(context, ref),
                          child: Text(t('STORE_FORM.RETURN_APPROVE')),
                        ),
                      if (detail.canReject) ...<Widget>[
                        const SizedBox(height: 8),
                        OutlinedButton(
                          onPressed: state.busy
                              ? null
                              : () => _reject(context, ref),
                          child: Text(t('STORE_FORM.RETURN_REJECT')),
                        ),
                      ],
                      if (state.busy)
                        const Padding(
                          padding: EdgeInsets.only(top: 12),
                          child: LinearProgressIndicator(),
                        ),
                    ],
                    const SizedBox(height: 16),
                    Text(
                      t('STORE_FORM.RETURN_ITEMS'),
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    ...detail.items.map(
                      (StaffReturnLine item) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Material(
                          color: theme.colorScheme.surface,
                          shape: RoundedRectangleBorder(
                            borderRadius: AppTheme.borderRadius,
                            side: const BorderSide(
                              color: AppTheme.hairlineColor,
                            ),
                          ),
                          child: ListTile(
                            title: Text(item.productName),
                            subtitle: Text(
                              'qty ${item.quantity} · ${item.condition} · '
                              '${item.restockAction}',
                            ),
                            trailing: Text(Format.rupee(item.refundAmount)),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}
