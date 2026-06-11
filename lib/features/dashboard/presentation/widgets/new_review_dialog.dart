import 'package:flutter/material.dart';

import '../theme/dashboard_design.dart';

class NewReviewDraft {
  const NewReviewDraft({
    required this.name,
    required this.owner,
    required this.discipline,
  });

  final String name;
  final String owner;
  final String discipline;
}

class NewReviewDialog extends StatefulWidget {
  const NewReviewDialog({super.key});

  @override
  State<NewReviewDialog> createState() => _NewReviewDialogState();
}

class _NewReviewDialogState extends State<NewReviewDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ownerController = TextEditingController();
  final _disciplineController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _ownerController.dispose();
    _disciplineController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: DashboardDesign.canvas(context),
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DashboardDesign.cardRadius),
        side: BorderSide(color: DashboardDesign.border(context)),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'CREATE DESIGN REVIEW',
                        style: TextStyle(
                          color: DashboardDesign.mutedText(context),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Close',
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded, size: 20),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'New Design Review',
                  style: TextStyle(
                    color: DashboardDesign.text(context),
                    fontSize: 27,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.8,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Add the review name, owner, and discipline. You can attach evidence and record decisions afterward.',
                  style: TextStyle(
                    color: DashboardDesign.mutedText(context),
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                _ReviewField(
                  label: 'DESIGN REVIEW NAME',
                  hint: 'e.g. Gearbox Cover Rev A',
                  controller: _nameController,
                  autofocus: true,
                ),
                const SizedBox(height: 18),
                _ReviewField(
                  label: 'OWNER',
                  hint: 'Owner',
                  controller: _ownerController,
                ),
                const SizedBox(height: 18),
                _ReviewField(
                  label: 'DISCIPLINE',
                  hint: 'Discipline',
                  controller: _disciplineController,
                ),
                const SizedBox(height: 28),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 10),
                    FilledButton(
                      onPressed: _submit,
                      child: const Text('Create'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      NewReviewDraft(
        name: _nameController.text.trim(),
        owner: _ownerController.text.trim(),
        discipline: _disciplineController.text.trim(),
      ),
    );
  }
}

class _ReviewField extends StatelessWidget {
  const _ReviewField({
    required this.label,
    required this.hint,
    required this.controller,
    this.autofocus = false,
  });

  final String label;
  final String hint;
  final TextEditingController controller;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: DashboardDesign.mutedText(context),
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.7,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          autofocus: autofocus,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(hintText: hint),
          validator: (value) =>
              value == null || value.trim().isEmpty ? 'Required' : null,
        ),
      ],
    );
  }
}
