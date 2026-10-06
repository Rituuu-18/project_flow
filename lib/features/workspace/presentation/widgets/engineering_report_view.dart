import 'package:flutter/material.dart';

import '../../domain/entities/engineering_report.dart';
import 'engineering_report_table.dart';
import '../../../dashboard/presentation/theme/dashboard_design.dart';

/// A document layout with wrapping cells and scrollable tables on small screens.
class EngineeringReportView extends StatelessWidget {
  final EngineeringReport report;
  final String horizontalScrollHint;

  const EngineeringReportView({
    super.key,
    required this.report,
    required this.horizontalScrollHint,
  });

  @override
  Widget build(BuildContext context) {
    return SelectionArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: Text(
              report.title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                height: 1.3,
                color: DashboardDesign.text(context),
              ),
            ),
          ),
          if (!report.hasTables) ...[
            const SizedBox(height: 8),
            _legacyContent(context),
          ],
          for (final section in report.sections) ...[
            const SizedBox(height: 24),
            Semantics(
              header: true,
              child: Text(
                section.heading,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: DashboardDesign.text(context),
                ),
              ),
            ),
            const SizedBox(height: 10),
            EngineeringReportTable(
              section: section,
              horizontalScrollHint: horizontalScrollHint,
            ),
          ],
        ],
      ),
    );
  }

  Widget _legacyContent(BuildContext context) => Text(
    report.toNotesText(),
    style: TextStyle(
      fontSize: 13,
      height: 1.55,
      color: DashboardDesign.text(context),
    ),
  );
}
