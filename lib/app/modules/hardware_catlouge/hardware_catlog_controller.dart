import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:hardwares/app/app_data/item_data_model.dart';
import 'package:hardwares/app/utils/catalog_data_utils.dart';

class CatalogController extends GetxController {
  // Observable lists
  var allItems = <PriceListItem>[].obs;
  var filteredItems = <PriceListItem>[].obs;
  var categories = <String>[].obs;
  var companies = <String>[].obs;
  var availableCompanies = <String>[].obs;

  // Selected values
  var selectedCategory = 'ppr'.obs; // Default to PPR
  var selectedCompany = 'Nepatop'.obs; // Default to Nepatop

  // Loading state
  var isLoading = false.obs;

  // Search
  var searchQuery = ''.obs;
  final TextEditingController searchController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    initializeData();
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }

  void initializeData() {
    try {
      isLoading.value = true;

      // Load all data using utils
      allItems.value = CatalogDataUtils.getAllItems();
      categories.value = CatalogDataUtils.getCategories();
      companies.value = CatalogDataUtils.getCompanies();

      // Set initial available companies for PPR
      availableCompanies.value =
          CatalogDataUtils.getCompaniesForCategory(selectedCategory.value);

      // Apply initial filter
      applyFilters();

      isLoading.value = false;
    } catch (e) {
      isLoading.value = false;
      Get.snackbar('Error', 'Failed to load catalog data: ${e.toString()}');
    }
  }

  // Change category
  void changeCategory(String category) {
    if (!CatalogDataUtils.isValidCategory(category)) return;

    selectedCategory.value = category;

    // Update available companies
    if (category == 'additional_items') {
      // availableCompanies.clear();
      // selectedCompany.value = '';
    } else {
      availableCompanies.value =
          CatalogDataUtils.getCompaniesForCategory(category);
      // Set default company to Nepatop if available
      if (availableCompanies.contains('Nepatop')) {
        selectedCompany.value = 'Nepatop';
      } else if (availableCompanies.isNotEmpty) {
        selectedCompany.value = availableCompanies.first;
      }
    }

    applyFilters();
  }

  // Change company
  void changeCompany(String company) {
    if (!CatalogDataUtils.isValidCompany(company)) return;

    selectedCompany.value = company;
    applyFilters();
  }

  // Apply filters
  void applyFilters() {
    List<PriceListItem> result;

    if (selectedCategory.value == 'additional') {
      // Additional items - no company filter
      result = CatalogDataUtils.filterByCategory(selectedCategory.value);
    } else if (selectedCompany.value.isEmpty) {
      // Category only
      result = CatalogDataUtils.filterByCategory(selectedCategory.value);
    } else {
      // Category and company
      result = CatalogDataUtils.filterByCategoryAndCompany(
          selectedCategory.value, selectedCompany.value);
    }

    // Apply search if any
    if (searchQuery.value.isNotEmpty) {
      result = CatalogDataUtils.searchItems(searchQuery.value, result);
    }

    filteredItems.value = result;
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

  // Getter methods using utils
  String getCategoryDisplayName(String category) {
    return CatalogDataUtils.getCategoryDisplayName(category);
  }

  Color getCompanyColor(String company) {
    final colorHex = CatalogDataUtils.getCompanyColor(company);
    return Color(int.parse(colorHex.replaceFirst('#', '0xFF')));
  }

  bool get shouldShowCompanyDropdown {
    return selectedCategory.value.isNotEmpty &&
        selectedCategory.value != 'additional_items';
  }

  int get totalItemsCount => filteredItems.length;

  // Get items count for category (for UI badges)
  int getCategoryItemCount(String category) {
    return CatalogDataUtils.getItemsCountForCategory(category);
  }

  // Navigation to item details
  void showItemDetails(PriceListItem item) {
    // This will be implemented when you have the item details page
    Get.snackbar('Item Selected', 'Selected: ${item.itemName}');
  }

  // Reset filters
  void resetFilters() {
    selectedCategory.value = 'ppr';
    selectedCompany.value = 'Nepatop';
    searchQuery.value = '';
    searchController.clear();
    availableCompanies.value = CatalogDataUtils.getCompaniesForCategory('ppr');
    applyFilters();
  }

  // Get filter summary for UI
  String getFilterSummary() {
    if (selectedCategory.value.isEmpty) {
      return 'Showing all items (${totalItemsCount})';
    }

    String categoryName = getCategoryDisplayName(selectedCategory.value);

    if (selectedCategory.value == 'additional_items') {
      return 'Showing $categoryName (${totalItemsCount})';
    }

    if (selectedCompany.value.isEmpty) {
      return 'Showing all $categoryName items (${totalItemsCount})';
    }

    return 'Showing $categoryName from ${selectedCompany.value} (${totalItemsCount})';
  }
}
