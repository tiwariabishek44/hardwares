import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hardwares/app/utils/database_helper.dart';
import 'package:intl/intl.dart';
import 'package:nepali_utils/nepali_utils.dart';

class TransactionEntryController extends GetxController {
  final formKey = GlobalKey<FormState>();
  final amountController = TextEditingController();
  final descriptionController = TextEditingController();

  var isSubmitting = false.obs;
  var selectedTransactionType = ''.obs;
  var partyData = <String, dynamic>{}.obs;
  var maxAllowedAmount = 0.0.obs;

  // Date handling - Nepali date only
  var selectedNepaliDate = NepaliDateTime.now().obs;

  final DatabaseHelper _databaseHelper = DatabaseHelper();

  @override
  void onInit() {
    super.onInit();

    // Get arguments passed from party detail view
    final arguments = Get.arguments as Map<String, dynamic>?;
    if (arguments != null) {
      partyData.value = arguments['partyData'] ?? {};
      selectedTransactionType.value = arguments['transactionType'] ?? '';

      // Calculate max allowed amount based on party type and transaction type
      calculateMaxAllowedAmount();
    }

    // Initialize with today's date in Nepali calendar
    selectedNepaliDate.value = NepaliDateTime.now();
  }

  void updateNepaliDate(NepaliDateTime date) {
    selectedNepaliDate.value = date;
  }

  void calculateMaxAllowedAmount() {
    // Get current balance
    double balance =
        double.tryParse(partyData['balance']?.toString() ?? '0') ?? 0.0;
    String partyType = partyData['party_type'] ?? 'customer';

    // If receiving payment from customer (rakam_prapta)
    if (partyType == 'customer' &&
        selectedTransactionType.value == 'rakam_prapta') {
      // Customer can't pay more than what they owe
      maxAllowedAmount.value = balance > 0 ? balance : 0.0;
      print(
          'Max allowed amount for customer payment: ${maxAllowedAmount.value}');
    }
    // If paying to supplier (rakam_prapta)
    else if (partyType == 'supplier' &&
        selectedTransactionType.value == 'rakam_prapta') {
      // Can't pay supplier more than what we owe them
      maxAllowedAmount.value = balance > 0 ? balance : 0.0;
      print(
          'Max allowed amount for supplier payment: ${maxAllowedAmount.value}');
    } else {
      // For adding new receivables or payables, no limit
      maxAllowedAmount.value = double.infinity;
    }
  }

  @override
  void onClose() {
    amountController.dispose();
    descriptionController.dispose();
    super.onClose();
  }

  Color get primaryColor {
    return selectedTransactionType.value == 'paune_parne'
        ? Color(0xFFC53030) // Red for adding amount to receive/pay
        : Color(0xFF2F855A); // Green for received/paid
  }

  String? validateAmount(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter an amount';
    }

    double? amount = double.tryParse(value.trim());
    if (amount == null) {
      return 'Please enter a valid amount';
    }

    if (amount <= 0) {
      return 'Amount must be greater than 0';
    }

    // Only validate max amount for payment transactions (not for adding new receivables)
    String partyType = partyData['party_type'] ?? 'customer';

    if (selectedTransactionType.value == 'rakam_prapta') {
      // For receiving payment from customer or paying to supplier
      if (maxAllowedAmount.value > 0 && amount > maxAllowedAmount.value) {
        if (partyType == 'customer') {
          return 'Cannot exceed customer\'s outstanding amount (Max: Rs. ${NumberFormat('#,##,###.00').format(maxAllowedAmount.value)})';
        } else {
          return 'Cannot exceed amount owed to supplier (Max: Rs. ${NumberFormat('#,##,###.00').format(maxAllowedAmount.value)})';
        }
      }
    }

    return null;
  }

  Future<void> submitTransaction() async {
    if (!formKey.currentState!.validate()) {
      return;
    }

    isSubmitting.value = true;

    try {
      double amount = double.parse(amountController.text.trim());
      String description = descriptionController.text.trim();
      int partyId = partyData['id'];

      // Convert Nepali date to English date for storage
      DateTime englishDate = selectedNepaliDate.value.toDateTime();
      String formattedDate = englishDate.toIso8601String();

      // Insert transaction with the date
      int transactionId = await _databaseHelper.insertTransaction(
        partyId: partyId,
        amount: amount,
        transactionType: selectedTransactionType.value,
        description: description.isNotEmpty ? description : null,
        date: formattedDate,
      );

      print('✅ Transaction saved with ID: $transactionId');

      _showSuccessDialog(amount);
    } catch (e) {
      print('❌ Error saving transaction: $e');
      ScaffoldMessenger.of(Get.context!).showSnackBar(
        SnackBar(
          content: Text('लेनदेन सेभ गर्दा समस्या भयो: ${e.toString()}'),
          backgroundColor: Colors.red[600],
          duration: Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.all(16),
        ),
      );
    } finally {
      isSubmitting.value = false;
    }
  }

  void _showSuccessDialog(double amount) {
    String partyType = partyData['party_type'] ?? 'customer';
    String successMessageEn;
    String successMessageNe;

    if (partyType == 'customer') {
      if (selectedTransactionType.value == 'paune_parne') {
        successMessageEn =
            'Rs. ${NumberFormat('#,##,###.00').format(amount)} added to receivables';
        successMessageNe =
            'रू. ${NumberFormat('#,##,###.00').format(amount)} पाउनु पर्ने रकम थपियो';
      } else {
        successMessageEn =
            'Rs. ${NumberFormat('#,##,###.00').format(amount)} payment received';
        successMessageNe =
            'रू. ${NumberFormat('#,##,###.00').format(amount)} रकम प्राप्त भयो';
      }
    } else {
      if (selectedTransactionType.value == 'paune_parne') {
        successMessageEn =
            'Rs. ${NumberFormat('#,##,###.00').format(amount)} added to payables';
        successMessageNe =
            'रू. ${NumberFormat('#,##,###.00').format(amount)} तिर्नु पर्ने रकम थपियो';
      } else {
        successMessageEn =
            'Rs. ${NumberFormat('#,##,###.00').format(amount)} payment made';
        successMessageNe =
            'रू. ${NumberFormat('#,##,###.00').format(amount)} भुक्तानी गरियो';
      }
    }

    showDialog(
      context: Get.context!,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Success Icon
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(
                    Icons.check_circle,
                    color: primaryColor,
                    size: 40,
                  ),
                ),
              ),

              SizedBox(height: 20),

              // Success Message
              Text(
                'सफल!',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E293B),
                ),
                textAlign: TextAlign.center,
              ),

              SizedBox(height: 8),

              Text(
                successMessageNe,
                style: TextStyle(
                  fontSize: 15,
                  color: Color(0xFF64748B),
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),

              SizedBox(height: 24),

              // OK Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Close dialog
                    Navigator.of(context).pop(true); // Go back with result
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 14),
                    elevation: 0,
                  ),
                  child: Text(
                    'ठीक छ',
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
    );
  }
}
