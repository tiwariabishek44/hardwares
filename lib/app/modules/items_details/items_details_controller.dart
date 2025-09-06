import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hardwares/app/data/hardware_items.dart';
import 'package:hardwares/app/services/saved_items_service.dart';

class ItemDetailController extends GetxController {
  // Observable variables
  var currentItem = Rxn<HardwareItem>();
  var selectedSize = ''.obs;
  var quantity = 1.obs;
  var isLoading = false.obs;
  final quantityController = TextEditingController();

  // Get the shared service
  final SavedItemsService _savedItemsService = Get.find<SavedItemsService>();

  @override
  void onInit() {
    super.onInit();
    quantityController.text = quantity.value.toString();

    // Listen to quantity changes to update text field
    ever(quantity, (value) {
      if (quantityController.text != value.toString()) {
        quantityController.text = value.toString();
        quantityController.selection = TextSelection.fromPosition(
            TextPosition(offset: quantityController.text.length));
      }
    });
  }

  // Initialize with item data
  void initializeItem(HardwareItem item) {
    currentItem.value = item;
    if (item.sizeVariants.isNotEmpty) {
      selectedSize.value = item.sizeVariants.first;
    } else {
      selectedSize.value = '';
    }
    quantity.value = 1;
    quantityController.text = quantity.value.toString();
    isLoading.value = false;
  }

  // Select size variant
  void selectSize(String size) {
    selectedSize.value = size;
  }

  // Increment quantity
  void incrementQuantity() {
    quantity.value++;
  }

  // Decrement quantity
  void decrementQuantity() {
    if (quantity.value > 1) {
      quantity.value--;
    }
  }

  // Update quantity from text input
  void updateQuantityFromInput(String value) {
    final intValue = int.tryParse(value);
    if (intValue != null && intValue > 0) {
      quantity.value = intValue;
    }
  }

  // Method to add/update item using shared service
  void addItemToLocalList() {
    if (currentItem.value == null) {
      Get.snackbar('Error', 'No item selected to add.');
      return;
    }
    if (quantity.value <= 0) {
      Get.snackbar(
          'Invalid Quantity', 'Please enter a quantity greater than 0.');
      return;
    }

    isLoading.value = true;

    Future.delayed(Duration(milliseconds: 500), () {
      final item = currentItem.value!;
      final size = item.sizeVariants.isNotEmpty ? selectedSize.value : 'N/A';

      // Check if item already exists
      bool itemExists = SavedItemsService.savedItems.any((savedItem) =>
          savedItem['id'] == item.id && savedItem['selectedSize'] == size);

      // Create item data
      final itemData = {
        'id': item.id,
        'itemCode': item.itemCode,
        'nameEnglish': item.nameEnglish,
        'category': item.category,
        'imageUrl': item.imageUrl,
        'selectedSize': size,
        'isbrandItem': item.isbrandItem,
        'quantity': quantity.value,
        'dateAdded': DateTime.now().toIso8601String(),
        'rate': 0.0,
      };

      // Add/update using shared service
      _savedItemsService.addOrUpdateItem(itemData);

      String successTitle = itemExists ? 'Quantity Updated' : 'Item Added';
      Color successColor = itemExists ? Colors.green : Colors.blue;

      isLoading.value = false;

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
                SizedBox(height: 16),
                Text(
                  successTitle,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                    color: successColor,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  item.nameEnglish,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
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
                    minimumSize: Size(120, 45),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).pop();
                  },
                  child: Text("OK",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          );
        },
      );
    });
  }

  @override
  void onClose() {
    quantityController.dispose();
    super.onClose();
  }
}
