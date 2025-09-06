import 'cpvc_items.dart';
import 'ppr_items.dart';
import 'upvc_items.dart';

class HardwareItem {
  final int? id;
  final String itemCode;
  final String nameEnglish;
  final String category;
  final List<String> sizeVariants;
  final String? imageUrl;
  final bool isbrandItem;

  HardwareItem({
    this.id,
    required this.itemCode,
    required this.nameEnglish,
    required this.category,
    this.sizeVariants = const [],
    this.imageUrl,
    required this.isbrandItem,
  });

  // Convert from database map
  factory HardwareItem.fromMap(Map<String, dynamic> map) {
    // Parse size variants from comma-separated string
    List<String> sizeVariantsList = [];
    if (map['size_variants'] != null && map['size_variants'].isNotEmpty) {
      sizeVariantsList = map['size_variants']
          .toString()
          .split(',')
          .map((size) => size.trim())
          .where((size) => size.isNotEmpty)
          .toList();
    }

    return HardwareItem(
      id: map['id'],
      itemCode: map['item_code'] ?? '',
      nameEnglish: map['name_english'] ?? '',
      category: map['category'] ?? '',
      sizeVariants: sizeVariantsList,
      imageUrl: map['image_url'],
      isbrandItem: map['isbrandItem'] ?? false,
    );
  }

  // Convert to database map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'item_code': itemCode,
      'name_english': nameEnglish,
      'category': category,
      'size_variants':
          sizeVariants.join(','), // Store as comma-separated string
      'image_url': imageUrl,
      'isbrandItem': isbrandItem,
    };
  }

  // Get display name
  String getDisplayName() {
    return nameEnglish;
  }

  // Get category display name
  String getCategoryDisplayName() {
    switch (category.toLowerCase()) {
      case 'cpvc':
        return 'CPVC';
      case 'ppr':
        return 'PPR';
      case 'upvc':
        return 'UPVC';
      case 'fittings':
        return 'Fittings';
      case 'additional_items':
        return 'Additional Items';
      case 'tools':
        return 'Tools';
      default:
        return category.toUpperCase();
    }
  }

  // Get available sizes as formatted string
  String getAvailableSizes() {
    if (sizeVariants.isEmpty) return 'No sizes available';
    return sizeVariants.join(', ');
  }

  // Check if specific size is available
  bool isSizeAvailable(String size) {
    return sizeVariants.contains(size.trim());
  }

  // Check if item has multiple sizes
  bool get hasMultipleSizes => sizeVariants.length > 1;

  // Check if item has any sizes
  bool get hasSizes => sizeVariants.isNotEmpty;

  // Get default size (first in list)
  String get defaultSize => sizeVariants.isNotEmpty ? sizeVariants.first : '';

  // Get category color hex code
  String getCategoryColorHex() {
    switch (category.toLowerCase()) {
      case 'cpvc':
        return '#E57373'; // Red-ish
      case 'ppr':
        return '#81C784'; // Green
      case 'upvc':
        return '#64B5F6'; // Blue
      case 'fittings':
        return '#FFB74D'; // Orange
      case 'additional_items':
        return '#BA68C8'; // Purple
      case 'tools':
        return '#4FC3F7'; // Light blue
      default:
        return '#1976D2'; // Default blue
    }
  }
}

class HardwareItemsData {
  static List<HardwareItem> getAllItems() {
    return [
      ...CpvcItems.getItems(),
      ...PprItems.getItems(),
      ...UpvcItems.getItems(),
    ];
  }

  // Get items by category
  static List<HardwareItem> getItemsByCategory(String category) {
    switch (category.toLowerCase()) {
      case 'cpvc':
        return CpvcItems.getItems();
      case 'ppr':
        return PprItems.getItems();
      case 'upvc':
        return UpvcItems.getItems();
      default:
        return [];
    }
  }

  // Search items across all categories
  static List<HardwareItem> searchItems(String query) {
    if (query.isEmpty) return getAllItems();

    return getAllItems().where((item) {
      return item.nameEnglish.toLowerCase().contains(query.toLowerCase()) ||
          item.itemCode.toLowerCase().contains(query.toLowerCase());
    }).toList();
  }

  // Get category statistics
  static Map<String, int> getCategoryStats() {
    return {
      'cpvc': CpvcItems.getItems().length,
      'ppr': PprItems.getItems().length,
      'upvc': UpvcItems.getItems().length,
    };
  }

  // Get total items count
  static int getTotalItemsCount() {
    return getAllItems().length;
  }

  // Get categories list
  static List<String> getCategories() {
    return ['cpvc', 'ppr', 'upvc', 'fittings', 'additional_items', 'tools'];
  }
}
