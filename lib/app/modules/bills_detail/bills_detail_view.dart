import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import 'package:hardwares/app/modules/bills_detail/bills_detail_controller.dart';

class BillsDetailView extends StatefulWidget {
  BillsDetailView({Key? key}) : super(key: key);

  @override
  State<BillsDetailView> createState() => _BillsDetailViewState();
}

class _BillsDetailViewState extends State<BillsDetailView> {
  final BillsDetailController controller = Get.put(BillsDetailController());

  @override
  void initState() {
    super.initState();

    final isSynced = controller.orderData['synced'] == 1;

    if (!isSynced) {
      // Sync to Firebase first
      controller.syncToFirebaseBeforeShare();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Check if order needs to be synced first

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: Obx(() {
        if (controller.isLoading.value) {
          return Center(
            child: CircularProgressIndicator(
              color: Colors.black,
              strokeWidth: 2,
            ),
          );
        }

        return SingleChildScrollView(
          child: Column(
            children: [
              _buildHeader(),
              _buildItemsList(),
              SizedBox(height: 80),
            ],
          ),
        );
      }),
      bottomNavigationBar: _buildBottomActions(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text(
        'Bill Details',
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 18,
          color: Colors.black,
        ),
      ),
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
      elevation: 0,
      scrolledUnderElevation: 0,
    );
  }

  Widget _buildHeader() {
    final isSynced = controller.orderData['synced'] == 1;

    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey[300]!, width: 1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sync Status Banner (if not synced)
          if (!isSynced) ...[
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange[700], size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This bill needs to be uploaded to the server',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.orange[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),
          ],

          // Bill Code with sync status
          Row(
            children: [
              Text(
                'Bill Code:',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
              ),
              SizedBox(width: 12),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  controller.billCode,
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 1,
                  ),
                ),
              ),
              SizedBox(width: 8),
              IconButton(
                icon: Icon(Icons.copy, color: Colors.grey[600], size: 21.sp),
                onPressed: _copyBillCode,
                tooltip: 'Copy',
              ),
              Spacer(),
              // Sync status indicator
            ],
          ),

          SizedBox(height: 0.4.h),

          // Customer Name
          Row(
            children: [
              Text(
                'Customer:',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  controller.customerName,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: 0.5.h),

          // Phone Number
          Row(
            children: [
              Text(
                'Phone:',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
              ),
              SizedBox(width: 12),
              Text(
                controller.phoneNumber,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),

          // Date
          Row(
            children: [
              Text(
                'Date:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
              ),
              SizedBox(width: 12),
              Text(
                controller.orderDate,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildItemsList() {
    // Group items by category
    Map<String, List<Map<String, dynamic>>> groupedItems =
        _groupItemsByCategory();

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey[300]!, width: 1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Items Header
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.grey[300]!, width: 1),
              ),
            ),
            child: Row(
              children: [
                Text(
                  'Items',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${controller.orderItems.length} items',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Items List grouped by category
          ...groupedItems.entries.map((categoryEntry) {
            String category = categoryEntry.key;
            List<Map<String, dynamic>> categoryItems = categoryEntry.value;

            return _buildCategorySection(category, categoryItems, groupedItems);
          }).toList(),
        ],
      ),
    );
  }

  Map<String, List<Map<String, dynamic>>> _groupItemsByCategory() {
    Map<String, List<Map<String, dynamic>>> groupedItems = {};

    for (var item in controller.orderItems) {
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

  Widget _buildCategorySection(
      String categoryCompany, // This now contains "CATEGORY - COMPANY"
      List<Map<String, dynamic>> categoryItems,
      Map<String, List<Map<String, dynamic>>> allGroupedItems) {
    bool isLastCategory = allGroupedItems.keys.last == categoryCompany;

    // Split the key to get category and company
    List<String> parts = categoryCompany.split(' - ');
    String category = parts[0];
    String companyName = parts.length > 1 ? parts[1] : 'Unknown';

    return Column(
      children: [
        // Category Header with Company
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            border: Border(
              bottom: BorderSide(color: Colors.grey[200]!, width: 1),
            ),
          ),
          child: Row(
            children: [
              // Category Badge
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  category,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              SizedBox(width: 8),
              // Company Badge
              if (companyName != "")
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue[600],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    companyName,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              SizedBox(width: 12),
              // Item count
              Text(
                '${categoryItems.length} items',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),

        // Category Items
        ...categoryItems.asMap().entries.map((entry) {
          int index = entry.key;
          Map<String, dynamic> item = entry.value;
          bool isLastItem = index == categoryItems.length - 1;

          return _buildItemRow(item, index + 1, isLastItem && isLastCategory);
        }).toList(),
      ],
    );
  }

  Widget _buildItemRow(Map<String, dynamic> item, int index, bool isLast) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(
                bottom: BorderSide(color: Colors.grey[200]!, width: 1),
              ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Item Number
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[400]!),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Center(
                  child: Text(
                    '$index',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),

              SizedBox(width: 12),

              // Item Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['itemName'] ?? 'Unknown Item',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                      ),
                    ),
                    if (item['selectedSize'] != null) ...[
                      SizedBox(height: 2),
                      Text(
                        '${item['selectedVariantType'] ?? ''} -> Size: ${item['selectedSize']}',
                        style: TextStyle(
                          fontSize: 16.sp,
                          color: const Color.fromARGB(255, 20, 20, 20),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Quantity
              Container(
                padding: EdgeInsets.symmetric(horizontal: 1.w, vertical: 0.5.h),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[400]!),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Qty:${item['quantity'] ?? 1} ${item['unit'] == 'meter' ? " mtr" : ' pic'}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
              ),
            ],
          ),
          if (item['subType'] == 'pipe') ...[
            SizedBox(height: 8),
            Row(
              children: [
                SizedBox(width: 36), // Align with item name
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${item['subVariant']}',
                    maxLines: 2,
                    style: TextStyle(
                      fontSize: 15.sp,
                      color: Colors.black,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBottomActions() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey[300]!, width: 1),
        ),
      ),
      child: Row(
        children: [
          // Share as PDF
          Expanded(
            child: Obx(() => ElevatedButton(
                  onPressed: controller.isGeneratingPdf.value
                      ? null
                      : () => controller.shareAsPdf(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: controller.isGeneratingPdf.value
                        ? Colors.grey[500]
                        : const Color.fromARGB(255, 10, 168, 99),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                    elevation: 0,
                  ),
                  child: controller.isGeneratingPdf.value
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(width: 12),
                            Text('Generating PDF...'),
                          ],
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.image, color: Colors.white, size: 24),
                            SizedBox(width: 12),
                            Text(
                              'Share as PDF',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                )),
          ),
        ],
      ),
    );
  }

  void _copyBillCode() {
    Clipboard.setData(ClipboardData(text: controller.billCode.toUpperCase()));
    Get.snackbar(
      'Copied',
      'Bill code copied to clipboard',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.black,
      colorText: Colors.white,
      duration: Duration(seconds: 2),
      margin: EdgeInsets.all(16),
    );
  }
}
