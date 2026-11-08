import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/format.dart';
import '../../../core/i18n.dart';
import '../../../core/routes.dart';
import '../../../core/theme.dart';
import '../../../data/models/purchase.dart';
import '../shell/staff_app_bar.dart';
import 'purchases_controller.dart';

class PurchaseDetailPage extends ConsumerWidget {
  const PurchaseDetailPage({super.key, required this.purchaseOrderId});

  final String purchaseOrderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(localeProvider);
    final state = ref.watch(purchaseDetailProvider(purchaseOrderId));
    final theme = Theme.of(context);
    final detail = state.detail;

    return Scaffold(
      appBar: StaffAppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(Routes.staffPurchases),
        ),
        title: detail?.invoiceNumber ?? t('STORE_FORM.VIEW_PURCHASE'),
        actions: <Widget>[
          StaffAppBarAction.refresh(
            onPressed: () => ref
                .read(purchaseDetailProvider(purchaseOrderId).notifier)
                .refresh(),
          ),
        ],
      ),
      body: state.loading && detail == null
          ? const Center(child: CircularProgressIndicator())
          : detail == null
              ? Center(
                  child: Text(state.error ?? t('ERROR_GENERIC')),
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
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
                              detail.invoiceNumber,
                              style: theme.textTheme.titleLarge,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${detail.supplierName} · ${detail.invoiceDate}',
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${_statusLabel(detail.status)} · ${Format.rupee(detail.grandTotal)}',
                              style: theme.textTheme.labelLarge,
                            ),
                            Text(
                              '${t('STORE_FORM.PURCHASE_PAYMENT_STATUS')}: ${_paymentLabel(detail.paymentStatus)}'
                              ' · ${t('STORE_FORM.PURCHASE_PAID_AMOUNT')} ${Format.rupee(detail.paidAmount)}',
                              style: theme.textTheme.bodySmall,
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
                    const SizedBox(height: 16),
                    Text(
                      t('STORE_FORM.PURCHASE_ITEMS'),
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    ...detail.items.map(
                      (PurchaseLineItem item) => Padding(
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
                              '${item.batchNumber} · qty ${Format.stock(item.quantity)}'
                              ' · ${Format.rupee(item.purchasePrice)}'
                              '${item.expiresAt == null || item.expiresAt!.isEmpty ? '' : ' · exp ${item.expiresAt}'}',
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }

  String _statusLabel(String status) {
    return switch (status) {
      'completed' => t('STORE_FORM.PURCHASE_STATUS_COMPLETED'),
      'cancelled' => t('STORE_FORM.PURCHASE_STATUS_CANCELLED'),
      _ => t('STORE_FORM.PURCHASE_STATUS_DRAFT'),
    };
  }

  String _paymentLabel(String status) {
    return switch (status) {
      'paid' => t('STORE_FORM.PURCHASE_PAYMENT_PAID'),
      'partial' => t('STORE_FORM.PURCHASE_PAYMENT_PARTIAL'),
      _ => t('STORE_FORM.PURCHASE_PAYMENT_PENDING'),
    };
  }
}
