import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/brand.dart';
import '../../../core/theme.dart';

/// Staff-scoped theme: imaged AppBars + Google-style bottom nav.
/// Does not change the global customer [AppTheme].
ThemeData buildStaffTheme(ThemeData base) {
  const unselected = Color(0xFF64748B);
  final titleStyle = (base.textTheme.titleLarge ?? const TextStyle()).copyWith(
    color: AppTheme.onTeal,
    fontWeight: FontWeight.w700,
  );

  return base.copyWith(
    scaffoldBackgroundColor: Colors.transparent,
    canvasColor: Colors.transparent,
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: AppTheme.onTeal,
      elevation: 0,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      iconTheme: const IconThemeData(color: AppTheme.onTeal),
      actionsIconTheme: const IconThemeData(color: AppTheme.onTeal),
      titleTextStyle: titleStyle,
    ),
    navigationBarTheme: NavigationBarThemeData(
      elevation: 0,
      shadowColor: Colors.transparent,
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      indicatorColor: Colors.transparent,
      height: 64,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      iconTheme: WidgetStateProperty.resolveWith((Set<WidgetState> states) {
        final selected = states.contains(WidgetState.selected);
        return IconThemeData(
          size: 24,
          color: selected ? Brand.themeColor : unselected,
        );
      }),
      labelTextStyle: WidgetStateProperty.resolveWith((
        Set<WidgetState> states,
      ) {
        final selected = states.contains(WidgetState.selected);
        return (base.textTheme.labelMedium ?? const TextStyle()).copyWith(
          color: selected ? Brand.themeColor : unselected,
          fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
        );
      }),
    ),
  );
}
