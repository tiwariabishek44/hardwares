import 'dart:developer';

import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hardwares/app/modules/bottom_navigation/user_main_screen.dart';
import 'package:hardwares/app/modules/login/login_view.dart';
import 'package:hardwares/app/utils/firebase_sync_service.dart';

class LoginController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Text controller for phone input
  final TextEditingController phoneController = TextEditingController();

  // Observable variables
  var isLoading = false.obs;
  var phoneNumber = ''.obs;

  // User data variables
  var userData = Rxn<Map<String, dynamic>>();
  var currentUser = Rxn<User>();

  @override
  void onClose() {
    phoneController.dispose();
    super.onClose();
  }

  // Login function with comprehensive Firebase exception handling
  Future<void> login() async {
    // Dismiss keyboard first
    FocusManager.instance.primaryFocus?.unfocus();

    // Input validation
    if (phoneController.text.trim().isEmpty) {
      _showError(
        'त्रुटि / Error',
        'कृपया मोबाइल नम्बर राख्नुहोस् / Please enter phone number',
        Colors.red[600]!,
        Icons.error,
      );
      return;
    }

    // Check if phone number starts with valid digits
    String phone = phoneController.text.trim();
    if (!phone.startsWith('98') &&
        !phone.startsWith('97') &&
        !phone.startsWith('96')) {
      _showError(
        'त्रुटि / Error',
        'कृपया सही नेपाली मोबाइल नम्बर राख्नुहोस् (98/97/96) / Please enter valid Nepali mobile number (98/97/96)',
        Colors.orange[600]!,
        Icons.phone_android,
      );
      return;
    }

    try {
      isLoading.value = true;

      String email = '$phone@gmail.com';
      String password = phone;

      // Try to sign in with Firebase Auth
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Set current user
      currentUser.value = userCredential.user;

      // Fetch user data from Firestore
      await fetchUserData(userCredential.user!.uid);

      // Clear phone input
      phoneController.clear();

      // Navigate to home page
      Get.offAll(() => UserMainScreen());
    } catch (e) {
      _showError(
        'अप्रत्याशित त्रुटि / Unexpected Error',
        'केही गलत भयो। कृपया पुनः प्रयास गर्नुहोस् / Something went wrong. Please try again',
        Colors.red[600]!,
        Icons.error_outline,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Helper method to show error messages
  void _showError(String title, String message, Color color, IconData icon) {
    final context = Get.context;
    if (context != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(icon, color: Colors.white),
              SizedBox(width: 10),
              Expanded(
                  child: Text(message, style: TextStyle(color: Colors.white))),
            ],
          ),
          backgroundColor: color,
          duration: Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: EdgeInsets.all(10),
        ),
      );
    }
  }

  // Fetch user data from Firestore with better error handling
  Future<void> fetchUserData(String uid) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection('plumbers').doc(uid).get();

      if (doc.exists) {
        userData.value = doc.data() as Map<String, dynamic>;
        log('User data fetched successfully: ${userData.value?['name']}');
      } else {
        log('No user data found in Firestore for UID: $uid');

        userData.value = null;
      }
    } on FirebaseException catch (e) {
      log('Firestore error: ${e.code} - ${e.message}');
    } catch (e) {
      log('Unexpected error fetching user data: $e');

      final context = Get.context;
      if (context != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: Colors.white),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'प्रोफाइल लोड गर्न सकिएन / Could not load profile data',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red[600],
            duration: Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            margin: EdgeInsets.all(10),
          ),
        );
      }

      userData.value = null;
    }
  }

  // Enhanced logout function with error handling
  Future<void> logout() async {
    try {
      await _auth.signOut();

      // Clear all data
      userData.value = null;
      currentUser.value = null;
      phoneController.clear();

      // Close loading dialog
      Get.back();

      // Navigate to login
      Get.offAll(() => LoginView());
    } catch (e) {
      // Close loading dialog if open
      if (Get.isDialogOpen!) Get.back();
    }
  }

  // Get user name
  String getUserName() {
    return userData.value?['name'] ?? 'प्रयोगकर्ता';
  }

  String getPlumberId() {
    return userData.value?['plumberId'] ?? 'प्रयोगकर्ता';
  }

  // Get user phone
  String getUserPhone() {
    return userData.value?['phone'] ?? '';
  }

  // Get user address
  String getUserAddress() {
    return userData.value?['address'] ?? 'ठेगाना उपलब्ध छैन';
  }

  // Get formatted date of birth
  String getDateOfBirth() {
    return userData.value?['dateOfBirth'] ?? '2080-01-01';
  }

  // Check if profile is complete
  bool isProfileComplete() {
    return userData.value?['profileComplete'] ?? false;
  }

  // Check if user is logged in
  bool isLoggedIn() {
    return currentUser.value != null && userData.value != null;
  }

  // Get user email
  String getUserEmail() {
    return userData.value?['email'] ?? '';
  }

  // Get user type
  String getUserType() {
    return userData.value?['userType'] ?? 'plumber';
  }
}
