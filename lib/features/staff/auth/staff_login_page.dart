import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/brand.dart';
import '../../../core/i18n.dart';
import '../../../core/routes.dart';
import '../../../core/theme.dart';
import 'staff_auth_shell.dart';
import 'staff_session.dart';

class StaffLoginPage extends ConsumerStatefulWidget {
  const StaffLoginPage({super.key});

  @override
  ConsumerState<StaffLoginPage> createState() => _StaffLoginPageState();
}

class _StaffLoginPageState extends ConsumerState<StaffLoginPage> {
  static const _bgAsset = 'assets/images/med_login_bg.webp';

  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  var _busy = false;
  var _obscure = true;
  String? _error;
  String? _info;
  var _resumeChecked = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(localeProvider);
    final session = ref.watch(staffSessionProvider);
    final theme = Theme.of(context);
    final size = MediaQuery.sizeOf(context);

    if (!_resumeChecked && session.ready && session.isSignedIn) {
      _resumeChecked = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.go(staffHomePath(session.storeUser));
      });
    }

    final artGap = (size.height * 0.18).clamp(96.0, 200.0);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          Positioned.fill(
            child: Image.asset(
              _bgAsset,
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
              filterQuality: FilterQuality.medium,
            ),
          ),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_rounded),
                    tooltip: t('AUTH_BACK_CUSTOMER'),
                    onPressed: () => context.go(Routes.location),
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(28, 0, 28, 28),
                    children: <Widget>[
                      const SizedBox(height: 4),
                      Text(
                        Brand.appName,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: Brand.themeColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 28,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        t('STORE_LOGIN_TAGLINE'),
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppTheme.ink.withValues(alpha: 0.45),
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                      SizedBox(height: artGap),
                      Text(
                        t('STORE_LOGIN_TITLE'),
                        textAlign: TextAlign.center,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: AppTheme.ink,
                          fontWeight: FontWeight.w700,
                          fontSize: 26,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        t('STORE_LOGIN_SUBTITLE'),
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppTheme.ink.withValues(alpha: 0.55),
                          fontSize: 15,
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
                            if (_info != null) ...<Widget>[
                              _InfoBanner(message: _info!),
                              const SizedBox(height: 16),
                            ],
                            TextFormField(
                              controller: _email,
                              keyboardType: TextInputType.emailAddress,
                              autofillHints: const <String>[
                                AutofillHints.email,
                              ],
                              textInputAction: TextInputAction.next,
                              style: theme.textTheme.bodyLarge,
                              decoration: _fieldDecoration(
                                hint: t('AUTH_EMAIL_LABEL'),
                                prefix: Icons.mail_outline_rounded,
                              ),
                              validator: _validateEmail,
                            ),
                            const SizedBox(height: 14),
                            TextFormField(
                              controller: _password,
                              obscureText: _obscure,
                              autofillHints: const <String>[
                                AutofillHints.password,
                              ],
                              textInputAction: TextInputAction.done,
                              onFieldSubmitted: (_) => _submit(),
                              style: theme.textTheme.bodyLarge,
                              decoration: _fieldDecoration(
                                hint: t('AUTH_PASSWORD_LABEL'),
                                prefix: Icons.lock_outline_rounded,
                                suffix: IconButton(
                                  onPressed: () =>
                                      setState(() => _obscure = !_obscure),
                                  icon: Icon(
                                    _obscure
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                    color: AppTheme.ink.withValues(alpha: 0.4),
                                  ),
                                ),
                              ),
                              validator: (String? value) {
                                if (value == null || value.isEmpty) {
                                  return t('AUTH_REQUIRED');
                                }
                                return null;
                              },
                            ),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: _busy ? null : _forgotPassword,
                                style: TextButton.styleFrom(
                                  foregroundColor: Brand.themeColor,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                    vertical: 8,
                                  ),
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: Text(
                                  t('AUTH_FORGOT_PASSWORD'),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              height: AppTheme.chargeHeight,
                              child: FilledButton(
                                onPressed: _busy ? null : _submit,
                                style: AppTheme.charge.copyWith(
                                  shape: const WidgetStatePropertyAll(
                                    RoundedRectangleBorder(
                                      borderRadius: BorderRadius.all(
                                        Radius.circular(14),
                                      ),
                                    ),
                                  ),
                                ),
                                child: _busy
                                    ? Text(t('AUTH_SIGNING_IN'))
                                    : Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: <Widget>[
                                          const Icon(
                                            Icons.login_rounded,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 10),
                                          Text(t('STORE_SIGN_IN')),
                                        ],
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),
                      StaffAuthFooterLink(
                        message: t('STORE_NO_ACCOUNT'),
                        linkLabel: t('STORE_CREATE_ONE'),
                        onTap: () => context.go(Routes.staffSignup),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _fieldDecoration({
    required String hint,
    required IconData prefix,
    Widget? suffix,
  }) {
    final border = OutlineInputBorder(
      borderRadius: const BorderRadius.all(Radius.circular(14)),
      borderSide: BorderSide(
        color: AppTheme.hairlineColor.withValues(alpha: 0.9),
        width: AppTheme.hairline,
      ),
    );

    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: AppTheme.ink.withValues(alpha: 0.38),
        fontWeight: FontWeight.w400,
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      prefixIcon: Icon(
        prefix,
        color: AppTheme.ink.withValues(alpha: 0.38),
        size: 22,
      ),
      suffixIcon: suffix,
      border: border,
      enabledBorder: border,
      focusedBorder: OutlineInputBorder(
        borderRadius: const BorderRadius.all(Radius.circular(14)),
        borderSide: const BorderSide(
          color: Brand.themeColor,
          width: AppTheme.hairline,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: const BorderRadius.all(Radius.circular(14)),
        borderSide: const BorderSide(
          color: AppTheme.error,
          width: AppTheme.hairline,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: const BorderRadius.all(Radius.circular(14)),
        borderSide: const BorderSide(
          color: AppTheme.error,
          width: AppTheme.hairline,
        ),
      ),
    );
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return t('AUTH_REQUIRED');
    if (!_looksLikeEmail(email)) return t('AUTH_EMAIL_INVALID');
    return null;
  }

  bool _looksLikeEmail(String value) {
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value);
  }

  Future<void> _forgotPassword() async {
    setState(() {
      _error = null;
      _info = null;
    });

    final email = _email.text.trim();
    if (!_looksLikeEmail(email)) {
      setState(() => _error = t('AUTH_EMAIL_INVALID'));
      return;
    }

    setState(() => _busy = true);
    try {
      await ref.read(staffSessionProvider.notifier).resetPassword(email: email);
      if (!mounted) return;
      setState(() => _info = t('AUTH_RESET_SENT'));
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

  Future<void> _submit() async {
    setState(() {
      _error = null;
      _info = null;
    });
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _busy = true);
    try {
      final storeUser = await ref.read(staffSessionProvider.notifier).signIn(
            email: _email.text,
            password: _password.text,
          );
      if (!mounted) return;
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

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: AppTheme.borderRadius,
        border: Border.all(
          color: Brand.themeColor.withValues(alpha: 0.35),
        ),
        color: Brand.themeColor.withValues(alpha: 0.06),
      ),
      child: Text(
        message,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: Brand.themeColor,
        ),
      ),
    );
  }
}
