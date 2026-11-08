import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/i18n.dart';
import '../../../core/routes.dart';
import '../../../core/theme.dart';
import 'staff_auth_shell.dart';
import 'staff_session.dart';

class StaffSignupPage extends ConsumerStatefulWidget {
  const StaffSignupPage({super.key});

  @override
  ConsumerState<StaffSignupPage> createState() => _StaffSignupPageState();
}

class _StaffSignupPageState extends ConsumerState<StaffSignupPage> {
  final _formKey = GlobalKey<FormState>();
  final _fullName = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  var _busy = false;
  var _obscure = true;
  var _obscureConfirm = true;
  String? _error;
  String? _info;
  var _resumeChecked = false;

  @override
  void dispose() {
    _fullName.dispose();
    _email.dispose();
    _phone.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(localeProvider);
    final session = ref.watch(staffSessionProvider);

    if (!_resumeChecked && session.ready && session.isSignedIn) {
      _resumeChecked = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.go(staffHomePath(session.storeUser));
      });
    }

    return StaffAuthShell(
      title: t('STORE_SIGNUP_TITLE'),
      subtitle: t('STORE_SIGNUP_SUBTITLE'),
      footer: StaffAuthFooterLink(
        message: t('STORE_HAS_ACCOUNT'),
        linkLabel: t('STORE_SIGN_IN'),
        onTap: () => context.go(Routes.staffLogin),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            if (_error != null) ...<Widget>[
              StaffAuthErrorBanner(message: _error!),
              const SizedBox(height: 16),
            ],
            if (_info != null) ...<Widget>[
              Text(_info!, style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 16),
            ],
            TextFormField(
              controller: _fullName,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: t('AUTH_FULL_NAME_LABEL'),
              ),
              validator: (String? value) {
                final name = value?.trim() ?? '';
                if (name.length < 2) return t('AUTH_REQUIRED');
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const <String>[AutofillHints.email],
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(labelText: t('AUTH_EMAIL_LABEL')),
              validator: _validateEmail,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(labelText: t('AUTH_PHONE_LABEL')),
              validator: (String? value) {
                final phone = value?.trim() ?? '';
                if (phone.isEmpty) return null;
                if (phone.length < 10 || phone.length > 15) {
                  return t('AUTH_PHONE_INVALID');
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _password,
              obscureText: _obscure,
              autofillHints: const <String>[AutofillHints.newPassword],
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: t('AUTH_PASSWORD_LABEL'),
                suffixIcon: IconButton(
                  onPressed: () => setState(() => _obscure = !_obscure),
                  icon: Icon(
                    _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  ),
                ),
              ),
              validator: (String? value) {
                if (value == null || value.length < 8) {
                  return t('AUTH_PASSWORD_TOO_SHORT');
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _confirm,
              obscureText: _obscureConfirm,
              autofillHints: const <String>[AutofillHints.newPassword],
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _submit(),
              decoration: InputDecoration(
                labelText: t('AUTH_CONFIRM_PASSWORD_LABEL'),
                suffixIcon: IconButton(
                  onPressed: () =>
                      setState(() => _obscureConfirm = !_obscureConfirm),
                  icon: Icon(
                    _obscureConfirm
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                ),
              ),
              validator: (String? value) {
                if (value != _password.text) {
                  return t('AUTH_PASSWORD_MISMATCH');
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _busy ? null : _submit,
              style: AppTheme.charge,
              child: Text(
                _busy ? t('AUTH_CREATING_ACCOUNT') : t('AUTH_CREATE_ACCOUNT'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return t('AUTH_REQUIRED');
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      return t('AUTH_EMAIL_INVALID');
    }
    return null;
  }

  Future<void> _submit() async {
    setState(() {
      _error = null;
      _info = null;
    });
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _busy = true);
    try {
      final storeUser = await ref.read(staffSessionProvider.notifier).signUp(
        email: _email.text,
        password: _password.text,
        fullName: _fullName.text,
        phone: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
      );
      if (!mounted) return;
      if (storeUser == null) {
        setState(() => _info = t('AUTH_CHECK_EMAIL'));
        return;
      }
      context.go(staffHomePath(storeUser));
    } on AuthException catch (error) {
      if (!mounted) return;
      setState(() => _error = error.message);
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
