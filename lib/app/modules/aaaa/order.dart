import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// ---------- CONTROLLER ----------
class OrderController extends GetxController {
  var selectedCompany = Rxn<Map<String, dynamic>>();
  var orders = <Map<String, dynamic>>[].obs;

  // Dummy customer order items
  final List<Map<String, dynamic>> customerOrders = [
    {
      "category": "Beverages",
      "itemName": "Milo",
      "itemCode": "ITM001",
      "sizeVariant": "500g",
      "quantity": 2,
    },
    {
      "category": "Snacks",
      "itemName": "Lays",
      "itemCode": "ITM002",
      "sizeVariant": "100g",
      "quantity": 5,
    },
    {
      "category": "Personal Care",
      "itemName": "Dove Soap",
      "itemCode": "ITM003",
      "sizeVariant": "100g",
      "quantity": 3,
    },
  ];
  final List<Map<String, dynamic>> companyPriceList = [
    {
      "companyCode": "C001",
      "companyName": "Unilever",
      "items": [
        {
          "itemCode": "ITM001", // Milo
          "variants": [
            {"size": "250g", "price": 140},
            {"size": "500g", "price": 250},
            {"size": "1kg", "price": 480},
          ]
        },
        {
          "itemCode": "ITM002", // Lays
          "variants": [
            {"size": "50g", "price": 30},
            {"size": "100g", "price": 60},
          ]
        },
        {
          "itemCode": "ITM003", // Dove
          "variants": [
            {"size": "75g", "price": 90},
            {"size": "100g", "price": 120},
          ]
        },
        {
          "itemCode": "ITM006", // Sunsilk Shampoo
          "variants": [
            {"size": "200ml", "price": 120},
            {"size": "1L", "price": 180},
          ]
        },
        {
          "itemCode": "ITM007", // Lux Body Wash
          "variants": [
            {"size": "250ml", "price": 150},
            {"size": "500ml", "price": 260},
          ]
        },
        {
          "itemCode": "ITM008", // Pepsodent
          "variants": [
            {"size": "50g", "price": 90},
            {"size": "100g", "price": 160},
          ]
        },
        {
          "itemCode": "ITM009", // Lipton Tea
          "variants": [
            {"size": "250ml", "price": 110},
            {"size": "500ml", "price": 200},
          ]
        },
      ],
    },
    {
      "companyCode": "C002",
      "companyName": "Nestle",
      "items": [
        {
          "itemCode": "ITM004", // Nescafe
          "variants": [
            {"size": "100g", "price": 160},
            {"size": "200g", "price": 300},
          ]
        },
        {
          "itemCode": "ITM005", // Everyday Milk Powder
          "variants": [
            {"size": "500g", "price": 240},
            {"size": "1kg", "price": 450},
          ]
        },
        {
          "itemCode": "ITM010", // KitKat
          "variants": [
            {"size": "200g", "price": 180},
            {"size": "400g", "price": 350},
          ]
        },
        {
          "itemCode": "ITM011", // Nestle Juice
          "variants": [
            {"size": "250ml", "price": 80},
            {"size": "1L", "price": 280},
          ]
        },
        {
          "itemCode": "ITM012", // Maggi
          "variants": [
            {"size": "70g", "price": 20},
            {"size": "100g", "price": 100},
          ]
        },
        {
          "itemCode": "ITM013", // Nestea
          "variants": [
            {"size": "500ml", "price": 150},
            {"size": "750ml", "price": 220},
          ]
        },
        {
          "itemCode": "ITM014", // Cerelac
          "variants": [
            {"size": "100g", "price": 120},
            {"size": "150g", "price": 160},
          ]
        },
        {
          "itemCode": "ITM015", // Nestle Water
          "variants": [
            {"size": "500ml", "price": 130},
            {"size": "1L", "price": 220},
          ]
        },
      ],
    },
  ];

  @override
  void onInit() {
    super.onInit();
    orders.assignAll(customerOrders);
  }

