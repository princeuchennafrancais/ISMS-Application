import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../models/login_model.dart';

class TokenService {
  static final TokenService _instance = TokenService._internal();
  factory TokenService() => _instance;
  TokenService._internal();

  static const String _fcmTokenKey = 'fcm_token';
  static const String _authTokenKey = 'auth_token';
  static const String _loginResponseKey = 'login_response_data'; // NEW

  // ============================================
  // FCM TOKEN METHODS
  // ============================================

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

  // ============================================
  // AUTH TOKEN METHODS
  // ============================================

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

  // ============================================
  // LOGIN RESPONSE METHODS (NEW)
  // ============================================

  /// Save complete LoginResponseModel after successful login
// In TokenService class, update saveLoginResponse method
  Future<void> saveLoginResponse(LoginResponseModel loginResponse) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // DEBUG: Check the role before saving
      print('💾 BEFORE SAVING LOGIN RESPONSE:');
      print('   - Role: ${loginResponse.role}');
      print('   - Data role: ${loginResponse.data?.role}');

      // Convert the model to JSON string
      final jsonString = json.encode(loginResponse.toJson());

      // DEBUG: Check what was actually saved
      final savedData = json.decode(jsonString);
      print('💾 ACTUALLY SAVED TO STORAGE:');
      print('   - Saved role: ${savedData['role']}');
      print('   - Saved data role: ${savedData['data']?['role']}');

      // Store in SharedPreferences
      await prefs.setString(_loginResponseKey, jsonString);
      print('✅ Login response data saved successfully');
    } catch (e) {
      print('❌ Error saving login response: $e');
    }
  }

  /// Retrieve stored LoginResponseModel
  Future<LoginResponseModel?> getLoginResponse() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_loginResponseKey);

      if (jsonString != null && jsonString.isNotEmpty) {
        final Map<String, dynamic> jsonData = json.decode(jsonString);
        print('✅ Login response data retrieved successfully');
        return LoginResponseModel.fromJson(jsonData);
      } else {
        print('⚠️ No stored login response found');
        return null;
      }
    } catch (e) {
      print('❌ Error reading login response: $e');
      return null;
    }
  }

  /// Check if user is logged in (has both auth token and login data)
  Future<bool> isUserLoggedIn() async {
    try {
      final authToken = await getAuthToken();
      final loginResponse = await getLoginResponse();

      final isLoggedIn = authToken != null &&
          authToken.isNotEmpty &&
          loginResponse != null;

      print(isLoggedIn
          ? '✅ User is logged in'
          : '⚠️ User is not logged in');

      return isLoggedIn;
    } catch (e) {
      print('❌ Error checking login status: $e');
      return false;
    }
  }

  // ============================================
  // CLEAR/LOGOUT METHODS
  // ============================================

  // Clear all tokens (for logout)
  Future<void> clearAllTokens() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_fcmTokenKey);
      await prefs.remove(_authTokenKey);
      await prefs.remove(_loginResponseKey); // UPDATED - also clear login data
      print("✅ All tokens cleared");
    } catch (e) {
      print("❌ Error clearing tokens: $e");
    }
  }

  /// Alternative name for clearAllTokens (more descriptive)
  Future<void> logout() async {
    await clearAllTokens();
  }
}