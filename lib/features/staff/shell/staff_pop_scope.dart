import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/i18n.dart';
import '../../../core/routes.dart';

/// Staff shell home tab index (Today / dashboard).
const int staffHomeTabIndex = 0;

/// More tab index in the staff shell.
const int staffMoreTabIndex = 4;

void goStaffHome(BuildContext context) {
  context.go(Routes.staffToday);
}

void goStaffMore(BuildContext context) {
  context.go(Routes.staffMore);
}

/// AppBar / system back: pop if possible, else [fallback].
void staffBack(
  BuildContext context, {
  String fallback = Routes.staffMore,
}) {
  final router = GoRouter.of(context);
  if (router.canPop()) {
    router.pop();
    return;
  }
  context.go(fallback);
}

/// Off-shell staff pages: system back pops nested routes, else [fallback].
class StaffPopToHome extends StatelessWidget {
  const StaffPopToHome({
    super.key,
    required this.child,
    this.fallback = Routes.staffMore,
  });

  final Widget child;

  /// Where to land when there is no stack entry (usually More).
  final String fallback;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (didPop) return;
        staffBack(context, fallback: fallback);
      },
      child: child,
    );
  }
}

/// Tab shell: nested pop → other tab to home → double-back exits.
class StaffShellPopScope extends StatefulWidget {
  const StaffShellPopScope({
    super.key,
    required this.navigationShell,
    required this.child,
  });

  final StatefulNavigationShell navigationShell;
  final Widget child;

  @override
  State<StaffShellPopScope> createState() => _StaffShellPopScopeState();
}

class _StaffShellPopScopeState extends State<StaffShellPopScope> {
  static const _exitWindow = Duration(seconds: 2);
  DateTime? _lastExitAt;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (didPop) return;
        final router = GoRouter.of(context);
        if (router.canPop()) {
          router.pop();
          return;
        }
        final shell = widget.navigationShell;
        if (shell.currentIndex != staffHomeTabIndex) {
          shell.goBranch(staffHomeTabIndex);
          return;
        }
        final now = DateTime.now();
        final last = _lastExitAt;
        if (last == null || now.difference(last) > _exitWindow) {
          _lastExitAt = now;
          final messenger = ScaffoldMessenger.maybeOf(context);
          messenger?.hideCurrentSnackBar();
          messenger?.showSnackBar(
            SnackBar(content: Text(t('CHROME.PRESS_BACK_AGAIN'))),
          );
          return;
        }
        SystemNavigator.pop();
      },
      child: widget.child,
    );
  }
}
