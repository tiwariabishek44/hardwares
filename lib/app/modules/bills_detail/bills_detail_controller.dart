import 'dart:convert';
import 'dart:developer';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hardwares/app/modules/login/login_controller.dart';
import 'package:hardwares/app/utils/bill_pdf_generator.dart';
import 'package:hardwares/app/utils/database_helper.dart';
import 'package:hardwares/app/utils/firebase_services.dart';

class BillsDetailController extends GetxController {
  var isLoading = false.obs;
  var orderData = <String, dynamic>{}.obs;
  var orderItems = <Map<String, dynamic>>[].obs;

  final RxBool isGeneratingImage = false.obs;
  final RxBool isGeneratingPdf = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadOrderData();
  }

  void loadOrderData() {
    try {
      isLoading.value = true;

      // Get order data passed from bills view
      final arguments = Get.arguments as Map<String, dynamic>?;

      if (arguments != null) {
        orderData.value = arguments;
        log('📄 Received order data: ${arguments.keys}');

        // Parse items from the database - FIXED FOR NEW DATA MODEL
        if (arguments['items'] != null) {
          try {
            // The 'items' column contains JSON string from SQLite
            String itemsJsonString = arguments['items'].toString();
            log('📦 Raw items JSON: ${itemsJsonString.substring(0, itemsJsonString.length > 200 ? 200 : itemsJsonString.length)}...');

            List<dynamic> itemsData = jsonDecode(itemsJsonString);
            orderItems.value =
                itemsData.map((item) => item as Map<String, dynamic>).toList();

            log('✅ Successfully parsed ${orderItems.length} items');

            // Debug: Print first item structure using NEW data model fields
            if (orderItems.isNotEmpty) {
              final firstItem = orderItems.first;
            }
          } catch (e) {
            log('❌ Error parsing items JSON: $e');
            orderItems.value = [];
          }
        }
        // Handle legacy format if exists
        else if (arguments['items_json'] != null) {
          try {
            List<dynamic> itemsData = jsonDecode(arguments['items_json']);
            orderItems.value =
                itemsData.map((item) => item as Map<String, dynamic>).toList();
            log('✅ Parsed ${orderItems.length} items from items_json');
          } catch (e) {
            log('❌ Error parsing items_json: $e');
            orderItems.value = [];
          }
        }
        // Handle if items are already parsed (from Firebase)
        else if (arguments['parsed_items'] != null) {
          orderItems.value =
              List<Map<String, dynamic>>.from(arguments['parsed_items']);
          log('✅ Used parsed_items: ${orderItems.length} items');
        } else {
          log('⚠️ No items found in order data');
          orderItems.value = [];
        }

        log('📊 Final items count: ${orderItems.length}');
        log('📄 Order for customer: ${arguments['customer_name']}');
        log('💰 Total amount: ${arguments['total_amount']}');
      } else {
        log('❌ No arguments received');
      }
    } catch (e) {
      log('❌ Error loading order data: $e');
      Get.snackbar(
        'Error',
        'Failed to load order details',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Get formatted date
  String getFormattedDate(dynamic dateValue) {
    try {
      if (dateValue == null) return 'Unknown date';

      DateTime date;
      if (dateValue is Map && dateValue.containsKey('seconds')) {
        // Firestore Timestamp format
        date = DateTime.fromMillisecondsSinceEpoch(dateValue['seconds'] * 1000);
      } else if (dateValue is String) {
        // Handle different string formats
        if (dateValue.contains('T')) {
          // ISO format: "2024-12-27T10:30:00.000Z"
          date = DateTime.parse(dateValue);
        } else if (dateValue.contains('/')) {
          // Firebase format: "2024/12/27"
          final parts = dateValue.split('/');
          date = DateTime(
              int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
        } else {
          date = DateTime.parse(dateValue);
        }
      } else {
        return 'Unknown date';
      }

      return '${date.day}/${date.month}/${date.year} at ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      log('❌ Error formatting date: $e');
      return dateValue?.toString() ?? 'Unknown date';
    }
  }

  // UPDATED: Calculate total quantity using new data model
  int get totalQuantity {
    return orderItems.fold(
        0, (sum, item) => sum + (item['quantity'] as int? ?? 1));
  }

  // Get customer name
  String get customerName => orderData['customer_name'] ?? 'Unknown Customer';

  // Get phone number
  String get phoneNumber => orderData['phone_number'] ?? 'No phone';

  // Get order date
  String get orderDate =>
      getFormattedDate(orderData['order_date'] ?? orderData['created_at']);

  // Check if it's offline order
  bool get isOfflineOrder =>
      orderData['items'] != null; // Changed from items_json

  // Get order source
  String get orderSource => isOfflineOrder ? 'Offline' : 'Online';

  String get billCode => orderData['bill_code'] ?? '';

  String get shortDate {
    if (orderDate.isNotEmpty) {
      try {
        // Extract just the date part for short format
        if (orderDate.contains(' at ')) {
          return orderDate.split(' at ').first;
        }
        return orderDate;
      } catch (e) {
        return orderDate;
      }
    }
    return '';
  }

  // UPDATED: Calculate total amount using new data model (rate field)
  double get totalAmount {
    if (orderData['total_amount'] != null) {
      return double.tryParse(orderData['total_amount'].toString()) ?? 0.0;
    }

    // Calculate from items using NEW data model fields
    return orderItems.fold(0.0, (sum, item) {
      // Use 'rate' field from new data model (not 'price')
      double rate = double.tryParse(item['rate']?.toString() ?? '0') ?? 0.0;
      int quantity = int.tryParse(item['quantity']?.toString() ?? '1') ?? 1;
      return sum + (rate * quantity);
    });
  }

  // UPDATED: Get item name using new data model
  String getItemName(Map<String, dynamic> item) {
    // Use 'itemName' field from new data model
    return item['itemName'] ??
        item['name'] ??
        item['nameEnglish'] ??
        'Unknown Item';
  }

  // NEW: Get item company name
  String getItemCompany(Map<String, dynamic> item) {
    return item['companyName'] ?? 'N/A';
  }

  // UPDATED: Get item size/variant info
  String getItemSizeVariant(Map<String, dynamic> item) {
    String variant = item['selectedVariantType'] ?? '';
    String size = item['selectedSize'] ?? '';

    if (variant.isNotEmpty && size.isNotEmpty) {
      return '$variant - $size';
    } else if (size.isNotEmpty) {
      return size;
    } else if (variant.isNotEmpty) {
      return variant;
    }
    return '';
  }

  // NEW: Get item rate
  double getItemRate(Map<String, dynamic> item) {
    return double.tryParse(item['rate']?.toString() ?? '0') ?? 0.0;
  }

  // NEW: Get item total (rate * quantity)
  double getItemTotal(Map<String, dynamic> item) {
    double rate = getItemRate(item);
    int quantity = int.tryParse(item['quantity']?.toString() ?? '1') ?? 1;
    return rate * quantity;
  }

  Future<void> shareAsPdf() async {
    try {
      isGeneratingPdf.value = true;

      // Check if order needs to be synced first
      final isSynced = orderData['synced'] == 1;

      if (!isSynced) {
        // Sync to Firebase first
        await syncToFirebaseBeforeShare();
      }

      // UPDATED: Pass items with new data model
      await BillPdfGenerator.generateAndShareBillPdf(
        billCode: billCode,
        customerName: customerName,
        phoneNumber: phoneNumber,
        orderDate: orderDate,
        items: orderItems, // Items already in new data model format
        plumberName: orderData['plumber_name'] ?? 'Unknown Plumber',
      );
    } catch (e) {
      log('❌ Error sharing PDF: $e');
      _handleShareError(e.toString());
    } finally {
      isGeneratingPdf.value = false;
    }
  }

  // UPDATED: Sync to Firebase using new data model
  Future<void> syncToFirebaseBeforeShare() async {
    try {
      // Import required services
      final DatabaseHelper _dbHelper = DatabaseHelper();
      final FirebaseService _firebaseService = FirebaseService();
      final LoginController _loginController = Get.find<LoginController>();

      // Check internet connectivity
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        throw Exception(
            'No internet connection. Please connect to internet and try again.');
      }

      final orderId = orderData['id'] as int;

      // Sync to Firebase using new data model
      await _firebaseService.saveRequirementListToFirebase(
        billCode: orderData['bill_code'],
        customerName: orderData['customer_name'] ?? '',
        phoneNumber: orderData['phone_number'] ?? '',
        plumberId: _loginController.getPlumberId(),
        plumberName: _loginController.getUserName(),
        items: orderItems, // Items already in new data model format
      );

      // Mark as synced in SQLite
      await _dbHelper.markOrderAsSynced(orderId);

      // Update local order data
      orderData['synced'] = 1;
      orderData.refresh();

      log('✅ Order $orderId synced successfully before sharing');
    } catch (e) {
      log('❌ Error syncing before share: $e');
      throw e; // Re-throw to be handled by shareAsPdf
    }
  }

  // Enhanced error handling
  void _handleShareError(String error) {
    if (error.contains('internet') || error.contains('connection')) {
      Get.dialog(
        AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Row(
            children: [
              Icon(Icons.wifi_off, color: Colors.red[600], size: 24),
              SizedBox(width: 8),
              Text('No Internet Connection',
                  style: TextStyle(color: Colors.red[600])),
            ],
          ),
          content: Text(
            'This bill needs to be synced to cloud before sharing. Please connect to internet and try again.',
            style: TextStyle(fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(Get.context!).pop(),
              child: Text('Cancel'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[600],
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    } else {
      Get.snackbar(
        'Error',
        'Failed to share bill. Please try again.\n\nError: $error',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red[600],
        colorText: Colors.white,
        duration: Duration(seconds: 4),
        margin: EdgeInsets.all(16),
      );
    }
  }
}
