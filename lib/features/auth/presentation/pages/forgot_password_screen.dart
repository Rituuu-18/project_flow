import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:engineering_werk/core/utils/app_messenger.dart';
import 'package:engineering_werk/core/localization/locale_provider.dart';
import 'package:engineering_werk/features/auth/presentation/providers/auth_provider.dart';
import 'package:engineering_werk/features/auth/presentation/widgets/auth_layout.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _isSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendResetLink() async {
    final t = ref.read(localeProvider.notifier).t;
    if (!_formKey.currentState!.validate()) {
      AppMessenger.error(t('enter_valid_email_reset'));
      return;
    }

    setState(() => _isLoading = true);
    try {
      await ref.read(authRepositoryProvider).resetPasswordForEmail(
            _emailController.text.trim(),
          );
      if (mounted) setState(() => _isSent = true);
      AppMessenger.success(
        t('reset_link_sent'),
      );
    } on AuthException catch (e) {
      AppMessenger.error(AppMessenger.describeError(e));
    } catch (e) {
      AppMessenger.fromError(e, prefix: t('could_not_send_reset_email'));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(localeProvider);
    final t = ref.read(localeProvider.notifier).t;

    return AuthLayout(
      child: _isSent
          ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.mark_email_read, size: 64, color: Colors.green),
                const SizedBox(height: 24),
                Text(
                  t('check_inbox_title'),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Text(
                  t('check_inbox_message', {'email': _emailController.text}),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton(
                    onPressed: () => context.go('/login'),
                    child: Text(t('back_to_sign_in')),
                  ),
                ),
              ],
            )
          : Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  IconButton(
                    alignment: Alignment.centerLeft,
                    padding: EdgeInsets.zero,
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => context.go('/login'),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    t('reset_password_title'),
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    t('reset_password_subtitle'),
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 32),
                  TextFormField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: t('email_label'),
                      prefixIcon: const Icon(Icons.email_outlined),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _sendResetLink(),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return t('please_enter_email');
                      }
                      if (!value.contains('@')) {
                        return t('please_enter_valid_email');
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    height: 52,
                    child: FilledButton(
                      onPressed: _isLoading ? null : _sendResetLink,
                      child: _isLoading
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : Text(t('send_reset_link'), style: const TextStyle(fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
