import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hardwares/app/modules/bottom_navigation/user_main_screen.dart';
import '../login/login_view.dart';
import '../login/login_controller.dart';
import 'package:hardwares/app/utils/firebase_sync_service.dart';

class SplashController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Animation variables
  var logoScale = 0.0.obs;
  var textOpacity = 0.0.obs;

  // Status messages
  var statusMessage = 'एप सुरु गर्दै... / Starting App...'.obs;
  var subStatusMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    _startSplashSequence();
  }

  // Start the splash screen sequence
  Future<void> _startSplashSequence() async {
    // Start animations immediately
    _startAnimations();

    // Wait for animations to complete and Firebase to initialize
    await Future.delayed(
        Duration(milliseconds: 1500)); // Reduced from 3 seconds

    // Check authentication status
    await _checkAuthenticationStatus();
  }

  // Start logo and text animations
  void _startAnimations() {
    // Logo scale animation
    Future.delayed(Duration(milliseconds: 300), () {
      logoScale.value = 1.0;
    });

    // Text fade in animation
    Future.delayed(Duration(milliseconds: 800), () {
      textOpacity.value = 1.0;
    });
  }

  // Check if user is logged in and has valid data
  Future<void> _checkAuthenticationStatus() async {
    try {
      // Update status
      statusMessage.value = 'प्रयोगकर्ता जाँच गर्दै... / Checking User...';
      await Future.delayed(Duration(milliseconds: 300));

      // FIXED: Get current user directly instead of waiting for auth state changes
      User? currentUser = _auth.currentUser;

      // If currentUser is null, wait a bit for Firebase to initialize
      if (currentUser == null) {
        print('No immediate user found, waiting for Firebase Auth...');
        await Future.delayed(Duration(milliseconds: 500));
        currentUser = _auth.currentUser; // Check again
      }

      print('Current Firebase User: ${currentUser?.uid}');
      print('User Email: ${currentUser?.email}');
      print('User Phone: ${currentUser?.phoneNumber}');

      if (currentUser != null) {
        // User is signed in, check if profile data exists
        statusMessage.value = 'प्रोफाइल लोड गर्दै... / Loading Profile...';
        subStatusMessage.value = 'कृपया पर्खनुहोस् / Please wait...';

        await Future.delayed(Duration(milliseconds: 500));

        try {
          // Try to fetch user data from Firestore
          DocumentSnapshot userDoc = await _firestore
              .collection('plumbers')
              .doc(currentUser.uid)
              .get()
              .timeout(Duration(seconds: 10)); // Add timeout

          print('Firestore doc exists: ${userDoc.exists}');

          if (userDoc.exists && userDoc.data() != null) {
            // User has complete profile data
            Map<String, dynamic> userData =
                userDoc.data() as Map<String, dynamic>;

            print('User data loaded: ${userData['name']}');

            // INITIALIZE LOGINCONTROLLER WITH USER DATA
            final LoginController loginController = Get.find<LoginController>();
            loginController.currentUser.value = currentUser;
            loginController.userData.value = userData;

            statusMessage.value = 'स्वागत छ! / Welcome!';
            subStatusMessage.value = 'डाटा सिंक गर्दै... / Syncing data...';

            // SYNC CUSTOMER REQUIREMENTS
            try {
              String plumberId = userData['plumberId'] ?? '';
              if (plumberId.isNotEmpty) {
                FirebaseSyncService syncService = FirebaseSyncService();
                await syncService.syncCustomerRequirements(plumberId);
              }
            } catch (e) {
              print('Error syncing data: $e');
              // Continue with login even if sync fails
            }

            subStatusMessage.value = 'होम पेजमा जाँदै... / Going to Home...';

            await Future.delayed(Duration(milliseconds: 500));

            print('Navigating to UserMainScreen');

            // Navigate to home
            Get.offAll(() => UserMainScreen());
          } else {
            // User exists in Auth but no Firestore data
            print('No Firestore data found for user');

            statusMessage.value =
                'प्रोफाइल डाटा फेला परेन / Profile Data Not Found';
            subStatusMessage.value = 'लगइन पेजमा जाँदै... / Going to Login...';

            await Future.delayed(Duration(milliseconds: 1000));

            // Don't sign out, just navigate to login
            // The user can try to login again and it should work
            print('Navigating to login - incomplete profile');

            // Navigate to login
            Get.offAll(() => LoginView());
          }
        } catch (firestoreError) {
          print('Firestore error: $firestoreError');

          // Check if it's a network error
          if (firestoreError.toString().contains('network') ||
              firestoreError.toString().contains('timeout')) {
            statusMessage.value = 'नेटवर्क त्रुटि / Network Error';
            subStatusMessage.value = 'होम पेजमा जाँदै... / Going to Home...';

            // If network error, still try to navigate to home with cached user
            final LoginController loginController = Get.find<LoginController>();
            loginController.currentUser.value = currentUser;

            await Future.delayed(Duration(milliseconds: 1000));
            Get.offAll(() => UserMainScreen());
          } else {
            statusMessage.value = 'डाटाबेस त्रुटि / Database Error';
            subStatusMessage.value = 'लगइन पेजमा जाँदै... / Going to Login...';

            await Future.delayed(Duration(milliseconds: 1000));
            Get.offAll(() => LoginView());
          }
        }
      } else {
        // No user signed in
        print('No user signed in');

        statusMessage.value = 'लगइन आवश्यक / Login Required';
        subStatusMessage.value = 'लगइन पेजमा जाँदै... / Going to Login...';

        await Future.delayed(Duration(milliseconds: 800));

        // Navigate to login
        Get.offAll(() => LoginView());
      }
    } catch (e) {
      print('Error during authentication check: $e');

      // Handle errors gracefully
      statusMessage.value = 'त्रुटि भयो / Error Occurred';
      subStatusMessage.value = 'लगइन पेजमा जाँदै... / Going to Login...';

      await Future.delayed(Duration(milliseconds: 1000));

      // Navigate to login as fallback (don't sign out)
      Get.offAll(() => LoginView());
    }
  }

  // Manual retry function (if needed)
  Future<void> retryAuthentication() async {
    statusMessage.value = 'पुनः प्रयास गर्दै... / Retrying...';
    subStatusMessage.value = '';

    await Future.delayed(Duration(milliseconds: 500));
    await _checkAuthenticationStatus();
  }
}
