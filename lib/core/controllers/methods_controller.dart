import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:wallet/core/controllers/api_endpoints.dart';
import 'package:wallet/core/controllers/school_service.dart';
import 'package:wallet/core/controllers/token_service.dart';
import 'package:wallet/core/models/login_model.dart';
import 'package:wallet/core/models/news_letter_model.dart';
import 'package:wallet/core/models/payment_response_model.dart';
import 'package:wallet/core/models/profile_model.dart';
import 'package:wallet/core/utils/color_utils/color_util.dart';
import 'package:wallet/core/utils/widget_utils/custom_snackbar.dart';
import 'package:wallet/feautures/auth/create_pin.dart';
import 'package:wallet/feautures/auth/create_wallet.dart';
import 'package:wallet/feautures/presentation/home/index_screen.dart';
import 'package:wallet/feautures/presentation/home/payment_success_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthController extends GetxController {
  final RxBool isLoading = false.obs;
  final isAccountNameLoading = false.obs;
  final isTransactionsLoading = false.obs;
  final isVillageLoading = false.obs;
  final isBankNameLoading = false.obs;
  final isBankLoading = false.obs;
  String receiptUrl = "";
  String demandNoticeUrl = "";
  String receiptno = "";
  List<dynamic> paymentHistory = [];
  String walletBankAccountName = "";
  String walletBankAccountNumber = "";
  String walletBankCode = "";
  String bankAccountName = "";
  static List<Newsletter> newsletters = [];
  final selectedRememberMeValue = "false".obs;
  static ValueNotifier<bool> isCreatingPin = ValueNotifier<bool>(false);
  static List<Newsletter> _newsletters = [];
  String schoolCode = "";



  LoginResponseModel loginResponseModel = LoginResponseModel();
  PaymentResponseModel? paymentResponseModel;
  @override
  void onInit() {
    super.onInit();
    _initializeSchoolCode();
  }

  Future<void> _initializeSchoolCode() async {
    final schoolData = await SchoolDataService.getSchoolData();
    schoolCode = schoolData?.schoolCode ?? "";
  }



  Future<void> loginUser({
    required String userName,
    required String password,
    required String fcmToken,
    required BuildContext context,
  }) async {
    try {
      // Ensure school code is initialized before making the request
      await _ensureSchoolCodeInitialized();

      print("🔄 Attempting login to: ${APIEndpoints.loginUserEndpoint}");
      print("📝 Username: $userName");
      print("📝 Password: $password");
      print("📝 FCMToken: $fcmToken");
      print("🏫 School Code: '$schoolCode'");
      print("🏫 School Code is null: ${schoolCode == null}");
      print("🏫 School Code is empty: ${schoolCode.isEmpty}");

      // Create JSON body
      final Map<String, dynamic> requestBody = {
        'username': userName,
        'password': password,
        // 'device_token': fcmToken, // Uncomment if needed
      };

      // Convert to JSON string
      final String jsonBody = jsonEncode(requestBody);
      print("📋 Request Body JSON: $jsonBody");

      // Create headers
      final Map<String, String> headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'scode': schoolCode,
      };

      // Print all headers being sent
      print("📋 Request Headers:");
      headers.forEach((key, value) {
        print("   $key: '$value'");
      });

      print("📤 Sending JSON request...");

      // Make HTTP POST request with JSON body
      final response = await http.post(
        Uri.parse(APIEndpoints.loginUserEndpoint),
        headers: headers,
        body: jsonBody,
      );

      print("📥 Response Status: ${response.statusCode}");
      print("📥 Response Body: ${response.body}");

      if (response.statusCode == 200) {
        // Clean the response body to remove PHP warnings/errors
        String cleanedResponse = cleanJsonResponse(response.body);
        print("🧹 Cleaned Response: $cleanedResponse");

        final responseData = jsonDecode(cleanedResponse);

        // Access the payload first, then check status
        final payload = responseData['payload'];
        if (payload != null && payload['status'] == 1) {
          // Create login response model from the payload data
          loginResponseModel = LoginResponseModel.fromJson(payload);

          // Get token from the payload
          final token = payload['token'];

          // ✅ STEP 1: Store auth token (you already have this)
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('auth_token', token);
          print("🔐 Token saved locally: $token");

          // ✅ STEP 2: Store auth token using TokenService (for consistency)
          await TokenService().storeAuthToken(token);

          // ✅ STEP 3: Save complete login response (NEW - ADD THIS!)
          await TokenService().saveLoginResponse(loginResponseModel);
          print("💾 Complete login response saved");

          if (context.mounted) {
            CustomSnackbar.success(payload['message'] ?? 'Login successful');
          }

          print(loginResponseModel.data);

          // Always send device token to backend after successful login
          print("📱 Attempting to send device token to backend...");

          // Get FCM token using TokenService (which has fallback to Firebase)
          String? fcmToken = await TokenService().getFCMToken();
          final authToken = token; // Use the token we just received

          if (fcmToken != null && fcmToken.isNotEmpty && authToken.isNotEmpty) {
            print("📤 Sending device token to backend...");
            print("   FCM Token: $fcmToken");
            print("   Auth Token: ${authToken.substring(0, 20)}...");

            try {
              await sendTokenToBackend(fcmToken, authToken);
              print("✅ Device token sent successfully");
            } catch (e) {
              print("❌ Error sending device token: $e");
              // Don't block login if token send fails
            }
          } else {
            print("⚠️ Warning: Unable to send device token");
            print("   FCM Token: ${fcmToken ?? 'null'}");
            print("   Auth Token: ${authToken.isNotEmpty ? 'available' : 'null'}");
            print("   This might happen if:");
            print("   1. Firebase is not properly initialized");
            print("   2. User denied notification permissions");
            print("   3. App is running on an emulator without Google Play Services");
          }

          // Navigate based on wallet status from payload
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => IndexScreen(loginResponse: loginResponseModel)),
          );
        } else {
          // Handle error from payload or if payload is null
          print("❌ Login failed: Invalid payload or status");
          handleLoginError(payload ?? {'message': 'Invalid response structure'}, context);
        }
      } else {
        print("❌ HTTP Error: ${response.statusCode}");
        if (context.mounted) {
          CustomSnackbar.error("Server error: ${response.statusCode}");
        }
      }
    } on SocketException catch (e) {
      print("❌ Socket Exception: $e");
      if (context.mounted) {
        CustomSnackbar.error("Connection failed check your internet Connection");
      }
    } on TimeoutException catch (e) {
      print("❌ Timeout Exception: $e");
      if (context.mounted) {
        CustomSnackbar.error("Request timeout, Please try again");
      }
    } on FormatException catch (e) {
      print("❌ JSON Format Exception: $e");
      if (context.mounted) {
        CustomSnackbar.error("Invalid response format from server");
      }
    } catch (error) {
      print("❌ General Error: $error");
      print("❌ Stack trace: ${StackTrace.current}");
      if (context.mounted) {
        CustomSnackbar.error("Login failed please try again");
      }
    } finally {
      isLoading.value = false;
    }
  }
