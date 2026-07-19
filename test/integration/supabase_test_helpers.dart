import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// True when local credential files exist (used to skip the suite in CI).
bool supabaseEnvFilesPresent() =>
    File('.env').existsSync() && File('.env.admin').existsSync();

/// Returns false when live Supabase credentials are missing.
bool supabaseIntegrationAvailable() {
  final url = dotenv.env['NEXT_PUBLIC_SUPABASE_URL'] ?? '';
  final anon = dotenv.env['SUPABASE_ANON_KEY'] ?? '';
  return url.isNotEmpty && anon.isNotEmpty;
}

bool supabaseAdminAvailable() {
  final secret = dotenv.env['SERVICE_ROLE_SECRET'] ??
      dotenv.env['SUPABASE_SERVICE_ROLE_KEY'] ??
      '';
  return secret.isNotEmpty;
}

void requireLiveSupabase() {
  expect(
    supabaseIntegrationAvailable() && supabaseAdminAvailable(),
    isTrue,
    reason: 'Expected NEXT_PUBLIC_SUPABASE_URL, SUPABASE_ANON_KEY, '
        'and SERVICE_ROLE_SECRET in .env / .env.admin',
  );
}

Future<void> loadSupabaseTestEnv() async {
  // Use WidgetsFlutterBinding (not TestWidgetsFlutterBinding) so real HTTP
  // calls to Supabase are allowed. TestWidgetsFlutterBinding mocks HttpClient
  // and returns 400 for every request.
  WidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = null;
  SharedPreferences.setMockInitialValues({});

  // Load from the repo filesystem (not Flutter assets) so CI/local
  // integration tests work without bundling secrets.
  final envFile = File('.env');
  final adminFile = File('.env.admin');
  final buffer = StringBuffer();
  if (envFile.existsSync()) {
    buffer.writeln(envFile.readAsStringSync());
  }
  if (adminFile.existsSync()) {
    buffer.writeln(adminFile.readAsStringSync());
  }
  dotenv.testLoad(fileInput: buffer.toString());
}

String requireEnv(String key) {
  final value = dotenv.env[key] ?? '';
  if (value.isEmpty) {
    throw StateError('$key is missing from .env / .env.admin');
  }
  return value;
}

String supabaseUrl() => requireEnv('NEXT_PUBLIC_SUPABASE_URL');
String supabaseAnonKey() => requireEnv('SUPABASE_ANON_KEY');
String supabaseServiceRoleKey() =>
    dotenv.env['SERVICE_ROLE_SECRET'] ??
    dotenv.env['SUPABASE_SERVICE_ROLE_KEY'] ??
    (throw StateError('SERVICE_ROLE_SECRET missing from .env.admin'));

bool supabaseClientInitialized = false;

/// Initializes the global [Supabase] client with the anon key (app path).
Future<SupabaseClient> initAnonSupabase() async {
  if (supabaseClientInitialized) {
    return Supabase.instance.client;
  }
  await Supabase.initialize(
    url: supabaseUrl(),
    anonKey: supabaseAnonKey(),
  );
  supabaseClientInitialized = true;
  return Supabase.instance.client;
}

Future<void> signOutIfInitialized() async {
  if (!supabaseClientInitialized) return;
  await Supabase.instance.client.auth.signOut();
}

/// Service-role client for admin user create/delete (never ship in the app).
SupabaseClient createAdminClient() {
  return SupabaseClient(supabaseUrl(), supabaseServiceRoleKey());
}

class DisposableUser {
  DisposableUser({
    required this.id,
    required this.email,
    required this.password,
  });

  final String id;
  final String email;
  final String password;
}

Future<DisposableUser> createConfirmedUser({
  required SupabaseClient admin,
  required String emailPrefix,
  Map<String, dynamic>? metadata,
  String password = 'IntegrationTest123!xyz',
}) async {
  final email =
      '$emailPrefix.${DateTime.now().microsecondsSinceEpoch}@gmail.com';
  final response = await admin.auth.admin.createUser(
    AdminUserAttributes(
      email: email,
      password: password,
      emailConfirm: true,
      userMetadata: metadata ??
          const {
            'first_name': 'Integration',
            'last_name': 'Tester',
          },
    ),
  );
  final user = response.user;
  if (user == null) {
    throw StateError('Admin createUser returned no user for $email');
  }
  return DisposableUser(id: user.id, email: email, password: password);
}

Future<void> deleteUser(SupabaseClient admin, String userId) async {
  try {
    await admin.auth.admin.deleteUser(userId);
  } catch (_) {
    // Best-effort cleanup
  }
}
