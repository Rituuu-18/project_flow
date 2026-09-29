import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:engineering_werk/services/groq_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    dotenv.testLoad(fileInput: '');
  });

  test(
    'GroqService handles missing API key gracefully without crashing',
    () async {
      final hasKey = GroqService.hasApiKey();
      expect(hasKey, isFalse);

      expect(
        () => GroqService.analyzeSubStep(
          projectName: 'Test Project',
          checklistItem: 'Define Scope',
          itemDescription: 'Scope description',
        ),
        throwsA(
          isA<GroqException>().having(
            (e) => e.isMissingKey,
            'isMissingKey',
            isTrue,
          ),
        ),
      );
    },
  );

  test('GroqService reads key strictly from dotenv', () {
    dotenv.testLoad(fileInput: 'GROQ_API_KEY=gsk_env_test_123\n');
    expect(GroqService.hasApiKey(), isTrue);
    expect(GroqService.getApiKey(), equals('gsk_env_test_123'));
  });

  test(
    'AI prompt uses the specific checklist, project name, and description',
    () {
      final pumpPrompt = GroqService.buildAnalysisPrompt(
        projectName: '  Pump Housing  ',
        checklistItem: 'Perform engineering calculations',
        itemDescription: 'Calculate pressure and wall stress at 12 bar.',
      );
      final ladderPrompt = GroqService.buildAnalysisPrompt(
        projectName: 'Ladder Assembly',
        checklistItem: 'Define interfaces',
        itemDescription: 'Define mounting and user interfaces.',
      );

      expect(pumpPrompt, contains('Project name: Pump Housing'));
      expect(pumpPrompt.split('\n'), hasLength(3));
      expect(
        pumpPrompt,
        contains('Checklist item: Perform engineering calculations'),
      );
      expect(
        pumpPrompt,
        contains(
          'Checklist description: Calculate pressure and wall stress at 12 bar.',
        ),
      );
      expect(pumpPrompt, isNot(contains('Ladder Assembly')));
      expect(ladderPrompt, contains('Project name: Ladder Assembly'));
      expect(ladderPrompt, isNot(equals(pumpPrompt)));
      expect(
        GroqService.engineeringInstructions,
        contains('do not recycle a fixed sentence pattern'),
      );
      expect(
        GroqService.engineeringInstructions,
        contains('do not infer a product type'),
      );
    },
  );

  test(
    'AI prompt rejects missing project or description instead of generic context',
    () {
      expect(
        () => GroqService.buildAnalysisPrompt(
          projectName: '',
          checklistItem: 'Define interfaces',
          itemDescription: 'Define mounting points.',
        ),
        throwsA(isA<GroqException>()),
      );
      expect(
        () => GroqService.buildAnalysisPrompt(
          projectName: 'Pump Housing',
          checklistItem: 'Define interfaces',
          itemDescription: '',
        ),
        throwsA(isA<GroqException>()),
      );
    },
  );

  test('legacy dual-section output keeps only the engineering statement', () {
    const output = '''
### General problem statement
A technician needs a safe fixture.

### Engineering-focused version
Verify mounting loads and bolt selection for the pump housing.
''';
    expect(
      GroqService.engineeringStatementFrom(output),
      'Verify mounting loads and bolt selection for the pump housing.',
    );
    expect(
      GroqService.engineeringStatementFrom('Size the pump outlet for 12 bar.'),
      'Size the pump outlet for 12 bar.',
    );
    expect(
      GroqService.engineeringStatementFrom(
        '### General problem statement\nA technician needs a safe fixture.',
      ),
      isEmpty,
    );
  });

  test('bold and inline legacy headings cannot expose general text', () {
    const output = '''
**General Problem Statement:** A technician needs a safe fixture.
**Engineering-Focused Version:** Verify mounting loads and select bolts for the pump housing.
**General Description:** This is a broad product summary.
''';
    expect(
      GroqService.engineeringStatementFrom(output),
      'Verify mounting loads and select bolts for the pump housing.',
    );
    expect(
      GroqService.engineeringStatementFrom(
        '**General Description:** This is a broad product summary.',
      ),
      isEmpty,
    );
  });

  test('GroqService defines resilient model hierarchy with fast fallback', () {
    expect(GroqService.availableModels, contains('llama-3.3-70b-versatile'));
    expect(GroqService.availableModels, contains('llama-3.1-8b-instant'));
    expect(GroqService.defaultModel, equals('openai/gpt-oss-120b'));
  });
}
