import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hardwares/app/data/price_lists/price_list.dart';
import 'package:hardwares/app/data/price_lists/price_list_registry.dart';
import 'package:hardwares/app/modules/customer_details_entry/customer_details_view.dart';
import 'package:hardwares/app/modules/selected_items/selecte_items_controller.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

class SelectedItemsView extends StatelessWidget {
  final controller = Get.put(SelectedItemsController());

  @override
  Widget build(BuildContext context) {
    return Obx(() => Scaffold(
          backgroundColor: Colors.white,
          appBar: _buildAppBar(context),
          body: _buildBody(context),
          bottomNavigationBar: controller.isPriceUpdateLoading.value
              ? null
              : _buildBottomBar(context),
        ));
  }

  Widget _buildBody(BuildContext context) {
    if (controller.isLoading.value) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: Color(0xFF1976D2),
              strokeWidth: 3,
            ),
            SizedBox(height: 16),
            Text(
              'Loading items...',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    if (controller.locallySavedItems.isEmpty) {
      return _buildEmptyState(context);
    }

    return _buildItemsList(context);
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.plumbing_outlined,
            size: 43.sp,
            color: Colors.grey[400],
          ),
          SizedBox(height: 20),
          Text(
            'No Items Selected',
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.w600,
              color: Color(0xFF212121),
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Start adding items from the catalog to see them here',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16.sp,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 24),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      foregroundColor: Color(0xFF212121),
      scrolledUnderElevation: 0,
      elevation: 0,
      centerTitle: false,
      title: Text(
        controller.isSelectionMode.value
            ? '${controller.selectedCount} Selected'
            : 'Selected Items (${controller.locallySavedItems.length})',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Color(0xFF212121),
        ),
      ),
      leading: IconButton(
        icon: Icon(
          controller.isSelectionMode.value ? Icons.close : Icons.arrow_back,
          color: Color(0xFF212121),
        ),
        onPressed: controller.isSelectionMode.value
            ? () => controller.toggleSelectionMode()
            : () => Navigator.pop(context),
      ),
      actions: _buildAppBarActions(),
    );
  }

  List<Widget> _buildAppBarActions() {
    List<Widget> actions = [];

    if (controller.isSelectionMode.value) {
      actions.add(
        TextButton(
          onPressed: () => controller.selectAll(),
          child: Text(
            'Select All',
            style: TextStyle(
              color: Color(0xFF1976D2),
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
      );
    } else if (controller.locallySavedItems.isNotEmpty) {
      actions.add(
        IconButton(
          icon: Icon(Icons.delete_outline, color: Color(0xFF212121)),
          onPressed: () => controller.toggleSelectionMode(),
          tooltip: 'Delete Items',
        ),
      );
    }

    actions.add(SizedBox(width: 8));
    return actions;
  }

  Widget _buildBottomBar(BuildContext context) {
    if (controller.isSelectionMode.value) {
      return Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: Colors.grey[300]!, width: 1),
          ),
        ),
        child: SafeArea(
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => controller.toggleSelectionMode(),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.grey[400]!),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: controller.selectedCount > 0
                      ? () => _showDeleteSelectedDialog(context)
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[600],
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey[300],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 14),
                    elevation: 0,
                  ),
                  child: Text(
                    'Delete (${controller.selectedCount})',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    } else if (controller.locallySavedItems.isNotEmpty) {
      return Row(
        children: [
          Expanded(
            flex: 7,
            child: Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(color: Colors.grey[300]!, width: 1),
                ),
              ),
              child: SafeArea(
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Get.to(
                        () => CustomerDetailsView(),
                        arguments: controller.locallySavedItems.toList(),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF1976D2),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                    ),
                    child: Text(
                      'Continue (Rs. ${controller.grandTotal.toStringAsFixed(0)})',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(width: 2),
          Expanded(
            flex: 3,
            child: OutlinedButton(
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: false,
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(18)),
                  ),
                  builder: (context) => _companyChooseSheet(context),
                );
              },
              style: OutlinedButton.styleFrom(
                backgroundColor: Colors.white,
                side: BorderSide(color: Colors.grey[300]!, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: EdgeInsets.symmetric(vertical: 14),
              ),
              child: Obx(
                () => Text(
                  controller.brand.value != ''
                      ? controller.brand.value
                      : 'Brand',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
              ),
            ),
          ),
          SizedBox(width: 8),
        ],
      );
    }
    return SizedBox();
  }

  Widget _buildItemsList(BuildContext context) {
    return Container(
      color: Color(0xFFF8F9FA),
      child: Column(
        children: [
          // Items List
          Expanded(
            child: ListView.separated(
              padding: EdgeInsets.zero,
              itemCount: controller.locallySavedItems.length,
              separatorBuilder: (context, index) => Divider(
                height: 1,
                color: const Color.fromARGB(255, 210, 208, 208),
                indent: 16,
                endIndent: 16,
              ),
              itemBuilder: (context, index) {
                final item = controller.locallySavedItems[index];
                return _buildItemRow(item, index, context);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemRow(
      Map<String, dynamic> item, int index, BuildContext context) {
    final rate = item['rate'] ?? item['price'] ?? 0.0;

    return GestureDetector(
      onTap: controller.isSelectionMode.value
          ? () => controller.toggleItemSelection(index)
          : null,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 2, horizontal: 8),
        padding: EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: controller.isSelectionMode.value &&
                    controller.isItemSelected(index)
                ? Color(0xFF1976D2)
                : Colors.grey[300]!,
            width: controller.isSelectionMode.value &&
                    controller.isItemSelected(index)
                ? 2
                : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Stack(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child:
                        item['imageUrl'] != null && item['imageUrl'].isNotEmpty
                            ? Image.asset(
                                item['imageUrl'],
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) {
                                  return Icon(Icons.hardware,
                                      size: 40, color: Colors.grey[400]);
                                },
                              )
                            : Icon(Icons.hardware,
                                size: 40, color: Colors.grey[400]),
                  ),
                ),
                if (item['isbrandItem'] == true)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      padding: EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 2,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.verified,
                        color: Colors.green,
                        size: 18,
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(width: 14),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name
                  Text(
                    item['nameEnglish'] ?? item['name'] ?? 'Unknown Item',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF212121),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 6),
                  // Size
                  if (item['selectedSize'] != null)
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 4.0, horizontal: 8.0),
                        child: Text(
                          'Size: ${item['selectedSize']}',
                          style: TextStyle(
                            fontSize: 14,
                            color: const Color.fromARGB(255, 43, 42, 42),
                          ),
                        ),
                      ),
                    ),
                  SizedBox(height: 8),
                  // Rate
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          "Rs ${rate.toStringAsFixed(2)}",
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.green[800],
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(width: 8),
                      Text(
                        '/ Rs ${((item['quantity'] ?? 1) * rate).toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.blueGrey[700],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Quantity & Checkbox
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (controller.isSelectionMode.value) ...[
                  Checkbox(
                    value: controller.isItemSelected(index),
                    onChanged: (_) => controller.toggleItemSelection(index),
                    activeColor: Color(0xFF1976D2),
                  ),
                ],
                SizedBox(height: 8),
                Container(
                  margin: EdgeInsets.only(left: 8),
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: Color(0xFF1976D2).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Color(0xFF1976D2).withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    '${item['quantity'] ?? 1} pcs',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1976D2),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Updated with your delete logic
  void _showDeleteSelectedDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.warning, color: Colors.orange[600], size: 24),
              SizedBox(width: 8),
              Text(
                'Delete Items',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF212121),
                ),
              ),
            ],
          ),
          content: Text(
            'Are you sure you want to delete ${controller.selectedCount} selected items? This action cannot be undone.',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[700],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                controller.deleteSelectedItems();

                // Show success snackbar
                Get.snackbar(
                  'Success',
                  '${controller.selectedCount} items deleted successfully',
                  backgroundColor: Colors.green[600],
                  colorText: Colors.white,
                  duration: Duration(seconds: 2),
                  margin: EdgeInsets.all(16),
                  borderRadius: 8,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[600],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              child: Text(
                'Delete',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // Updated company choose sheet without callback parameter
  Widget _companyChooseSheet(BuildContext context) {
    // Get available companies from registry
    final availableCompanies = CompanyPriceList.getAvailableCompanies();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Text(
            "Choose Company",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF212121),
            ),
          ),
          SizedBox(height: 20),
          ...availableCompanies.map((company) {
            IconData icon;
            Color iconColor;

            // Assign appropriate icon and color based on company name
            switch (company.toLowerCase()) {
              case 'nepatop':
                icon = Icons.verified;
                iconColor = Colors.green;
                break;
              case 'marvel':
                icon = Icons.star;
                iconColor = Colors.blue;
                break;
              default:
                icon = Icons.business;
                iconColor = Colors.orange;
            }

            // Get company code from registry
            final priceList = PriceListRegistry().getPriceListByName(company);
            final companyCode = priceList?.companyCode ?? '';

            return Column(
              children: [
                _companyTile(context, company, icon, iconColor, () {
                  Navigator.of(context).pop(); // Close bottom sheet
                  _applyCompanyPrices(context, company, companyCode);
                }),
                SizedBox(height: 8),
              ],
            );
          }).toList(),
        ],
      ),
    );
  }

  // New method to handle dialog properly
  void _applyCompanyPrices(
      BuildContext context, String brandName, String companyCode) async {
    controller.brand.value = brandName;

    // Create a dialog context that we can reference later
    BuildContext? dialogContext;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        dialogContext = context;
        return Dialog(
          backgroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            width: 320,
            padding: EdgeInsets.all(24),
            child: Obx(() => Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Applying Prices...",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Color(0xFF212121),
                      ),
                    ),
                    SizedBox(height: 24),
                    LinearProgressIndicator(
                      value: controller.priceUpdateProgress.value,
                      minHeight: 8,
                      backgroundColor: Colors.grey[200],
                      color: Color(0xFF1976D2),
                    ),
                    SizedBox(height: 18),
                    Text(
                      "${(controller.priceUpdateProgress.value * 100).toStringAsFixed(0)}%",
                      style: TextStyle(
                          fontWeight: FontWeight.w600, color: Colors.grey[700]),
                    ),
                  ],
                )),
          ),
        );
      },
    );

    // Apply the prices
    await controller.applyCompanyPrices(companyCode);

    // Close the dialog after prices are applied (with a brief delay for smoothness)
    await Future.delayed(const Duration(milliseconds: 300));
    if (dialogContext != null) {
      Navigator.of(dialogContext!).pop();
    }
  }

  Widget _companyTile(BuildContext context, String name, IconData icon,
      Color iconColor, VoidCallback onTap) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        child: Row(
          children: [
            SizedBox(width: 16),
            Expanded(
              child: Text(
                name,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF212121),
                ),
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey[500]),
          ],
        ),
      ),
    );
  }
}