// Add this helper method to ensure school code is initialized
  Future<void> _ensureSchoolCodeInitialized() async {
    if (schoolCode.isEmpty) {
      print("🔄 School code not initialized, fetching now...");
      final schoolData = await SchoolDataService.getSchoolData();
      schoolCode = schoolData?.schoolCode ?? "";
      print("🏫 School code initialized: '$schoolCode'");
    } else {
      print("✅ School code already initialized: '$schoolCode'");
    }
  }

  // Helper method to clean JSON response
  String cleanJsonResponse(String responseBody) {
    // Find the first occurrence of '{'
    int jsonStart = responseBody.indexOf('{');

    if (jsonStart == -1) {
      throw FormatException('No valid JSON found in response');
    }

    // Extract everything from the first '{' to the end
    String cleanedJson = responseBody.substring(jsonStart);

    // Optional: Remove any trailing HTML/PHP errors after the JSON
    // Find the last '}' which should be the end of our JSON
    int jsonEnd = cleanedJson.lastIndexOf('}');
    if (jsonEnd != -1) {
      cleanedJson = cleanedJson.substring(0, jsonEnd + 1);
    }

    return cleanedJson;
  }

  void handleLoginError(Map body, BuildContext context) {
    final errorMessage = body["message"] ?? "Login failed";
    if (kDebugMode) print("❌ Login Error: $errorMessage");

    if (context.mounted) {
      CustomSnackbar.error(errorMessage);
    }
  }


  Future<void> sendTokenToBackend(String fcmToken, String authToken) async {
    try {
      // 1. Create the request with JSON body
      final response = await http.post(
        Uri.parse('https://api.ceemact.com/firebase_api/saveDeviceToken'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
          'scode': schoolCode,
        },
        body: jsonEncode({
          'device_token': fcmToken,
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        print('✅ Token successfully sent to backend');

        // Parse the response
        final jsonResponse = jsonDecode(response.body);

        // Access response data
        final state = jsonResponse['state'];
        final payload = jsonResponse['payload'];

        print('Status: ${state['status']}');
        print('Message: ${state['message']}');
        print('Is Device Token: ${payload['is_device_token']}');

        // You can return or handle the response data as needed
      } else {
        print('❌ Failed to send token: ${response.statusCode}');
        print('Response: ${response.body}');
      }
    } catch (e) {
      print('❌ Error sending token: $e');
    }
  }

  Future makePayment({
    required String sender,
    required String amount,
    required String description,
    required String pin,
    required BuildContext context,
  }) async {
    try {
      print("🔄 Attempting payment to: ${APIEndpoints.makePaymentEndpoint}");
      print("📝 sender: $sender");
      print("📝 Amount: $amount");
      print("📝 Description: $description");
      print("📝 Pin: $pin");

      var request = http.MultipartRequest(
        'POST',
        Uri.parse(APIEndpoints.makePaymentEndpoint),
      );

      request.fields['sender'] = sender;
      request.fields['amount'] = amount;
      request.fields['description'] = description;
      request.fields['pin'] = pin;


      // Get auth token from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? '';

      request.headers.addAll({
        'Content-Type': 'multipart/form-data',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
        'scode': schoolCode,
      });

      print("📤 Sending payment request...");
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      print("📥 Response Status: ${response.statusCode}");
      print("📥 Response Body: ${response.body}");

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        if (response.statusCode == 200) {
          final responseData = jsonDecode(response.body);

          if (responseData['status'] == 1) {
            paymentResponseModel = PaymentResponseModel.fromJson(responseData);

            if (context.mounted) {
              CustomSnackbar.success(responseData['message'] ?? 'Payment successful');
              // Immediately navigate without delay
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => PaymentSuccessScreen(
                    paymentResponse: paymentResponseModel!,
                  ),
                ),
              );
            }
          } else {
            handlePaymentError(responseData, context);
          }
        }
      } else {
        print("❌ HTTP Error: ${response.statusCode}");
        if (context.mounted) {
          CustomSnackbar.error("Server error: ${response.statusCode}");
        }
      }
    } on SocketException catch (e) {
      print("❌ Socket Exception: $e");
      if (context.mounted) {
        CustomSnackbar.error("Connection failed check your internet connection");
      }
    } on TimeoutException catch (e) {
      print("❌ Timeout Exception: $e");
      if (context.mounted) {
        CustomSnackbar.error("Request timeout, Please try again");
      }
    } catch (error) {
      print("❌ General Error: $error");
      if (context.mounted) {
        CustomSnackbar.error("Payment failed please try again");
      }
    } finally {
      isLoading.value = false;
    }
  }

  void handlePaymentError(Map body, BuildContext context) {
    final errorMessage = body["message"] ?? "Payment failed";
    if (kDebugMode) print("❌ Payment Error: $errorMessage");

    if (context.mounted) {
      CustomSnackbar.error(errorMessage);
    }
  }



  Future<void> logoutUser({
    required BuildContext context,
  }) async {
    if (isLoading.value) return;

    // Store the navigator before showing dialog
    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    isLoading.value = true;


    try {
      print("🔄 Attempting logout...");

      final request = http.MultipartRequest(
        'POST',
        Uri.parse(APIEndpoints.logoutUserEndpoint),
      );

      request.headers.addAll({
        'Content-Type': 'multipart/form-data',
        'Accept': 'application/json',
        'scode': schoolCode,
      });


      final streamedResponse = await request.send().timeout(const Duration(seconds: 30));
      final response = await http.Response.fromStream(streamedResponse);

      print("📥 Response Status: ${response.statusCode}");
      print("📥 Response Body: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 302) {
        // Success - handle everything in sequence
        print("✅ Logout successful, cleaning up...");

        // 1. Close dialog first
        if (navigator.canPop()) {
          navigator.pop();
          print("✅ Dialog closed");
        }

        // 2. Reset ALL loading states immediately
        isLoading.value = false;
        print("🔄 Loading state reset to: ${isLoading.value}");

        // 3. Add a small delay to ensure UI updates
        await Future.delayed(const Duration(milliseconds: 100));

        // 4. Clear any additional app state if needed
        // Add these lines if you have other state management:
        // userController.clearUserData(); // Clear user data
        // authController.setLoggedOut(); // Set auth state

        // 5. Show success message briefly
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: const Text('Logout successful'),
            backgroundColor: AppColors.primaryBlue,
            duration: const Duration(milliseconds: 800),
          ),
        );

        print("Current route: ${ModalRoute.of(context)?.settings.name}");

        // 6. Navigate with complete replacement
        if (context.mounted) {
          Navigator.of(context, rootNavigator: true).pushNamedAndRemoveUntil('/login', (route) => false);
        }
        print("Current route: ${ModalRoute.of(context)?.settings.name}");



        print("✅ Navigation to login completed");

      } else {
        // Error handling
        _handleDialogError(navigator, scaffoldMessenger, "Server error: ${response.statusCode}");
      }

    } catch (error) {
      print("❌ Logout error: $error");
      _handleDialogError(navigator, scaffoldMessenger, "Logout failed. Please try again.");
    }
  }

  void _handleDialogError(NavigatorState navigator, ScaffoldMessengerState scaffoldMessenger, String message) {
    // Close dialog
    if (navigator.canPop()) {
      navigator.pop();
    }

    // Reset loading state
    isLoading.value = false;
    print("🔄 Error: Loading state reset to: ${isLoading.value}");

    // Show error
    scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }


  // Only the updated parts are shown here
  Future<void> createWallet({
    required String bvn,
    required String email,
    required String phone,
    required LoginResponseModel loginResponse,
    required BuildContext context,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) {
        throw Exception("No token found. Please login again.");
      }

      // Format phone number to international format if it's not already
      String formattedPhone = formatPhoneNumber(phone);

      print("🔄 Attempting createWallet at: ${APIEndpoints.createWalletEndpoint}");
      print("📝 BVN: $bvn");
      print("📝 Email: $email");
      print("📝 Phone (original): $phone");
      print("📝 Phone (formatted): $formattedPhone");
      print("🔐 Token: $token");

      var request = http.MultipartRequest(
        'POST',
        Uri.parse(APIEndpoints.createWalletEndpoint),
      );

      request.fields['bvn'] = bvn;
      request.fields['email'] = email;
      request.fields['phone'] = formattedPhone;
      request.fields['phone'] = formattedPhone;

      request.headers.addAll({
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'scode': schoolCode,
      });

      print("📤 Sending create wallet request...");
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      print("📥 Response Status: ${response.statusCode}");
      print("📥 Response Body: ${response.body}");

      // Parse JSON response regardless of status code
      Map<String, dynamic>? responseData;
      try {
        if (response.body.isNotEmpty) {
          responseData = jsonDecode(response.body);
        }
      } catch (e) {
        print("❌ JSON Parse Error: $e");
      }

      if (response.statusCode == 200) {
        if (responseData != null && responseData['status'] == 1) {
          if (context.mounted) {
            CustomSnackbar.success(responseData['message'] ?? 'Wallet created successfully');
          }

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => CreatePin(loginResponse: loginResponse)),
          );
        } else {
          handleWalletError(responseData ?? {}, context);
        }
      } else {
        print("❌ HTTP Error: ${response.statusCode}");

        if (responseData != null) {
          handleWalletError(responseData, context);
        } else {
          if (context.mounted) {
            CustomSnackbar.error("Server error: ${response.statusCode}");
          }
        }
      }
    } on SocketException catch (e) {
      print("❌ Socket Exception: $e");
      if (context.mounted) {
        CustomSnackbar.error("Connection failed. Please check your internet connection.");
      }
    } on TimeoutException catch (e) {
      print("❌ Timeout Exception: $e");
      if (context.mounted) {
        CustomSnackbar.error("Request timeout. Please try again.");
      }
    } catch (error) {
      print("❌ General Error: $error");
      if (context.mounted) {
        CustomSnackbar.error("Wallet creation failed. Please try again.");
      }
    }
  }

