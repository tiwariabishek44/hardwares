import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hardwares/app/services/saved_items_service.dart';

class SelectedItemsController extends GetxController {
  final SavedItemsService _savedItemsService = Get.find<SavedItemsService>();
  var isLoading = false.obs;

  // Selection mode variables
  var isSelectionMode = false.obs;
  var selectedItems = <int>[].obs;

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

  // Calculate grand total from existing rates
  double get grandTotal => locallySavedItems.fold(
        0.0,
        (sum, item) {
          final rate = (item['rate'] ?? 0.0) as double;
          final quantity = (item['quantity'] ?? 1) as int;
          return sum + (rate * quantity);
        },
      );
}
