import 'dart:convert';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

void main() async {
  final pdf = pw.Document();
  pdf.addPage(
    pw.Page(
      build: (context) {
        return pw.Column(
          children: [
            // Option A: pw.UrlLink inside pw.Expanded
            pw.Row(
              children: [
                pw.Expanded(
                  child: pw.UrlLink(
                    destination: 'https://example.com/A.pdf',
                    child: pw.Text('Option A: Checklist.pdf'),
                  ),
                ),
                pw.Text('PDF Document'),
              ],
            ),
            pw.SizedBox(height: 20),
            // Option B: pw.UrlLink wrapping the entire Container/Row
            pw.UrlLink(
              destination: 'https://example.com/B.pdf',
              child: pw.Container(
                padding: const pw.EdgeInsets.all(6),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Option B: Checklist.pdf'),
                    pw.Text('PDF Document'),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    ),
  );

  final bytes = await pdf.save();
  final content = latin1.decode(bytes);
  for (final chunk in content.split('endobj')) {
    if (chunk.contains('/Link') || chunk.contains('/URI')) {
      print('--- ANNOTATION OBJ ---');
      print(chunk.trim());
    }
  }
}
