import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:http/http.dart' as http;
import 'package:wallet/core/controllers/api_endpoints.dart';
import 'package:wallet/core/controllers/methods_controller.dart';
import 'package:wallet/core/utils/color_utils/color_util.dart';
import 'package:wallet/core/utils/widget_utils/custom_snackbar.dart';
import 'package:wallet/feautures/presentation/home/payment_screen.dart';
import 'package:wallet/feautures/presentation/home/payment_success_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/controllers/school_service.dart';
import '../../../core/models/login_model.dart';
import '../../../core/models/payment_response_model.dart';

class PaymentPin extends StatefulWidget {
  final String amount;
  final String? description;
  final String studentId;
  final LoginResponseModel loginResponseModel;

  const PaymentPin({
    super.key,
    required this.amount,
    this.description,
    required this.studentId,
    required this.loginResponseModel,
  });

  @override
  State<PaymentPin> createState() => _PaymentPinState();
}

class _PaymentPinState extends State<PaymentPin> {
  bool isLoadingCircle = false;
  AuthController authController = AuthController();
  PaymentResponseModel? paymentResponseModel;
  late bool isLoading = false;
  String? errorMessage;
  String? schoolCode;

  void handlePaymentError(Map body, BuildContext context) {
    final errorMessage = body["message"] ?? "Payment failed";
    if (kDebugMode) print("❌ Payment Error: $errorMessage");

    if (context.mounted) {
      CustomSnackbar.error(errorMessage);
    }
  }