// Helper function to format phone number to international format
  String formatPhoneNumber(String phone) {
    // Remove any spaces, dashes, or other characters
    String cleanPhone = phone.replaceAll(RegExp(r'[^\d+]'), '');

    // If it already starts with +234, return as is
    if (cleanPhone.startsWith('+234')) {
      return cleanPhone;
    }

    // If it starts with 234, add the +
    if (cleanPhone.startsWith('234')) {
      return '+$cleanPhone';
    }

    // If it starts with 0 (Nigerian local format), replace with +234
    if (cleanPhone.startsWith('0') && cleanPhone.length == 11) {
      return '+234${cleanPhone.substring(1)}';
    }

    // If it's 10 digits (without leading 0), add +234
    if (cleanPhone.length == 10 && !cleanPhone.startsWith('0')) {
      return '+234$cleanPhone';
    }

    // If none of the above, assume it needs +234 prefix
    return '+234$cleanPhone';
  }

  void handleWalletError(Map<String, dynamic> body, BuildContext context) {
    final errorMessage = body["message"] ?? "Wallet creation failed";
    final errorDetails = body["error"] ?? "";

    String fullErrorMessage = errorMessage;
    if (errorDetails.isNotEmpty && errorDetails != errorMessage) {
      fullErrorMessage = "$errorMessage: $errorDetails";
    }

    if (kDebugMode) print("❌ Wallet Error: $fullErrorMessage");

    if (context.mounted) {
      CustomSnackbar.error(fullErrorMessage);
    }
  }



  Future<void> getProfile({
    required BuildContext context,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) {
        throw Exception("No auth token found");
      }

      final uri = Uri.parse(APIEndpoints.getProfileEndpoint);
      print("🔄 Attempting to fetch profile from: $uri");
      print("🔐 Using token: $token");
      print("🔐 Using scode: $schoolCode");

      final response = await http.get(
        uri,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
          'scode': schoolCode,
        },
      );


      print("📥 Response Status: ${response.statusCode}");
      print("📥 Response Body: ${response.body}");

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        if (responseData['status'] == 1) {
          ProfileResponseModel profileResponseModel = ProfileResponseModel.fromJson(responseData);
          print("✅ Profile fetched successfully: ${profileResponseModel.data}");

          // TODO: Use the profileResponseModel in your app as needed
        } else {
          handleProfileError(responseData, context);
        }
      } else {
        print("❌ HTTP Error: ${response.statusCode}");
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Server error: ${response.statusCode}")),
          );
        }
      }
    } on SocketException catch (e) {
      print("❌ Socket Exception: $e");
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Connection failed. Check your internet connection."),
            backgroundColor: Colors.red,
          ),
        );
      }
    } on TimeoutException catch (e) {
      print("❌ Timeout Exception: $e");
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Request timeout. Please try again."),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (error) {
      print("❌ General Error: $error");
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Failed to fetch profile. Please try again."),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }


  void handleProfileError(Map body, BuildContext context) {
    final errorMessage = body["message"] ?? "Profile fetch failed";
    if (kDebugMode) print("❌ Profile Error: $errorMessage");

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> createPin({
    required String pin,
    required String confirmPin,
    required BuildContext context,
    required LoginResponseModel loginResponse,
  }) async {
    try {
      print("🔄 Creating wallet PIN...");
      print("📝 PIN: $pin");
      print("📝 Confirm PIN: $confirmPin");

      // Validate PIN match
      if (pin != confirmPin) {
        if (context.mounted) {
          CustomSnackbar.error("PINs do not match");
        }
        return;
      }

      // Validate PIN length (adjust as needed)
      if (pin.length != 4) {
        if (context.mounted) {
          CustomSnackbar.error("PIN must be up to 4 digits");
        }
        return;
      }

      isCreatingPin.value = true;

      // Get stored token
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) {
        if (context.mounted) {
          CustomSnackbar.error("Authentication token not found. Please login again.");
        }
        return;
      }

      var request = http.MultipartRequest(
        'POST',
        Uri.parse(APIEndpoints.CreatePinEndpoint), // Adjust endpoint as needed
      );

      request.fields['pin'] = pin;
      request.fields['pin2'] = confirmPin;


      request.headers.addAll({
        'Content-Type': 'multipart/form-data',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
        'scode': schoolCode,
      });

      print("📤 Sending create PIN request...");
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      print("📥 Create PIN Response Status: ${response.statusCode}");
      print("📥 Create PIN Response Body: ${response.body}");

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        if (responseData['status'] == 1) {
          // PIN created successfully
          if (context.mounted) {
            CustomSnackbar.success(responseData['message'] ?? 'PIN created successfully');
          }

          print("✅ PIN created successfully");

          // Navigate to IndexScreen
          if (context.mounted) {
            Navigator.pushReplacement(
              context, MaterialPageRoute(
                builder: (context) => IndexScreen(loginResponse: loginResponse),
              ),
            );
          }
        } else {
          handleCreatePinError(responseData, context);
        }
      } else {
        print("❌ HTTP Error: ${response.statusCode}");
        if (context.mounted) {
          CustomSnackbar.error("Server error: ${response.statusCode}");
        }
      }
    } on SocketException catch (e) {
      print("❌ Socket Exception: $e");
      if (context.mounted) {
        CustomSnackbar.error("Connection failed. Check your internet connection");
      }
    } on TimeoutException catch (e) {
      print("❌ Timeout Exception: $e");
      if (context.mounted) {
        CustomSnackbar.error("Request timeout. Please try again");
      }
    } catch (error) {
      print("❌ General Error: $error");
      if (context.mounted) {
        CustomSnackbar.error("Failed to create PIN. Please try again");
      }
    } finally {
      isCreatingPin.value = false;
    }
  }

  /// Handle create PIN error
  static void handleCreatePinError(Map body, BuildContext context) {
    final errorMessage = body["message"] ?? "Failed to create PIN";
    if (kDebugMode) print("❌ Create PIN Error: $errorMessage");

    if (context.mounted) {
      CustomSnackbar.error(errorMessage);
    }
  }
  Future<void> changePin({
    required String oldPin,
    required String newPin,
    required String password,
    required BuildContext context,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) {
        throw Exception("No token found. Please login again.");
      }

      await _ensureSchoolCodeInitialized();
      print("🔄 Attempting changePin at: ${APIEndpoints.ChangePinEndpoint}");
      print("📝 Old Pin: $oldPin");
      print("📝 New Pin: $newPin");
      print("🔐 Token: $token");
      print("🔐 Scode: $schoolCode");

      // Create JSON body
      Map<String, dynamic> requestBody = {
        'old_pin': oldPin,
        'new_pin': newPin,
        'password': password,
      };

      print("📤 Request Body: ${jsonEncode(requestBody)}");

      var response = await http.post(
        Uri.parse(APIEndpoints.ChangePinEndpoint),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'scode': schoolCode,
        },
        body: jsonEncode(requestBody),
      );

      print("📥 Response Status: ${response.statusCode}");
      print("📥 Response Body: ${response.body}");

      // Parse JSON response regardless of status code
      Map<String, dynamic>? responseData;
      try {
        if (response.body.isNotEmpty) {
          responseData = jsonDecode(response.body);
        }
      } catch (e) {
        print("❌ JSON Parse Error: $e");
      }

      if (response.statusCode == 200) {
        if (responseData != null) {
          // Check the new response structure
          final state = responseData['state'] as Map<String, dynamic>?;
          final payload = responseData['payload'] as Map<String, dynamic>?;

          if (state != null && state['status'] == 1 && payload != null && payload['status'] == 1) {
            if (context.mounted) {
              CustomSnackbar.success(payload['message'] ?? 'Pin changed successfully');
              // Navigate back to previous screen after successful pin change
              Navigator.pop(context);
            }
          } else {
            // Handle API error response
            String errorMessage = payload?['message'] ?? state?['message'] ?? 'Pin change failed';
            if (context.mounted) {
              CustomSnackbar.error(errorMessage);
            }
          }
        } else {
          if (context.mounted) {
            CustomSnackbar.error("Invalid response format");
          }
        }
      } else {
        // Handle HTTP error responses that might contain JSON error details
        print("❌ HTTP Error: ${response.statusCode}");

        if (responseData != null) {
          // Server returned JSON error details - extract message from new structure
          final state = responseData['state'] as Map<String, dynamic>?;
          final payload = responseData['payload'] as Map<String, dynamic>?;
          String errorMessage = payload?['message'] ?? state?['message'] ?? "Server error: ${response.statusCode}";

          if (context.mounted) {
            CustomSnackbar.error(errorMessage);
          }
        } else {
          // Generic HTTP error without JSON details
          if (context.mounted) {
            CustomSnackbar.error("Server error: ${response.statusCode}");
          }
        }
      }
    } on SocketException catch (e) {
      print("❌ Socket Exception: $e");
      if (context.mounted) {
        CustomSnackbar.error("Connection failed. Please check your internet connection.");
      }
    } on TimeoutException catch (e) {
      print("❌ Timeout Exception: $e");
      if (context.mounted) {
        CustomSnackbar.error("Request timeout. Please try again.");
      }
    } catch (error) {
      print("❌ General Error: $error");
      if (context.mounted) {
        CustomSnackbar.error("Pin change failed. Please try again.");
      }
    }
  }

  void handleChangePinError(Map<String, dynamic> body, BuildContext context) {
    final errorMessage = body["message"] ?? "Pin change failed";
    final errorDetails = body["error"] ?? "";

    String fullErrorMessage = errorMessage;
    if (errorDetails.isNotEmpty && errorDetails != errorMessage) {
      fullErrorMessage = "$errorMessage: $errorDetails";
    }

    if (kDebugMode) print("❌ Change Pin Error: $fullErrorMessage");

    if (context.mounted) {
      CustomSnackbar.error(fullErrorMessage);
    }
  }



  static Future<List<Newsletter>?> getNewsletters({
    required BuildContext context,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) {
        throw Exception("No auth token found");
      }

      // Get school code from SchoolDataService
      final schoolData = await SchoolDataService.getSchoolData();
      final schoolCode = schoolData?.schoolCode ?? '';

      if (schoolCode.isEmpty) {
        throw Exception("No school code found");
      }

      final uri = Uri.parse("${APIEndpoints.baseUrl}notifications_api/getNewsletters");
      print("🔄 Attempting to fetch newsletters from: $uri");
      print("🔐 Using token: $token");

      final response = await http.get(
        uri,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
          'scode': schoolCode,
        },
      ).timeout(const Duration(seconds: 30));

      print("📥 Response Status: ${response.statusCode}");
      print("📥 Response Body: ${response.body}");

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        // Check if response has proper structure with state and payload
        if (responseData['state'] != null && responseData['state']['status'] == 1) {
          final payload = responseData['payload'];

          if (payload != null && payload['status'] == true) {
            // Use the payload data for NewsletterResponseModel
            final newsletterData = {
              'status': payload['status'],
              'data': payload['data'],
            };

            NewsletterResponseModel newsletterResponseModel =
            NewsletterResponseModel.fromJson(newsletterData);

            // IMPORTANT: Store the newsletters in the static variable
            newsletters = newsletterResponseModel.data;
            print("✅ Newsletters fetched successfully: ${newsletters.length} items");
            print("📝 Stored in static variable: ${newsletters.length} items");

            return newsletters;
          } else {
            // Clear newsletters on payload error
            newsletters.clear();
            print("❌ Payload Error: ${payload?['message'] ?? 'Payload status is false'}");
            _handleNewsletterErrorStatic(payload ?? {}, context);
            return null;
          }
        } else {
          // Handle direct structure (fallback)
          if (responseData['status'] == true) {
            NewsletterResponseModel newsletterResponseModel =
            NewsletterResponseModel.fromJson(responseData);

            // IMPORTANT: Store the newsletters in the static variable
            newsletters = newsletterResponseModel.data;
            print("✅ Newsletters fetched successfully: ${newsletters.length} items");
            print("📝 Stored in static variable: ${newsletters.length} items");

            return newsletters;
          } else {
            // Clear newsletters on error
            newsletters.clear();
            _handleNewsletterErrorStatic(responseData, context);
            return null;
          }
        }
      } else {
        // Clear newsletters on HTTP error
        newsletters.clear();
        print("❌ HTTP Error: ${response.statusCode}");
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Server error: ${response.statusCode}")),
          );
        }
        return null;
      }
    } on SocketException catch (e) {
      newsletters.clear();
      print("❌ Socket Exception: $e");
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Connection failed. Check your internet connection."),
            backgroundColor: Colors.red,
          ),
        );
      }
      return null;
    } on TimeoutException catch (e) {
      newsletters.clear();
      print("❌ Timeout Exception: $e");
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Request timeout. Please try again."),
            backgroundColor: Colors.red,
          ),
        );
      }
      return null;
    } on FormatException catch (e) {
      newsletters.clear();
      print("❌ JSON Format Error: $e");
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Invalid response format from server."),
            backgroundColor: Colors.red,
          ),
        );
      }
      return null;
    } catch (error) {
      newsletters.clear();
      print("❌ General Error: $error");
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Failed to fetch newsletters. Please try again."),
            backgroundColor: Colors.red,
          ),
        );
      }
      return null;
    }
  }

