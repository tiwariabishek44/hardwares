import 'item_price_list.dart';
import 'price_list_base.dart';

class RejalcoPriceList implements PriceListBase {
  @override
  String get companyCode => 'Reja100';

  @override
  String get companyName => 'Rejalco';

  @override
  List<ItemPriceList> getItems() {
    // For now, return empty list or copy structure from other price lists
    return [];
  }
}
