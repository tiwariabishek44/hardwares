import 'package:hardwares/app/app_data/item_data_model.dart';
import 'package:hardwares/app/app_data/nepatop_price_list.dart';
import 'package:hardwares/app/app_data/marvel_pricelis.dart';
import 'package:hardwares/app/app_data/additional_items_list.dart';

class CatalogDataUtils {
  // Get all items from all sources
  static List<PriceListItem> getAllItems() {
    return [
      ...nepatopPriceList,
      ...marvelPriceList,
      ...additionalItemsList,
    ];
  }

  // Get all available categories
  static List<String> getCategories() {
    return ['ppr', 'cpvc', 'upvc', 'additional'];
  }

  // Get all available companies
  static List<String> getCompanies() {
    return ['Nepatop', 'Marvel'];
  }

  // Get companies for a specific category
  static List<String> getCompaniesForCategory(String category) {
    if (category == 'additional') {
      return []; // No companies for additional items
    }
    return ['Nepatop', 'Marvel'];
  }

  // Filter items by category only
  static List<PriceListItem> filterByCategory(String category) {
    return getAllItems()
        .where((item) => item.category.toLowerCase() == category.toLowerCase())
        .toList();
  }

  // Filter items by category and company
  static List<PriceListItem> filterByCategoryAndCompany(
      String category, String company) {
    return getAllItems()
        .where((item) =>
            item.category.toLowerCase() == category.toLowerCase() &&
            item.companyName.toLowerCase() == company.toLowerCase())
        .toList();
  }

  // Filter items by company only
  static List<PriceListItem> filterByCompany(String company) {
    return getAllItems()
        .where(
            (item) => item.companyName.toLowerCase() == company.toLowerCase())
        .toList();
  }

  // Search items by query (name or code)
  static List<PriceListItem> searchItems(
      String query, List<PriceListItem> sourceItems) {
    if (query.isEmpty) return sourceItems;

    return sourceItems.where((item) {
      return item.itemName.toLowerCase().contains(query.toLowerCase()) ||
          item.itemCode.toLowerCase().contains(query.toLowerCase());
    }).toList();
  }

  // Get category display name
  static String getCategoryDisplayName(String category) {
    switch (category.toLowerCase()) {
      case 'ppr':
        return 'PPR';
      case 'cpvc':
        return 'CPVC';
      case 'upvc':
        return 'UPVC';
      case 'additional':
        return 'Tools & Supplies';
      default:
        return category.toUpperCase();
    }
  }

  // Get company color
  static String getCompanyColor(String company) {
    switch (company.toLowerCase()) {
      case 'nepatop':
        return '#1976D2'; // Blue
      case 'marvel':
        return '#E57373'; // Red
      default:
        return '#81C784'; // Green
    }
  }

  // Get items count for category
  static int getItemsCountForCategory(String category) {
    return filterByCategory(category).length;
  }

  // Get items count for company
  static int getItemsCountForCompany(String company) {
    return filterByCompany(company).length;
  }

  // Get items count for category and company
  static int getItemsCountForCategoryAndCompany(
      String category, String company) {
    return filterByCategoryAndCompany(category, company).length;
  }

  // Get unique item codes (for validation)
  static List<String> getAllItemCodes() {
    return getAllItems().map((item) => item.itemCode).toList();
  }

  // Get item by code
  static PriceListItem? getItemByCode(String itemCode) {
    try {
      return getAllItems().firstWhere((item) => item.itemCode == itemCode);
    } catch (e) {
      return null;
    }
  }

  // Get variants for an item
  static List<Variant> getVariantsForItem(String itemCode) {
    final item = getItemByCode(itemCode);
    return item?.variants ?? [];
  }

  // Get price range for an item
  static String getPriceRangeForItem(String itemCode) {
    final item = getItemByCode(itemCode);
    if (item == null || item.variants.isEmpty) return 'N/A';

    final rates = item.variants.map((v) => v.rate).toList();
    final minRate = rates.reduce((a, b) => a < b ? a : b);
    final maxRate = rates.reduce((a, b) => a > b ? a : b);

    if (minRate == maxRate) {
      return 'Rs. ${minRate.toStringAsFixed(2)}';
    } else {
      return 'Rs. ${minRate.toStringAsFixed(2)} - Rs. ${maxRate.toStringAsFixed(2)}';
    }
  }

  // Validation methods
  static bool isValidCategory(String category) {
    return getCategories().contains(category.toLowerCase());
  }

  static bool isValidCompany(String company) {
    return getCompanies().any((c) => c.toLowerCase() == company.toLowerCase());
  }

  static bool hasItemsForCategory(String category) {
    return getItemsCountForCategory(category) > 0;
  }

  static bool hasItemsForCompany(String company) {
    return getItemsCountForCompany(company) > 0;
  }
}
