import 'dart:convert';

/// The same report is used for rendering, caching, and copying into notes.
class EngineeringReport {
  final String title;
  final String _legacyText;
  final List<EngineeringReportSection> sections;

  const EngineeringReport({
    required this.title,
    String legacyText = '',
    required this.sections,
  }) : _legacyText = legacyText;

  bool get hasTables => sections.isNotEmpty;

  factory EngineeringReport.fromResponse(
    String response, {
    bool requireTables = false,
  }) {
    var content = response.trim();
    if (content.length > 100000) {
      throw const FormatException('Engineering report is too large.');
    }
    if (content.startsWith('```')) {
      content = content
          .replaceFirst(RegExp(r'^```(?:json)?\s*', caseSensitive: false), '')
          .replaceFirst(RegExp(r'\s*```$'), '')
          .trim();
    }
    if (content.startsWith('{') || content.startsWith('[')) {
      final decoded = jsonDecode(content);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Expected an engineering report object.');
      }
      final title = _requiredText(decoded['title'], 180);
      // Older cached reports may include a summary; only retain the tables.
      final rawSections = decoded['sections'];
      if (rawSections is! List ||
          rawSections.length < 2 ||
          rawSections.length > 5 ||
          _isGeneralHeading(title)) {
        throw const FormatException('Expected two to five engineering tables.');
      }
      final sections = rawSections
          .map((raw) {
            if (raw is! Map<String, dynamic>) {
              throw const FormatException('Invalid engineering table.');
            }
            return EngineeringReportSection.fromJson(raw);
          })
          .toList(growable: false);
      return EngineeringReport(title: title, sections: sections);
    }
    if (requireTables) {
      throw const FormatException('The AI response did not contain tables.');
    }
    // Preserve older cached engineering statements without exposing their general section.
    final legacyText = legacyEngineeringText(content);
    if (legacyText.isEmpty) {
      throw const FormatException('No engineering content was returned.');
    }
    return EngineeringReport(
      title: 'Engineering report',
      legacyText: legacyText,
      sections: const [],
    );
  }

  Map<String, dynamic> toJson() => {
    'title': title,
    'sections': sections.map((section) => section.toJson()).toList(),
  };

  String _legacyNotesText() {
    var text = _legacyText.trim();
    if (text.length >= 2 &&
        ((text.startsWith('"') && text.endsWith('"')) ||
            (text.startsWith("'") && text.endsWith("'")))) {
      text = text.substring(1, text.length - 1).trim();
    }
    return text;
  }

  String toNotesText() {
    if (!hasTables) return _legacyNotesText();
    final output = StringBuffer('# $title');
    for (final section in sections) {
      output.write('\n\n## ${section.heading}\n\n');
      output.writeln(_markdownRow(section.columns));
      output.writeln(_markdownRow(List.filled(section.columns.length, '---')));
      for (final row in section.rows) {
        output.writeln(_markdownRow(row));
      }
    }
    return output.toString().trim();
  }

  static String _markdownRow(List<String> cells) =>
      '| ${cells.map((cell) => cell.replaceAll('\\', '\\\\').replaceAll('|', '\\|').replaceAll(RegExp(r'[\r\n]+'), ' ')).join(' | ')} |';

  static String legacyEngineeringText(String response) {
    final engineeringHeader = RegExp(
      r'^engineering[-\s]*focused(?:\s+(?:version|statement|description))?(?:\s*:\s*(.*)|\s*)$',
      caseSensitive: false,
    );
    final generalHeader = RegExp(
      r'^general(?:\s+(?:problem statement|description|statement|version))?(?:\s*:\s*.*|\s*)$',
      caseSensitive: false,
    );
    final engineeringLines = <String>[];
    var section = '';
    var hasSectionHeader = false;
    for (final line in response.trim().split('\n')) {
      final headingLine = line
          .trim()
          .replaceFirst(RegExp(r'^#{1,6}\s*'), '')
          .replaceFirst(RegExp(r'^\d+[.)]\s*'), '')
          .replaceAll(RegExp(r'\*\*|__'), '');
      final engineeringMatch = engineeringHeader.firstMatch(headingLine);
      if (engineeringMatch != null) {
        hasSectionHeader = true;
        section = 'engineering';
        final inlineText = engineeringMatch.group(1)?.trim() ?? '';
        if (inlineText.isNotEmpty) engineeringLines.add(inlineText);
        continue;
      }
      if (generalHeader.hasMatch(headingLine)) {
        hasSectionHeader = true;
        section = 'general';
        continue;
      }
      if (line.trimLeft().startsWith('#')) section = '';
      if (section == 'engineering') engineeringLines.add(line);
    }
    return hasSectionHeader
        ? engineeringLines.join('\n').trim()
        : response.trim();
  }
}

class EngineeringReportSection {
  final String heading;
  final List<String> columns;
  final List<List<String>> rows;

  const EngineeringReportSection({
    required this.heading,
    required this.columns,
    required this.rows,
  });

  factory EngineeringReportSection.fromJson(Map<String, dynamic> json) {
    final heading = _requiredText(json['heading'], 180);
    final rawColumns = json['columns'];
    final rawRows = json['rows'];
    if (_isGeneralHeading(heading) ||
        rawColumns is! List ||
        rawColumns.length < 2 ||
        rawColumns.length > 3 ||
        rawRows is! List ||
        rawRows.isEmpty ||
        rawRows.length > 8) {
      throw const FormatException('Invalid engineering table structure.');
    }
    final columns = rawColumns
        .map((column) => _requiredText(column, 160))
        .toList(growable: false);
    final rows = rawRows
        .map((rawRow) {
          if (rawRow is! List || rawRow.length != columns.length) {
            throw const FormatException(
              'Engineering table columns do not match.',
            );
          }
          return rawRow
              .map((cell) => _requiredText(cell, 2000))
              .toList(growable: false);
        })
        .toList(growable: false);
    return EngineeringReportSection(
      heading: heading,
      columns: columns,
      rows: rows,
    );
  }

  Map<String, dynamic> toJson() => {
    'heading': heading,
    'columns': columns,
    'rows': rows,
  };
}

String _requiredText(dynamic value, int maxLength) {
  if (value is! String || value.trim().isEmpty || value.length > maxLength) {
    throw const FormatException('Invalid engineering report text.');
  }
  return value.trim();
}

bool _isGeneralHeading(String heading) => RegExp(
  r'^general\b',
  caseSensitive: false,
).hasMatch(heading.replaceFirst(RegExp(r'^[#*_\s\d.)]+'), ''));
