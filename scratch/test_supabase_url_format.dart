import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  final client = SupabaseClient('https://myproject.supabase.co', 'dummyKey');
  final storage = client.storage.from('attachments');
  final publicUrl = storage.getPublicUrl('workspace/123/Checklist.pdf');
  print('Public URL: "$publicUrl"');
}
