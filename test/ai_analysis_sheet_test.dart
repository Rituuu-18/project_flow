import 'package:flutter/material.dart';
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
}
