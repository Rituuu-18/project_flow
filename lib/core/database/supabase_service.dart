import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Centralised Supabase bootstrap and client accessor.
///
/// Call [SupabaseService.init] once in [main] (after dotenv is loaded).
/// Anywhere else in the app use [SupabaseService.client] to reach the client.
class SupabaseService {
  SupabaseService._();

  static Future<void> init() async {
    final url = dotenv.env['NEXT_PUBLIC_SUPABASE_URL'] ?? '';
    final anonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';

    // Use throw (not assert) so release builds also fail clearly.
    if (url.isEmpty) {
      throw StateError('NEXT_PUBLIC_SUPABASE_URL is missing from .env');
    }
    if (anonKey.isEmpty) {
      throw StateError('SUPABASE_ANON_KEY is missing from .env');
    }

    await Supabase.initialize(
      url: url,
      anonKey: anonKey,
    );
  }

  /// Convenience getter — equivalent to [Supabase.instance.client].
  static SupabaseClient get client => Supabase.instance.client;
}
