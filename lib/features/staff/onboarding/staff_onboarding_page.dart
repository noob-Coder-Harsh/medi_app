import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/brand.dart';
import '../../../core/i18n.dart';
import '../../../core/routes.dart';
import '../../../core/medi_app_bar.dart';
import '../../../core/theme.dart';
import '../../../data/supabase_client.dart';
import '../auth/staff_auth_shell.dart';
import '../auth/staff_session.dart';
import 'create_store_input.dart';
import 'store_onboarding_service.dart';

class StaffOnboardingPage extends ConsumerStatefulWidget {
  const StaffOnboardingPage({super.key});

  @override
  ConsumerState<StaffOnboardingPage> createState() =>
      _StaffOnboardingPageState();
}

class _StaffOnboardingPageState extends ConsumerState<StaffOnboardingPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _whatsapp = TextEditingController();
  final _address = TextEditingController();
  final _city = TextEditingController();
  final _state = TextEditingController();
  final _pincode = TextEditingController();

  var _busy = false;
  String? _error;
  var _resumeChecked = false;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _whatsapp.dispose();
    _address.dispose();
    _city.dispose();
    _state.dispose();
    _pincode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(localeProvider);
    final session = ref.watch(staffSessionProvider);

    if (!_resumeChecked && session.ready) {
      _resumeChecked = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !AppSupabase.isReady) return;
        if (!session.isSignedIn) {
          context.go(Routes.staffLogin);
          return;
        }
        if (session.hasStore) {
          context.go(Routes.staffToday);
        }
      });
    }

    return Scaffold(
      appBar: MediAppBar(titleText: Brand.appName),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          children: <Widget>[
            Text(
              t('STORE_PANEL_ONBOARDING_TITLE'),
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              t('STORE_PANEL_ONBOARDING_SUBTITLE'),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.72),
              ),
            ),
            const SizedBox(height: 28),
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  if (_error != null) ...<Widget>[
                    StaffAuthErrorBanner(message: _error!),
                    const SizedBox(height: 16),
                  ],
                  TextFormField(
                    controller: _name,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: t('STAFF.PHARMACY_NAME'),
                    ),
                    validator: (String? value) {
                      if ((value?.trim().length ?? 0) < 2) {
                        return t('AUTH_REQUIRED');
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _phone,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(labelText: t('STAFF.PHONE')),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _whatsapp,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: t('STAFF.WHATSAPP'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _address,
                    textCapitalization: TextCapitalization.sentences,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: t('STOREFRONT.ADDRESS_LINE'),
                    ),
                    validator: (String? value) {
                      if ((value?.trim().length ?? 0) < 3) {
                        return t('STOREFRONT.VALIDATION_ADDRESS_LINE');
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _city,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: t('STOREFRONT.CITY'),
                    ),
                    validator: (String? value) {
                      if ((value?.trim().length ?? 0) < 2) {
                        return t('STOREFRONT.VALIDATION_CITY');
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _state,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: t('STOREFRONT.STATE'),
                    ),
                    validator: (String? value) {
                      if ((value?.trim().length ?? 0) < 2) {
                        return t('STOREFRONT.VALIDATION_STATE');
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _pincode,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _submit(),
                    decoration: InputDecoration(
                      labelText: t('STOREFRONT.PINCODE'),
                    ),
                    validator: (String? value) {
                      if (!RegExp(r'^\d{6}$').hasMatch(value?.trim() ?? '')) {
                        return t('STOREFRONT.VALIDATION_PINCODE');
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _busy ? null : _submit,
                    style: AppTheme.charge,
                    child: Text(
                      _busy
                          ? t('STAFF.ONBOARDING_CREATING')
                          : t('STAFF.ONBOARDING_SUBMIT'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    setState(() => _error = null);
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _busy = true);
    try {
      final storeUser = await ref
          .read(storeOnboardingServiceProvider)
          .createStore(
            CreateStoreInput(
              name: _name.text,
              phone: _phone.text,
              whatsappNumber: _whatsapp.text,
              address: _address.text,
              city: _city.text,
              state: _state.text,
              pincode: _pincode.text.trim(),
            ),
          );
      ref.read(staffSessionProvider.notifier).setStoreUser(storeUser);
      if (!mounted) return;
      context.go(Routes.staffToday);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        final message = '$error';
        _error = message.contains('not configured')
            ? t('AUTH_SUPABASE_MISSING')
            : (message.isEmpty ? t('ERROR_GENERIC') : message);
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}
