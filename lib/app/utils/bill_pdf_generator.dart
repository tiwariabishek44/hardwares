import 'dart:developer';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
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
      // Create PDF document with simplified format (no pricing)
      final pdf = pw.Document();

      // Separate pipe items from regular items
      List<Map<String, dynamic>> pipeItems =
          items.where((item) => item['subType'] == 'pipe').toList();
      List<Map<String, dynamic>> regularItems =
          items.where((item) => item['subType'] != 'pipe').toList();

      // Group regular items by category and company
      Map<String, List<Map<String, dynamic>>> groupedItems =
          _groupItemsByCategory(regularItems);

      // Prepare data using the new data model (no amounts)
      int totalQuantity = items.fold(0, (sum, item) {
        return sum + ((item['quantity'] ?? 1) as int);
      });

      log(" --------------we are generating pdf now");

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.all(24),
          maxPages: 100,
          footer: _buildPageFooter,
          build: (pw.Context context) {
            return [
              // Professional header
              _buildCompanyHeader(billCode),
              pw.SizedBox(height: 12),

              // Customer details
              _buildCustomerInfoSection(customerName, phoneNumber, orderDate),
              pw.SizedBox(height: 20),

              // Order summary (without amounts)
              if (items.length > 0)
                _buildOrderSummary(items.length, totalQuantity),
              pw.SizedBox(height: 20),

              // Build grouped items sections (ORIGINAL TABLE - REGULAR ITEMS ONLY)
              if (items.length > 0)
                ...groupedItems.entries.map((categoryEntry) {
                  String categoryCompany = categoryEntry.key;
                  List<Map<String, dynamic>> categoryItems =
                      categoryEntry.value;

                  return _buildCategorySection(categoryCompany, categoryItems);
                }).toList(),

              // ============================================
              // NEW PIPE TABLE SECTION (if pipe items exist)
              // ============================================
              if (pipeItems.isNotEmpty) ...[
                pw.SizedBox(height: 40),

                // Separator line
                pw.Container(
                  height: 2,
                  color: PdfColors.orange700,
                ),

                pw.SizedBox(height: 20),

                // Group pipe items by itemName and companyName
                ..._buildPipeSections(pipeItems),
              ],

              pw.SizedBox(height: 20),

              // Footer with plumber info
              _buildFooterSection(plumberName),
            ];
          },
        ),
      );

      // Format the current date
      String currentDate = DateFormat('yyyy-MM-dd').format(DateTime.now());

      log(' -------------we are now creating file name');
      // Create a sanitized customer name for the filename
      String sanitizedCustomerName = customerName
          .replaceAll(RegExp(r'[^\w\s]+'), '')
          .replaceAll(RegExp(r'\s+'), '_');

      if (sanitizedCustomerName.isEmpty) {
        sanitizedCustomerName = "customer";
      }

      if (sanitizedCustomerName.length > 20) {
        sanitizedCustomerName = sanitizedCustomerName.substring(0, 20);
      }
      log(' -------------file  save');
      // Save and share PDF
      final Directory tempDir = await getTemporaryDirectory();
      final String fileName =
          'requirements_${sanitizedCustomerName}_${currentDate}.pdf';
      final File pdfFile = File('${tempDir.path}/$fileName');
      await pdfFile.writeAsBytes(await pdf.save());

      log("---------------------file share ");
      await Share.shareXFiles(
        [XFile(pdfFile.path)],
        text:
            'Bill Code: $billCode\nCustomer: $customerName\nTotal Items: ${items.length}',
        subject: 'Hardware Requirements List - $billCode',
      );

      log('✅ Requirements list PDF generated and shared successfully as $fileName');
    } catch (e) {
      log('❌ Error generating requirements PDF: $e');
      throw e;
    }
  }

  // NEW: Build pipe sections - group by itemName and companyName
  static List<pw.Widget> _buildPipeSections(
      List<Map<String, dynamic>> pipeItems) {
    // Group pipe items by itemName + companyName
    Map<String, List<Map<String, dynamic>>> groupedPipes = {};

    for (var item in pipeItems) {
      String itemName = item['itemName'] ?? 'Unknown Pipe';
      String companyName = item['companyName'] ?? '';
      String key = '$itemName|$companyName';

      if (!groupedPipes.containsKey(key)) {
        groupedPipes[key] = [];
      }
      groupedPipes[key]!.add(item);
    }

    // Build a section for each group
    List<pw.Widget> sections = [];

    groupedPipes.forEach((key, items) {
      String itemName = key.split('|')[0];
      String companyName = key.split('|')[1];

      sections.addAll([
        // Pipe Header with itemName - companyName
        pw.Container(
          width: double.infinity,
          padding: pw.EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: pw.BoxDecoration(
            color: PdfColors.orange700,
            borderRadius: pw.BorderRadius.circular(4),
          ),
          child: pw.Text(
            '$itemName - $companyName',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
          ),
        ),

        pw.SizedBox(height: 5),

        // Pipe items (NO HEADER ROW)
        ...items.asMap().entries.map((entry) {
          int index = entry.key;
          Map<String, dynamic> item = entry.value;
          bool isEvenRow = index % 2 == 0;

          String subVariant = item['subVariant'] ?? '-';
          String selectedVariantType = item['selectedVariantType'] ?? '-';
          String selectedSize = item['selectedSize'] ?? '-';
          int quantity = (item['quantity'] ?? 1) as int;
          String unit = item['unit'] ?? "";

          return pw.Container(
            decoration: pw.BoxDecoration(
              color: isEvenRow ? PdfColors.orange50 : PdfColors.white,
              border: pw.Border(
                left: pw.BorderSide(width: 1, color: PdfColors.orange200),
                right: pw.BorderSide(width: 1, color: PdfColors.orange200),
                bottom: pw.BorderSide(width: 0.5, color: PdfColors.orange200),
              ),
            ),
            padding: pw.EdgeInsets.symmetric(vertical: 8, horizontal: 10),
            child: pw.Row(
              children: [
                // S.N.
                pw.Expanded(
                  flex: 1,
                  child: pw.Text(
                    '${index + 1}',
                    style: pw.TextStyle(
                      fontSize: 11,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                // subVariant (replaces Company Name column)
                pw.Expanded(
                  flex: 4,
                  child: pw.Text(
                    subVariant,
                    style: pw.TextStyle(fontSize: 11),
                    maxLines: 2,
                  ),
                ),
                // Type
                pw.Expanded(
                  flex: 2,
                  child: pw.Text(
                    selectedVariantType,
                    style: pw.TextStyle(fontSize: 11),
                    textAlign: pw.TextAlign.center,
                    maxLines: 1,
                  ),
                ),
                // Size
                pw.Expanded(
                  flex: 3,
                  child: pw.Text(
                    selectedSize,
                    style: pw.TextStyle(fontSize: 11),
                    textAlign: pw.TextAlign.center,
                    maxLines: 1,
                  ),
                ),
                // Quantity
                pw.Expanded(
                  flex: 1,
                  child: pw.Text(
                    '$quantity' + " " + (unit == "meter" ? "mtr" : "pic"),
                    style: pw.TextStyle(
                      fontSize: 11,
                      fontWeight: pw.FontWeight.bold,
                    ),
                    textAlign: pw.TextAlign.center,
                  ),
                ),
              ],
            ),
          );
        }).toList(),

        pw.SizedBox(height: 20),
      ]);
    });

    return sections;
  }

  // Group items by category and company
  static Map<String, List<Map<String, dynamic>>> _groupItemsByCategory(
      List<Map<String, dynamic>> items) {
    Map<String, List<Map<String, dynamic>>> groupedItems = {};

    for (var item in items) {
      String category = (item['category'] ?? 'OTHERS').toString().toUpperCase();
      String companyName =
          (item['companyName'] == 'Nepatop' ? 'Nepatop' : '').toString();

      // Create a combined key: "CATEGORY - COMPANY"
      String groupKey = '$category - $companyName';

      if (!groupedItems.containsKey(groupKey)) {
        groupedItems[groupKey] = [];
      }
      groupedItems[groupKey]!.add(item);
    }

    // Sort groups: First by category, then by company
    var sortedKeys = groupedItems.keys.toList()
      ..sort((a, b) {
        // Extract category and company from keys
        String categoryA = a.split(' - ')[0];
        String categoryB = b.split(' - ')[0];

        if (categoryA == 'OTHERS') return 1;
        if (categoryB == 'OTHERS') return -1;

        // First sort by category
        int categoryComparison = categoryA.compareTo(categoryB);
        if (categoryComparison != 0) return categoryComparison;

        // Then sort by company within same category
        String companyA = a.split(' - ')[1];
        String companyB = b.split(' - ')[1];
        return companyA.compareTo(companyB);
      });

    Map<String, List<Map<String, dynamic>>> sortedGroupedItems = {};
    for (String key in sortedKeys) {
      sortedGroupedItems[key] = groupedItems[key]!;
    }

    return sortedGroupedItems;
  }

  // Build category section with header and items
  static pw.Widget _buildCategorySection(
      String categoryCompany, List<Map<String, dynamic>> categoryItems) {
    // Split the key to get category and company
    List<String> parts = categoryCompany.split(' - ');
    String category = parts[0];
    String companyName = parts.length > 1 ? parts[1] : '';

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Category Header with Company
        pw.Container(
          width: double.infinity,
          padding: pw.EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: pw.BoxDecoration(
            color: PdfColors.grey200,
            border: pw.Border.all(width: 0.5, color: PdfColors.grey400),
            borderRadius: pw.BorderRadius.circular(4),
          ),
          child: pw.Row(
            children: [
              // Category Badge
              pw.Container(
                padding: pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: pw.BoxDecoration(
                  color: PdfColors.black,
                  borderRadius: pw.BorderRadius.circular(3),
                ),
                child: pw.Text(
                  category,
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                  ),
                ),
              ),
              if (companyName.isNotEmpty) ...[
                pw.SizedBox(width: 8),
                // Company Badge
                pw.Container(
                  padding: pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.blue,
                    borderRadius: pw.BorderRadius.circular(3),
                  ),
                  child: pw.Text(
                    companyName,
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.white,
                    ),
                  ),
                ),
              ],
              pw.SizedBox(width: 12),
              // Item count
              pw.Text(
                '${categoryItems.length} items',
                style: pw.TextStyle(
                  fontSize: 11,
                  color: PdfColors.grey700,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ],
          ),
        ),

        pw.SizedBox(height: 5),

        // Table header for this category
        _buildTableHeader(),

        // Category Items
        ...categoryItems.asMap().entries.map((entry) {
          int index = entry.key;
          Map<String, dynamic> item = entry.value;
          bool isEvenRow = index % 2 == 0;

          return _buildItemTableRow(
            index + 1,
            item,
            isEvenRow,
          );
        }).toList(),

        pw.SizedBox(height: 15),
      ],
    );
  }

  static pw.Widget _buildCompanyHeader(String billCode) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'Hardware Requirements List',
              style: pw.TextStyle(
                fontSize: 24,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 5),
            pw.Text(
              'Item Requirements List',
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
            'Bill Code: $billCode',
            style: pw.TextStyle(
              fontSize: 14,
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
                    pw.Text('Customer Name:',
                        style: pw.TextStyle(
                            color: PdfColors.grey700, fontSize: 10)),
                    pw.SizedBox(height: 2),
                    pw.Text(customerName,
                        style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold, fontSize: 12)),
                    pw.SizedBox(height: 8),
                    pw.Text('Phone Number:',
                        style: pw.TextStyle(
                            color: PdfColors.grey700, fontSize: 10)),
                    pw.SizedBox(height: 2),
                    pw.Text(phoneNumber,
                        style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold, fontSize: 12)),
                  ],
                ),
              ),
              pw.Expanded(
                flex: 1,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Date:',
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
            'REQUIREMENTS SUMMARY',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.Row(
            children: [
              pw.Text(
                'Total Items: $totalItems  ',
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildTableHeader() {
    return pw.Container(
      color: PdfColors.grey300,
      padding: pw.EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      child: pw.Row(
        children: [
          pw.Expanded(
            flex: 1,
            child: pw.Text(
              'S.N.',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12),
            ),
          ),
          pw.Expanded(
            flex: 5,
            child: pw.Text(
              'Item Name',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12),
            ),
          ),
          pw.Expanded(
            flex: 2,
            child: pw.Text(
              'Type',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12),
              textAlign: pw.TextAlign.center,
            ),
          ),
          pw.Expanded(
            flex: 3,
            child: pw.Text(
              'Size',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12),
              textAlign: pw.TextAlign.center,
            ),
          ),
          pw.Expanded(
            flex: 1,
            child: pw.Text(
              'Qnty',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12),
              textAlign: pw.TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildItemTableRow(
      int number, Map<String, dynamic> item, bool isEvenRow) {
    // Extract data using new data model fields
    String itemName = item['itemName'] ?? 'Unknown Item';
    String selectedVariantType = item['selectedVariantType'] ?? '-';
    String selectedSize = item['selectedSize'] ?? '-';
    int quantity = (item['quantity'] ?? 1) as int;
    String unit = item['unit'] ?? "";

    return pw.Container(
      color: isEvenRow ? PdfColors.grey50 : PdfColors.white,
      padding: pw.EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      child: pw.Row(
        children: [
          pw.Expanded(
            flex: 1,
            child: pw.Text(
              '$number',
              style:
                  pw.TextStyle(fontSize: 12.4, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.Expanded(
            flex: 5,
            child: pw.Text(
              itemName,
              style: pw.TextStyle(fontSize: 12.4),
              maxLines: 2,
              overflow: pw.TextOverflow.clip,
            ),
          ),
          pw.Expanded(
            flex: 2,
            child: pw.Text(
              selectedVariantType,
              style: pw.TextStyle(fontSize: 12.4),
              textAlign: pw.TextAlign.center,
              maxLines: 1,
            ),
          ),
          pw.Expanded(
            flex: 3,
            child: pw.Text(
              selectedSize,
              style: pw.TextStyle(fontSize: 12.4),
              textAlign: pw.TextAlign.center,
              maxLines: 1,
            ),
          ),
          pw.Expanded(
            flex: 1,
            child: pw.Text(
              '$quantity' + " " + (unit == "meter" ? "mtr" : "pic"),
              style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
              textAlign: pw.TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildFooterSection(String plumberName) {
    return pw.Container(
      padding: pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border(
          top: pw.BorderSide(color: PdfColors.grey300, width: 1),
        ),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(height: 8),
          pw.Text(
            'Note: This is a requirements list for hardware items needed.',
            style: pw.TextStyle(
              fontSize: 10,
              color: PdfColors.grey600,
              fontStyle: pw.FontStyle.italic,
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
