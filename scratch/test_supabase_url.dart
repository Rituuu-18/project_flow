import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  // Check SupabaseStorage URL format conceptually
  final client = SupabaseClient('https://example.supabase.co', 'anonKey');
  try {
    final res = await client.storage.from('attachments').createSignedUrl('workspace/123/file.pdf', 60);
    print('Signed URL result: "$res"');
    print('Starts with http: ${res.startsWith('http')}');
  } catch (e) {
    print('Error: $e');
  }
}
