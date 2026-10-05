import 'package:flutter/material.dart';

import '../../domain/entities/engineering_report.dart';
import '../../domain/entities/notes_document.dart';
import '../../../dashboard/presentation/theme/dashboard_design.dart';
import 'engineering_report_table.dart';

class NotesDocumentView extends StatelessWidget {
  final NotesDocument document;
  final String horizontalScrollHint;

  const NotesDocumentView({
    super.key,
    required this.document,
    required this.horizontalScrollHint,
  });

  @override
  Widget build(BuildContext context) {
    return SelectionArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var index = 0; index < document.blocks.length; index++) ...[
            if (index > 0) const SizedBox(height: 14),
            switch (document.blocks[index]) {
              NotesHeading(:final text, :final level) => Semantics(
                header: true,
                child: Text(
                  text,
                  style: TextStyle(
                    fontSize: level == 1 ? 18 : 15,
                    fontWeight: FontWeight.w700,
                    height: 1.4,
                    color: DashboardDesign.text(context),
                  ),
                ),
              ),
              NotesParagraph(:final text) => Text(
                text,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.55,
                  color: DashboardDesign.text(context),
                ),
              ),
              NotesTable(:final columns, :final rows) => EngineeringReportTable(
                section: EngineeringReportSection(
                  heading: '',
                  columns: columns,
                  rows: rows,
                ),
                horizontalScrollHint: horizontalScrollHint,
              ),
            },
          ],
        ],
      ),
    );
  }
}
