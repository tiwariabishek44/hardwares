import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hardwares/app/modules/hardware_catlouge/hardware_catlog_controller.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

class CategoryFilter extends StatelessWidget {
  final HardwareCatalogController controller;

  const CategoryFilter({
    Key? key,
    required this.controller,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Category Filter Section
          Container(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Container(
              height: 44,
              child: Obx(() => ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    itemCount: controller.categories.length,
                    itemBuilder: (context, index) {
                      String category = controller.categories[index];
                      return _buildCompactCategoryButton(category);
                    },
                  )),
            ),
          ),
        ],
      ),
    );
  }

  // Compact Professional Category Button
  Widget _buildCompactCategoryButton(String category) {
    return GestureDetector(
      onTap: () => controller.changeCategory(category),
      child: Obx(() {
        bool isSelected = controller.selectedCategory.value == category;

        return Container(
          margin: EdgeInsets.only(right: 8),
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? Color(0xFF1976D2) : Colors.grey[50],
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isSelected ? Color(0xFF1976D2) : Colors.grey[300]!,
              width: 1,
            ),
          ),
          child: Center(
            child: Text(
              controller.getCategoryDisplayName(category),
              style: TextStyle(
                fontSize: 17.sp,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w700,
                color: isSelected ? Colors.white : Color(0xFF424242),
              ),
            ),
          ),
        );
      }),
    );
  }
}