  /// Find price of an item from selected company
  int? getPrice(String itemCode, String size) {
    if (selectedCompany.value == null) return null;
    final items = selectedCompany.value!["items"] as List;
    final item = items.firstWhereOrNull((e) => e["itemCode"] == itemCode);
    if (item == null) return null;
    final variants = item["variants"] as List;
    final variant = variants.firstWhereOrNull((v) => v["size"] == size);
    return variant?["price"];
  }

  int get grandTotal {
    int total = 0;
    for (var order in orders) {
      final price = getPrice(order["itemCode"], order["sizeVariant"]);
      if (price != null) {
        total += (order["quantity"] as int) * price;
      }
    }
    return total;
  }
}

/// ---------- MAIN ORDER PAGE ----------
class OrderPage extends StatelessWidget {
  final OrderController c = Get.put(OrderController());

  OrderPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Customer Orders")),
      body: Obx(() => Column(
            children: [
              // --- Orders List ---
              Expanded(
                child: ListView.builder(
                  itemCount: c.orders.length,
                  itemBuilder: (context, index) {
                    final order = c.orders[index];
                    return Card(
                      margin: const EdgeInsets.all(6),
                      child: ListTile(
                        title: Text(order["itemName"]),
                        subtitle: Text(
                            "${order["category"]} | ${order["sizeVariant"]} | Qty: ${order["quantity"]}"),
                        trailing: const Text("Price: --",
                            style: TextStyle(color: Colors.grey)),
                      ),
                    );
                  },
                ),
              ),

              // --- Choose Company Button ---
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                child: ElevatedButton(
                  onPressed: () => _showCompanyPicker(context),
                  child: const Text("Choose Company"),
                ),
              ),
            ],
          )),
    );
  }

  /// Bottom sheet company picker
  void _showCompanyPicker(BuildContext context) {
    final companies = c.companyPriceList;
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return ListView.builder(
          itemCount: companies.length,
          itemBuilder: (ctx, i) {
            final company = companies[i];
            return ListTile(
              title: Text(company["companyName"]),
              onTap: () {
                c.selectedCompany.value = company;
                Get.back();

                // Navigate to loading screen
                Get.to(() => LoadingPage(), arguments: company);
              },
            );
          },
        );
      },
    );
  }
}

/// ---------- LOADING PAGE ----------
class LoadingPage extends StatefulWidget {
  @override
  State<LoadingPage> createState() => _LoadingPageState();
}

class _LoadingPageState extends State<LoadingPage> {
  double progress = 0.0;

  @override
  void initState() {
    super.initState();
    _simulateLoading();
  }

  void _simulateLoading() async {
    for (int i = 1; i <= 10; i++) {
      await Future.delayed(const Duration(milliseconds: 200));
      setState(() => progress = i / 10);
    }
    // After loading success -> Go to result page
    Get.off(() => OrderSummaryPage());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Applying Prices")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            LinearProgressIndicator(value: progress),
            const SizedBox(height: 20),
            const Text("Applying prices to items..."),
          ],
        ),
      ),
    );
  }
}

/// ---------- ORDER SUMMARY PAGE ----------
class OrderSummaryPage extends StatelessWidget {
  final OrderController c = Get.find();

  OrderSummaryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            Text("Order Summary (${c.selectedCompany.value!["companyName"]})"),
      ),
      body: Obx(() => Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: c.orders.length,
                  itemBuilder: (context, index) {
                    final order = c.orders[index];
                    final price =
                        c.getPrice(order["itemCode"], order["sizeVariant"]);
                    final qty = order["quantity"];
                    final subtotal = (price != null) ? qty * price : null;

                    return Card(
                      margin: const EdgeInsets.all(6),
                      child: ListTile(
                        title: Text(order["itemName"]),
                        subtitle: Text("${order["sizeVariant"]} | Qty: $qty"),
                        trailing: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(price != null ? "Rs $price" : "N/A",
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                            if (subtotal != null)
                              Text("Subtotal: Rs $subtotal",
                                  style: const TextStyle(fontSize: 12)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              // --- Grand Total ---
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.grey.shade200,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Grand Total",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 18)),
                    Text("Rs ${c.grandTotal}",
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 18)),
                  ],
                ),
              ),
            ],
          )),
    );
  }
}
