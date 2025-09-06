import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hardwares/app/data/price_lists/item_price_list.dart';
import 'package:hardwares/app/data/price_lists/price_list.dart';
import 'package:hardwares/app/services/saved_items_service.dart';

class SelectedItemsController extends GetxController {
  final SavedItemsService _savedItemsService = Get.find<SavedItemsService>();
  var isLoading = false.obs;
  var brand = ''.obs;
  var appliedCompanyCode = ''.obs;

  // Selection mode variables
  var isSelectionMode = false.obs;
  var selectedItems = <int>[].obs;

  // Progress indicator for price updates
  var priceUpdateProgress = 0.0.obs; // Progress value (0.0 to 1.0)
  var isPriceUpdateLoading = false.obs;

  // Use the shared service's saved items
  RxList<Map<String, dynamic>> get locallySavedItems =>
      SavedItemsService.savedItems;

  @override
  void onInit() {
    super.onInit();
  }

  @override
  void onReady() {
    super.onReady();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _savedItemsService.loadSavedItems();
    });
  }

  // Toggle selection mode
  void toggleSelectionMode() {
    isSelectionMode.value = !isSelectionMode.value;
    if (!isSelectionMode.value) {
      selectedItems.clear();
    }
  }

  // Toggle item selection
  void toggleItemSelection(int index) {
    if (selectedItems.contains(index)) {
      selectedItems.remove(index);
    } else {
      selectedItems.add(index);
    }
  }

  // Select all items
  void selectAll() {
    selectedItems.clear();
    for (int i = 0; i < locallySavedItems.length; i++) {
      selectedItems.add(i);
    }
  }

  // Check if item is selected
  bool isItemSelected(int index) {
    return selectedItems.contains(index);
  }

  // Get selected items count
  int get selectedCount => selectedItems.length;

  // Delete selected items with loading and delay
  Future<void> deleteSelectedItems() async {
    isLoading.value = true;

    // Optional: Add a short delay for UX feedback
    await Future.delayed(Duration(milliseconds: 400));

    // Sort indices in descending order to avoid index shifting issues
    final sortedIndices = selectedItems.toList()
      ..sort((a, b) => b.compareTo(a));

    for (int index in sortedIndices) {
      _savedItemsService.removeItem(index);
    }

    // Exit selection mode
    isSelectionMode.value = false;
    selectedItems.clear();

    isLoading.value = false;

    // Show a snackbar or some feedback to the user
    ScaffoldMessenger.of(Get.context!).showSnackBar(
      SnackBar(
        content: Text('${sortedIndices.length} item(s) have been removed.'),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // Remove specific item (for backward compatibility)
  void removeItem(int index) {
    _savedItemsService.removeItem(index);
  }

  // Clear all saved items
  void clearAllSavedItems() {
    _savedItemsService.clearAllItems();
    isSelectionMode.value = false;
    selectedItems.clear();
  }

  // Get total number of items
  int get totalItems => _savedItemsService.totalItems;

  // Update the applyCompanyPrices method
  Future<void> applyCompanyPrices(String companyCode) async {
    isLoading.value = true;
    isPriceUpdateLoading.value = true;
    priceUpdateProgress.value = 0.0;
    appliedCompanyCode.value = companyCode;

    // Get items only for the selected company
    final priceList = CompanyPriceList.getItemsByCompany(companyCode);

    final totalItems = locallySavedItems.length;
    for (int i = 0; i < totalItems; i++) {
      final item = locallySavedItems[i];
      final match = priceList.firstWhere(
        (p) => p.itemCode == item['itemCode'],
        orElse: () => ItemPriceList(
          id: -1,
          companyCode: '',
          itemName: '',
          category: '',
          itemCode: '',
          sizeVariants: {},
        ),
      );

      if (match.itemCode.isNotEmpty) {
        final size = item['selectedSize'] as String?;
        final unitPrice = match.sizeVariants[size] ?? 0.0;
        item['rate'] = unitPrice;
      } else {
        item['rate'] = 0.0;
      }

      // Update progress
      await Future.delayed(const Duration(milliseconds: 100));
      priceUpdateProgress.value = (i + 1) / totalItems;
    }

    locallySavedItems.refresh();
    isLoading.value = false;
    isPriceUpdateLoading.value = false;
    priceUpdateProgress.value = 0.0;
  }

  double get grandTotal => locallySavedItems.fold(
        0.0,
        (sum, item) =>
            sum + ((item['rate'] * (item['quantity'])) as double? ?? 0.0),
      );
}
