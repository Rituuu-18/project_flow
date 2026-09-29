import 'package:flutter/material.dart';

import '../../domain/entities/engineering_report.dart';
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
            _EngineeringTable(
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

class _EngineeringTable extends StatefulWidget {
  final EngineeringReportSection section;
  final String horizontalScrollHint;

  const _EngineeringTable({
    required this.section,
    required this.horizontalScrollHint,
  });

  @override
  State<_EngineeringTable> createState() => _EngineeringTableState();
}

class _EngineeringTableState extends State<_EngineeringTable> {
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = DashboardDesign.isDark(context);
    final section = widget.section;
    final border = DashboardDesign.border(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final minWidth = section.columns.length == 2 ? 480.0 : 660.0;
        final hasOverflow = constraints.maxWidth < minWidth;
        final tableWidth = hasOverflow ? minWidth : constraints.maxWidth;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (hasOverflow) ...[
              Text(
                widget.horizontalScrollHint,
                style: TextStyle(
                  fontSize: 11,
                  color: DashboardDesign.mutedText(context),
                ),
              ),
              const SizedBox(height: 6),
            ],
            Scrollbar(
              controller: _scrollController,
              thumbVisibility: hasOverflow,
              trackVisibility: hasOverflow,
              scrollbarOrientation: ScrollbarOrientation.bottom,
              notificationPredicate: (notification) =>
                  notification.metrics.axis == Axis.horizontal,
              child: SingleChildScrollView(
                controller: _scrollController,
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.only(bottom: hasOverflow ? 14 : 0),
                child: SizedBox(
                  width: tableWidth,
                  child: Table(
                    defaultVerticalAlignment: TableCellVerticalAlignment.top,
                    columnWidths: {
                      0: FixedColumnWidth(
                        section.columns.length == 2 ? 155 : 140,
                      ),
                    },
                    border: TableBorder.all(color: border, width: 1),
                    children: [
                      TableRow(
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF263244)
                              : const Color(0xFFF1F5F9),
                        ),
                        children: section.columns
                            .map((text) => _cell(context, text, isHeader: true))
                            .toList(),
                      ),
                      for (
                        var rowIndex = 0;
                        rowIndex < section.rows.length;
                        rowIndex++
                      )
                        TableRow(
                          decoration: BoxDecoration(
                            color: rowIndex.isEven
                                ? (isDark
                                      ? const Color(0xFF182231)
                                      : Colors.white)
                                : (isDark
                                      ? const Color(0xFF1E293B)
                                      : const Color(0xFFF8FAFC)),
                          ),
                          children: section.rows[rowIndex]
                              .map((text) => _cell(context, text))
                              .toList(),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _cell(BuildContext context, String text, {bool isHeader = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      child: Semantics(
        header: isHeader,
        child: Text(
          text,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: isHeader ? FontWeight.w600 : FontWeight.w400,
            height: 1.5,
            color: DashboardDesign.text(context),
          ),
        ),
      ),
    );
  }
}
