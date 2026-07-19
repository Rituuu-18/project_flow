import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_test_helpers.dart';

void main() {
  late SupabaseClient admin;
  late SupabaseClient client;

  setUpAll(() async {
    await loadSupabaseTestEnv();
  });

  setUp(() async {
    if (!supabaseEnvFilesPresent()) return;
    requireLiveSupabase();
    admin = createAdminClient();
    client = await initAnonSupabase();
  });

  tearDown(() async {
    await signOutIfInitialized();
  });

  group('Supabase auth', () {
    test('signup metadata populates profile first_name/last_name', () async {
      requireLiveSupabase();

      final user = await createConfirmedUser(
        admin: admin,
        emailPrefix: 'auth.profile',
        metadata: const {
          'first_name': 'Ada',
          'last_name': 'Lovelace',
        },
      );
      addTearDown(() => deleteUser(admin, user.id));

      final session = await client.auth.signInWithPassword(
        email: user.email,
        password: user.password,
      );
      expect(session.session, isNotNull);

      final profile = await client
          .from('profiles')
          .select('first_name, last_name')
          .eq('id', user.id)
          .single();

      expect(profile['first_name'], 'Ada');
      expect(profile['last_name'], 'Lovelace');
    });

    test('login / signOut session lifecycle', () async {
      requireLiveSupabase();

      final user = await createConfirmedUser(
        admin: admin,
        emailPrefix: 'auth.session',
      );
      addTearDown(() => deleteUser(admin, user.id));

      final signedIn = await client.auth.signInWithPassword(
        email: user.email,
        password: user.password,
      );
      expect(signedIn.session?.accessToken, isNotEmpty);
      expect(client.auth.currentUser?.id, user.id);

      await client.auth.signOut();
      expect(client.auth.currentSession, isNull);
    });
  }, skip: !supabaseEnvFilesPresent()
      ? 'Live Supabase credentials not configured (.env / .env.admin)'
      : false);
}
