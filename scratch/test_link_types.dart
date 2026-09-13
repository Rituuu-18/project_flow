import 'package:pdf/widgets.dart' as pw;
import 'dart:io';

void main() async {
  final pdf = pw.Document();
  pdf.addPage(
    pw.Page(
      build: (context) {
        return pw.Column(
          children: [
            pw.UrlLink(
              destination: 'https://example.com/Checklist.pdf',
              child: pw.Text('UrlLink Checklist.pdf'),
            ),
            pw.Link(
              destination: 'https://example.com/Checklist.pdf',
              child: pw.Text('Link Checklist.pdf'),
            ),
          ],
        );
      },
    ),
  );
  final bytes = await pdf.save();
  File('test_output.pdf').writeAsBytesSync(bytes);
  print('Saved test_output.pdf');
}
