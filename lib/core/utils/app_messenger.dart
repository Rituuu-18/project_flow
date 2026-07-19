import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Root messenger so snackbars survive route changes (login redirects, etc.).
final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

enum AppNoticeKind { info, success, error }

/// User-facing toast helpers with clear auth / backend messaging.
class AppMessenger {
  AppMessenger._();

  static void show(
    String message, {
    AppNoticeKind kind = AppNoticeKind.info,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    final messenger = rootScaffoldMessengerKey.currentState;
    if (messenger == null) return;

    final background = switch (kind) {
      AppNoticeKind.success => const Color(0xFF1B7A4E),
      AppNoticeKind.error => const Color(0xFFB42318),
      AppNoticeKind.info => null,
    };

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: background,
          duration: Duration(seconds: kind == AppNoticeKind.error ? 5 : 3),
          action: actionLabel != null && onAction != null
              ? SnackBarAction(
                  label: actionLabel,
                  textColor: Colors.white,
                  onPressed: onAction,
                )
              : null,
        ),
      );
  }

  static void info(String message) =>
      show(message, kind: AppNoticeKind.info);

  static void success(String message) =>
      show(message, kind: AppNoticeKind.success);

  static void error(String message) =>
      show(message, kind: AppNoticeKind.error);

  static void authRequired({VoidCallback? onSignIn}) {
    show(
      'You need to sign in before creating or saving reviews.',
      kind: AppNoticeKind.error,
      actionLabel: onSignIn != null ? 'Sign in' : null,
      onAction: onSignIn,
    );
  }

  /// Turns repository / Supabase failures into short readable copy.
  static String describeError(Object err) {
    final raw = err.toString();

    if (err is AuthException) {
      return _friendlyAuth(err.message);
    }
    if (err is PostgrestException) {
      if (err.code == '42501') {
        return 'Permission denied. Sign in again, then retry.';
      }
      return err.message.isNotEmpty
          ? err.message
          : 'Database request failed.';
    }

    final lower = raw.toLowerCase();
    if (lower.contains('user not authenticated') ||
        lower.contains('not authenticated')) {
      return 'You are not signed in. Please sign in and try again.';
    }
    if (lower.contains('invalid login credentials')) {
      return 'Wrong email or password. Check your credentials and try again.';
    }
    if (lower.contains('email not confirmed')) {
      return 'Confirm your email before signing in, or ask an admin to verify your account.';
    }
    if (lower.contains('failed (auth)') ||
        lower.contains('failed (postgrest')) {
      return raw.replaceFirst(RegExp(r'^Exception:\s*'), '');
    }

    return raw.replaceFirst(RegExp(r'^Exception:\s*'), '');
  }

  static String _friendlyAuth(String message) {
    final lower = message.toLowerCase();
    if (lower.contains('invalid login credentials')) {
      return 'Wrong email or password. Check your credentials and try again.';
    }
    if (lower.contains('email not confirmed')) {
      return 'Confirm your email before signing in, or ask an admin to verify your account.';
    }
    if (lower.contains('user already registered')) {
      return 'An account with this email already exists. Sign in instead.';
    }
    return message;
  }

  static void fromError(Object err, {String? prefix}) {
    final message = describeError(err);
    final text = prefix == null ? message : '$prefix $message';
    error(text);
  }

  static bool isAuthError(Object err) {
    final message = describeError(err).toLowerCase();
    return message.contains('not signed in') ||
        message.contains('not authenticated') ||
        message.contains('sign in') ||
        message.contains('permission denied') ||
        message.contains('failed (auth)');
  }
}
