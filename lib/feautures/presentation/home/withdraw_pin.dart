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

import '../../../core/models/login_model.dart';
import '../../../core/models/payment_response_model.dart';

class WithdrawPin extends StatefulWidget {
  // final String amount;
  // final String? description;
  // final String studentId;

  final String bank_code;
  final String account_no;
  final String amount;
  final LoginResponseModel loginResponseModel;

  const WithdrawPin({
    super.key,
    required this.amount,
    required this.account_no,
    required this.bank_code,
    required this.loginResponseModel,
  });

  @override
  State<WithdrawPin> createState() => _WithdrawPinState();
}

class _WithdrawPinState extends State<WithdrawPin> {
  bool isLoadingCircle = false;
  AuthController authController = AuthController();
  PaymentResponseModel? paymentResponseModel;
  late bool isLoading = false;

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
          onWillPop: () async => false, // Prevent dismissal
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

  @override
  void initState() {
    super.initState();

    // Show bottom sheet after the first frame is rendered
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showPinEntryBottomSheet(
        context: context,
        account_no: widget.account_no,
        amount: widget.amount,
       bank_code: widget.bank_code,
      );
    });

    print('Amount: ${widget.amount}');
    print('bank code: ${widget.bank_code ?? "No description"}');
    print('acount no: ${widget.account_no}');
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
    required String bank_code,
    required String amount,
    required String account_no,
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
      // Prevent dragging to dismiss
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(15.0)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return WillPopScope(
              onWillPop: () async => false, // Prevent back button dismissal
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
                                    // Move to previous field and clear it
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
                                  // Move to next field when user enters a digit
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

                        onPressed:
                        isLoadingCircle
                            ? null
                            : () async {
                          String pin =
                          pinControllers
                              .map((controller) => controller.text)
                              .join();

                          if (pin.length == 4) {
                            // Update loading state for the modal button
                            setModalState(() {
                              isLoadingCircle = true;
                            });

                            // Store the current context before closing modal
                            final currentContext = context;

                            try {
                              print(
                                "🔄 Attempting withdraw to: ${APIEndpoints.makePaymentEndpoint}",
                              );
                              print(
                                "📝 account_no: ${widget.account_no.toString()}",
                              );
                              print(
                                "📝 Amount: ${widget.amount.toString()}",
                              );
                              print(
                                "📝 bank_code: ${widget.bank_code ?? ""}",
                              );
                              print("📝 Pin: $pin");

                              var request = http.MultipartRequest(
                                'POST',
                                Uri.parse(
                                  APIEndpoints.withdrawFromWallet,
                                ),
                              );

                              request.fields['bank_code'] =
                                  widget.bank_code.toString();
                              request.fields['acctno'] =
                                  widget.account_no ?? "";
                              request.fields['amount'] =
                                  widget.amount.toString();
                              request.fields['pin'] = pin;

                              // Get auth token from SharedPreferences
                              final prefs =
                              await SharedPreferences.getInstance();
                              final token =
                                  prefs.getString('auth_token') ?? '';

                              request.headers.addAll({
                                'Content-Type': 'multipart/form-data',
                                'Accept': 'application/json',
                                'Authorization': 'Bearer $token',
                              });

                              print("📤 Sending payment request...");
                              var streamedResponse =
                              await request.send();
                              var response = await http
                                  .Response.fromStream(
                                streamedResponse,
                              );

                              print(
                                "📥 Response Status: ${response.statusCode}",
                              );
                              print(
                                "📥 Response Body: ${response.body}",
                              );

                              // Close the modal first, then show processing dialog
                              if (currentContext.mounted) {
                                Navigator.pop(
                                  currentContext,
                                ); // Close the modal

                                // Show processing dialog
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
                                          padding: EdgeInsets.all(24.w),
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
                                                child: CircularProgressIndicator(
                                                  color:
                                                  AppColors
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

                              // Small delay to ensure dialog is shown
                              await Future.delayed(
                                Duration(milliseconds: 100),
                              );

                              // Check if response is successful (200) or error (500, etc.)
                              if (response.statusCode == 200) {
                                final responseData = jsonDecode(
                                  response.body,
                                );

                                if (responseData['status'] == 1) {
                                  // Success case - close dialog first

                                  print("✅ Withdrawal successful");
                                  if (currentContext.mounted) {
                                    // Close the processing dialog by finding it
                                    Navigator.of(
                                      currentContext,
                                      rootNavigator: true,
                                    ).pop();
                                  }

                                  paymentResponseModel =
                                      PaymentResponseModel.fromJson(
                                        responseData,
                                      );

                                  if (currentContext.mounted) {
                                    CustomSnackbar.success(
                                      responseData['message'] ??
                                          'Payment successful',
                                    );

                                    // Navigate to success screen
                                    Navigator.pushReplacement(
                                      currentContext,
                                      MaterialPageRoute(
                                        builder:
                                            (
                                            context,
                                            ) => PaymentSuccessScreen(
                                          paymentResponse:
                                          paymentResponseModel!,
                                        ),
                                      ),
                                    );
                                  }
                                } else {
                                  // API error with status 0 - close dialog and show error
                                  if (currentContext.mounted) {
                                    Navigator.of(currentContext, rootNavigator: true,).pop(); // Close processing dialog
                                  }
                                  Navigator.of(context).pushNamedAndRemoveUntil(
                                    '/index',
                                        (route) => false,
                                    arguments: {'initialTab': 0},
                                  );
                                  handlePaymentError(
                                    responseData,
                                    currentContext,
                                  );
                                }
                              } else {
                                // HTTP error (500, 404, etc.) - close dialog first
                                if (currentContext.mounted) {
                                  Navigator.of(
                                    currentContext,
                                    rootNavigator: true,
                                  ).pop(); // Close processing dialog
                                }

                                print(
                                  "❌ HTTP Error: ${response.statusCode}",
                                );

                                String errorMessage =
                                    "Server error occurred";
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) => PaymentScreen(
                                      loginResponseModel:
                                      widget.loginResponseModel,
                                    ),
                                  ),
                                );
                                // Try to extract error message from response
                                try {
                                  final errorBody = jsonDecode(
                                    response.body,
                                  );
                                  if (errorBody != null &&
                                      errorBody['message'] != null) {
                                    errorMessage = errorBody['message'];
                                  }
                                } catch (e) {
                                  print(
                                    "❌ Could not parse error response: $e",
                                  );
                                  // Use status code specific messages
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
                                    builder:
                                        (context) => PaymentScreen(
                                      loginResponseModel:
                                      widget.loginResponseModel,
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
                                ).pop(); // Close processing dialog
                                CustomSnackbar.error(
                                  "Connection failed. Check your internet connection.",
                                );

                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) => PaymentScreen(
                                      loginResponseModel:
                                      widget.loginResponseModel,
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
                                ).pop(); // Close processing dialog
                                CustomSnackbar.error(
                                  "Request timeout. Please try again.",
                                );

                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) => PaymentScreen(
                                      loginResponseModel:
                                      widget.loginResponseModel,
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
                                ).pop(); // Close processing dialog
                                CustomSnackbar.error(
                                  "Payment failed. Please try again.",
                                );

                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) => PaymentScreen(
                                      loginResponseModel:
                                      widget.loginResponseModel,
                                    ),
                                  ),
                                );
                              }
                            } finally {
                              // Reset the main widget loading state
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
                        child:
                        isLoadingCircle
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
