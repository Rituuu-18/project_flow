import 'package:flutter/material.dart';

import '../../domain/entities/engineering_report.dart';
import 'engineering_report_table.dart';
import '../../../dashboard/presentation/theme/dashboard_design.dart';

/// A document layout with wrapping cells and scrollable tables on small screens.
class EngineeringReportView extends StatelessWidget {
  final EngineeringReport report;
  final String horizontalScrollHint;
  final String focusedHeading;
  final Widget? summaryActions;

  const EngineeringReportView({
    super.key,
    required this.report,
    required this.horizontalScrollHint,
    this.focusedHeading = 'Engineering-focused version',
    this.summaryActions,
  });

  @override
  Widget build(BuildContext context) {
    return SelectionArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (report.hasTables) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: DashboardDesign.isDark(context)
                    ? const Color(0xFF1E293B)
                    : const Color(0xFFF8FAFC),
                border: Border.all(color: DashboardDesign.border(context)),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Semantics(
                    header: true,
                    child: Text(
                      focusedHeading,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: DashboardDesign.text(context),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _summary(context),
                  if (summaryActions != null) ...[
                    const SizedBox(height: 12),
                    summaryActions!,
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
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
            _summary(context),
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

  Widget _summary(BuildContext context) => Text(
    report.toFocusedText(),
    style: TextStyle(
      fontSize: 13,
      height: 1.55,
      color: DashboardDesign.text(context),
    ),
  );
}
