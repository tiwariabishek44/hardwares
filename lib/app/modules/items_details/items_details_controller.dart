import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hardwares/app/app_data/item_data_model.dart';
import 'package:hardwares/app/services/saved_items_service.dart';

class ItemDetailController extends GetxController {
  // Current item (PriceListItem instead of HardwareItem)
  var currentItem = Rx<PriceListItem?>(null);
  final TextEditingController customSizeController = TextEditingController();

  // Selected variant type (Self Fit / R/F)
  var selectedVariantType = ''.obs;

  // Available sizes for selected type
  var availableSizes = <String>[].obs;

  // Selected size
  var selectedSize = ''.obs;

  // Quantity management
  var quantity = 1.obs;
  final TextEditingController quantityController = TextEditingController();

  // Loading state
  var isLoading = false.obs;

  // Flag to prevent circular updates
  bool _isUpdatingFromInput = false;

  // Get the shared service
  final SavedItemsService _savedItemsService = Get.find<SavedItemsService>();

  @override
  void onInit() {
    super.onInit();
    quantityController.text = quantity.value.toString();

    // Listen to quantity changes to update text field (but avoid circular updates)
    ever(quantity, (value) {
      if (!_isUpdatingFromInput) {
        if (quantityController.text != value.toString()) {
          quantityController.text = value.toString();
          quantityController.selection = TextSelection.fromPosition(
              TextPosition(offset: quantityController.text.length));
        }
      }
    });
  }

  @override
  void onClose() {
    quantityController.dispose();
    super.onClose();
  }

  // Function to detect if we should show variant types (only for UPVC items)
  bool hasVariantTypes() {
    if (currentItem.value == null) return false;

    // Only show variant types for UPVC category
    return currentItem.value!.category.toLowerCase() == 'upvc';
  }

  // Get available types for UPVC items
  List<String> getAvailableTypes() {
    if (currentItem.value == null || !hasVariantTypes()) return [];

    // For UPVC items, return fixed types
    return ['R/F', 'S/F'];
  }

  void initializeItem(PriceListItem item) {
    currentItem.value = item;

    if (hasVariantTypes()) {
      // For UPVC items - show variant type selection
      final types = getAvailableTypes();

      // Auto-select first type (S/F)
      if (types.isNotEmpty) {
        selectVariantType(types.first);
      }
    } else {
      // For non-UPVC items - show all sizes directly
      availableSizes.value = item.variants.map((v) => v.size).toList();
      if (availableSizes.isNotEmpty) {
        selectedSize.value = availableSizes.first;
      }
      // Clear variant type since we're not using it
      selectedVariantType.value = '';
    }

    // Reset quantity
    quantity.value = 1;
    _isUpdatingFromInput = false;
    quantityController.text = '1';
  }

  void selectVariantType(String type) {
    selectedVariantType.value = type;

    // For UPVC items, all variants have the same sizes regardless of type
    // So we just show all available sizes
    availableSizes.value =
        currentItem.value!.variants.map((v) => v.size).toList();

    // Auto-select first size if available
    if (availableSizes.isNotEmpty) {
      selectedSize.value = availableSizes.first;
    } else {
      selectedSize.value = '';
    }
  }

  void selectSize(String size) {
    selectedSize.value = size;
  }

  void incrementQuantity() {
    _isUpdatingFromInput = false;
    quantity.value++;
  }

  void decrementQuantity() {
    _isUpdatingFromInput = false;
    if (quantity.value > 0) {
      // Allow going down to 0
      quantity.value--;
    }
  }

  // FIXED: Better handling of text input
  void updateQuantityFromInput(String value) {
    _isUpdatingFromInput = true;

    // Allow empty string temporarily (user might be typing)
    if (value.isEmpty) {
      return;
    }

    // Parse the input
    final int? newQuantity = int.tryParse(value);

    if (newQuantity != null && newQuantity >= 0) {
      // Valid input (including 0)
      quantity.value = newQuantity;
    }
    // Don't reset the text field for invalid input - let user continue typing

    _isUpdatingFromInput = false;
  }

