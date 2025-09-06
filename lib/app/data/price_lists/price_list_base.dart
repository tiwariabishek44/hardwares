import 'item_price_list.dart';

abstract class PriceListBase {
  String get companyCode;
  String get companyName;
  List<ItemPriceList> getItems();
}
