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
            pw.UrlLink(
              destination: 'https://example.com/test.pdf',
              child: pw.Text('Clickable Link'),
            ),
            pw.Link(
              destination: 'https://example.com/test2.pdf',
              child: pw.Text('Link 2'),
            ),
          ],
        );
      },
    ),
  );

  final bytes = await pdf.save();
  final pdfStr = latin1.decode(bytes);
  print('PDF Contains /URI: ${pdfStr.contains('/URI')}');
  print('PDF Contains /Link: ${pdfStr.contains('/Link')}');
  print('PDF Contains /Action: ${pdfStr.contains('/Action')}');
  print('PDF snippet around URI:');
  final idx = pdfStr.indexOf('/URI');
  if (idx != -1) {
    print(pdfStr.substring(idx - 50, idx + 100));
  } else {
    print('No /URI found in generated PDF!');
  }
}
