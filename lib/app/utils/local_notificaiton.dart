import 'dart:developer';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hardwares/app/utils/enhance_firebase_sync_servicer.dart';

class LocalNotificationService {
  static final LocalNotificationService _instance =
      LocalNotificationService._internal();
  factory LocalNotificationService() => _instance;
  LocalNotificationService._internal();

  late FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin;

  // Notification IDs
  static const int SYNC_START_ID = 1001;
  static const int ORDERS_SYNC_ID = 1002;
  static const int PARTIES_SYNC_ID = 1003;
  static const int TRANSACTIONS_SYNC_ID = 1004;
  static const int SYNC_COMPLETE_ID = 1005;
  static const int SYNC_ERROR_ID = 1006;
  static const int NO_DATA_SYNC_ID = 1007;

  Future<void> initialize() async {
    _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

    // Android initialization
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS initialization
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Request permissions for Android 13+
    if (Platform.isAndroid) {
      await _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    }

    log('📱 Local notification service initialized with push notifications');
  }

  void _onNotificationTapped(NotificationResponse notificationResponse) {
    log('📱 Notification tapped: ${notificationResponse.payload}');
    // Handle notification tap if needed
  }

  // Show progress notification for each type with progress bar - NO ICON
  Future<void> showProgressNotification(String type, int uploaded, int failed,
      {int? currentProgress, int? maxProgress}) async {
    String message = uploaded > 0
        ? '$uploaded $type uploaded successfully'
        : 'Processing $type...';

    if (failed > 0) {
      message += ' ($failed failed)';
    }

    // Determine color based on results
    Color notificationColor = failed > 0
        ? Color(0xFFFF9800) // Orange for partial success
        : Color(0xFF4CAF50); // Green for success

    AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'sync_progress_channel',
      'Sync Progress',
      channelDescription: 'Progress updates for data synchronization',
      importance: Importance.high,
      priority: Priority.high,
      ongoing: true,
      showProgress: currentProgress != null && maxProgress != null,
      maxProgress: maxProgress ?? 100,
      progress: currentProgress ?? 0,
      // icon: '@drawable/ic_upload', // REMOVED
      color: notificationColor,
      autoCancel: false,
    );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: false, // No sound for progress updates
    );

    NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    // Use different IDs for different types
    int notificationId;
    switch (type.toLowerCase()) {
      case 'orders':
        notificationId = ORDERS_SYNC_ID;
        break;
      case 'parties':
        notificationId = PARTIES_SYNC_ID;
        break;
      case 'transactions':
        notificationId = TRANSACTIONS_SYNC_ID;
        break;
      default:
        notificationId = SYNC_START_ID;
    }

    await _flutterLocalNotificationsPlugin.show(
      notificationId,
      '📤 $type Sync',
      message,
      platformChannelSpecifics,
      payload: 'sync_progress_$type',
    );
  }

  // Show completion notification - NO ICON

  // Show no data notification - NO ICON
  Future<void> showNoDataToSyncNotification() async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'sync_info_channel',
      'Sync Info',
      channelDescription: 'Information about sync status',
      importance: Importance.low,
      priority: Priority.low,
      autoCancel: true,
      // icon: '@drawable/ic_info', // REMOVED
      color: Color(0xFF2196F3),
    );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: false,
      presentSound: false,
    );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    await _flutterLocalNotificationsPlugin.show(
      NO_DATA_SYNC_ID,
      'ℹ️ Already Synced',
      'All your data is already uploaded to server',
      platformChannelSpecifics,
      payload: 'no_data_sync',
    );
  }

  // Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _flutterLocalNotificationsPlugin.cancelAll();
  }
}
