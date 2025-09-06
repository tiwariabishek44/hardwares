import 'dart:developer';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:responsive_sizer/responsive_sizer.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';

class BillPdfGenerator {
  static Future<void> generateAndShareBillPdf({
    required String billCode,
    required String customerName,
    required String phoneNumber,
    required String orderDate,
    required List<Map<String, dynamic>> items,
    required String plumberName,
  }) async {
    try {
      // Create PDF document with professional invoice format
      final pdf = pw.Document();

      // Prepare data
      int totalQuantity =
          items.fold(0, (sum, item) => sum + (item['quantity'] as int? ?? 1));

      // Always use paged format for better reliability with large datasets
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.all(24),
          maxPages: 100,
          footer: _buildPageFooter,
          build: (pw.Context context) {
            return [
              // Professional header with company logo placeholder
              _buildCompanyHeader(billCode),
              pw.SizedBox(height: 12),

              // Bill information in a clean layout
              pw.SizedBox(height: 12),

              // Customer details
              _buildCustomerInfoSection(customerName, phoneNumber, orderDate),
              pw.SizedBox(height: 20),

              // Items Summary
              _buildOrderSummary(items.length, totalQuantity),
              pw.SizedBox(height: 20),

              // Simple table header
              _buildTableHeader(),

              // Fixed simple item rows (no complex nested tables)
              ...items.asMap().entries.map((entry) {
                int index = entry.key;
                Map<String, dynamic> item = entry.value;
                bool isEvenRow = index % 2 == 0;

                return _buildSimpleTableRow(
                  index + 1,
                  item['nameEnglish'] ?? item['name'] ?? 'Unknown Item',
                  item['category'] ?? 'Others',
                  item['selectedSize'] ?? '-',
                  item['quantity'] ?? 1,
                  isEvenRow,
                );
              }).toList(),

              pw.SizedBox(height: 20),
            ];
          },
        ),
      );

      // Format the current date
      String currentDate = DateFormat('yyyy-MM-dd').format(DateTime.now());

      // Create a sanitized customer name for the filename (remove special characters)
      String sanitizedCustomerName = customerName
          .replaceAll(RegExp(r'[^\w\s]+'), '') // Remove special chars
          .replaceAll(RegExp(r'\s+'), '_'); // Replace spaces with underscores

      // If sanitized name is empty (rare case), use "customer" as fallback
      if (sanitizedCustomerName.isEmpty) {
        sanitizedCustomerName = "customer";
      }

      // Limit name length to avoid excessively long filenames
      if (sanitizedCustomerName.length > 20) {
        sanitizedCustomerName = sanitizedCustomerName.substring(0, 20);
      }

      // Save and share PDF with the new filename format
      final Directory tempDir = await getTemporaryDirectory();
      final String fileName =
          'bill_${sanitizedCustomerName}_${currentDate}.pdf';
      final File pdfFile = File('${tempDir.path}/$fileName');
      await pdfFile.writeAsBytes(await pdf.save());

      await Share.shareXFiles(
        [XFile(pdfFile.path)],
        text: 'Bill Code: ${billCode.toUpperCase()}\nCustomer: $customerName',
        subject: 'Hardware Bill - ${billCode.toUpperCase()}',
      );

      log('Bill PDF generated and shared successfully as $fileName');
    } catch (e) {
      log('❌ Error generating bill PDF: $e');
      throw e;
    }
  }

  static pw.Widget _buildCompanyHeader(String billCode) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'Requirement List ',
              style: pw.TextStyle(
                fontSize: 24,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 5),
            pw.Text(
              'Hardware Items Requirement List',
              style: pw.TextStyle(
                fontSize: 12,
                color: PdfColors.grey700,
              ),
            ),
          ],
        ),
        pw.Container(
          padding: pw.EdgeInsets.all(10),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.black),
            borderRadius: pw.BorderRadius.circular(5),
          ),
          child: pw.Text(
            'BILL Code : ${billCode}',
            style: pw.TextStyle(
              fontSize: 20.sp,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildCustomerInfoSection(
      String customerName, String phoneNumber, String orderDate) {
    return pw.Container(
      padding: pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(width: 0.5, color: PdfColors.grey400),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'CUSTOMER DETAILS',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.Divider(color: PdfColors.grey300),
          pw.SizedBox(height: 8),
          pw.Row(
            children: [
              pw.Expanded(
                flex: 1,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Bill To:',
                        style: pw.TextStyle(
                            color: PdfColors.grey700, fontSize: 10)),
                    pw.SizedBox(height: 2),
                    pw.Text(customerName,
                        style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold, fontSize: 12)),
                    pw.SizedBox(height: 4),
                    pw.Text('$orderDate', style: pw.TextStyle(fontSize: 10)),
                  ],
                ),
              ),
              pw.Expanded(
                flex: 1,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Bill Date :',
                        style: pw.TextStyle(
                            color: PdfColors.grey700, fontSize: 10)),
                    pw.SizedBox(height: 2),
                    pw.Text(orderDate,
                        style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildOrderSummary(int totalItems, int totalQuantity) {
    return pw.Container(
      padding: pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey200,
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'LIST SUMMARY',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.Text(
            'Total Items: $totalItems  ',
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildTableHeader() {
    return pw.Container(
      color: PdfColors.grey200,
      padding: pw.EdgeInsets.symmetric(vertical: 6, horizontal: 10),
      child: pw.Row(
        children: [
          pw.Expanded(
            flex: 1,
            child: pw.Text(
              'No.',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
            ),
          ),
          pw.Expanded(
            flex: 5,
            child: pw.Text(
              'Item Description',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
            ),
          ),
          pw.Expanded(
            flex: 2,
            child: pw.Text(
              'Size',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
              textAlign: pw.TextAlign.center,
            ),
          ),
          pw.Expanded(
            flex: 1,
            child: pw.Text(
              'Qty',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
              textAlign: pw.TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildSimpleTableRow(int number, String description,
      String category, String size, int quantity, bool isEvenRow) {
    return pw.Container(
      color: isEvenRow ? PdfColors.grey100 : PdfColors.white,
      padding: pw.EdgeInsets.symmetric(vertical: 4, horizontal: 10),
      child: pw.Row(
        children: [
          pw.Expanded(
            flex: 1,
            child: pw.Text('$number', style: pw.TextStyle(fontSize: 11)),
          ),
          pw.Expanded(
            flex: 5,
            child: pw.Text(
              description,
              style: pw.TextStyle(fontSize: 12),
              maxLines: 1,
              overflow: pw.TextOverflow.clip,
            ),
          ),
          pw.Expanded(
            flex: 2,
            child: pw.Text(
              size,
              style: pw.TextStyle(fontSize: 12),
              textAlign: pw.TextAlign.center,
              maxLines: 1,
            ),
          ),
          pw.Expanded(
            flex: 1,
            child: pw.Text(
              '$quantity',
              style: pw.TextStyle(fontSize: 12),
              textAlign: pw.TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildPageFooter(pw.Context context) {
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      margin: const pw.EdgeInsets.only(top: 10),
      child: pw.Text(
        'Page ${context.pageNumber} of ${context.pagesCount}',
        style: pw.TextStyle(
          fontSize: 8,
          fontStyle: pw.FontStyle.italic,
          color: PdfColors.grey700,
        ),
      ),
    );
  }
}
