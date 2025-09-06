import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:hardwares/app/data/hardware_items.dart';
import 'package:hardwares/app/modules/items_details/items_details.dart';
import 'package:hardwares/app/utils/app_setting_service.dart';

class HardwareCatalogController extends GetxController {
  // Services
  final AppSettingsService _settingsService = Get.find<AppSettingsService>();

  // Observable variables
  var isLoading = false.obs;
  var selectedCategory = 'cpvc'.obs;
  var searchQuery = ''.obs;
  var useNepaliLanguage = true.obs;

  // Hardware items
  var allItems = <HardwareItem>[].obs;
  var filteredItems = <HardwareItem>[].obs;

  // Simple plumbing categories
  var categories = <String>[
    'cpvc',
    'ppr',
    'upvc',
    'additional_items',
  ].obs;

  // Text controllers
  final TextEditingController searchController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    useNepaliLanguage.value = _settingsService.selectedLanguage.value == 'ne';
    loadHardwareItems();
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }

  // Load all hardware items from data file (NO DATABASE)
  void loadHardwareItems() {
    try {
      isLoading.value = true;

      // Get items from static data
      allItems.value = HardwareItemsData.getAllItems();

      applyFilters();
    } catch (e) {
      print('Error loading hardware items: $e');
      Get.snackbar(
        'त्रुटि / Error',
        'हार्डवेयर सामानहरू लोड गर्न सकिएन / Could not load hardware items',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red[600],
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Apply filters based on category and search
  void applyFilters() {
    List<HardwareItem> filtered = allItems
        .where((item) => item.category == selectedCategory.value)
        .toList();

    // Filter by search query
    if (searchQuery.value.isNotEmpty) {
      String query = searchQuery.value.toLowerCase();
      filtered = filtered.where((item) {
        return item.nameEnglish.toLowerCase().contains(query) ||
            item.itemCode.toLowerCase().contains(query);
      }).toList();
    }

    filteredItems.value = filtered;
  }

  // Change category filter
  void changeCategory(String category) {
    selectedCategory.value = category;
    applyFilters();
  }

  // Search items
  void searchItems(String query) {
    searchQuery.value = query;
    applyFilters();
  }

  // Clear search
  void clearSearch() {
    searchController.clear();
    searchQuery.value = '';
    applyFilters();
  }

  // Toggle language
  void toggleLanguage() {
    useNepaliLanguage.value = !useNepaliLanguage.value;
    _settingsService.setLanguage(useNepaliLanguage.value ? 'ne' : 'en');
  }

  // Get category display name
  String getCategoryDisplayName(String category) {
    switch (category) {
      case 'cpvc':
        return !useNepaliLanguage.value ? 'सीपीभीसी' : 'CPVC';
      case 'ppr':
        return !useNepaliLanguage.value ? 'पीपीआर' : 'PPR';
      case 'upvc':
        return !useNepaliLanguage.value ? 'यूपीभीसी' : 'UPVC';
      case 'fittings':
        return !useNepaliLanguage.value ? 'फिटिङहरू' : 'Fittings';
      case 'additional_items':
        return !useNepaliLanguage.value ? 'अतिरिक्त सामान' : 'Additional Items';
      case 'tools':
        return !useNepaliLanguage.value ? 'औजारहरू' : 'Tools';
      default:
        return category.toUpperCase();
    }
  }

  // Get category color
  Color getCategoryColor(String category) {
    switch (category) {
      case 'cpvc':
        return Color(0xFFE57373); // Red
      case 'ppr':
        return Color(0xFF81C784); // Green
      case 'upvc':
        return Color(0xFF64B5F6); // Blue
      case 'fittings':
        return Color(0xFFFFB74D); // Orange
      case 'additional_items':
        return Color(0xFFBA68C8); // Purple
      case 'tools':
        return Color(0xFF4FC3F7); // Light blue
      default:
        return Color(0xFF1976D2);
    }
  }

  // Get filtered items count for each category
  int getCategoryItemCount(String category) {
    return allItems.where((item) => item.category == category).length;
  }

  // Show item details
  void showItemDetails(HardwareItem item) {
    Get.to(
        () => ItemDetailPage(
              item: item,
            ),
        transition: Transition.rightToLeft);
  }
}
