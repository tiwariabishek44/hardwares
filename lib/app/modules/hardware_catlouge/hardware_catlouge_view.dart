import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hardwares/app/app_data/item_data_model.dart';
import 'package:hardwares/app/modules/hardware_catlouge/hardware_catlog_controller.dart';
import 'package:hardwares/app/modules/items_details/items_details.dart';
import 'package:hardwares/app/modules/selected_items/selected_items_view.dart';
import 'package:hardwares/app/services/saved_items_service.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

class HardwareCatalogView extends StatelessWidget {
  const HardwareCatalogView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final CatalogController controller = Get.put(CatalogController());

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(controller, context),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        return Column(
          children: [
            // Enhanced Filter Section
            _buildFilterSection(controller),

            // Items Grid (3 columns)
            Expanded(
              child: controller.filteredItems.isEmpty
                  ? _buildEmptyState()
                  : _buildItemsList(controller),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildFilterSection(CatalogController controller) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category Selection Section
          _buildCategorySection(controller),

          // Company Selection Section (conditional)
          if (controller.shouldShowCompanyDropdown)
            _buildCompanySection(controller),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(
      CatalogController controller, BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      foregroundColor: Color(0xFF212121),
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      title: Text(
        'Hardware Items',
        style: TextStyle(
          fontSize: 22.sp,
          fontWeight: FontWeight.w600,
          color: Color(0xFF212121),
        ),
      ),
      actions: [
        Obx(() {
          final selectedItemCount = SavedItemsService.savedItems.length;
          return Container(
            margin: EdgeInsets.only(right: 16, top: 8, bottom: 8),
            child: Material(
              borderRadius: BorderRadius.circular(12),
              elevation: 2,
              shadowColor: Colors.blue.withOpacity(0.2),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => SelectedItemsView()),
                  );
                },
                child: AnimatedContainer(
                  duration: Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF1976D2), Color(0xFF42A5F5)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Color(0xFF1976D2).withOpacity(0.3),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0xFF1976D2).withOpacity(0.3),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Animated Icon
                        AnimatedContainer(
                          duration: Duration(milliseconds: 200),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Icon(
                            Icons.list_alt_outlined,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),

                        SizedBox(width: 2),

                        // List Text
                        Text(
                          'List',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),

                        // Count Badge (if items exist)
                        if (selectedItemCount > 0) ...[
                          SizedBox(width: 8),
                          AnimatedContainer(
                            duration: Duration(milliseconds: 300),
                            curve: Curves.elasticOut,
                            padding: EdgeInsets.symmetric(
                                horizontal: 8, vertical: 0),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 2,
                                  offset: Offset(0, 1),
                                ),
                              ],
                            ),
                            child: Text(
                              '$selectedItemCount',
                              style: TextStyle(
                                color: Color(0xFF1976D2),
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildCategorySection(CatalogController controller) {
    return Container(
      padding: const EdgeInsets.only(top: 20, left: 16, right: 16, bottom: 12),
      child: SizedBox(
        height: 45,
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: [
            // Individual Categories
            ...controller.categories.map((category) {
              final isSelected = controller.selectedCategory.value == category;
              return Padding(
                padding: const EdgeInsets.only(right: 14),
                child: GestureDetector(
                  onTap: () => controller.changeCategory(category),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 17, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? Color(0xFF64B5F6) : Colors.grey[100],
                      borderRadius: BorderRadius.circular(2),
                      border: Border.all(
                        color:
                            isSelected ? Color(0xFF64B5F6) : Colors.grey[300]!,
                        width: 1.5,
                      ),
                    ),
                    child: Text(
                      controller.getCategoryDisplayName(category),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white : Colors.grey[700],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildCompanySection(CatalogController controller) {
    return Container(
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Companies List
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: controller.availableCompanies.length,
              itemBuilder: (context, index) {
                final company = controller.availableCompanies[index];
                final isSelected = controller.selectedCompany.value == company;
                final companyColor = controller.getCompanyColor(company);

                return Container(
                  margin: EdgeInsets.only(right: 12),
                  child: Material(
                    borderRadius: BorderRadius.circular(25),
                    elevation: isSelected ? 4 : 1,
                    shadowColor: companyColor.withOpacity(0.3),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(25),
                      onTap: () => controller.changeCompany(company),
                      child: AnimatedContainer(
                        duration: Duration(milliseconds: 200),
                        curve: Curves.easeInOut,
                        padding:
                            EdgeInsets.symmetric(horizontal: 20, vertical: 1),
                        decoration: BoxDecoration(
                          gradient: isSelected
                              ? LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    companyColor,
                                    companyColor.withOpacity(0.8),
                                  ],
                                )
                              : LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Colors.white,
                                    Colors.grey[50]!,
                                  ],
                                ),
                          borderRadius: BorderRadius.circular(25),
                          border: Border.all(
                            color: isSelected
                                ? companyColor.withOpacity(0.5)
                                : companyColor.withOpacity(0.3),
                            width: isSelected ? 2 : 1.5,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: companyColor.withOpacity(0.4),
                                    blurRadius: 8,
                                    offset: Offset(0, 3),
                                  ),
                                  BoxShadow(
                                    color: companyColor.withOpacity(0.1),
                                    blurRadius: 12,
                                    offset: Offset(0, 6),
                                  ),
                                ]
                              : [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.1),
                                    blurRadius: 4,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Company Name
                            Text(
                              company,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: isSelected ? Colors.white : companyColor,
                                letterSpacing: 0.3,
                              ),
                            ),

                            // Selected Check Icon
                            if (isSelected) ...[
                              SizedBox(width: 8),
                              Container(
                                padding: EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.check,
                                  size: 14,
                                  color: companyColor,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsList(CatalogController controller) {
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
          PriceListItem item = controller.filteredItems[index];
          return _buildItemCard(item, index);
        },
      ),
    );
  }

  // Simplified Item Card Widget for Grid View
  Widget _buildItemCard(PriceListItem item, int index) {
    return GestureDetector(
      onTap: () {
        Get.to(() => ItemDetailView(item: item));
      },
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
                    '${item.itemName}',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF212121),
                      height: 1.2,
                    ),
                    maxLines: 3,
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No items found',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your filters',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
}
