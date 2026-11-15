import 'package:flutter/material.dart';

import '../../../core/brand.dart';
import '../../../core/theme.dart';

/// Status accents for returns list cards / filter chips.
Color returnStatusAccent(String status) {
  switch (status.trim().toLowerCase()) {
    case 'pending':
      return const Color(0xFFE67E22);
    case 'inspection':
      return const Color(0xFF2F6FED);
    case 'approved':
      return const Color(0xFF0F9F6E);
    case 'completed':
      return Brand.themeColor;
    case 'rejected':
      return AppTheme.error;
    default:
      return Brand.themeColor;
  }
}

Color returnStatusWash(String status) {
  switch (status.trim().toLowerCase()) {
    case 'pending':
      return const Color(0xFFFFF7ED);
    case 'inspection':
      return const Color(0xFFEFF6FF);
    case 'approved':
      return const Color(0xFFECFDF5);
    case 'completed':
      return const Color(0xFFEDF8F5);
    case 'rejected':
      return const Color(0xFFFEF2F2);
    default:
      return Colors.white;
  }
}

Color returnStatusBorder(String status) {
  return returnStatusAccent(status).withValues(alpha: 0.22);
}

IconData returnStatusIcon(String status) {
  switch (status.trim().toLowerCase()) {
    case 'pending':
      return Icons.schedule_rounded;
    case 'inspection':
      return Icons.search_rounded;
    case 'approved':
      return Icons.verified_outlined;
    case 'completed':
      return Icons.check_circle_outline_rounded;
    case 'rejected':
      return Icons.cancel_outlined;
    default:
      return Icons.assignment_return_outlined;
  }
}
