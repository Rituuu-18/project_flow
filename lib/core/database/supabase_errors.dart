import 'package:supabase_flutter/supabase_flutter.dart';

/// Wraps Supabase/PostgREST/Storage failures with a clearer message for callers.
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
  } on StorageException catch (e) {
    final status = e.statusCode ?? '';
    final authLike = status == '401' ||
        status == '403' ||
        e.message.toLowerCase().contains('not authorized') ||
        e.message.toLowerCase().contains('unauthorized') ||
        e.message.toLowerCase().contains('permission');
    if (authLike) {
      throw Exception(
        '$operation failed (auth): not signed in or permission denied. ${e.message}',
      );
    }
    throw Exception(
      '$operation failed (storage${status.isEmpty ? '' : ' $status'}): ${e.message}',
    );
  } catch (e) {
    throw Exception('$operation failed: $e');
  }
}
