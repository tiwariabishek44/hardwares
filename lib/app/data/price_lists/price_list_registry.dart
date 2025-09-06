import 'item_price_list.dart';
import 'marvel_price_list.dart';
import 'nepatop_price_list.dart';
import 'price_list_base.dart';
import 'rejalco_price_list.dart';

class PriceListRegistry {
  // Singleton pattern
  static final PriceListRegistry _instance = PriceListRegistry._internal();
  factory PriceListRegistry() => _instance;
  PriceListRegistry._internal();

  // List of all available price lists
  final List<PriceListBase> _priceLists = [
    NepatopPriceList(),
    MarvelPriceList(),
    RejalcoPriceList(),
  ];

  // Get all registered price lists
  List<PriceListBase> getAllPriceLists() => _priceLists;

  // Get a specific price list by company code
  PriceListBase? getPriceListByCode(String code) {
    try {
      return _priceLists.firstWhere((list) => list.companyCode == code);
    } catch (e) {
      return null;
    }
  }

  // Get a specific price list by company name
  PriceListBase? getPriceListByName(String name) {
    try {
      return _priceLists.firstWhere(
        (list) => list.companyName.toLowerCase() == name.toLowerCase(),
      );
    } catch (e) {
      return null;
    }
  }

  // Get all items from all price lists
  List<ItemPriceList> getAllItems() {
    List<ItemPriceList> allItems = [];
    for (var priceList in _priceLists) {
      allItems.addAll(priceList.getItems());
    }
    return allItems;
  }

  // Get items for a specific company code
  List<ItemPriceList> getItemsByCompanyCode(String code) {
    final priceList = getPriceListByCode(code);
    return priceList?.getItems() ?? [];
  }
}
