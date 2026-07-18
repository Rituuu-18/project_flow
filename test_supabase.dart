import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  await dotenv.load(fileName: '.env');
  final url = dotenv.env['SUPABASE_URL']!;
  final key = dotenv.env['SUPABASE_ANON_KEY']!;
  
  await Supabase.initialize(url: url, anonKey: key);
  
  final client = Supabase.instance.client;
  try {
    final response = await client
        .from('design_reviews')
        .select('*, sub_steps(*), stakeholders(*)')
        .order('created_at', ascending: false);
    
    print('Response: $response');
  } catch (e, st) {
    print('Error: $e');
    print(st);
  }
}
