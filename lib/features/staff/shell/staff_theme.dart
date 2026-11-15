import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/app_colors.dart';
import '../../../core/brand.dart';
import '../../../core/theme.dart';

/// Staff-scoped theme: imaged AppBars + Google-style bottom nav.
/// Does not change the global customer [AppTheme].
ThemeData buildStaffTheme(ThemeData base) {
  const unselected = AppColors.muted;
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
    // Staff uses custom [StaffBottomNav]; keep M3 NavigationBar quiet if used.
    navigationBarTheme: NavigationBarThemeData(
      elevation: 0,
      shadowColor: Colors.transparent,
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      indicatorColor: Brand.themeColor.withValues(alpha: 0.12),
      height: 64,
      labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
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
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          fontSize: 12.5,
        );
      }),
    ),
  );
}
