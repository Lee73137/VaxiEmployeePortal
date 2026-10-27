import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/forecast.dart';

/// Suggested-PO report grouped by supplier, for printing or handing to
/// purchasing. Items with no costing_items/supplier mapping on file are
/// bucketed under "Unassigned" (sorted last) rather than dropped.
Future<Uint8List> buildForecastPdf(List<ForecastRow> rows) async {
  final doc = pw.Document();

  final grouped = <String, List<ForecastRow>>{};
  for (final r in rows) {
    grouped.putIfAbsent(r.supplier, () => []).add(r);
  }
  for (final items in grouped.values) {
    items.sort((a, b) => a.itemCode.compareTo(b.itemCode));
  }
  final supplierNames = grouped.keys.toList()
    ..sort((a, b) {
      if (a == 'Unassigned') return 1;
      if (b == 'Unassigned') return -1;
      return a.compareTo(b);
    });

  const headers = ['Item', 'UOM', 'On Hand', 'Pending', 'Available', 'Avg Monthly Sales', 'Suggested PO Qty'];

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(28),
      header: (context) {
        if (context.pageNumber > 1) return pw.SizedBox();
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('vaxiCSR - Sales Forecast / Suggested PO Report', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 2),
            pw.Text(
              'Generated ${DateTime.now().toString().split('.').first} · ${rows.length} item${rows.length == 1 ? '' : 's'} across ${supplierNames.length} supplier${supplierNames.length == 1 ? '' : 's'}',
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
            ),
            pw.SizedBox(height: 8),
            pw.Divider(color: PdfColors.grey400),
          ],
        );
      },
      footer: (context) => pw.Align(
        alignment: pw.Alignment.centerRight,
        child: pw.Text('Page ${context.pageNumber} of ${context.pagesCount}', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
      ),
      build: (context) => [
        for (final supplier in supplierNames) ...[
          pw.SizedBox(height: 14),
          pw.Text(supplier, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.red900)),
          pw.SizedBox(height: 4),
          pw.TableHelper.fromTextArray(
            headers: headers,
            data: grouped[supplier]!
                .map((r) => [
                      r.itemCode,
                      r.uom ?? '',
                      '${r.onHand}',
                      '${r.pending}',
                      '${r.available}',
                      r.avgMonthlySales.toStringAsFixed(1),
                      '${r.suggestedPoQty}',
                    ])
                .toList(),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9, color: PdfColors.white),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.red800),
            cellStyle: const pw.TextStyle(fontSize: 9),
            cellHeight: 20,
            cellAlignments: const {
              0: pw.Alignment.centerLeft,
              1: pw.Alignment.center,
              2: pw.Alignment.centerRight,
              3: pw.Alignment.centerRight,
              4: pw.Alignment.centerRight,
              5: pw.Alignment.centerRight,
              6: pw.Alignment.centerRight,
            },
            border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
            oddRowDecoration: const pw.BoxDecoration(color: PdfColors.grey100),
          ),
        ],
      ],
    ),
  );

  return doc.save();
}
