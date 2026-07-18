import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  await dotenv.load(fileName: '.env');
  final url = dotenv.env['NEXT_PUBLIC_SUPABASE_URL']!;
  final key = dotenv.env['SUPABASE_ANON_KEY']!;
  
  final uri = Uri.parse('$url/rest/v1/design_reviews?select=*,sub_steps(*),stakeholders(*)');
  final response = await http.get(uri, headers: {
    'apikey': key,
    'Authorization': 'Bearer $key',
  });
  
  print('Response status: ${response.statusCode}');
  print('Response body: ${response.body}');
}
