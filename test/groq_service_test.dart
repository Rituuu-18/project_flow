import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:engineering_werk/services/groq_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('GroqService handles missing API key gracefully without crashing', () async {
    final hasKey = await GroqService.hasApiKey();
    expect(hasKey, isFalse);

    expect(
      () => GroqService.analyzeSubStep(
        projectName: 'Test Project',
        stageName: 'Requirements',
        checklistItem: 'Define Scope',
        itemDescription: 'Scope description',
        discipline: 'Systems Engineering',
      ),
      throwsA(isA<GroqException>().having(
        (e) => e.isMissingKey,
        'isMissingKey',
        isTrue,
      )),
    );
  });

  test('GroqService stores and clears custom API key in SharedPreferences', () async {
    await GroqService.setCustomApiKey('gsk_test_key_123');
    final key = await GroqService.getApiKey();
    expect(key, equals('gsk_test_key_123'));
    expect(await GroqService.hasApiKey(), isTrue);

    await GroqService.clearCustomApiKey();
    expect(await GroqService.getApiKey(), isNull);
    expect(await GroqService.hasApiKey(), isFalse);
  });
}
