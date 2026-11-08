import 'package:flutter/material.dart';

import '../../../core/i18n.dart';
import '../../../core/medi_app_bar.dart';

/// Staff AppBar — branded strip via [MediAppBar].
class StaffAppBar extends StatelessWidget implements PreferredSizeWidget {
  const StaffAppBar({
    super.key,
    required this.title,
    this.actions,
    this.leading,
    this.automaticallyImplyLeading = true,
  });

  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool automaticallyImplyLeading;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return MediAppBar(
      titleText: title,
      actions: actions,
      leading: leading,
      automaticallyImplyLeading: automaticallyImplyLeading,
    );
  }
}

/// Shared AppBar action constructors for staff pages.
abstract final class StaffAppBarAction {
  static Widget refresh({
    required VoidCallback onPressed,
    bool enabled = true,
  }) {
    return IconButton(
      tooltip: t('TODAY.REFRESH'),
      onPressed: enabled ? onPressed : null,
      icon: const Icon(Icons.refresh),
    );
  }

  static Widget filter({
    required VoidCallback onPressed,
    bool active = false,
  }) {
    return IconButton(
      tooltip: t('STORE_FORM.CATALOG_FILTERS_TITLE'),
      onPressed: onPressed,
      icon: Icon(active ? Icons.tune : Icons.tune_outlined),
    );
  }
}
