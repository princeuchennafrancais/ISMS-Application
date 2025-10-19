import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class TokenService {
  static final TokenService _instance = TokenService._internal();
  factory TokenService() => _instance;
  TokenService._internal();

  static const String _fcmTokenKey = 'fcm_token';
  static const String _authTokenKey = 'auth_token';

  // Store FCM Token
  Future<void> storeFCMToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_fcmTokenKey, token);
      print("✅ FCM Token stored: $token");
    } catch (e) {
      print("❌ Error storing FCM token: $e");
    }
  }

  // Get FCM Token - with fallback to Firebase if not found
  Future<String?> getFCMToken() async {
    try {
      // First, try to get from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString(_fcmTokenKey);

      if (token != null && token.isNotEmpty) {
        print("📱 FCM Token retrieved from storage: $token");
        return token;
      }

      // If not found in storage, fetch from Firebase directly
      print("⚠️ No stored FCM token found, fetching from Firebase...");
      token = await _getFCMTokenFromFirebase();

      if (token != null && token.isNotEmpty) {
        // Store it for next time
        await storeFCMToken(token);
        print("✅ FCM token fetched and stored: $token");
        return token;
      }

      print("❌ Unable to retrieve FCM token from any source");
      return null;
    } catch (e) {
      print("❌ Error getting FCM token: $e");
      return null;
    }
  }

  // Get FCM token directly from Firebase
  Future<String?> _getFCMTokenFromFirebase() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      print("📱 FCM Token fetched from Firebase: $token");
      return token;
    } catch (e) {
      print("❌ Error fetching FCM token from Firebase: $e");
      return null;
    }
  }

  // Store Auth Token
  Future<void> storeAuthToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_authTokenKey, token);
      print("✅ Auth Token stored successfully");
    } catch (e) {
      print("❌ Error storing auth token: $e");
    }
  }

  // Get Auth Token
  Future<String?> getAuthToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_authTokenKey);
      if (token != null) {
        print("🔐 Auth Token retrieved: ${token.substring(0, 20)}...");
      } else {
        print("⚠️ No auth token found");
      }
      return token;
    } catch (e) {
      print("❌ Error getting auth token: $e");
      return null;
    }
  }

  // Clear all tokens (for logout)
  Future<void> clearAllTokens() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_fcmTokenKey);
      await prefs.remove(_authTokenKey);
      print("✅ All tokens cleared");
    } catch (e) {
      print("❌ Error clearing tokens: $e");
    }
  }
}