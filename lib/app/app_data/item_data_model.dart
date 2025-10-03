class Variant {
  final String size; // 110mm, 160mm, etc.
  final double rate; // price
  final String? pressureRating; // "2.5 Kg/cm2", "4 Kg/cm2", etc.
  final String? length; // "3mtrs", "6mtrs"

  Variant({
    required this.size,
    required this.rate,
    this.pressureRating,
    this.length,
  });
}

// Price List Item model
class PriceListItem {
  final String itemName;
  final String itemCode;
  final String companyName; // Nepatop, Marvel, or empty for additional items
  final String category; // upvc, ppr, cpvc, additional_items (lowercase)
  final String imageUrl;
  final String unit; // default is 'pic'
  final List<Variant> variants;
  final String? subType;
  final bool
      isCompanyItems; // true for company items, false for additional items

  PriceListItem({
    required this.itemName,
    required this.itemCode,
    required this.companyName,
    required this.category,
    required this.imageUrl,
    this.unit = 'pic',
    required this.variants,
    this.subType,
    required this.isCompanyItems,
  });
}
