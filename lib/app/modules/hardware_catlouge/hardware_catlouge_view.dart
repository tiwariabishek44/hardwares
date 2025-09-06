import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hardwares/app/data/hardware_items.dart';
import 'package:hardwares/app/modules/hardware_catlouge/hardware_catlog_controller.dart';
import 'package:hardwares/app/modules/items_details/items_details_controller.dart';
import 'package:hardwares/app/modules/selected_items/selected_items_view.dart';
import 'package:hardwares/app/services/saved_items_service.dart';
import 'package:hardwares/app/widget/category_filter.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

class HardwareCatalogView extends StatelessWidget {
  HardwareCatalogView({Key? key}) : super(key: key);
  final itemDetailController = Get.put(ItemDetailController());

  @override
  Widget build(BuildContext context) {
    final HardwareCatalogController controller =
        Get.put(HardwareCatalogController());

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(controller, context),
      body: Obx(() => controller.isLoading.value
          ? _buildLoadingView()
          : _buildMainContent(controller)),
    );
  }

  // Clean Professional White App Bar
  PreferredSizeWidget _buildAppBar(
      HardwareCatalogController controller, BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      foregroundColor: Color(0xFF212121),
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      title: Text(
        'Hardware Items',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Color(0xFF212121),
        ),
      ),
      actions: [
        Obx(() {
          final selectedItemCount = SavedItemsService.savedItems.length;
          return Container(
            margin: EdgeInsets.only(right: 16),
            child: Stack(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Color(0xFF1976D2), width: 1.5),
                  ),
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => SelectedItemsView()),
                      );
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.list_alt,
                          color: Color(0xFF1976D2),
                          size: 18,
                        ),
                        SizedBox(width: 6),
                        Text(
                          ' List',
                          style: TextStyle(
                            color: Color(0xFF1976D2),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (selectedItemCount > 0)
                  Positioned(
                    right: -4,
                    top: -4,
                    child: Container(
                      padding: EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Color(0xFF1976D2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      constraints: BoxConstraints(minWidth: 18, minHeight: 18),
                      child: Text(
                        '$selectedItemCount',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
          );
        }),
      ],
    );
  }

  // Clean Loading View
  Widget _buildLoadingView() {
    return Center(
      child: Container(
        padding: EdgeInsets.all(32),
        margin: EdgeInsets.symmetric(horizontal: 32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              color: Color(0xFF1976D2),
              strokeWidth: 3,
            ),
            SizedBox(height: 20),
            Text(
              'Loading Hardware Items',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF212121),
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Please wait while we load the catalog...',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Main Content with Clean Layout
  Widget _buildMainContent(HardwareCatalogController controller) {
    return Column(
      children: [
        // Category Filter Section
        Container(
          color: Color(0xFFF8F9FA),
          padding: EdgeInsets.symmetric(vertical: 12),
          child: CategoryFilter(controller: controller),
        ),

        // Items List Section
        Expanded(
          child: Container(
            color: Color(0xFFF8F9FA),
            child: Obx(() => controller.filteredItems.isEmpty
                ? _buildEmptyView(controller)
                : _buildItemsList(controller)),
          ),
        ),
      ],
    );
  }

  // Professional Empty View
  Widget _buildEmptyView(HardwareCatalogController controller) {
    return Container(
      padding: EdgeInsets.all(32),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Empty state illustration
            Container(
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.grid_view,
                size: 60,
                color: Colors.grey[400],
              ),
            ),

            SizedBox(height: 24),

            // Empty message
            Text(
              controller.searchQuery.value.isNotEmpty
                  ? 'No items found'
                  : 'No items in this category',
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.w600,
                color: Color(0xFF212121),
              ),
              textAlign: TextAlign.center,
            ),

            SizedBox(height: 12),

            Text(
              controller.searchQuery.value.isNotEmpty
                  ? 'Try searching for different items'
                  : 'Select another category to view items',
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),

            SizedBox(height: 24),

            // Action button
            if (controller.searchQuery.value.isNotEmpty)
              ElevatedButton(
                onPressed: () => controller.clearSearch(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF1976D2),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: Text(
                  'Clear Search',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Clean Items List - Updated to Grid View
  Widget _buildItemsList(HardwareCatalogController controller) {
    return Container(
      padding: EdgeInsets.all(12),
      child: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3, // 3 items per row
          childAspectRatio: 0.5, // Better aspect ratio for image + name
          crossAxisSpacing: 5, // Space between columns
          mainAxisSpacing: 4, // Space between rows
        ),
        itemCount: controller.filteredItems.length,
        itemBuilder: (context, index) {
          HardwareItem item = controller.filteredItems[index];
          return _buildItemCard(item, controller, index);
        },
      ),
    );
  }

  // Simplified Item Card Widget for Grid View
  Widget _buildItemCard(
      HardwareItem item, HardwareCatalogController controller, int index) {
    return GestureDetector(
      onTap: () => controller.showItemDetails(item),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            // Item Image Section
            Expanded(
              flex: 2,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(8),
                    topRight: Radius.circular(8),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(8),
                    topRight: Radius.circular(8),
                  ),
                  child: Image.asset(
                    item.imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[100],
                        child: Icon(
                          Icons.image_not_supported,
                          color: Colors.grey[400],
                          size: 24,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),

            // Item Name Section
            Expanded(
              flex: 2,
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.all(8),
                child: Center(
                  child: Text(
                    item.nameEnglish,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF212121),
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
