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

  testWidgets('AIAnalysisSheet shows missing key state without any input field in UI',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: AIAnalysisSheet(
              projectName: 'Pump Project',
              stageName: 'Detailed Design',
              checklistItem: 'Tolerance Stack',
              itemDescription: 'Verify clearance fit',
              discipline: 'Mechanical Engineering',
              existingNotes: 'Existing team observations',
              onApplyNotes: (text, append) {},
            ),
          ),
        ),
      ),
    );

    // Initial pump
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Verify header and elements render without any crash
    expect(find.text('AI Engineering Analysis'), findsOneWidget);
    expect(find.text('Detailed Design • Tolerance Stack'), findsOneWidget);

    // Verify missing key prompt appears without any input box on frontend
    expect(find.byIcon(Icons.vpn_key_off_rounded), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
  });
}
