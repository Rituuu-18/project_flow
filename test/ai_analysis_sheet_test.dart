import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:engineering_werk/features/workspace/presentation/widgets/ai_analysis_sheet.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    dotenv.testLoad(fileInput: '');
  });

  testWidgets('AIAnalysisSheet shows pre-analysis view by default and does not auto-analyze',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: AIAnalysisSheet(
              projectName: 'Pump Project Alpha',
              stageName: 'Detailed Design',
              checklistItem: 'Tolerance Stack',
              itemDescription: 'Verify clearance fit for shaft assembly',
              discipline: 'Mechanical Engineering',
              priority: 'High',
              assignee: 'Marcus Vance',
              existingNotes: 'Existing team observations',
              onApplyNotes: (text, append) {},
            ),
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Verify header and elements render
    expect(find.text('AI Engineering Analysis'), findsOneWidget);
    expect(find.text('Detailed Design • Tolerance Stack'), findsOneWidget);

    // Verify pre-analysis view is shown by default (not loading, not missing key)
    expect(find.text('Analyze with AI'), findsNWidgets(2)); // Title and Button
    expect(find.text('Pump Project Alpha'), findsOneWidget);
    expect(find.text('Verify clearance fit for shaft assembly'), findsOneWidget);
    expect(find.text('CONTEXT PARAMETERS'), findsOneWidget);
    expect(find.text('High'), findsOneWidget);
    expect(find.text('Marcus Vance'), findsOneWidget);

    // Groq key error is NOT shown yet because analysis has not been triggered
    expect(find.byIcon(Icons.vpn_key_off_rounded), findsNothing);
  });

  testWidgets('AIAnalysisSheet triggers analysis when "Analyze with AI" button is tapped',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: AIAnalysisSheet(
              projectName: 'Pump Project Alpha',
              stageName: 'Detailed Design',
              checklistItem: 'Tolerance Stack',
              itemDescription: 'Verify clearance fit for shaft assembly',
              discipline: 'Mechanical Engineering',
              existingNotes: '',
              onApplyNotes: (text, append) {},
            ),
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Tap the "Analyze with AI" action button
    final analyzeButton = find.widgetWithText(ElevatedButton, 'Analyze with AI');
    expect(analyzeButton, findsOneWidget);
    await tester.tap(analyzeButton);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // After triggering without an API key, the missing key state is displayed
    expect(find.byIcon(Icons.vpn_key_off_rounded), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
  });

  testWidgets('AIAnalysisSheet handles fallback when itemDescription and projectName are empty',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: AIAnalysisSheet(
              projectName: '',
              stageName: 'Concept Verification',
              stageDescription: 'Stage level fallback description',
              checklistItem: 'Feasibility Review',
              itemDescription: '',
              discipline: 'Systems Engineering',
              existingNotes: '',
              onApplyNotes: (text, append) {},
            ),
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Project name falls back to localized Project label
    expect(find.text('Project'), findsWidgets);
    // Description falls back to stageDescription
    expect(find.text('Stage level fallback description'), findsOneWidget);
  });

  testWidgets(
      'AIAnalysisSheet orders Engineering-focused version ABOVE General problem statement',
      (tester) async {
    const rawAiOutput = '''
### General problem statement
A maintenance technician needs a reliable climbing fixture for elevated industrial machinery. Existing fixed ladders lack lateral stability and exceed safe transport weights.

### Engineering-focused version
Design a ladder system that supports 150 kg working load while complying with EN 131 / OSHA 1926.1053 within 18 kg total weight.
''';

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: AIAnalysisSheet(
              projectName: 'Ladder Project',
              stageName: 'Detailed Design',
              checklistItem: 'Safety Spec',
              itemDescription: 'Climbing fixture review',
              discipline: 'Mechanical Engineering',
              existingNotes: '',
              initialRawAnalysis: rawAiOutput,
              onApplyNotes: (text, append) {},
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify both headers are present
    final enggHeaderFinder = find.text('Engineering-focused version');
    final generalHeaderFinder = find.text('General problem statement');

    expect(enggHeaderFinder, findsOneWidget);
    expect(generalHeaderFinder, findsOneWidget);

    // Verify Engineering-focused version is positioned ABOVE General problem statement
    final enggTop = tester.getTopLeft(enggHeaderFinder).dy;
    final generalTop = tester.getTopLeft(generalHeaderFinder).dy;
    expect(enggTop, lessThan(generalTop),
        reason: 'Engineering-focused version should appear above General problem statement');
  });

  testWidgets(
      'AIAnalysisSheet Paste to Notes passes ONLY the engineering-focused statement',
      (tester) async {
    String? appliedText;
    bool? wasAppended;

    const rawAiOutput = '''
### General problem statement
A maintenance technician needs a reliable climbing fixture for elevated industrial machinery. Existing fixed ladders lack lateral stability.

### Engineering-focused version
Design a ladder system that supports 150 kg working load while complying with EN 131 within 18 kg total weight.
''';

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: AIAnalysisSheet(
              projectName: 'Ladder Project',
              stageName: 'Detailed Design',
              checklistItem: 'Safety Spec',
              itemDescription: 'Climbing fixture review',
              discipline: 'Mechanical Engineering',
              existingNotes: '',
              initialRawAnalysis: rawAiOutput,
              onApplyNotes: (text, append) {
                appliedText = text;
                wasAppended = append;
              },
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Tap "Paste into Notes"
    final pasteButton = find.widgetWithText(ElevatedButton, 'Paste into Notes');
    expect(pasteButton, findsOneWidget);
    await tester.tap(pasteButton);
    await tester.pumpAndSettle();

    expect(appliedText, isNotNull);
    expect(wasAppended, isFalse);
    // Applied text must be the engineering-focused statement only
    expect(appliedText,
        'Design a ladder system that supports 150 kg working load while complying with EN 131 within 18 kg total weight.');
    // It must NOT contain the general problem statement
    expect(appliedText!.contains('General problem statement'), isFalse);
    expect(appliedText!.contains('maintenance technician'), isFalse);
  });

  testWidgets(
      'AIAnalysisSheet bottom Copy button copies ONLY the engineering-focused statement to clipboard',
      (tester) async {
    const rawAiOutput = '''
### General problem statement
A maintenance technician needs a reliable climbing fixture for elevated industrial machinery.

### Engineering-focused version
Design a ladder system that supports 150 kg working load while complying with EN 131 within 18 kg total weight.
''';

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: AIAnalysisSheet(
              projectName: 'Ladder Project',
              stageName: 'Detailed Design',
              checklistItem: 'Safety Spec',
              itemDescription: 'Climbing fixture review',
              discipline: 'Mechanical Engineering',
              existingNotes: '',
              initialRawAnalysis: rawAiOutput,
              onApplyNotes: (text, append) {},
            ),
          ),
        ),
      ),
    );

    final log = <MethodCall>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (MethodCall methodCall) async {
        log.add(methodCall);
        return null;
      },
    );

    await tester.pumpAndSettle();

    // Tap bottom action bar "Copy" button (tooltip: 'Copy')
    final copyButton = find.byTooltip('Copy');
    expect(copyButton, findsOneWidget);
    await tester.tap(copyButton);
    await tester.pumpAndSettle();

    final copyCall = log.firstWhere(
      (call) => call.method == 'Clipboard.setData',
    );
    final copiedText = (copyCall.arguments as Map)['text'] as String?;
    expect(copiedText,
        'Design a ladder system that supports 150 kg working load while complying with EN 131 within 18 kg total weight.');
    expect(copiedText?.contains('General problem statement'), isFalse);
    expect(copiedText?.contains('maintenance technician'), isFalse);
  });

  testWidgets(
      'AIAnalysisSheet Append to Notes passes ONLY the engineering-focused statement',
      (tester) async {
    String? appliedText;
    bool? wasAppended;

    const rawAiOutput = '''
### Engineering-focused version
Design a ladder system that supports 150 kg working load while complying with EN 131 within 18 kg total weight.

### General problem statement
A maintenance technician needs a reliable climbing fixture for elevated industrial machinery.
''';

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: AIAnalysisSheet(
              projectName: 'Ladder Project',
              stageName: 'Detailed Design',
              checklistItem: 'Safety Spec',
              itemDescription: 'Climbing fixture review',
              discipline: 'Mechanical Engineering',
              existingNotes: 'Existing note line 1',
              initialRawAnalysis: rawAiOutput,
              onApplyNotes: (text, append) {
                appliedText = text;
                wasAppended = append;
              },
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Tap "Append to Notes"
    final appendButton = find.widgetWithText(OutlinedButton, 'Append to Notes');
    expect(appendButton, findsOneWidget);
    await tester.tap(appendButton);
    await tester.pumpAndSettle();

    expect(appliedText, isNotNull);
    expect(wasAppended, isTrue);
    expect(appliedText,
        'Design a ladder system that supports 150 kg working load while complying with EN 131 within 18 kg total weight.');
    expect(appliedText!.contains('maintenance technician'), isFalse);
  });

  testWidgets(
      'AIAnalysisSheet Notes preview tab renders only the engineering-focused statement',
      (tester) async {
    const rawAiOutput = '''
### General problem statement
A maintenance technician needs a reliable climbing fixture for elevated industrial machinery.

### Engineering-focused version
Design a ladder system that supports 150 kg working load while complying with EN 131 within 18 kg total weight.
''';

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: AIAnalysisSheet(
              projectName: 'Ladder Project',
              stageName: 'Detailed Design',
              checklistItem: 'Safety Spec',
              itemDescription: 'Climbing fixture review',
              discipline: 'Mechanical Engineering',
              existingNotes: '',
              initialRawAnalysis: rawAiOutput,
              onApplyNotes: (text, append) {},
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Switch to "Notes" tab
    final notesTab = find.text('Notes');
    expect(notesTab, findsOneWidget);
    await tester.tap(notesTab);
    await tester.pumpAndSettle();

    // Verify preview heading is shown
    expect(
        find.text('Preview of engineering statement ready for insertion:'),
        findsOneWidget);

    // Verify the engineering-focused text is inside the preview
    expect(
        find.text(
            'Design a ladder system that supports 150 kg working load while complying with EN 131 within 18 kg total weight.'),
        findsOneWidget);

    // General problem statement should not be shown in the preview box
    expect(
        find.text(
            'A maintenance technician needs a reliable climbing fixture for elevated industrial machinery.'),
        findsNothing);
  });
}

