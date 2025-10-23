
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:wallet/core/controllers/notification_service.dart';
import 'package:wallet/core/controllers/token_service.dart';
import 'package:wallet/core/utils/widget_utils/custom_snackbar.dart';
import 'package:wallet/feautures/auth/launch.dart';
import 'package:wallet/feautures/auth/login.dart';
import 'package:wallet/firebase_options.dart';
import 'core/controllers/notification_service.dart';
import 'core/controllers/school_service.dart';
import 'core/controllers/token_service.dart';
import 'core/models/login_model.dart';
import 'feautures/presentation/home/home_screen.dart';
import 'feautures/auth/school_code_screen.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'firebase_options.dart';



final _storage = const FlutterSecureStorage();

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Ensure Firebase is initialized in background
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await NotificationService.initialize();
  NotificationService.display(message);

  print('Background message handled: ${message.notification?.title}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform
  );

  // Initialize school data and colors at app startup
  await SchoolDataService.initializeSchoolData();

  // Initialize Firebase Messaging
  FirebaseMessaging firebaseMessaging = FirebaseMessaging.instance;

  // Request notification permissions (CRITICAL for iOS and Android 13+)
  NotificationSettings settings = await firebaseMessaging.requestPermission(
    alert: true,
    announcement: false,
    badge: true,
    carPlay: false,
    criticalAlert: false,
    provisional: false,
    sound: true,
  );

  print('User granted permission: ${settings.authorizationStatus}');

  if (settings.authorizationStatus == AuthorizationStatus.authorized ||
      settings.authorizationStatus == AuthorizationStatus.provisional) {

    // Get FCM token directly
    firebaseMessaging.getToken().then((token) async {
      if (token != null) {
        // Store using TokenService (consistent storage method)
        await TokenService().storeFCMToken(token);
        print("📱 FCM Token stored: $token");

        // Subscribe to topics
        try {
          await firebaseMessaging.subscribeToTopic('Students');
          print("✅ Subscribed to default topics");
        } catch (e) {
          print("❌ Error subscribing to topics: $e");
        }
      } else {
        print('⚠️ FCM Token is null');
      }
    }).catchError((error) {
      print('❌ Error getting FCM token: $error');
    });

    // Handle token refresh
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      // Store using TokenService
      await TokenService().storeFCMToken(newToken);
      print('🔄 FCM Token refreshed: $newToken');

      // Re-subscribe to topics
      try {
        await firebaseMessaging.subscribeToTopic('Students');
        print("✅ Re-subscribed to topics");
      } catch (e) {
        print("❌ Error re-subscribing to topics: $e");
      }
    });
  } else {
    print('⚠️ Notification permission denied');
  }

  // Set up background message handler (MUST be done before runApp)
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Handle foreground messages
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print('Received foreground message: ${message.notification?.title}');
    NotificationService.display(message);
  });

  // Handle notification taps when app is in background/terminated
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    print('Message clicked! ${message.notification?.title}');
    _handleNotificationTap(message);
  });

  // Handle notification tap when app is terminated
  FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
    if (message != null) {
      print('App launched from notification: ${message.notification?.title}');
      _handleNotificationTap(message);
    }
  });

  // Initialize notifications
  await NotificationService.initialize();

  runApp(MyApp());
}

// Handle notification tap actions
void _handleNotificationTap(RemoteMessage message) {
  // You can navigate to specific screens based on notification data
  if (message.data.containsKey('route')) {
    String route = message.data['route'];
    print('Navigate to: $route');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: Size(428, 926),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp(
          navigatorKey: CustomSnackbar.navigatorKey,
          debugShowCheckedModeBanner: false,
          title: 'Rosary College Wallet System',
          initialRoute: '/',
          onGenerateRoute: (settings) {
            switch (settings.name) {
              case '/':
              // Use the smart initializer to determine first screen
                return MaterialPageRoute(
                  builder: (_) => FutureBuilder<Widget>(
                    future: AppInitializer.getInitialScreen(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Scaffold(
                          body: Center(
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }

                      if (snapshot.hasError) {
                        return const Scaffold(
                          body: Center(
                            child: Text('Error initializing app'),
                          ),
                        );
                      }

                      return snapshot.data ?? const Launch();
                    },
                  ),
                );

              case '/school-code':
                return MaterialPageRoute(builder: (_) => const SchoolCodeScreen());

              case '/launch':
                return MaterialPageRoute(builder: (_) => const Launch());

              case '/login':
                return MaterialPageRoute(builder: (_) => const LoginScreen());

              case '/home':
                final LoginResponseModel? loginResponse = settings.arguments as LoginResponseModel?;
                return MaterialPageRoute(
                  builder: (_) => HomeScreen(
                    loginResponse: loginResponse ?? LoginResponseModel(),
                  ),
                );

              default:
                return MaterialPageRoute(
                  builder: (_) => Scaffold(
                    body: Center(child: Text('Route not found: ${settings.name}')),
                  ),
                );
            }
          },
        );
      },
    );
  }
}


class AppInitializer {
  static Future<Widget> getInitialScreen() async {
    try {
      print('AppInitializer: Starting app initialization...');

      // Check if school data exists using SchoolDataService
      final bool hasSchoolData = await SchoolDataService.hasSchoolData();

      if (hasSchoolData) {
        print('✓ School data found, loading stored data...');

        // Get stored school data
        final schoolData = await SchoolDataService.getSchoolData();
        if (schoolData != null) {
          print('✓ Applied school data for: ${schoolData.schoolName}');
          print('✓ School color: ${schoolData.colorHex}');

          // School data exists, check if user is logged in
          final bool isLoggedIn = await TokenService().isUserLoggedIn();
          if (isLoggedIn) {
            // User is logged in and has school data, get stored login data
            print('✓ User is logged in, loading stored user data...');

            final loginResponse = await TokenService().getLoginResponse();

            if (loginResponse != null) {
              print('✓ User data loaded, going to home screen');
              return LoginScreen();
            } else {
              // Login data corrupted, go to login screen
              print('⚠️ Login data not found, going to login screen');
              return const LoginScreen();
            }
          } else {
          // User has school data but not logged in, go to login
          print('✓ User not logged in, going to login screen');
          return const LoginScreen();
        }
      } else {
        // School data exists but couldn't load it, go to school code screen
        print('⚠️ School data exists but couldn\'t load, going to school code screen');
        return const SchoolCodeScreen();
      }
    } else {
    // No school data, user needs to enter school code first
    print('ℹ️ No school data found, going to school code screen');
    return const SchoolCodeScreen();
    }
    } catch (e) {
    print('❌ Error during app initialization: $e');
    // On error, default to school code screen
    return const SchoolCodeScreen();
    }
  }
}