import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:engineering_werk/features/workspace/presentation/widgets/ai_analysis_sheet.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('AIAnalysisSheet shows missing key UI gracefully when key is absent',
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

    // Verify missing key prompt appears since no key was configured
    expect(find.byIcon(Icons.vpn_key_rounded), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
  });
}
