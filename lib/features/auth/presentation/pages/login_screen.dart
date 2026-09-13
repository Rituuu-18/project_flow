import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:engineering_werk/core/utils/app_messenger.dart';
import 'package:engineering_werk/core/localization/locale_provider.dart';
import 'package:engineering_werk/features/auth/presentation/providers/auth_provider.dart';
import 'package:engineering_werk/features/auth/presentation/widgets/auth_layout.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _shownAuthReason = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_shownAuthReason) return;
    final reason = GoRouterState.of(context).uri.queryParameters['reason'];
    if (reason == 'auth') {
      _shownAuthReason = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final t = ref.read(localeProvider.notifier).t;
        AppMessenger.info(
          t('please_sign_in_to_open'),
        );
      });
    }
  }

  Future<void> _signIn() async {
    final t = ref.read(localeProvider.notifier).t;
    if (!_formKey.currentState!.validate()) {
      AppMessenger.error(t('enter_valid_email_password_to_continue'));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final response = await ref.read(authRepositoryProvider).signIn(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );
      if (response.session == null) {
        throw const AuthException(
          'Sign-in succeeded but no session was created. '
          'Confirm your email or contact an admin.',
        );
      }
      AppMessenger.success(t('signed_in_successfully'));
      if (mounted) {
        context.go('/');
      }
    } on AuthException catch (e) {
      AppMessenger.error(AppMessenger.describeError(e));
    } catch (e) {
      AppMessenger.fromError(e, prefix: 'Sign-in failed.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(localeProvider);
    final t = ref.read(localeProvider.notifier).t;

    return AuthLayout(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              t('login_title'),
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              t('login_subtitle'),
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 32),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: t('email_label'),
                prefixIcon: const Icon(Icons.email_outlined),
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty || !val.contains('@')) {
                  return t('enter_valid_email');
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _signIn(),
              decoration: InputDecoration(
                labelText: t('password_label'),
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() => _obscurePassword = !_obscurePassword);
                  },
                ),
              ),
              validator: (val) {
                if (val == null || val.isEmpty) return t('enter_password');
                return null;
              },
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => context.go('/forgot-password'),
                child: Text(t('forgot_password')),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 52,
              child: FilledButton(
                onPressed: _isLoading ? null : _signIn,
                child: _isLoading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : Text(t('sign_in_action'), style: const TextStyle(fontSize: 16)),
              ),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  t('no_account_text'),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                TextButton(
                  onPressed: () => context.go('/register'),
                  child: Text(t('register_here')),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