  void showProcessingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black54,
      builder: (BuildContext context) {
        return WillPopScope(
          onWillPop: () async => false,
          child: Dialog(
            elevation: 0,
            backgroundColor: Colors.transparent,
            child: Container(
              padding: EdgeInsets.all(24.w),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: 60.h,
                    width: 60.w,
                    child: CircularProgressIndicator(
                      color: AppColors.primaryBlue,
                      strokeWidth: 4,
                    ),
                  ),
                  SizedBox(height: 24.h),
                  Text(
                    "Please wait while we\nprocess payment",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Cleans response body by removing HTML warnings and extracting valid JSON
  String _cleanResponseBody(String responseBody) {
    print("🧹 Cleaning response body...");

    // Remove HTML tags and PHP warnings
    String cleaned = responseBody.replaceAll(RegExp(r'<br\s*\/?>', caseSensitive: false), '');
    cleaned = cleaned.replaceAll(RegExp(r'<b>.*?<\/b>', caseSensitive: false), '');
    cleaned = cleaned.replaceAll(RegExp(r'<.*?>', caseSensitive: false), '');

    // Remove "Warning:" messages and everything before the first valid JSON
    final jsonStartIndex = cleaned.indexOf('{');
    if (jsonStartIndex != -1) {
      cleaned = cleaned.substring(jsonStartIndex);
    }

    print("🧹 Cleaned response: $cleaned");
    return cleaned.trim();
  }

  /// Extracts valid JSON from potentially multiple JSON objects
  Map<String, dynamic> _extractValidJson(String responseBody) {
    // Clean the response
    String cleaned = _cleanResponseBody(responseBody);

    // Try to find the complete JSON structure (new format with state and payload)
    int braceCount = 0;
    int endIndex = 0;

    for (int i = 0; i < cleaned.length; i++) {
      if (cleaned[i] == '{') {
        braceCount++;
      } else if (cleaned[i] == '}') {
        braceCount--;
        if (braceCount == 0) {
          endIndex = i + 1;
          break;
        }
      }
    }

    if (endIndex > 0) {
      String validJson = cleaned.substring(0, endIndex);
      print("✅ Extracted valid JSON: $validJson");
      return jsonDecode(validJson);
    }

    throw FormatException('No valid JSON found in response');
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      showPinEntryBottomSheet(
        context: context,
        regNumber: widget.studentId,
        amount: widget.amount,
        year: "2024",
      );
    });

    print('Amount: ${widget.amount}');
    print('Description: ${widget.description ?? "No description"}');
    print('Student ID: ${widget.studentId}');
    _initializeData();
  }

  Future<void> _initializeData() async {
    try {
      final schoolData = await SchoolDataService.getSchoolData();
      schoolCode = schoolData?.schoolCode ?? "";

      print("🏫 School code initialized: '$schoolCode'");
    } catch (e) {
      print("❌ Error initializing data: $e");
      setState(() {
        errorMessage = 'Failed to initialize app data';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [],
        ),
      ),
    );
  }

  void showPinEntryBottomSheet({
    required BuildContext context,
    required String regNumber,
    required String amount,
    required String year,
  }) {
    List<TextEditingController> pinControllers = List.generate(
      4,
          (index) => TextEditingController(),
    );

    List<FocusNode> pinFocusNodes = List.generate(4, (index) => FocusNode());

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(15.0)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return WillPopScope(
              onWillPop: () async => false,
              child: Padding(
                padding: EdgeInsets.only(
                  left: 16.0,
                  right: 16.0,
                  top: 16.0,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 16.0,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Enter Your 4-Digit PIN",
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Please enter your wallet PIN to confirm payment",
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),

                    // PIN input fields
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(4, (index) {
                        return Container(
                          width: 50.w,
                          margin: EdgeInsets.symmetric(horizontal: 8.w),
                          child: RawKeyboardListener(
                            focusNode: FocusNode(),
                            onKey: (RawKeyEvent event) {
                              if (event is RawKeyDownEvent) {
                                if (event.logicalKey ==
                                    LogicalKeyboardKey.backspace) {
                                  if (pinControllers[index].text.isEmpty &&
                                      index > 0) {
                                    pinFocusNodes[index - 1].requestFocus();
                                    pinControllers[index - 1].clear();
                                  }
                                }
                              }
                            },
                            child: TextField(
                              controller: pinControllers[index],
                              focusNode: pinFocusNodes[index],
                              textAlign: TextAlign.center,
                              keyboardType: TextInputType.number,
                              obscureText: true,
                              maxLength: 1,
                              decoration: InputDecoration(
                                counterText: "",
                                contentPadding: EdgeInsets.zero,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(
                                    color: AppColors.primaryBlue,
                                    width: 2,
                                  ),
                                ),
                              ),
                              style: TextStyle(
                                fontSize: 24.sp,
                                fontWeight: FontWeight.bold,
                              ),
                              onChanged: (value) {
                                if (value.isNotEmpty) {
                                  if (index < 3) {
                                    pinFocusNodes[index + 1].requestFocus();
                                  }
                                }
                              },
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(1),
                              ],
                            ),
                          ),
                        );
                      }),
                    ),

                    const SizedBox(height: 32),

                    // Confirm button
                    Container(
                      padding: EdgeInsets.symmetric(
                        vertical: 12.h,
                        horizontal: 12.w,
                      ),
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.r),
                          ),
                          backgroundColor: AppColors.primaryBlue,
                        ),
                        onPressed: isLoadingCircle
                            ? null
                            : () async {
                          String pin = pinControllers
                              .map((controller) => controller.text)
                              .join();

                          if (pin.length == 4) {
                            setModalState(() {
                              isLoadingCircle = true;
                            });

                            final currentContext = context;

                            try {
                              print(
                                "🔄 Attempting payment to: ${APIEndpoints.makePaymentEndpoint}",
                              );
                              print(
                                "📝 sender: ${widget.studentId.toString()}",
                              );
                              print(
                                "📝 Amount: ${widget.amount.toString()}",
                              );
                              print(
                                "📝 Description: ${widget.description ?? ""}",
                              );
                              print("📝 Pin: $pin");

                              final Map<String, dynamic> requestBody = {
                                'sender': widget.studentId.toString(),
                                'amount': widget.amount.toString(),
                                'description': widget.description ?? "",
                                'pin': pin,
                              };

                              final prefs =
                              await SharedPreferences.getInstance();
                              final token =
                                  prefs.getString('auth_token') ?? '';

                              final headers = {
                                'Content-Type': 'application/json',
                                'Accept': 'application/json',
                                'Authorization': 'Bearer $token',
                                'scode': schoolCode ?? "",
                              };

                              print("📤 Sending payment request...");
                              print(
                                  "📤 Request Body: ${jsonEncode(requestBody)}");
                              print("📤 Headers: $headers");

                              final response = await http
                                  .post(
                                Uri.parse(APIEndpoints
                                    .makePaymentEndpoint),
                                headers: headers,
                                body: jsonEncode(requestBody),
                              )
                                  .timeout(Duration(seconds: 30));

                              print(
                                "📥 Response Status: ${response.statusCode}",
                              );
                              print(
                                "📥 Response Body: ${response.body}",
                              );

                              if (currentContext.mounted) {
                                Navigator.pop(currentContext);

                                showDialog(
                                  context: currentContext,
                                  barrierDismissible: false,
                                  barrierColor: Colors.black54,
                                  builder: (dialogContext) {
                                    return WillPopScope(
                                      onWillPop: () async => false,
                                      child: Dialog(
                                        elevation: 0,
                                        backgroundColor:
                                        Colors.transparent,
                                        child: Container(
                                          padding:
                                          EdgeInsets.all(24.w),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius:
                                            BorderRadius.circular(
                                              16.r,
                                            ),
                                          ),
                                          child: Column(
                                            mainAxisSize:
                                            MainAxisSize.min,
                                            children: [
                                              SizedBox(
                                                height: 60.h,
                                                width: 60.w,
                                                child:
                                                CircularProgressIndicator(
                                                  color: AppColors
                                                      .primaryBlue,
                                                  strokeWidth: 4,
                                                ),
                                              ),
                                              SizedBox(height: 24.h),
                                              Text(
                                                "Please wait while we\nprocess payment",
                                                textAlign:
                                                TextAlign.center,
                                                style: TextStyle(
                                                  fontSize: 16.sp,
                                                  fontWeight:
                                                  FontWeight.w500,
                                                  color: Colors.black87,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                );
                              }

                              await Future.delayed(
                                Duration(milliseconds: 100),
                              );

                              if (response.statusCode == 200) {
                                try {
                                  // Extract and parse valid JSON
                                  final responseData =
                                  _extractValidJson(response.body);

                                  print(
                                      "✅ Successfully parsed response: $responseData");

                                  // Check both old and new response structures
                                  final state = responseData['state']
                                  as Map<String, dynamic>?;
                                  final payload = responseData['payload']
                                  as Map<String, dynamic>?;
                                  final topLevelStatus =
                                  responseData['status'];
                                  final topLevelMessage =
                                  responseData['message'];

                                  // Handle new structure with state and payload
                                  if (state != null &&
                                      state['status'] == 1) {
                                    // State approved
                                    if (payload != null &&
                                        payload['status'] == 1) {
                                      // Success
                                      if (currentContext.mounted) {
                                        Navigator.of(
                                          currentContext,
                                          rootNavigator: true,
                                        ).pop();
                                      }

                                      paymentResponseModel =
                                          PaymentResponseModel.fromJson(
                                              payload);

                                      if (currentContext.mounted) {
                                        CustomSnackbar.success(
                                          payload['message'] ??
                                              'Payment successful',
                                        );

                                        Navigator.pushReplacement(
                                          currentContext,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                PaymentSuccessScreen(
                                                  paymentResponse:
                                                  paymentResponseModel!,
                                                ),
                                          ),
                                        );
                                      }
                                    } else {
                                      // Payload error
                                      if (currentContext.mounted) {
                                        Navigator.of(
                                          currentContext,
                                          rootNavigator: true,
                                        ).pop();

                                        String errorMsg = payload
                                        ?['message'] ??
                                            state['message'] ??
                                            'Payment failed';
                                        CustomSnackbar.error(errorMsg);

                                        Navigator.of(context)
                                            .pushNamedAndRemoveUntil(
                                          '/index',
                                              (route) => false,
                                          arguments: {
                                            'initialTab': 0
                                          },
                                        );
                                      }
                                    }
                                  }
                                  // Handle old structure (top-level status)
                                  else if (topLevelStatus == 1) {
                                    // Old format success
                                    print(
                                        "✅ Old format response detected");
                                    if (currentContext.mounted) {
                                      Navigator.of(
                                        currentContext,
                                        rootNavigator: true,
                                      ).pop();
                                    }

                                    paymentResponseModel =
                                        PaymentResponseModel.fromJson(
                                            responseData);

                                    if (currentContext.mounted) {
                                      CustomSnackbar.success(
                                        topLevelMessage ??
                                            'Payment successful',
                                      );

                                      Navigator.pushReplacement(
                                        currentContext,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              PaymentSuccessScreen(
                                                paymentResponse:
                                                paymentResponseModel!,
                                              ),
                                        ),
                                      );
                                    }
                                  } else {
                                    // State error or payment not approved
                                    if (currentContext.mounted) {
                                      Navigator.of(
                                        currentContext,
                                        rootNavigator: true,
                                      ).pop();

                                      String errorMsg = state
                                      ?['message'] ??
                                          topLevelMessage ??
                                          'Payment not approved';
                                      CustomSnackbar.error(errorMsg);

                                      Navigator.of(context)
                                          .pushNamedAndRemoveUntil(
                                        '/index',
                                            (route) => false,
                                        arguments: {
                                          'initialTab': 0
                                        },
                                      );
                                    }
                                  }
                                } catch (jsonError) {
                                  print(
                                      "❌ JSON Parsing Error: $jsonError");
                                  print(
                                      "📥 Problematic Response: ${response.body}");

                                  if (currentContext.mounted) {
                                    Navigator.of(
                                      currentContext,
                                      rootNavigator: true,
                                    ).pop();
                                    CustomSnackbar.error(
                                        "Invalid response format from server. Please try again.");

                                    Navigator.of(context)
                                        .pushNamedAndRemoveUntil(
                                      '/index',
                                          (route) => false,
                                      arguments: {
                                        'initialTab': 0
                                      },
                                    );
                                  }
                                }
                              } else {
                                // HTTP error
                                if (currentContext.mounted) {
                                  Navigator.of(
                                    currentContext,
                                    rootNavigator: true,
                                  ).pop();
                                }

                                print(
                                  "❌ HTTP Error: ${response.statusCode}",
                                );

                                String errorMessage =
                                    "Server error occurred";

                                try {
                                  final errorBody =
                                  _extractValidJson(response.body);
                                  final state =
                                  errorBody['state']
                                  as Map<String, dynamic>?;
                                  final payload =
                                  errorBody['payload']
                                  as Map<String, dynamic>?;

                                  if (state != null &&
                                      state['message'] != null) {
                                    errorMessage = state['message'];
                                  } else if (payload != null &&
                                      payload['message'] != null) {
                                    errorMessage = payload['message'];
                                  } else if (errorBody['message'] !=
                                      null) {
                                    errorMessage =
                                    errorBody['message'];
                                  }
                                } catch (e) {
                                  print(
                                    "❌ Could not parse error response: $e",
                                  );
                                  switch (response.statusCode) {
                                    case 500:
                                      errorMessage =
                                      "Internal server error. Please try again later.";
                                      break;
                                    case 404:
                                      errorMessage =
                                      "Service not found. Please contact support.";
                                      break;
                                    default:
                                      errorMessage =
                                      "Server error: ${response.statusCode}";
                                  }
                                }

                                if (currentContext.mounted) {
                                  CustomSnackbar.error(errorMessage);
                                }

                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        PaymentScreen(
                                          loginResponseModel: widget
                                              .loginResponseModel,
                                        ),
                                  ),
                                );
                              }
                            } on SocketException catch (e) {
                              print("❌ Socket Exception: $e");
                              if (currentContext.mounted) {
                                Navigator.of(
                                  currentContext,
                                  rootNavigator: true,
                                ).pop();
                                CustomSnackbar.error(
                                  "Connection failed. Check your internet connection.",
                                );

                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        PaymentScreen(
                                          loginResponseModel: widget
                                              .loginResponseModel,
                                        ),
                                  ),
                                );
                              }
                            } on TimeoutException catch (e) {
                              print("❌ Timeout Exception: $e");
                              if (currentContext.mounted) {
                                Navigator.of(
                                  currentContext,
                                  rootNavigator: true,
                                ).pop();
                                CustomSnackbar.error(
                                  "Request timeout. Please try again.",
                                );

                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        PaymentScreen(
                                          loginResponseModel: widget
                                              .loginResponseModel,
                                        ),
                                  ),
                                );
                              }
                            } catch (error) {
                              print("❌ General Error: $error");
                              if (currentContext.mounted) {
                                Navigator.of(
                                  currentContext,
                                  rootNavigator: true,
                                ).pop();
                                CustomSnackbar.error(
                                  "Payment failed. Please try again.",
                                );

                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        PaymentScreen(
                                          loginResponseModel: widget
                                              .loginResponseModel,
                                        ),
                                  ),
                                );
                              }
                            } finally {
                              if (mounted) {
                                setState(() {
                                  isLoadingCircle = false;
                                  isLoading = false;
                                });
                              }
                            }
                          } else {
                            CustomSnackbar.error(
                              "Please enter a valid 4-digit PIN",
                            );
                          }
                        },
                        child: isLoadingCircle
                            ? SizedBox(
                          height: 20.h,
                          width: 20.w,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                            : Text(
                          "Confirm Payment",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16.sp,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Cancel button
                    GestureDetector(
                      onTap: () {
                        Navigator.of(context).pushNamedAndRemoveUntil(
                          '/index',
                              (route) => false,
                          arguments: {'initialTab': 0},
                        );
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          vertical: 12.h,
                          horizontal: 12.w,
                        ),
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: Colors.grey.withOpacity(0.2),
                        ),
                        child: Text(
                          'Cancel',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 16.sp,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}