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

  testWidgets(
    'AIAnalysisSheet shows pre-analysis view by default and does not auto-analyze',
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
      expect(
        find.text('Analyze with AI'),
        findsNWidgets(2),
      ); // Title and Button
      expect(find.text('Pump Project Alpha'), findsOneWidget);
      expect(
        find.text('Verify clearance fit for shaft assembly'),
        findsOneWidget,
      );
      expect(find.text('CONTEXT PARAMETERS'), findsOneWidget);
      expect(find.text('Tolerance Stack'), findsWidgets);
      expect(find.text('Checklist item'), findsOneWidget);
      expect(find.text('Checklist description'), findsOneWidget);

      // Groq key error is NOT shown yet because analysis has not been triggered
      expect(find.byIcon(Icons.vpn_key_off_rounded), findsNothing);
    },
  );

  testWidgets(
    'AIAnalysisSheet triggers analysis when "Analyze with AI" button is tapped',
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
      final analyzeButton = find.widgetWithText(
        ElevatedButton,
        'Analyze with AI',
      );
      expect(analyzeButton, findsOneWidget);
      await tester.tap(analyzeButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // After triggering without an API key, the missing key state is displayed
      expect(find.byIcon(Icons.vpn_key_off_rounded), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
    },
  );

  testWidgets(
    'AIAnalysisSheet handles fallback when itemDescription and projectName are empty',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: AIAnalysisSheet(
                projectName: '',
                stageName: 'Concept Verification',
                checklistItem: 'Feasibility Review',
                itemDescription: '',
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
      // Missing description is identified rather than replaced with stage text.
      expect(find.text('No checklist description provided'), findsOneWidget);

      await tester.tap(find.widgetWithText(ElevatedButton, 'Analyze with AI'));
      await tester.pump();
      expect(
        find.text('A project name is required for AI analysis.'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'AIAnalysisSheet shows only the engineering-focused statement from older output',
    (tester) async {
      const rawAiOutput = '''
**General problem statement:** A maintenance technician needs a reliable climbing fixture for elevated industrial machinery. Existing fixed ladders lack lateral stability and exceed safe transport weights.

**Engineering-focused version:** Design a ladder system that supports 150 kg working load while complying with EN 131 / OSHA 1926.1053 within 18 kg total weight.
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
                existingNotes: '',
                initialRawAnalysis: rawAiOutput,
                onApplyNotes: (text, append) {},
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Engineering report'), findsOneWidget);
      expect(find.text('Engineering-focused version'), findsNothing);
      expect(find.text('General problem statement'), findsNothing);
      expect(find.textContaining('maintenance technician'), findsNothing);
    },
  );

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

      // Paste into Notes is provided only once in the lower action bar
      final pasteButton = find.widgetWithText(
        ElevatedButton,
        'Paste into Notes',
      );
      expect(pasteButton, findsOneWidget);
      expect(find.text('View Only'), findsNothing);
      expect(find.textContaining('maintenance technician'), findsNothing);

      await tester.tap(pasteButton);
      await tester.pumpAndSettle();

      expect(appliedText, isNotNull);
      expect(wasAppended, isFalse);
      // Applied text must be the engineering-focused statement only
      expect(
        appliedText,
        'Design a ladder system that supports 150 kg working load while complying with EN 131 within 18 kg total weight.',
      );
      // It must NOT contain the general problem statement
      expect(appliedText!.contains('General problem statement'), isFalse);
      expect(appliedText!.contains('maintenance technician'), isFalse);
    },
  );

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
      expect(
        copiedText,
        'Design a ladder system that supports 150 kg working load while complying with EN 131 within 18 kg total weight.',
      );
      expect(copiedText?.contains('General problem statement'), isFalse);
      expect(copiedText?.contains('maintenance technician'), isFalse);
    },
  );

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
      final appendButton = find.widgetWithText(
        OutlinedButton,
        'Append to Notes',
      );
      expect(appendButton, findsOneWidget);
      await tester.tap(appendButton);
      await tester.pumpAndSettle();

      expect(appliedText, isNotNull);
      expect(wasAppended, isTrue);
      expect(
        appliedText,
        'Design a ladder system that supports 150 kg working load while complying with EN 131 within 18 kg total weight.',
      );
      expect(appliedText!.contains('maintenance technician'), isFalse);
    },
  );

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
        findsOneWidget,
      );

      // Verify the engineering-focused text is inside the preview
      expect(
        find.text(
          'Design a ladder system that supports 150 kg working load while complying with EN 131 within 18 kg total weight.',
        ),
        findsOneWidget,
      );

      // General problem statement should not be shown in the preview box
      expect(
        find.text(
          'A maintenance technician needs a reliable climbing fixture for elevated industrial machinery.',
        ),
        findsNothing,
      );
    },
  );

  testWidgets(
    'AIAnalysisSheet with autoStart: true immediately starts analysis without showing pre-analysis view',
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
                existingNotes: '',
                autoStart: true,
                onApplyNotes: (text, append) {},
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Bypasses pre-analysis view directly
      expect(find.text('CONTEXT PARAMETERS'), findsNothing);
      // Since no Groq key is set in test environment, analysis immediately executed and entered key missing state with Retry
      expect(find.byIcon(Icons.vpn_key_off_rounded), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    },
  );
}
