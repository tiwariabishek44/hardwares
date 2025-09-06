import '../hardware_items.dart';

class ItemPriceList {
  final int? id;
  final String companyCode;
  final String itemName;
  final String category;
  final String itemCode;
  final Map<String, double>
      sizeVariants; // Size variants with their respective prices

  ItemPriceList({
    this.id,
    required this.companyCode,
    required this.itemName,
    required this.category,
    required this.itemCode,
    this.sizeVariants = const {},
  });

  // Convert from database map
  factory ItemPriceList.fromMap(Map<String, dynamic> map) {
    // Parse size variants and prices from comma-separated strings
    Map<String, double> sizeVariantsMap = {};
    if (map['size_variants'] != null && map['prices'] != null) {
      List<String> sizes = map['size_variants']
          .toString()
          .split(',')
          .map((size) => size.trim())
          .where((size) => size.isNotEmpty)
          .toList();
      List<String> prices = map['prices']
          .toString()
          .split(',')
          .map((price) => price.trim())
          .where((price) => price.isNotEmpty)
          .toList();

      for (int i = 0; i < sizes.length && i < prices.length; i++) {
        sizeVariantsMap[sizes[i]] = double.tryParse(prices[i]) ?? 0.0;
      }
    }

    return ItemPriceList(
      id: map['id'],
      companyCode: map['company_code'] ?? '',
      itemName: map['item_name'] ?? '',
      category: map['category'] ?? '',
      itemCode: map['item_code'] ?? '',
      sizeVariants: sizeVariantsMap,
    );
  }

  // Convert to database map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'company_code': companyCode,
      'item_name': itemName,
      'category': category,
      'item_code': itemCode,
      'size_variants':
          sizeVariants.keys.join(','), // Store sizes as comma-separated string
      'prices': sizeVariants.values
          .map((price) => price.toString())
          .join(','), // Store prices as comma-separated string
    };
  }

  // Check if item matches a hardware item by code
  bool matchesHardwareItem(HardwareItem hardwareItem) {
    return itemCode == hardwareItem.itemCode &&
        category.toLowerCase() == hardwareItem.category.toLowerCase();
  }
}
