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

  test('GroqService supports full project and sub-step context parameters', () async {
    expect(
      () => GroqService.analyzeSubStep(
        projectName: 'Turbine Housing Project',
        projectOwner: 'Dr. Sarah Connor',
        projectStatus: 'active',
        stageName: 'Detailed Design',
        stageDescription: 'Complete CAD models and CFD analysis',
        subStepName: 'Vibration Dampening Study',
        checklistItem: 'Harmonic Oscillation Test',
        itemDescription: 'Ensure resonance frequency exceeds 450Hz',
        discipline: 'Aero-thermal Engineering',
        priority: 'High',
        assignee: 'Alex Miller',
        problemStatement: 'Excessive blade flutter observed in proto-1',
        scopeIn: ['Blade root interface', 'Casing stiffness'],
        scopeOut: ['Control electronics'],
        engineeringComments: 'Needs revised damping material',
        actionDescription: 'Run 10-hour endurance vibration sweep',
        existingNotes: 'Previous sweep passed at 300Hz',
      ),
      throwsA(isA<GroqException>().having(
        (e) => e.isMissingKey,
        'isMissingKey',
        isTrue,
      )),
    );
  });

  test('GroqService defines resilient model hierarchy with fast fallback', () {
    expect(GroqService.availableModels, contains('llama-3.3-70b-versatile'));
    expect(GroqService.availableModels, contains('llama-3.1-8b-instant'));
    expect(GroqService.defaultModel, equals('openai/gpt-oss-120b'));
  });
}
