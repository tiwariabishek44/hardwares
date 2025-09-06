import 'package:hardwares/app/data/price_lists/price_list_registry.dart';

import 'item_price_list.dart';

class CompanyPriceList {
  static List<ItemPriceList> getItems() {
    return PriceListRegistry().getAllItems();
  }

  static List<ItemPriceList> getItemsByCompany(String companyCode) {
    return PriceListRegistry().getItemsByCompanyCode(companyCode);
  }

  static List<String> getAvailableCompanies() {
    return PriceListRegistry()
        .getAllPriceLists()
        .map((list) => list.companyName)
        .toList();
  }
}
