import 'package:flutter/material.dart';

import '../../domain/entities/engineering_report.dart';
import '../../../dashboard/presentation/theme/dashboard_design.dart';

class EngineeringReportTable extends StatefulWidget {
  final EngineeringReportSection section;
  final String horizontalScrollHint;

  const EngineeringReportTable({
    super.key,
    required this.section,
    required this.horizontalScrollHint,
  });

  @override
  State<EngineeringReportTable> createState() => _EngineeringReportTableState();
}

class _EngineeringReportTableState extends State<EngineeringReportTable> {
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
