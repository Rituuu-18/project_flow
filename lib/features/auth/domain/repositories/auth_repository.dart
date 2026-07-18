import 'package:supabase_flutter/supabase_flutter.dart';

abstract class AuthRepository {
  /// Stream of authentication state changes.
  Stream<AuthState> get authStateChanges;

  /// Returns the current user if logged in, otherwise null.
  User? get currentUser;

  /// Sign in with email and password.
  Future<AuthResponse> signIn({required String email, required String password});

  /// Sign up with email and password.
  Future<AuthResponse> signUp({required String email, required String password, String? firstName, String? lastName});

  /// Sign out the current user.
  Future<void> signOut();

  /// Send password reset email.
  Future<void> resetPasswordForEmail(String email);

  /// Update the current user's password.
  Future<UserResponse> updatePassword(String newPassword);
}
