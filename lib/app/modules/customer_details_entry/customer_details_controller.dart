import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hardwares/app/modules/login/login_controller.dart';
import 'package:hardwares/app/services/saved_items_service.dart';
import 'package:hardwares/app/utils/database_helper.dart';

class CustomerDetailsController extends GetxController {
  final formKey = GlobalKey<FormState>();
  final customerNameController = TextEditingController();
  final phoneNumberController = TextEditingController();

  final SavedItemsService _savedItemsService = Get.find<SavedItemsService>();
  final loginController = Get.find<LoginController>();
  var isSubmitting = false.obs;

  final DatabaseHelper _dbHelper = DatabaseHelper();

  // Pricing logic
  final RxDouble discount = 0.0.obs;
  final RxDouble total = 0.0.obs;
  final RxDouble finalTotal = 0.0.obs;
  final TextEditingController discountController = TextEditingController();

  // Get the items passed from SavedItemsView
  late List<Map<String, dynamic>> selectedItems;

  @override
  void onInit() {
    super.onInit();
    selectedItems = Get.arguments ?? [];
    _calculateTotals();
    discountController.addListener(_onDiscountChanged);
  }

  void _calculateTotals() {
    double sum = 0.0;
    for (var item in selectedItems) {
      final rate = item['rate'] ?? item['price'] ?? 0.0;
      final qty = item['quantity'] ?? 1;
      sum += rate * qty;
    }
    total.value = sum;
    _updateFinalTotal();
  }

  void _onDiscountChanged() {
    double discPercent = double.tryParse(discountController.text) ?? 0.0;
    discount.value = discPercent;
    _updateFinalTotal();
  }

  void _updateFinalTotal() {
    finalTotal.value = (total.value - (total.value * discount.value / 100))
        .clamp(0, double.infinity);
  }

  @override
  void onClose() {
    customerNameController.dispose();
    phoneNumberController.dispose();
    discountController.dispose();
    super.onClose();
  }

  // Show success popup dialog
  void _showSuccessPopup(String message, String billCode) {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Colors.white,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Success Icon
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.check_circle, color: Colors.green, size: 40),
              ),
              SizedBox(height: 20),

              // Title
              Text(
                '  Saved Successfully',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),

              // OK Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // Clear all saved items using the shared service
                    _savedItemsService.clearAllItems();

                    // Close dialogs and navigate back
                    Navigator.of(Get.context!).pop(); // Close success dialog
                    Navigator.of(Get.context!)
                        .pop(); // Go back to previous screen
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'OK',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }

  void submitOrder() async {
    // Close keyboard first

    if (formKey.currentState!.validate()) {
      isSubmitting.value = true;

      try {
        // Save to SQLite only - Simple and straightforward
        log('Saving order to local database (SQLite)');

        int orderId = await _dbHelper.insertOrder(
          customerName: customerNameController.text.trim(),
          phoneNumber: phoneNumberController.text.trim(),
          plumberName: loginController.getUserName(),
          plumberId: loginController.getPlumberId(),
          items: selectedItems,
        );

        // Get the created order with bill code
        final createdOrder = await _dbHelper.getOrderById(orderId);
        String billCode = createdOrder['bill_code'];

        log('✅ Order saved to SQLite with ID: $orderId, Bill Code: $billCode');

        await Future.delayed(const Duration(seconds: 1));

        // Show success popup
        _showSuccessPopup(
          'Your order has been saved successfully!\n\nCustomer: ${customerNameController.text.trim()}\nItems: ${selectedItems.length}',
          billCode,
        );
      } catch (e) {
        log('❌ Error saving order to SQLite: $e');

        // Show error dialog
        Get.dialog(
          AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                Icon(Icons.error, color: Colors.red, size: 24),
                SizedBox(width: 8),
                Text(
                  'Error',
                  style: TextStyle(color: Colors.red),
                ),
              ],
            ),
            content: Text(
              'Failed to save order. Please try again.\n\nError: ${e.toString()}',
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Get.back(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: Text('OK'),
              ),
            ],
          ),
        );
      } finally {
        isSubmitting.value = false;
      }
    }
  }

  String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Customer name is required';
    }
    if (value.trim().length < 2) {
      return 'Name must be at least 2 characters';
    }
    return null;
  }

  String? validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required';
    }

    // Remove any non-digit characters for validation
    String digitsOnly = value.replaceAll(RegExp(r'[^0-9]'), '');

    if (digitsOnly.length != 10) {
      return 'Phone number must be exactly 10 digits';
    }

    return null;
  }
}
