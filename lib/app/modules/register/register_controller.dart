import 'dart:developer';

import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

class RegisterController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = Uuid();

  // Text controllers (removed password controllers)
  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController addressController = TextEditingController();

  // Observable variables (removed password visibility variables)
  var isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
  }

  @override
  void onClose() {
    nameController.dispose();
    phoneController.dispose();
    addressController.dispose();
    super.onClose();
  }

  // Generate 6-digit plumber ID
  String generatePlumberId() {
    // Generate UUID and take first 6 characters, then convert to numbers
    String uuid = _uuid.v4().replaceAll('-', '');
    String numericString = '';

    for (int i = 0; i < uuid.length && numericString.length < 6; i++) {
      int? digit = int.tryParse(uuid[i]);
      if (digit != null) {
        numericString += digit.toString();
      }
    }

    // If we don't have enough digits, pad with random numbers
    while (numericString.length < 6) {
      numericString += (DateTime.now().millisecondsSinceEpoch % 10).toString();
    }

    return numericString.substring(0, 6);
  }

  // Helper method to show error messages using Flutter popup
  void _showError(String message) {
    showDialog(
      context: Get.context!,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: Row(
            children: [
              Icon(Icons.error, color: Colors.red[600], size: 24),
              SizedBox(width: 10),
              Text(
                'त्रुटि / Error',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.red[600],
                ),
              ),
            ],
          ),
          content: Text(
            message,
            style: TextStyle(fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'ठीक छ / OK',
                style: TextStyle(
                  color: Colors.red[600],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // Show success popup with plumber ID
  void _showSuccess(String plumberId) {
    showDialog(
      context: Get.context!,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green[600], size: 24),
              SizedBox(width: 10),
              Text(
                'सफल / Success',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.green[600],
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'दर्ता सफल भयो! / Registration successful!',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(Get.context!).pop(); // Close registration screen
              },
              child: Text(
                'ठीक छ / OK',
                style: TextStyle(
                  color: Colors.green[600],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // Show Firebase Auth error popup
  void _showFirebaseError(String errorMessage) {
    showDialog(
      context: Get.context!,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.red[600], size: 24),
              SizedBox(width: 10),
              Text(
                'दर्ता त्रुटि / Registration Error',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.red[600],
                ),
              ),
            ],
          ),
          content: Text(
            errorMessage,
            style: TextStyle(fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'ठीक छ / OK',
                style: TextStyle(
                  color: Colors.red[600],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // Registration function - Updated to use popup dialogs
  Future<void> register() async {
    // Dismiss keyboard first
    FocusManager.instance.primaryFocus?.unfocus();

    // Validation
    if (nameController.text.trim().isEmpty) {
      _showError('कृपया नाम राख्नुहोस् / Please enter name');
      return;
    }

    if (phoneController.text.trim().isEmpty) {
      _showError('कृपया मोबाइल नम्बर राख्नुहोस् / Please enter phone number');
      return;
    }

    if (phoneController.text.trim().length != 10) {
      _showError(
          'कृपया सही १० अंकको मोबाइल नम्बर राख्नुहोस् / Please enter valid 10-digit phone number');
      return;
    }

    // Check if phone number starts with valid digits
    String phone = phoneController.text.trim();
    if (!phone.startsWith('98') &&
        !phone.startsWith('97') &&
        !phone.startsWith('96')) {
      _showError(
          'कृपया सही नेपाली मोबाइल नम्बर राख्नुहोस् (98/97/96) / Please enter valid Nepali mobile number (98/97/96)');
      return;
    }

    if (addressController.text.trim().isEmpty) {
      _showError('कृपया ठेगाना राख्नुहोस् / Please enter address');
      return;
    }

    try {
      isLoading.value = true;

      String email = '$phone@gmail.com'; // Phone as email
      String password = phone; // Phone as password
      String plumberId = generatePlumberId(); // Generate 6-digit plumber ID

      // Create Firebase Auth account
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Save user data to Firestore
      await _firestore
          .collection('plumbers')
          .doc(userCredential.user!.uid)
          .set({
        'name': nameController.text.trim(),
        'phone': phone,
        'address': addressController.text.trim(),

        'email': email,
        'plumberId': plumberId, // Add 6-digit plumber ID
        'createdAt': FieldValue.serverTimestamp(),
        'isActive': true,
      });

      // Log registration success
      log('Registration successful for user: ${userCredential.user!.uid} with plumber ID: $plumberId');

      // Show success popup with plumber ID
      _showSuccess(plumberId);

      // Clear form
      nameController.clear();
      phoneController.clear();
      addressController.clear();
    } catch (e) {
      log('Registration error: $e');
      String errorMessage = 'दर्ता असफल / Registration failed';

      if (e.toString().contains('email-already-in-use')) {
        errorMessage =
            'यो फोन नम्बर पहिले नै प्रयोग भएको छ। कृपया लगइन गर्नुहोस् / This phone number is already registered. Please login instead';
      } else if (e.toString().contains('weak-password')) {
        errorMessage =
            'फोन नम्बर कम्तिमा ६ अंकको हुनुपर्छ / Phone number must be at least 6 digits';
      } else if (e.toString().contains('network-request-failed')) {
        errorMessage =
            'इन्टरनेट जडान जाँच गर्नुहोस् / Check your internet connection';
      } else if (e.toString().contains('too-many-requests')) {
        errorMessage =
            'धेरै प्रयास। केही समय पछि प्रयास गर्नुहोस् / Too many attempts. Try again later';
      }

      _showFirebaseError(errorMessage);
    } finally {
      isLoading.value = false;
    }
  }
}
