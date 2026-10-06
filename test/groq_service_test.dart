import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:engineering_werk/services/groq_service.dart';
import 'package:engineering_werk/features/workspace/domain/entities/engineering_report.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'fixtures/engineering_report_fixture.dart';

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
        GroqService.engineeringInstructionsFor('Define interfaces'),
        contains('do not recycle a fixed sentence pattern'),
      );
      expect(
        GroqService.engineeringInstructionsFor('Define interfaces'),
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
      EngineeringReport.legacyEngineeringText(output),
      'Verify mounting loads and bolt selection for the pump housing.',
    );
    expect(
      EngineeringReport.legacyEngineeringText(
        'Size the pump outlet for 12 bar.',
      ),
      'Size the pump outlet for 12 bar.',
    );
    expect(
      EngineeringReport.legacyEngineeringText(
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
      EngineeringReport.legacyEngineeringText(output),
      'Verify mounting loads and select bolts for the pump housing.',
    );
    expect(
      EngineeringReport.legacyEngineeringText(
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

  test('the three engineering tasks get appropriate table layouts', () {
    final systems = GroqService.engineeringInstructionsFor(
      'Define systems, subsystems, and interfaces',
    );
    final calculations = GroqService.engineeringInstructionsFor(
      'Perform engineering calculations from allocated requirements',
    );
    final components = GroqService.engineeringInstructionsFor(
      'Select and justify candidate standard components',
    );
    expect(systems, contains('Level | Item | Function and boundary'));
    expect(systems, contains('Subsystems and allocation'));
    expect(
      calculations,
      contains('Check | Preliminary calculation | Result or design decision'),
    );
    expect(components, contains('Alternatives and preliminary rationale'));
    expect(
      components,
      contains('Supply, cost, or manufacturing consideration'),
    );
    expect(calculations, isNot(contains('For this system definition task')));
    expect(systems, isNot(contains('For this calculation task')));
  });

  test(
    'API response becomes a validated report with sufficient output space',
    () async {
      dotenv.testLoad(fileInput: 'GROQ_API_KEY=test_key\n');
      final client = MockClient((request) async {
        final payload = jsonDecode(request.body) as Map<String, dynamic>;
        final messages = payload['messages'] as List;
        expect(messages[0]['content'], contains('Calculation sequence'));
        expect(messages[0]['content'], isNot(contains('"summary":')));
        expect(messages[0]['content'], contains('Do not add a summary'));
        expect(
          messages[1]['content'],
          contains('Project name: Woodchipper rotor'),
        );
        expect(
          messages[1]['content'],
          contains('Checklist description: Calculate allocated rotor loads.'),
        );
        expect(payload['max_tokens'], greaterThan(320));
        return http.Response(
          jsonEncode({
            'choices': [
              {
                'message': {'content': jsonEncode(engineeringReportFixture)},
              },
            ],
          }),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });
      addTearDown(client.close);
      final result = await GroqService.analyzeSubStep(
        projectName: 'Woodchipper rotor',
        checklistItem:
            'Perform engineering calculations from allocated requirements',
        itemDescription: 'Calculate allocated rotor loads.',
        client: client,
      );
      expect(EngineeringReport.fromResponse(result).sections, hasLength(3));
    },
  );

  test(
    'malformed report retries with the next model without exposing raw output',
    () async {
      dotenv.testLoad(fileInput: 'GROQ_API_KEY=test_key\n');
      final requestedModels = <String>[];
      final client = MockClient((request) async {
        requestedModels.add(
          (jsonDecode(request.body) as Map)['model'] as String,
        );
        final content = requestedModels.length == 1
            ? '{"title":"Truncated report"'
            : jsonEncode(engineeringReportFixture);
        return http.Response(
          jsonEncode({
            'choices': [
              {
                'message': {'content': content},
              },
            ],
          }),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });
      addTearDown(client.close);
      final result = await GroqService.analyzeSubStep(
        projectName: 'Woodchipper rotor',
        checklistItem: 'Perform engineering calculations',
        itemDescription: 'Calculate allocated rotor loads.',
        client: client,
      );
      expect(requestedModels, GroqService.availableModels.take(2).toList());
      expect(
        EngineeringReport.fromResponse(result).title,
        'Woodchipper rotor calculations',
      );
    },
  );
}
