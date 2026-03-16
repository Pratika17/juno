import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:intl/intl.dart';
import '../models/item_model.dart';

class PDFService {
  static Future<void> generateMyPostsReport(List<ItemModel> items) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('UniFound - My Posts Report',
                      style: pw.TextStyle(
                          color: PdfColors.blue,
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 24)),
                  pw.Text(
                    DateFormat('MMM dd, yyyy').format(DateTime.now()),
                    style: pw.TextStyle(color: PdfColors.grey700),
                  )
                ],
              ),
            ),
            pw.SizedBox(height: 20),
            pw.Table.fromTextArray(
              headers: ['Title', 'Type', 'Category', 'Status', 'Date Posted'],
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
              rowDecoration: const pw.BoxDecoration(
                border: pw.Border(
                  bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
                ),
              ),
              cellAlignments: {
                0: pw.Alignment.centerLeft,
                1: pw.Alignment.center,
                2: pw.Alignment.center,
                3: pw.Alignment.center,
                4: pw.Alignment.centerRight,
              },
              data: items.map((item) {
                return [
                  item.title,
                  item.itemType.toString().split('.').last.toUpperCase(),
                  item.category.toString().split('.').last,
                  item.status.toString().split('.').last,
                  DateFormat('yyyy-MM-dd').format(item.createdAt),
                ];
              }).toList(),
            ),
            pw.SizedBox(height: 20),
            pw.Text(
              'Total Items: ${items.length}',
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ];
        },
      ),
    );

    try {
      final output = await getTemporaryDirectory();
      final file = File('${output.path}/my_posts_report.pdf');
      await file.writeAsBytes(await pdf.save());
      
      await OpenFilex.open(file.path);
    } catch (e) {
      print('Error generating or opening PDF: $e');
      rethrow;
    }
  }
}
