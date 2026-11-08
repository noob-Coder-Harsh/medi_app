import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/i18n.dart';
import '../../../core/routes.dart';
import '../../../data/supabase_client.dart';
import '../auth/staff_session.dart';
import 'staff_bottom_nav.dart';
import 'staff_pop_scope.dart';
import 'staff_theme.dart';

/// Staff tabs: Today · POS · Catalog · Orders · More.
/// Not reachable from customer bottom nav.
class StaffShell extends ConsumerStatefulWidget {
  const StaffShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  ConsumerState<StaffShell> createState() => _StaffShellState();
}

class _StaffShellState extends ConsumerState<StaffShell> {
  var _gateChecked = false;

  @override
  Widget build(BuildContext context) {
    ref.watch(localeProvider);
    final session = ref.watch(staffSessionProvider);

    if (!_gateChecked && session.ready) {
      _gateChecked = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !AppSupabase.isReady) return;
        if (!session.isSignedIn) {
          context.go(Routes.staffLogin);
          return;
        }
        if (!session.hasStore) {
          context.go(Routes.staffOnboarding);
        }
      });
    }

    final shell = widget.navigationShell;
    return Theme(
      data: buildStaffTheme(Theme.of(context)),
      child: StaffShellPopScope(
        navigationShell: shell,
        child: Scaffold(
          body: shell,
          bottomNavigationBar: StaffBottomNav(
            selectedIndex: shell.currentIndex,
            onDestinationSelected: (int index) {
              shell.goBranch(
                index,
                initialLocation: index == shell.currentIndex,
              );
            },
          ),
        ),
      ),
    );
  }
}
