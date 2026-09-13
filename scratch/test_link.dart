import 'package:pdf/widgets.dart' as pw;

void main() {
  final doc = pw.Document();
  doc.addPage(
    pw.Page(
      build: (context) {
        return pw.UrlLink(
          destination: 'https://example.com/Checklist.pdf',
          child: pw.Text('Checklist.pdf'),
        );
      },
    ),
  );
  print('Document created');
}
