import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'i18n.dart';
import 'medi_app_bar.dart';

/// Dummy page for unbuilt routes. Not a real feature screen.
class PlaceholderPage extends ConsumerWidget {
  const PlaceholderPage({
    super.key,
    this.titleKey,
    this.title,
    this.detail,
  });

  final String? titleKey;
  final String? title;
  final String? detail;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(localeProvider);
    final heading = titleKey != null ? t(titleKey!) : (title ?? '');
    return Scaffold(
      appBar: MediAppBar(titleText: heading),
      body: detail == null
          ? const SizedBox.expand()
          : Center(child: Text(detail!, textAlign: TextAlign.center)),
    );
  }
}
