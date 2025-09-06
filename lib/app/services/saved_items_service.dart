import 'dart:developer';
import 'dart:convert';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class SavedItemsService extends GetxService {
  final storage = GetStorage();
  static const String _storageKey = 'saved_hardware_items';

  // Single source of truth for saved items
  static RxList<Map<String, dynamic>> savedItems = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadSavedItems();
  }

  // Load saved items from storage
  void loadSavedItems() {
    try {
      final savedData = storage.read(_storageKey);
      if (savedData != null) {
        final List<dynamic> itemsList = jsonDecode(savedData);
        savedItems.value = itemsList.cast<Map<String, dynamic>>();
        log('SavedItemsService: Loaded ${savedItems.length} items from storage');
      } else {
        savedItems.clear();
      }
    } catch (e) {
      log('SavedItemsService: Error loading saved items: $e');
      savedItems.clear();
    }
  }

  // Save items to storage
  void _saveToStorage() {
    try {
      final jsonString = jsonEncode(savedItems.toList());
      storage.write(_storageKey, jsonString);
      log('SavedItemsService: Saved ${savedItems.length} items to storage');
    } catch (e) {
      log('SavedItemsService: Error saving items: $e');
    }
  }

  // Add or update item
  void addOrUpdateItem(Map<String, dynamic> newItem) {
    final id = newItem['id'];
    final selectedSize = newItem['selectedSize'];

    // Check if item with same ID and size already exists
    int existingItemIndex = savedItems.indexWhere((savedItem) =>
        savedItem['id'] == id && savedItem['selectedSize'] == selectedSize);

    if (existingItemIndex != -1) {
      // Update quantity of existing item
      savedItems[existingItemIndex]['quantity'] += newItem['quantity'];
    } else {
      // Add new item
      savedItems.add(newItem);
    }

    _saveToStorage();
    savedItems.refresh();
    log('SavedItemsService: Item added/updated - ${newItem['nameEnglish']}');
  }

  // Remove item by index
  void removeItem(int index) {
    if (index >= 0 && index < savedItems.length) {
      savedItems.removeAt(index);
      _saveToStorage();
      savedItems.refresh();
      log('SavedItemsService: Item removed at index $index');
    }
  }

  // Clear all items
  void clearAllItems() {
    savedItems.clear();
    storage.remove(_storageKey);
    savedItems.refresh();
    log('SavedItemsService: All saved items cleared');
  }

  // Update item quantity
  void updateItemQuantity(int index, int newQuantity) {
    if (index >= 0 && index < savedItems.length) {
      if (newQuantity > 0) {
        savedItems[index]['quantity'] = newQuantity;
        _saveToStorage();
        savedItems.refresh();
      } else {
        removeItem(index);
      }
    }
  }

  // Get total items count
  int get totalItems => savedItems.length;

  // Get total quantity
  int get totalQuantity =>
      savedItems.fold(0, (sum, item) => sum + (item['quantity'] as int));
}
