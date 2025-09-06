import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hardwares/app/modules/transaction/transaction_controller.dart';
import 'package:hardwares/app/utils/database_helper.dart';

class AddPartyController extends GetxController {
  final formKey = GlobalKey<FormState>();
  final partyNameController = TextEditingController();
  final phoneNumberController = TextEditingController();
  final openingBalanceController = TextEditingController();

  var isSubmitting = false.obs;
  var isSupplier = false.obs;
  final DatabaseHelper _databaseHelper = DatabaseHelper();

  // Computed properties for UI consistency
  String get partyType => isSupplier.value ? 'Supplier' : 'Customer';
  IconData get partyIcon =>
      isSupplier.value ? Icons.inventory_2_outlined : Icons.person_outline;

  @override
  void onClose() {
    partyNameController.dispose();
    phoneNumberController.dispose();
    openingBalanceController.dispose();
    super.onClose();
  }

  String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Name is required';
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
    if (value.length != 10) {
      return 'Phone number must be 10 digits';
    }
    return null;
  }

  void submitParty() async {
    // Close keyboard
    FocusManager.instance.primaryFocus?.unfocus();

    if (!formKey.currentState!.validate()) {
      return;
    }

    isSubmitting.value = true;

    try {
      // Store the party name before clearing the form
      String partyName = partyNameController.text.trim();
      String phoneNumber = phoneNumberController.text.trim();
      String dbPartyType = isSupplier.value ? 'supplier' : 'customer';

      // Parse opening balance (0 if empty)
      double openingBalance = 0.0;
      if (openingBalanceController.text.isNotEmpty) {
        openingBalance =
            double.tryParse(openingBalanceController.text.trim()) ?? 0.0;
      }

      // Check if party with this phone already exists
      var existingParty = await _databaseHelper.getPartyByPhone(phoneNumber);

      if (existingParty != null) {
        _showAlreadyExistsDialog(phoneNumber, existingParty['name']);
        isSubmitting.value = false;
        return;
      }

      // INSERT PARTY INTO DATABASE FIRST (with zero balance initially)
      int partyId = await _databaseHelper.insertParty(
        name: partyName,
        phone: phoneNumber,
        balance: 0.0, // Start with zero balance
        partyType: dbPartyType,
      );

      log('${partyType} inserted successfully with ID: $partyId');

      // Add opening balance transaction if amount is greater than 0
      if (openingBalance > 0) {
        await _databaseHelper.insertTransaction(
          partyId: partyId,
          amount: openingBalance,
          transactionType:
              'paune_parne', // Always "to receive/pay" for opening balance
          description: 'Opening Balance',
          date: DateTime.now().toIso8601String(),
        );
        log('Opening balance transaction added: $openingBalance');
      }

      // Clear form AFTER successful insertion
      partyNameController.clear();
      phoneNumberController.clear();
      openingBalanceController.clear();

      // Save current state for dialog
      final savedPartyType = partyType;
      final hasOpeningBalance = openingBalance > 0;

      // Reset toggle (do this after saving state for dialog)
      isSupplier.value = false;

      // Refresh transaction controller to show the new party
      try {
        var transactionController = Get.find<TransactionController>();
        await transactionController.loadParties();
        log('Transaction controller parties refreshed');
      } catch (e) {
        log('TransactionController not found: $e');
      }

      // Show success dialog and navigate back
      _showSuccessDialog(partyName, savedPartyType, hasOpeningBalance);
    } catch (e) {
      log('Error adding ${partyType.toLowerCase()}: $e');
      _showErrorDialog(e.toString());
    } finally {
      isSubmitting.value = false;
    }
  }

  void _showSuccessDialog(
      String partyName, String partyType, bool hasOpeningBalance) {
    String balanceMessage =
        hasOpeningBalance ? '\n\nOpening balance has been recorded.' : '';

    Get.dialog(
      AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green[50],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle,
                color: Colors.green[600],
                size: 48,
              ),
            ),
            SizedBox(height: 20),
            Text(
              '$partyType Added Successfully',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF212121),
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Text(
              '"$partyName" has been added to your ${partyType.toLowerCase()} list.$balanceMessage',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(Get.context!);
              Navigator.pop(Get.context!);
              try {
                var transactionController = Get.find<TransactionController>();
                transactionController.loadParties();
              } catch (e) {
                print('Could not refresh transaction controller: $e');
              }
            },
            style: TextButton.styleFrom(
              backgroundColor: Colors.green[600],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: Text(
              'Continue',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
        actionsPadding: EdgeInsets.fromLTRB(24, 0, 24, 20),
      ),
      barrierDismissible: false,
    );
  }

  void _showAlreadyExistsDialog(String phone, String existingName) {
    Get.dialog(
      AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded,
                color: Colors.orange[700], size: 24),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Party Already Exists',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF212121),
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'A party with this phone number already exists:',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
            SizedBox(height: 14),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.person, color: Colors.orange[700], size: 18),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          existingName,
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 15,
                            color: Colors.grey[800],
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.phone, color: Colors.orange[700], size: 18),
                      SizedBox(width: 8),
                      Text(
                        phone,
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.grey[800],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(Get.context!);
            },
            style: TextButton.styleFrom(
              backgroundColor: Colors.grey[200],
              foregroundColor: Colors.grey[800],
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'OK',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
        actionsPadding: EdgeInsets.all(16),
      ),
    );
  }

  void _showErrorDialog(String error) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        title: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red[600], size: 24),
            SizedBox(width: 10),
            Text(
              'Error',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF212121),
              ),
            ),
          ],
        ),
        content: Text(
          'Failed to add ${partyType.toLowerCase()}. Please try again.',
          style: TextStyle(
            fontSize: 15,
            color: Colors.grey[700],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(Get.context!);
            },
            style: TextButton.styleFrom(
              backgroundColor: Colors.red[50],
              foregroundColor: Colors.red[700],
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'OK',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
        actionsPadding: EdgeInsets.all(16),
      ),
    );
  }
}
