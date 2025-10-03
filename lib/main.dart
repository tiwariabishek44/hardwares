import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_storage/get_storage.dart';
import 'package:hardwares/app/modules/bills/bills_controller.dart';
import 'package:hardwares/app/modules/login/login_controller.dart';
import 'package:hardwares/app/services/saved_items_service.dart';
import 'package:hardwares/app/utils/database_helper.dart';
import 'package:hardwares/app/utils/app_setting_service.dart';
import 'package:hardwares/app/utils/connectivity_services.dart';
import 'package:hardwares/app/modules/splash_screen/splash_view.dart';
import 'package:hardwares/app/utils/enhance_connectivity_service.dart';
import 'package:hardwares/app/utils/enhance_firebase_sync_servicer.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Configure system UI to show status bar
  SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.manual,
    overlays: [
      SystemUiOverlay.top,
      SystemUiOverlay.bottom,
    ],
  );

  // Set status bar style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  // Initialize get storage
  await GetStorage.init();

  // Initialize Firebase
  await Firebase.initializeApp();

  // Configure Firebase Auth persistence
  await _configureFirebaseAuth();

  // Initialize Services
  _initializeServices();
  await _initializeDatabase();

  // Initialize controllers
  Get.put(LoginController(), permanent: true);
  Get.put(SavedItemsService(), permanent: true);
  Get.put(BillsController(), permanent: true);

  runApp(MyApp());
}

// Configure Firebase Auth for better persistence
Future<void> _configureFirebaseAuth() async {
  try {
    // Set persistence to LOCAL (default, but explicitly set)
    await FirebaseAuth.instance.setPersistence(Persistence.LOCAL);
    log('✅ Firebase Auth persistence configured');
  } catch (e) {
    print('❌ Error configuring Firebase Auth persistence: $e');
  }
}

void _initializeServices() {
  // Put services in GetX dependency injection
  Get.put(AppSettingsService(), permanent: true);
  Get.put(ConnectivityService(), permanent: true);

  // Put enhanced services
  Get.put(EnhancedConnectivityService(), permanent: true);
  Get.put(EnhancedFirebaseSyncService(), permanent: true);

  print('✅ Enhanced services initialized successfully');
}

Future<void> _initializeDatabase() async {
  try {
    DatabaseHelper dbHelper = DatabaseHelper();
    await dbHelper.database;
    print('✅ Database initialized successfully');
  } catch (e) {
    print('❌ Error initializing database: $e');
  }
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ResponsiveSizer(
      builder: (context, orientation, screenType) {
        return GetMaterialApp(
          title: 'Hardware',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            primarySwatch: Colors.blue,
            visualDensity: VisualDensity.adaptivePlatformDensity,
            fontFamily: 'Roboto',
            appBarTheme: const AppBarTheme(
              systemOverlayStyle: SystemUiOverlayStyle(
                statusBarColor: Colors.transparent,
                statusBarIconBrightness: Brightness.dark,
                statusBarBrightness: Brightness.light,
              ),
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              elevation: 0,
            ),
          ),
          home: SplashView(), // Changed back to SplashView as the entry point
        );
      },
    );
  }
}