  // Method to validate and fix quantity when focus is lost
  void validateQuantityInput() {
    final String currentText = quantityController.text;

    if (currentText.isEmpty) {
      // If empty, set to 1
      quantity.value = 1;
      quantityController.text = '1';
    } else {
      final int? parsedQuantity = int.tryParse(currentText);
      if (parsedQuantity == null || parsedQuantity < 0) {
        // If invalid, reset to current quantity value or 1
        quantity.value = quantity.value > 0 ? quantity.value : 1;
        quantityController.text = quantity.value.toString();
      }
    }
  }

  // Get current rate for selected variant
  double getCurrentRate() {
    if (currentItem.value == null || selectedSize.value.isEmpty) {
      return 0.0;
    }

    try {
      // For all items, just find by size since variants don't have type field anymore
      Variant selectedVariant = currentItem.value!.variants.firstWhere(
        (v) => v.size == selectedSize.value,
      );

      return selectedVariant.rate;
    } catch (e) {
      return 0.0;
    }
  }

  // Method to add/update item using shared service
  void addItemToLocalList() {
    // Validate quantity before adding
    if (quantity.value <= 0) {
      Get.snackbar(
          'Invalid Quantity', 'Please enter a quantity greater than 0.');
      return;
    }

    if (currentItem.value == null) {
      Get.snackbar('Error', 'No item selected to add.');
      return;
    }

    // Only check variant type for UPVC items
    if (hasVariantTypes() && selectedVariantType.value.isEmpty) {
      Get.snackbar('Error', 'Please select variant type');
      return;
    }

    if (selectedSize.value.isEmpty) {
      Get.snackbar('Error', 'Please select size');
      return;
    }

    isLoading.value = true;

    Future.delayed(const Duration(milliseconds: 500), () {
      final item = currentItem.value!;
      final rate = getCurrentRate();

      // Create unique key - include type only for UPVC items
      final String uniqueKey = hasVariantTypes()
          ? '${item.itemCode}_${selectedVariantType.value}_${selectedSize.value}'
          : '${item.itemCode}_${selectedSize.value}';

      // Check if item already exists
      bool itemExists = SavedItemsService.savedItems
          .any((savedItem) => savedItem['uniqueKey'] == uniqueKey);
      // Create item data to save
      final itemData = {
        'uniqueKey': uniqueKey,
        'unit': item.unit,
        'itemCode': item.itemCode,
        'itemName': item.itemName,
        'category': item.category,
        'companyName': item.companyName,
        'imageUrl': item.imageUrl,
        'isCompanyItems': item.isCompanyItems,
        'subType': item.subType,
        'selectedVariantType': hasVariantTypes()
            ? selectedVariantType.value
            : '', // Empty for non-UPVC
        'selectedSize': item.subType != 'pipe'
            ? selectedSize.value
            : customSizeController.text.trim() + " mm",
        "subVariant":
            item.subType == 'pipe' ? selectedSize.value : '', // Only for pipes
        'rate': rate,
        'quantity': quantity.value,
        'dateAdded': DateTime.now().toIso8601String(),
      };

      // Add/update using shared service
      _savedItemsService.addOrUpdateItem(itemData);

      String successTitle = itemExists ? 'Quantity Updated' : 'Item Added';
      Color successColor = itemExists ? Colors.green : Colors.blue;

      isLoading.value = false;

      // Show success dialog
      showDialog(
        context: Get.context!,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle_outline, color: successColor, size: 64),
                const SizedBox(height: 16),
                Text(
                  successTitle,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                    color: successColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  item.itemName,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  hasVariantTypes()
                      ? '${selectedVariantType.value} - ${selectedSize.value}'
                      : selectedSize.value,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                const SizedBox(height: 4),
                Text(
                  'Quantity: ${quantity.value} ${item.unit}',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
            actions: [
              Center(
                child: TextButton(
                  style: TextButton.styleFrom(
                    backgroundColor: successColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    minimumSize: const Size(120, 45),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop(); // Close dialog
                    Navigator.of(context).pop(); // Go back to previous screen
                  },
                  child: const Text(
                    "OK",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          );
        },
      );

      log('ItemDetailController: Item added/updated - ${item.itemName}');
    });
  }

  // Alias method for backward compatibility with the view
  void addToCart() {
    addItemToLocalList();
  }

  // Getters for UI
  List<String> get availableVariantTypes => getAvailableTypes();

  bool get hasVariants {
    return currentItem.value?.variants.isNotEmpty ?? false;
  }
}
