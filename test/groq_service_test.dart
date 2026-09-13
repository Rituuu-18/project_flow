import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:engineering_werk/services/groq_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    dotenv.testLoad(fileInput: '');
  });

  test('GroqService handles missing API key gracefully without crashing', () async {
    final hasKey = GroqService.hasApiKey();
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

  test('GroqService reads key strictly from dotenv', () {
    dotenv.testLoad(fileInput: 'GROQ_API_KEY=gsk_env_test_123\n');
    expect(GroqService.hasApiKey(), isTrue);
    expect(GroqService.getApiKey(), equals('gsk_env_test_123'));
  });
}
