import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import 'supabase_test_helpers.dart';

void main() {
  late SupabaseClient admin;

  setUpAll(() async {
    await loadSupabaseTestEnv();
  });

  setUp(() async {
    if (!supabaseEnvFilesPresent()) return;
    requireLiveSupabase();
    admin = createAdminClient();
    await initAnonSupabase();
  });

  tearDown(() async {
    await signOutIfInitialized();
  });

  group('Supabase RLS', () {
    test('anon cannot insert; user B cannot read user A rows', () async {
      requireLiveSupabase();

      final client = Supabase.instance.client;

      // Anon insert blocked by RLS
      await expectLater(
        client.from('projects').insert({
          'name': 'Anon Project',
          'owner': 'anon',
          'discipline': 'General',
          'created_by': '00000000-0000-0000-0000-000000000001',
        }),
        throwsA(isA<PostgrestException>()),
      );

      final userA = await createConfirmedUser(
        admin: admin,
        emailPrefix: 'rls.a',
      );
      final userB = await createConfirmedUser(
        admin: admin,
        emailPrefix: 'rls.b',
      );
      addTearDown(() => deleteUser(admin, userA.id));
      addTearDown(() => deleteUser(admin, userB.id));

      await client.auth.signInWithPassword(
        email: userA.email,
        password: userA.password,
      );

      const uuid = Uuid();
      final projectId = uuid.v4();
      final reviewId = uuid.v4();

      await client.from('projects').insert({
        'id': projectId,
        'name': 'A Project',
        'owner': userA.id,
        'discipline': 'General',
        'created_by': userA.id,
      });
      await client.from('design_reviews').insert({
        'id': reviewId,
        'project_id': projectId,
        'name': 'A Review',
        'owner': 'A',
        'discipline': 'General',
        'status': 'active',
        'created_by': userA.id,
      });

      await client.auth.signOut();
      await client.auth.signInWithPassword(
        email: userB.email,
        password: userB.password,
      );

      final visibleToB = await client
          .from('design_reviews')
          .select('id')
          .eq('id', reviewId);
      expect(visibleToB, isEmpty);

      await expectLater(
        client
            .from('design_reviews')
            .update({'name': 'Hijacked'}).eq('id', reviewId),
        completes,
      );
      // Update affects 0 rows under RLS; verify as user A that name unchanged.
      await client.auth.signOut();
      await client.auth.signInWithPassword(
        email: userA.email,
        password: userA.password,
      );
      final stillA = await client
          .from('design_reviews')
          .select('name')
          .eq('id', reviewId)
          .single();
      expect(stillA['name'], 'A Review');

      await client.from('design_reviews').delete().eq('id', reviewId);
      await client.from('projects').delete().eq('id', projectId);
    });
  }, skip: !supabaseEnvFilesPresent()
      ? 'Live Supabase credentials not configured (.env / .env.admin)'
      : false);
}
