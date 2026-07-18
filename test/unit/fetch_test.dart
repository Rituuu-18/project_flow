import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:engineering_werk/features/reviews/data/repositories/supabase_design_review_repository.dart';

void main() {
  test('Test Fetching and Mapping Design Reviews', () async {
    await dotenv.load(fileName: '.env');
    final url = dotenv.env['NEXT_PUBLIC_SUPABASE_URL']!;
    final key = dotenv.env['SUPABASE_ANON_KEY']!;
    
    await Supabase.initialize(url: url, anonKey: key);
    
    final repo = SupabaseDesignReviewRepository(Supabase.instance.client);
    try {
      final reviews = await repo.getAllReviews();
      print('Fetched ${reviews.length} reviews successfully.');
    } catch (e, st) {
      print('Error during fetching or mapping: $e');
      print(st);
      rethrow;
    }
  });
}
