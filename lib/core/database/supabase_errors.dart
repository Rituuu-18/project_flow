import 'package:supabase_flutter/supabase_flutter.dart';

/// Wraps Supabase/PostgREST failures with a clearer message for callers.
Future<T> supabaseCall<T>(
  Future<T> Function() action, {
  required String operation,
}) async {
  try {
    return await action();
  } on AuthException catch (e) {
    throw Exception('$operation failed (auth): ${e.message}');
  } on PostgrestException catch (e) {
    final code = e.code ?? 'unknown';
    throw Exception('$operation failed (postgrest $code): ${e.message}');
  } catch (e) {
    throw Exception('$operation failed: $e');
  }
}
