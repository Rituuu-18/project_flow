import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../theme/dashboard_design.dart';

class PdfStorageScreen extends StatefulWidget {
  const PdfStorageScreen({super.key});

  @override
  State<PdfStorageScreen> createState() => _PdfStorageScreenState();
}

class _PdfStorageScreenState extends State<PdfStorageScreen> {
  List<Map<String, dynamic>> _pdfs = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPdfs();
  }

  Future<void> _loadPdfs() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        setState(() {
          _error = 'Not signed in.';
          _isLoading = false;
        });
        return;
      }

      final response = await Supabase.instance.client
          .from('pdf_storage')
          .select()
          .eq('created_by', userId)
          .order('created_at', ascending: false);

      setState(() {
        _pdfs = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load PDFs: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _deletePdf(String id) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete PDF?'),
        content: const Text('This PDF will be permanently removed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: DashboardDesign.destructive,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (shouldDelete != true) return;

    try {
      await Supabase.instance.client
          .from('pdf_storage')
          .delete()
          .eq('id', id);
      _loadPdfs();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete: $e')),
        );
      }
    }
  }

  Future<void> _openPdf(Map<String, dynamic> pdf) async {
    try {
      final fileUrl = pdf['file_url'] as String? ?? '';
      final name = pdf['name'] as String? ?? 'document.pdf';

      if (fileUrl.startsWith('data:application/pdf;base64,')) {
        final base64Data = fileUrl.replaceFirst('data:application/pdf;base64,', '');
        final bytes = base64Decode(base64Data);
        await Printing.layoutPdf(
          onLayout: (format) async => bytes,
          name: name,
        );
      } else if (fileUrl.startsWith('http://') || fileUrl.startsWith('https://')) {
        await launchUrl(Uri.parse(fileUrl), mode: LaunchMode.externalApplication);
      } else if (fileUrl.isNotEmpty) {
        final bytes = base64Decode(fileUrl);
        await Printing.layoutPdf(
          onLayout: (format) async => bytes,
          name: name,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to open PDF: $e')),
        );
      }
    }
  }

  Future<void> _downloadPdf(Map<String, dynamic> pdf) async {
    try {
      final fileUrl = pdf['file_url'] as String? ?? '';
      final name = pdf['name'] as String? ?? 'document.pdf';

      if (fileUrl.startsWith('data:application/pdf;base64,')) {
        final base64Data = fileUrl.replaceFirst('data:application/pdf;base64,', '');
        final bytes = base64Decode(base64Data);
        await Printing.sharePdf(
          bytes: bytes,
          filename: name.endsWith('.pdf') ? name : '$name.pdf',
        );
      } else if (fileUrl.startsWith('http://') || fileUrl.startsWith('https://')) {
        await launchUrl(Uri.parse(fileUrl), mode: LaunchMode.externalApplication);
      } else if (fileUrl.isNotEmpty) {
        final bytes = base64Decode(fileUrl);
        await Printing.sharePdf(
          bytes: bytes,
          filename: name.endsWith('.pdf') ? name : '$name.pdf',
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to download PDF: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = DashboardDesign.isDark(context);
    final horizontalPadding = MediaQuery.sizeOf(context).width < 600 ? 16.0 : 24.0;

    return Scaffold(
      backgroundColor: DashboardDesign.canvas(context),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                20,
                horizontalPadding,
                0,
              ),
              child: Container(
                padding: const EdgeInsets.only(bottom: 18),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: DashboardDesign.border(context)),
                  ),
                ),
                child: Row(
                  children: [
                    isDark
                        ? ShaderMask(
                            blendMode: BlendMode.srcIn,
                            shaderCallback: (bounds) => const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Color(0xFF4D8FFF),
                                Color(0xFFF4F7F8),
                              ],
                              stops: [0.0, 1.0],
                            ).createShader(bounds),
                            child: Image.asset(
                              'assets/ed-logo.png',
                              height: 48,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) => Icon(
                                Icons.fact_check_outlined,
                                color: DashboardDesign.primary,
                                size: 28,
                              ),
                            ),
                          )
                        : Image.asset(
                            'assets/ed-logo.png',
                            height: 48,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) => Icon(
                              Icons.fact_check_outlined,
                              color: DashboardDesign.primary,
                              size: 28,
                            ),
                          ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'PDF Storage',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: DashboardDesign.text(context),
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.3,
                            ),
                          ),
                          Text(
                            'Design review workflow',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: DashboardDesign.mutedText(context),
                              fontSize: 12,
                              height: 1.25,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => context.go('/'),
                      tooltip: 'Back to Dashboard',
                      icon: const Icon(Icons.arrow_back_rounded, size: 20),
                      style: IconButton.styleFrom(
                        foregroundColor: DashboardDesign.text(context),
                        backgroundColor: DashboardDesign.surface(context),
                        side: BorderSide(color: DashboardDesign.border(context)),
                        shape: const CircleBorder(),
                        fixedSize: const Size(40, 40),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Content
            Expanded(
              child: _buildContent(horizontalPadding),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(double horizontalPadding) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: DashboardDesign.destructive),
            const SizedBox(height: 16),
            Text(_error!, style: TextStyle(color: DashboardDesign.mutedText(context))),
            const SizedBox(height: 16),
            FilledButton(onPressed: _loadPdfs, child: const Text('Retry')),
          ],
        ),
      );
    }

    if (_pdfs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.picture_as_pdf_rounded,
              size: 64,
              color: DashboardDesign.mutedText(context),
            ),
            const SizedBox(height: 16),
            Text(
              'No PDFs yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: DashboardDesign.text(context),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Created PDFs will appear here.',
              style: TextStyle(
                fontSize: 14,
                color: DashboardDesign.mutedText(context),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadPdfs,
      child: ListView.builder(
        padding: EdgeInsets.fromLTRB(horizontalPadding, 24, horizontalPadding, 24),
        itemCount: _pdfs.length,
        itemBuilder: (context, index) {
          final pdf = _pdfs[index];
          final name = pdf['name'] as String? ?? 'Untitled';
          final createdAt = DateTime.tryParse(pdf['created_at'] as String? ?? '');
          final dateStr = createdAt != null
              ? DateFormat('dd MMM yyyy, HH:mm').format(createdAt.toLocal())
              : '';

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: DashboardDesign.surface(context),
              borderRadius: BorderRadius.circular(DashboardDesign.cardRadius),
              border: Border.all(color: DashboardDesign.border(context)),
              boxShadow: DashboardDesign.softShadow(context),
            ),
            child: ListTile(
              onTap: () => _openPdf(pdf),
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: DashboardDesign.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.picture_as_pdf_rounded,
                  color: DashboardDesign.primary,
                ),
              ),
              title: Text(
                name,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: DashboardDesign.text(context),
                ),
              ),
              subtitle: Text(
                dateStr,
                style: TextStyle(
                  color: DashboardDesign.mutedText(context),
                  fontSize: 12,
                ),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.download_rounded, color: DashboardDesign.primary),
                    tooltip: 'Download PDF',
                    onPressed: () => _downloadPdf(pdf),
                  ),
                  IconButton(
                    icon: Icon(Icons.delete_outline_rounded, color: DashboardDesign.destructive),
                    tooltip: 'Delete PDF',
                    onPressed: () => _deletePdf(pdf['id'] as String),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
