import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/i18n.dart';
import '../../../core/routes.dart';
import 'staff_app_bar.dart';

/// Empty staff destination until its feature step lands.
class StaffStubPage extends ConsumerWidget {
  const StaffStubPage({
    super.key,
    required this.titleKey,
    this.showBackToPos = false,
  });

  final String titleKey;
  final bool showBackToPos;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(localeProvider);
    return Scaffold(
      appBar: StaffAppBar(
        leading: showBackToPos
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.go(Routes.staffToday),
              )
            : null,
        automaticallyImplyLeading: false,
        title: t(titleKey),
      ),
      body: const SizedBox.expand(),
    );
  }
}
