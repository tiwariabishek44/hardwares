import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hardwares/app/app_data/item_data_model.dart';
import 'package:hardwares/app/modules/items_details/items_details_controller.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

class ItemDetailView extends StatelessWidget {
  final PriceListItem item;

  const ItemDetailView({Key? key, required this.item}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ItemDetailController controller = Get.put(ItemDetailController());

    // Initialize controller with item data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.initializeItem(item);
    });

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Item Details'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: Column(
        children: [
          // Main Content
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Combined Image and Item Info Section
                  _buildImageAndInfoSection(item, controller),

                  // Combined Variant Type and Size Selection Section
                  _buildVariantSelectionSection(controller),

                  // Quantity Section
                  _buildQuantitySection(item, controller),

                  const SizedBox(height: 80), // Space for bottom button
                ],
              ),
            ),
          ),

          // Bottom Add to List Button
          _buildBottomButton(controller, context),
        ],
      ),
    );
  }

  Widget _buildImageAndInfoSection(
      PriceListItem item, ItemDetailController controller) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image Section
          Container(
            width: double.infinity,
            height: 200,
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
              child: item.imageUrl.isNotEmpty
                  ? Image.asset(
                      item.imageUrl,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return _buildPlaceholderImage();
                      },
                    )
                  : _buildPlaceholderImage(),
            ),
          ),

          // Item Info Section
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Item Name
                Text(
                  item.itemName,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                    height: 1.3,
                  ),
                ),

                const SizedBox(height: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      color: Colors.grey[200],
      child: const Center(
        child: Icon(
          Icons.image_not_supported,
          size: 64,
          color: Colors.grey,
        ),
      ),
    );
  }

  Widget _buildVariantSelectionSection(ItemDetailController controller) {
    return Obx(() {
      // Only show if item has variants
      if (!controller.hasVariants) {
        return const SizedBox.shrink();
      }

      return Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Variant Type Section (only show for UPVC items)
            if (controller.hasVariantTypes()) ...[
              const Text(
                'Select Variant Type',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  // S/F Button
                  Expanded(
                    child: GestureDetector(
                      onTap: () => controller.selectVariantType('R/F'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: controller.selectedVariantType.value == 'R/F'
                              ? Colors.blue[600]
                              : Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: controller.selectedVariantType.value == 'R/F'
                                ? Colors.blue[600]!
                                : Colors.grey[300]!,
                          ),
                        ),
                        child: Text(
                          'R/F',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: controller.selectedVariantType.value == 'R/F'
                                ? Colors.white
                                : Colors.black87,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // R/F Button
                  Expanded(
                    child: GestureDetector(
                      onTap: () => controller.selectVariantType('S/F'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: controller.selectedVariantType.value == 'S/F'
                              ? Colors.blue[600]
                              : Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: controller.selectedVariantType.value == 'S/F'
                                ? Colors.blue[600]!
                                : Colors.grey[300]!,
                          ),
                        ),
                        child: Text(
                          'S/F',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: controller.selectedVariantType.value == 'S/F'
                                ? Colors.white
                                : Colors.black87,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Divider
              Container(
                height: 1,
                width: double.infinity,
                color: Colors.grey[200],
              ),
              const SizedBox(height: 20),
            ],

            // Size Selection Section (always show if has variants)
            const Text(
              'Select Size',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            if (controller.availableSizes.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Text(
                  controller.hasVariantTypes()
                      ? 'Please select variant type first'
                      : 'No sizes available',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: controller.availableSizes.map((size) {
                  final isSelected = controller.selectedSize.value == size;
                  return GestureDetector(
                    onTap: () => controller.selectSize(size),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color:
                            isSelected ? Colors.green[600] : Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected
                              ? Colors.green[600]!
                              : Colors.grey[300]!,
                        ),
                      ),
                      child: Text(
                        size,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: isSelected ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
      );
    });
  }

  // Update the _buildQuantitySection in the view file:
  Widget _buildQuantitySection(
      PriceListItem item, ItemDetailController controller) {
    return Column(
      children: [
        SizedBox(height: 8),
        if (item.subType == 'pipe')
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                // Custom Size Input
                Text("Enter Size",
                    style: TextStyle(
                      fontSize: 17.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    )),
                const SizedBox(width: 12),
                SizedBox(
                  width: 80,
                  height: 40,
                  child: TextField(
                    controller: controller.customSizeController,
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'mm',
                  style: TextStyle(
                    fontSize: 16,
                    color: Color.fromARGB(255, 73, 73, 73),
                  ),
                ),
              ],
            ),
          ),
        SizedBox(height: item.subType == 'pipe' ? 8 : 0),
        Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Quantity',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  // Decrease Button
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: IconButton(
                      onPressed: controller.decrementQuantity,
                      icon: const Icon(Icons.remove, size: 16),
                      padding: EdgeInsets.zero,
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Quantity Input
                  SizedBox(
                    width: 80,
                    height: 40,
                    child: TextField(
                      controller: controller.quantityController,
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(4),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 8),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      onChanged: controller.updateQuantityFromInput,
                      onSubmitted: (_) => controller.validateQuantityInput(),
                      onTapOutside: (_) => controller.validateQuantityInput(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${item.unit}',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color.fromARGB(255, 73, 73, 73),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Increase Button
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: IconButton(
                      onPressed: controller.incrementQuantity,
                      icon: const Icon(Icons.add, size: 16),
                      padding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBottomButton(
      ItemDetailController controller, BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: double.infinity,
              height: 52,
              child: Obx(() => ElevatedButton(
                    onPressed: () {
                      if ((item.subType == 'pipe') &&
                          controller.customSizeController.text.isEmpty) {
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: const Text('Size Required'),
                              content:
                                  const Text('Please enter the size for pipe.'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  child: const Text('OK'),
                                ),
                              ],
                            );
                          },
                        );
                        return;
                      }
                      controller.addItemToLocalList();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[600],
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey[300],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: controller.isLoading.value
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : const Text(
                            'Add to List',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  )),
            ),
          ],
        ),
      ),
    );
  }
}
