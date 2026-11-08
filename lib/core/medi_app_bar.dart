import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'theme.dart';

/// Default AppBar for any page: [AppTheme.appBarBackgroundAsset] strip + light icons.
class MediAppBar extends StatelessWidget implements PreferredSizeWidget {
  const MediAppBar({
    super.key,
    this.title,
    this.titleText,
    this.actions,
    this.leading,
    this.automaticallyImplyLeading = true,
    this.bottom,
  }) : assert(title != null || titleText != null);

  final Widget? title;
  final String? titleText;
  final List<Widget>? actions;
  final Widget? leading;
  final bool automaticallyImplyLeading;
  final PreferredSizeWidget? bottom;

  @override
  Size get preferredSize => Size.fromHeight(
        kToolbarHeight + (bottom?.preferredSize.height ?? 0),
      );

  @override
  Widget build(BuildContext context) {
    final baseTitle = Theme.of(context).textTheme.titleLarge;
    return AppBar(
      backgroundColor: Colors.transparent,
      foregroundColor: AppTheme.onTeal,
      elevation: 0,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 0,
      flexibleSpace: AppTheme.appBarBackground(),
      systemOverlayStyle: SystemUiOverlayStyle.light,
      iconTheme: const IconThemeData(color: AppTheme.onTeal),
      actionsIconTheme: const IconThemeData(color: AppTheme.onTeal),
      automaticallyImplyLeading: automaticallyImplyLeading,
      leading: leading,
      title: title ??
          Text(
            titleText!,
            style: (baseTitle ?? const TextStyle()).copyWith(
              color: AppTheme.onTeal,
              fontWeight: FontWeight.w700,
            ),
          ),
      titleTextStyle: (baseTitle ?? const TextStyle()).copyWith(
        color: AppTheme.onTeal,
        fontWeight: FontWeight.w700,
      ),
      actions: actions,
      bottom: bottom,
    );
  }
}
