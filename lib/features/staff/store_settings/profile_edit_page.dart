import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n.dart';
import '../../../core/routes.dart';
import '../../../core/theme.dart';
import '../shell/staff_app_bar.dart';
import '../shell/staff_pop_scope.dart';
import 'profile_controller.dart';

/// Separate edit form for staff profile (off bottom bar).
class StaffProfileEditPage extends ConsumerStatefulWidget {
  const StaffProfileEditPage({super.key});

  @override
  ConsumerState<StaffProfileEditPage> createState() =>
      _StaffProfileEditPageState();
}

class _StaffProfileEditPageState extends ConsumerState<StaffProfileEditPage> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  String? _boundUserId;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(localeProvider);
    final state = ref.watch(profileSettingsProvider);
    final theme = Theme.of(context);
    final user = state.user;

    if (user != null && _boundUserId != user.id) {
      _boundUserId = user.id;
      _name.text = user.fullName ?? '';
      _phone.text = user.phone ?? '';
    }

    return Scaffold(
      appBar: StaffAppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => staffBack(context, fallback: Routes.staffProfile),
        ),
        title: t('CHROME.EDIT_PROFILE'),
      ),
      body: user == null
          ? Center(child: Text(t('ERROR_UNAUTHORIZED')))
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: <Widget>[
                if (state.error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      state.error!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.error,
                      ),
                    ),
                  ),
                if (user.email != null && user.email!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      user.email!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface
                            .withValues(alpha: 0.65),
                      ),
                    ),
                  ),
                TextField(
                  controller: _name,
                  decoration: InputDecoration(
                    labelText: t('AUTH_FULL_NAME_LABEL'),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: t('AUTH_PHONE_LABEL'),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: AppTheme.touchTarget,
                  child: FilledButton(
                    onPressed: state.busy
                        ? null
                        : () async {
                            final error = await ref
                                .read(profileSettingsProvider.notifier)
                                .save(
                                  fullName: _name.text,
                                  phone: _phone.text,
                                );
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  error ?? t('SUCCESS_PROFILE_UPDATE'),
                                ),
                              ),
                            );
                            if (error == null) {
                              staffBack(
                                context,
                                fallback: Routes.staffProfile,
                              );
                            }
                          },
                    child: state.busy
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(t('WRITE_LOADING_SAVE')),
                  ),
                ),
              ],
            ),
    );
  }
}
