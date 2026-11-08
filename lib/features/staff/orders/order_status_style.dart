import 'package:flutter/material.dart';

import '../../../core/theme.dart';

/// Status accents matched to the orders list mock (360px compact cards).
Color orderStatusAccent(String status) {
  switch (status.trim().toLowerCase()) {
    case 'pending':
      return const Color(0xFFE67E22);
    case 'confirmed':
      return const Color(0xFF2F6FED);
    case 'processing':
      return const Color(0xFF7C3AED);
    case 'ready':
      return const Color(0xFF0F9F6E);
    case 'out_for_delivery':
      return const Color(0xFF0891B2);
    case 'delivered':
      return const Color(0xFF0F766E);
    case 'cancelled':
      return AppTheme.error;
    case 'refunded':
      return const Color(0xFFC2410C);
    case 'draft':
      return const Color(0xFF94A3B8);
    default:
      return const Color(0xFF0F766E);
  }
}

Color orderStatusWash(String status) {
  switch (status.trim().toLowerCase()) {
    case 'pending':
      return const Color(0xFFFFF7ED);
    case 'confirmed':
      return const Color(0xFFEFF6FF);
    case 'processing':
      return const Color(0xFFF5F3FF);
    case 'ready':
      return const Color(0xFFECFDF5);
    case 'out_for_delivery':
      return const Color(0xFFECFEFF);
    case 'delivered':
      return const Color(0xFFEDF8F5);
    case 'cancelled':
      return const Color(0xFFFEF2F2);
    case 'refunded':
      return const Color(0xFFFFF4ED);
    case 'draft':
      return const Color(0xFFF8FAFC);
    default:
      return const Color(0xFFEDF8F5);
  }
}

Color orderStatusBorder(String status) {
  return orderStatusAccent(status).withValues(alpha: 0.22);
}

IconData orderStatusIcon(String status) {
  switch (status.trim().toLowerCase()) {
    case 'pending':
      return Icons.schedule_rounded;
    case 'confirmed':
      return Icons.verified_outlined;
    case 'processing':
      return Icons.local_shipping_outlined;
    case 'ready':
      return Icons.inventory_2_outlined;
    case 'out_for_delivery':
      return Icons.delivery_dining_outlined;
    case 'delivered':
      return Icons.check_circle_outline_rounded;
    case 'cancelled':
      return Icons.cancel_outlined;
    case 'refunded':
      return Icons.history_rounded;
    default:
      return Icons.receipt_long_outlined;
  }
}

IconData orderSourceIcon(String source) {
  switch (source.trim().toLowerCase()) {
    case 'online':
      return Icons.shopping_cart_outlined;
    case 'pos':
      return Icons.storefront_outlined;
    case 'kiosk':
      return Icons.tablet_mac_outlined;
    case 'admin':
      return Icons.admin_panel_settings_outlined;
    default:
      return Icons.storefront_outlined;
  }
}