// Static version of your error handler
  static void _handleNewsletterErrorStatic(Map<String, dynamic> responseData, BuildContext context) {
    // Handle error logic here
    String errorMessage = responseData['message'] ?? 'Unknown error occurred';

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Show permission request bottom sheet
  static Future<bool> _showPermissionBottomSheet(BuildContext context) async {
    return await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          padding: EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle indicator
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              SizedBox(height: 20),

              // Icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.folder_open,
                  size: 40,
                  color: Colors.blue.shade600,
                ),
              ),
              SizedBox(height: 20),

              // Title
              Text(
                'Storage Permission Required',
                style: TextStyle(
                  fontSize: 7,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Poppins',
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 12),

              // Description
              Text(
                'To download newsletters to your device, we need permission to access your storage. This allows us to save files in your Downloads folder.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                  fontFamily: 'Poppins',
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 24),

              // Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        side: BorderSide(color: Colors.grey.shade300),
                      ),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade600,
                        padding: EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'Allow Access',
                        style: TextStyle(
                          color: Colors.white,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
            ],
          ),
        );
      },
    ) ?? false;
  }

  // Show settings bottom sheet for permanently denied permissions
  static Future<void> _showSettingsBottomSheet(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          padding: EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle indicator
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              SizedBox(height: 20),

              // Icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.settings,
                  size: 40,
                  color: Colors.orange.shade600,
                ),
              ),
              SizedBox(height: 20),

              // Title
              Text(
                'Permission Required',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Poppins',
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 12),

              // Description
              Text(
                'Storage permission has been permanently denied. Please go to Settings and manually enable storage permission to download newsletters.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                  fontFamily: 'Poppins',
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 24),

              // Instructions
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Steps to enable permission:',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Poppins',
                        fontSize: 12,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '1. Tap "Open Settings" below\n2. Find "Permissions" or "App Permissions"\n3. Enable "Storage" or "Files and Media"',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                        fontFamily: 'Poppins',
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24),

              // Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        side: BorderSide(color: Colors.grey.shade300),
                      ),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        openAppSettings();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange.shade600,
                        padding: EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'Open Settings',
                        style: TextStyle(
                          color: Colors.white,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  // Handle newsletter fetch errors
  static void handleNewsletterError(Map body, BuildContext context) {
    final errorMessage = body["message"] ?? "Newsletter fetch failed";
    if (kDebugMode) print("❌ Newsletter Error: $errorMessage");

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Download newsletter file
  // Updated downloadNewsletter method with better permission handling
  // static Future<void> downloadNewsletter({
  //   required BuildContext context,
  //   required Newsletter newsletter,
  // }) async {
  //   try {
  //     // Check storage permission based on Android version
  //     Permission permission;
  //     if (Platform.isAndroid) {
  //       final androidInfo = await DeviceInfoPlugin().androidInfo;
  //       if (androidInfo.version.sdkInt >= 33) {
  //         // Android 13+ (API 33+) - Use media permissions for specific file types
  //         permission = Permission.manageExternalStorage;
  //       } else if (androidInfo.version.sdkInt >= 30) {
  //         // Android 11+ (API 30+)
  //         permission = Permission.manageExternalStorage;
  //       } else {
  //         // Android 10 and below
  //         permission = Permission.storage;
  //       }
  //     } else {
  //       permission = Permission.storage;
  //     }
  //
  //     var status = await permission.status;
  //     print("🔍 Current permission status: $status");
  //
  //     if (!status.isGranted) {
  //       // Show permission bottom sheet
  //       bool shouldProceed = await _showPermissionBottomSheet(context);
  //       if (!shouldProceed) {
  //         print("❌ User cancelled permission request");
  //         return;
  //       }
  //
  //       // Request permission after user approval
  //       print("🔄 Requesting permission...");
  //       status = await permission.request();
  //       print("📋 Permission request result: $status");
  //
  //       if (!status.isGranted) {
  //         if (status.isPermanentlyDenied) {
  //           print("❌ Permission permanently denied");
  //           await _showSettingsBottomSheet(context);
  //         } else if (status.isDenied) {
  //           print("❌ Permission denied");
  //           if (context.mounted) {
  //             ScaffoldMessenger.of(context).showSnackBar(
  //               const SnackBar(
  //                 content: Text("Storage permission is required to download files"),
  //                 backgroundColor: Colors.red,
  //               ),
  //             );
  //           }
  //         }
  //         return;
  //       }
  //     }
  //
  //     print("✅ Permission granted, proceeding with download");
  //
  //     // Show downloading toast
  //     if (context.mounted) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         const SnackBar(
  //           content: Text("Downloading newsletter..."),
  //           backgroundColor: Colors.blue,
  //           duration: Duration(seconds: 2),
  //         ),
  //       );
  //     }
  //
  //     // Get user-visible Documents directory
  //     Directory? directory;
  //     String documentsPath;
  //
  //     if (Platform.isAndroid) {
  //       // Use the public Documents directory that's visible in file managers
  //       documentsPath = '/storage/emulated/0/Documents';
  //       directory = Directory(documentsPath);
  //
  //       // If Documents doesn't exist, create it
  //       if (!await directory.exists()) {
  //         try {
  //           await directory.create(recursive: true);
  //         } catch (e) {
  //           // Fallback to Download folder if Documents creation fails
  //           documentsPath = '/storage/emulated/0/Download';
  //           directory = Directory(documentsPath);
  //           if (!await directory.exists()) {
  //             await directory.create(recursive: true);
  //           }
  //         }
  //       }
  //
  //       // Create a subfolder for better organization (optional)
  //       final appFolder = Directory('$documentsPath/Newsletters');
  //       if (!await appFolder.exists()) {
  //         await appFolder.create(recursive: true);
  //       }
  //       directory = appFolder;
  //
  //     } else {
  //       // For iOS, use Documents directory
  //       directory = await getApplicationDocumentsDirectory();
  //     }
  //
  //     // Generate file name with timestamp to avoid conflicts
  //     String fileName = newsletter.fileName;
  //
  //     // Add timestamp if file already exists
  //     String filePath = '${directory.path}/$fileName';
  //     if (await File(filePath).exists()) {
  //       final timestamp = DateTime.now().millisecondsSinceEpoch;
  //       final fileExtension = fileName.split('.').last;
  //       final nameWithoutExtension = fileName.replaceAll('.$fileExtension', '');
  //       fileName = '${nameWithoutExtension}_$timestamp.$fileExtension';
  //       filePath = '${directory.path}/$fileName';
  //     }
  //
  //     print("📁 Saving file to: $filePath");
  //
  //     // Download the file
  //     final response = await http.get(Uri.parse(newsletter.file));
  //
  //     if (response.statusCode == 200) {
  //       // Write file to storage
  //       File file = File(filePath);
  //       await file.writeAsBytes(response.bodyBytes);
  //
  //       print("✅ File downloaded successfully to: $filePath");
  //
  //       // Notify media scanner to make file visible immediately (Android only)
  //       if (Platform.isAndroid) {
  //         try {
  //           // This helps make the file visible in file managers immediately
  //           await Process.run('am', [
  //             'broadcast',
  //             '-a',
  //             'android.intent.action.MEDIA_SCANNER_SCAN_FILE',
  //             '-d',
  //             'file://$filePath'
  //           ]);
  //         } catch (e) {
  //           print("Media scanner notification failed: $e");
  //         }
  //       }
  //
  //       // Show success toast with file location
  //       if (context.mounted) {
  //         ScaffoldMessenger.of(context).showSnackBar(
  //           SnackBar(
  //             content: Column(
  //               mainAxisSize: MainAxisSize.min,
  //               crossAxisAlignment: CrossAxisAlignment.start,
  //               children: [
  //                 Text("Newsletter downloaded successfully"),
  //                 Text(
  //                   "Saved to: ${Platform.isAndroid ? 'Documents/Newsletters' : 'App Documents'}",
  //                   style: TextStyle(fontSize: 12, color: Colors.white70),
  //                 ),
  //               ],
  //             ),
  //             backgroundColor: Colors.green,
  //             duration: const Duration(seconds: 4),
  //             action: SnackBarAction(
  //               label: 'OK',
  //               textColor: Colors.white,
  //               onPressed: () {},
  //             ),
  //           ),
  //         );
  //       }
  //     } else {
  //       throw Exception("Failed to download file: ${response.statusCode}");
  //     }
  //   } catch (error) {
  //     print("❌ Download Error: $error");
  //     if (context.mounted) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(
  //           content: Text("Failed to download newsletter: ${error.toString()}"),
  //           backgroundColor: Colors.red,
  //         ),
  //       );
  //     }
  //   }
  // }



// Add this updated method to your AuthController class

  static Future<String> downloadNewsletter({
    required BuildContext context,
    required Newsletter newsletter,
    String? downloadPath,
  }) async {
    try {
      // Use provided path or create a safe fallback
      String finalDownloadPath;

      if (downloadPath != null && downloadPath.isNotEmpty) {
        finalDownloadPath = downloadPath;
        print('📁 Using provided download path: $finalDownloadPath');
      } else {
        finalDownloadPath = await getOptimalDownloadPath(); // Remove the asterisk
        print('📁 Using optimal download path: $finalDownloadPath');
      }

      // Get school code from SchoolDataService since it's static context
      final schoolData = await SchoolDataService.getSchoolData();
      final schoolCode = schoolData?.schoolCode ?? '';

      // Ensure directory exists
      final dir = Directory(finalDownloadPath);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
        print('📁 Created download directory: $finalDownloadPath');
      }

      // Create the full file path with proper filename
      String fileName = newsletter.fileName ?? 'newsletter_${newsletter.id}.pdf'; // Fixed asterisk

      // Sanitize filename
      fileName = fileName.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');

      final filePath = '$finalDownloadPath/$fileName';

      print('📄 Downloading to: $filePath');

      // Download the file
      final response = await http.get(
        Uri.parse(newsletter.file),
        headers: {
          'Accept': 'application/json',
          'scode': schoolCode,
        },
      );

      if (response.statusCode == 200) {
        final file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);
        print('✅ File downloaded successfully to: $filePath');

        return filePath; // Return the file path
      } else {
        throw Exception('Failed to download file: HTTP ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Download Error: $e');
      throw Exception('Download failed: ${e.toString()}');
    }
  }

// Make this method static as well
  static Future<String> getOptimalDownloadPath() async {
    // Implementation for getting optimal download path
    try {
      if (Platform.isAndroid) {
        final directory = await getExternalStorageDirectory();
        return '${directory?.path}/Downloads' ?? '/storage/emulated/0/Download';
      } else if (Platform.isIOS) {
        final directory = await getApplicationDocumentsDirectory();
        return directory.path;
      } else {
        final directory = await getDownloadsDirectory();
        return directory?.path ?? '';
      }
    } catch (e) {
      final directory = await getApplicationDocumentsDirectory();
      return directory.path;
    }
  }

// Get optimal download path based on Android version and permissions
  static Future<String> _getOptimalDownloadPath() async {
    if (Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;

      // Try different paths in order of preference
      final paths = [
        '/storage/emulated/0/Download/Newsletters',
        '/storage/emulated/0/Documents/Newsletters',
      ];

      for (String path in paths) {
        try {
          final dir = Directory(path);
          if (!await dir.exists()) {
            await dir.create(recursive: true);
          }

          // Test write access
          final testFile = File('$path/test.txt');
          await testFile.writeAsString('test');
          await testFile.delete();

          print('✅ Using public path: $path');
          return path;
        } catch (e) {
          print('❌ Cannot use path $path: $e');
          continue;
        }
      }

      // Fallback to app-specific storage
      final directory = await getExternalStorageDirectory();
      if (directory != null) {
        final path = '${directory.path}/Newsletters';
        final dir = Directory(path);
        if (!await dir.exists()) {
          await dir.create(recursive: true);
        }
        return path;
      }
    }

    // Final fallback
    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/Newsletters';
    final dir = Directory(path);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return path;
  }

// Open file with default app or show file location
  static Future<void> openFile(String filePath) async {
    try {
      final result = await OpenFile.open(filePath);
      print('📂 Open file result: ${result.message}');

      if (result.type != ResultType.done) {
        // If opening failed, try to open the containing folder
        final directory = File(filePath).parent.path;
        await OpenFile.open(directory);
      }
    } catch (e) {
      print('❌ Error opening file: $e');
      // Try opening the parent directory
      try {
        final directory = File(filePath).parent.path;
        await OpenFile.open(directory);
      } catch (e2) {
        print('❌ Error opening directory: $e2');
        rethrow;
      }
    }
  }

// Alternative method to show file in file manager
  static Future<void> showInFileManager(String filePath) async {
    try {
      if (Platform.isAndroid) {
        // For Android, try to open with file manager
        await OpenFile.open(File(filePath).parent.path);
      } else if (Platform.isIOS) {
        // For iOS, try to open the file
        await OpenFile.open(filePath);
      }
    } catch (e) {
      print('❌ Error showing in file manager: $e');
      rethrow;
    }
  }
}
