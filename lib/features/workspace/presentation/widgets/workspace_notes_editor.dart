import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/localization/locale_provider.dart';
import '../../../dashboard/presentation/theme/dashboard_design.dart';
import '../../domain/entities/notes_document.dart';
import 'notes_document_view.dart';

class WorkspaceNotesEditor extends ConsumerStatefulWidget {
  final TextEditingController controller;
  final InputDecoration decoration;
  final int formattedRevision;

  const WorkspaceNotesEditor({
    super.key,
    required this.controller,
    required this.decoration,
    this.formattedRevision = 0,
  });

  @override
  ConsumerState<WorkspaceNotesEditor> createState() =>
      _WorkspaceNotesEditorState();
}

class _WorkspaceNotesEditorState extends ConsumerState<WorkspaceNotesEditor> {
  late NotesDocument _document;
  late bool _showFormatted;
  late String _text;
  bool _editingText = false;

  @override
  void initState() {
    super.initState();
    _readDocument();
    _showFormatted = _document.hasTables;
    widget.controller.addListener(_onTextChanged);
  }

  void _readDocument() {
    _text = widget.controller.text;
    _document = NotesDocument.parse(_text);
  }

  void _onTextChanged() {
    if (_text == widget.controller.text) return;
    setState(() {
      final hadTables = _document.hasTables;
      _readDocument();
      if (!_editingText && !hadTables && _document.hasTables) {
        _showFormatted = true;
      }
      if (_text.isEmpty) _showFormatted = false;
    });
  }

  @override
  void didUpdateWidget(covariant WorkspaceNotesEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onTextChanged);
      _readDocument();
      _showFormatted = _document.hasTables;
      _editingText = false;
      widget.controller.addListener(_onTextChanged);
    }
    if (oldWidget.formattedRevision != widget.formattedRevision) {
      _showFormatted = _document.hasTables;
      _editingText = false;
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(localeProvider);
    final t = ref.read(localeProvider.notifier).t;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_document.hasTables || _showFormatted) ...[
          Wrap(
            spacing: 8,
            children: [
              ChoiceChip(
                label: Text(t('notes_formatted_view')),
                selected: _showFormatted,
                onSelected: (_) => setState(() {
                  _showFormatted = true;
                  _editingText = false;
                }),
              ),
              ChoiceChip(
                label: Text(t('notes_edit_text')),
                selected: !_showFormatted,
                onSelected: (_) => setState(() {
                  _showFormatted = false;
                  _editingText = true;
                }),
              ),
            ],
          ),
          const SizedBox(height: 10),
        ],
        if (_showFormatted)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              border: Border.all(color: DashboardDesign.border(context)),
              borderRadius: BorderRadius.circular(10),
            ),
            child: NotesDocumentView(
              document: _document,
              horizontalScrollHint: t('ai_table_scroll_hint'),
            ),
          )
        else
          TextField(
            key: const ValueKey('workspace_notes_text'),
            controller: widget.controller,
            minLines: 4,
            maxLines: _document.hasTables ? 16 : 4,
            style: TextStyle(color: DashboardDesign.text(context)),
            decoration: widget.decoration,
          ),
      ],
    );
  }
}
