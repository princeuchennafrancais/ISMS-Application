import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:wallet/core/utils/color_utils/color_util.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
  FlutterLocalNotificationsPlugin();

  static final AndroidNotificationChannel _channel = const AndroidNotificationChannel(
    'high_importance_channel',
    'High Importance Notifications',
    description: 'This channel is used for important notifications.',
    importance: Importance.high,
    enableVibration: true,
    enableLights: true,
    showBadge: true,
  );

  static Future<void> initialize() async {
    // Android initialization settings
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS initialization settings
    const DarwinInitializationSettings initializationSettingsIOS =
    DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    // Combined initialization settings
    const InitializationSettings initializationSettings =
    InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    // Initialize the plugin with tap handling
    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handle notification tap
        print('Notification tapped: ${response.payload}');
        _handleNotificationTap(response);
      },
    );

    // Set foreground notification presentation options for Firebase
    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // Create notification channel for Android 8+
    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    // Request permissions for local notifications
    await _requestPermissions();
  }

  static Future<void> _requestPermissions() async {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      await _notificationsPlugin
          .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      // For Android 13+ (API level 33+)
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
      _notificationsPlugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

      await androidImplementation?.requestNotificationsPermission();
    }
  }

  static Future<void> display(RemoteMessage message) async {
    try {
      final notification = message.notification;

      if (notification != null) {
        // Generate unique ID for each notification
        final id = DateTime.now().millisecondsSinceEpoch ~/ 1000;

        // Create notification details
        final NotificationDetails notificationDetails = NotificationDetails(
          android: AndroidNotificationDetails(
            _channel.id,
            _channel.name,
            channelDescription: _channel.description,
            importance: _channel.importance,
            priority: Priority.high,
            enableVibration: true,
            enableLights: true,
            color: AppColors.primaryBlue, // Blue color, customize as needed
            icon: '@mipmap/ic_launcher',
            largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
            showWhen: true,
            when: DateTime.now().millisecondsSinceEpoch,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
            sound: 'default',
          ),
        );

        // Show the notification
        await _notificationsPlugin.show(
          id,
          notification.title ?? 'New Notification',
          notification.body ?? 'You have a new message',
          notificationDetails,
          payload: _createPayload(message),
        );

        print('Notification displayed: ${notification.title}');
      } else {
        // If no notification object, create one from data
        final data = message.data;
        if (data.isNotEmpty) {
          final id = DateTime.now().millisecondsSinceEpoch ~/ 1000;

          final NotificationDetails notificationDetails = NotificationDetails(
            android: AndroidNotificationDetails(
              _channel.id,
              _channel.name,
              channelDescription: _channel.description,
              importance: _channel.importance,
              priority: Priority.high,
              enableVibration: true,
              enableLights: true,
              color: AppColors.primaryBlue,
              icon: '@mipmap/ic_launcher',
            ),
            iOS: const DarwinNotificationDetails(
              presentAlert: true,
              presentBadge: true,
              presentSound: true,
            ),
          );

          await _notificationsPlugin.show(
            id,
            data['title'] ?? 'New Notification',
            data['body'] ?? 'You have a new message',
            notificationDetails,
            payload: _createPayload(message),
          );
        }
      }
    } catch (e) {
      print('Error showing notification: $e');
    }
  }

  // Create payload from message data
  static String _createPayload(RemoteMessage message) {
    Map<String, dynamic> payload = {
      'messageId': message.messageId,
      'data': message.data,
    };

    if (message.notification != null) {
      payload['notification'] = {
        'title': message.notification!.title,
        'body': message.notification!.body,
      };
    }

    return payload.toString();
  }

  // Handle notification tap
  static void _handleNotificationTap(NotificationResponse response) {
    print('Notification tapped with payload: ${response.payload}');

    // You can add navigation logic here based on the payload
    // For isms, navigate to a specific screen based on notification data
    try {
      // Parse the payload and handle navigation
      // This is where you'd typically navigate to specific screens
      // based on the notification content

      if (response.payload != null && response.payload!.isNotEmpty) {
        // Handle different notification types here
        print('Processing notification tap...');

        // Example: You could extract route information from payload
        // and navigate accordingly using your app's navigation system
      }
    } catch (e) {
      print('Error handling notification tap: $e');
    }
  }

  // Method to show a local notification (useful for testing)
  static Future<void> showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    final id = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    const NotificationDetails notificationDetails = NotificationDetails(
      android: AndroidNotificationDetails(
        'high_importance_channel',
        'High Importance Notifications',
        channelDescription: 'This channel is used for important notifications.',
        importance: Importance.high,
        priority: Priority.high,
        enableVibration: true,
        enableLights: true,
        icon: '@mipmap/ic_launcher',
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    await _notificationsPlugin.show(
      id,
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }

  // Cancel a specific notification
  static Future<void> cancelNotification(int id) async {
    await _notificationsPlugin.cancel(id);
  }

  // Cancel all notifications
  static Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
  }
}