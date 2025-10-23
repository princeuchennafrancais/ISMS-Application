import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:wallet/core/controllers/api_endpoints.dart';
import 'package:wallet/core/models/login_model.dart';
import 'package:wallet/core/utils/color_utils/color_util.dart';
import 'package:wallet/core/utils/widget_utils/trial_custom_drawer.dart';
import 'package:wallet/feautures/auth/create_wallet.dart';
import 'package:wallet/feautures/presentation/home/withdraw_successful.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/controllers/school_service.dart';
import '../../../core/enum/navigation_source.dart';

class Bank {
  final String code;
  final String name;

  Bank({required this.code, required this.name});

  factory Bank.fromJson(Map<String, dynamic> json) {
    return Bank(code: json['code'].toString(), name: json['name']);
  }
}

class BankAccountDetails {
  final String accountName;
  final String accountNumber;
  final String bankCode;

  BankAccountDetails({
    required this.accountName,
    required this.accountNumber,
    required this.bankCode,
  });

  factory BankAccountDetails.fromString(String jsonString) {
    final Map<String, dynamic> data = json.decode(jsonString);

    return BankAccountDetails(
      accountName: data['accountName'] ?? '',
      accountNumber: data['accountNumber'] ?? '',
      bankCode: data['bankCode'] ?? '',
    );
  }

  @override
  String toString() {
    return 'BankAccountDetails(accountName: $accountName, accountNumber: $accountNumber, bankCode: $bankCode)';
  }
}

class WithdrawFromWallet extends StatefulWidget {
  final LoginResponseModel loginResponse;
  final NavigationSource navigationSource;

  const WithdrawFromWallet({
    super.key,
    required this.scaffoldKey,
    required this.loginResponse,
    this.navigationSource = NavigationSource.other,
  });

  final GlobalKey<ScaffoldState> scaffoldKey;

  @override
  State<WithdrawFromWallet> createState() => _WithdrawFromWalletState();
}

class _WithdrawFromWalletState extends State<WithdrawFromWallet> with TickerProviderStateMixin {
  final TextEditingController accountNumberController = TextEditingController();
  final TextEditingController amountController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  late final hasWallet = widget.loginResponse.hasWallet ?? false;

  List<Bank> banks = [];
  Bank? selectedBank;
  BankAccountDetails? accountDetails;
  bool isLoadingBanks = true;
  bool isProcessingTransfer = false;
  bool isFetchingAccountDetails = false;
  String? errorMessage;
  String? accountDetailsError;
  String? schoolCode;

  Timer? _debounceTimer;

  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;


  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    accountNumberController.addListener(_onAccountNumberChanged);
    _initializeDataAndFetchBanks();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    accountNumberController.dispose();
    amountController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }
  Future<void> _initializeDataAndFetchBanks() async {
    try {
      // First initialize the school code
      final schoolData = await SchoolDataService.getSchoolData();
      schoolCode = schoolData?.schoolCode ?? "";

      print("🏫 School code initialized: '$schoolCode'");

      // Then fetch banks after school code is ready
      await fetchBanks();
    } catch (e) {
      print("❌ Error initializing data: $e");
      setState(() {
        errorMessage = 'Failed to initialize app data';
        isLoadingBanks = false;
      });
    }
  }


  Future<void> _initializeData() async {
    final schoolData = await SchoolDataService.getSchoolData();
    schoolCode = schoolData?.schoolCode ?? "";
  }
  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _fadeController.forward();
    _slideController.forward();
  }

  void _onAccountNumberChanged() {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();

    _debounceTimer = Timer(const Duration(milliseconds: 800), () {
      if (accountNumberController.text.length == 10 && selectedBank != null) {
        fetchAccountDetails();
      } else {
        setState(() {
          accountDetails = null;
          accountDetailsError = null;
        });
      }
    });
  }

  Future<void> fetchBanks() async {
    try {
      print("🔄 Attempting to fetch banks from: wallet_api/getBanks");

      setState(() {
        isLoadingBanks = true;
        errorMessage = null;
      });

      // Add school code check and initialization if needed
      if (schoolCode == null || schoolCode!.isEmpty) {
        print("🔄 School code not initialized, fetching now...");
        final schoolData = await SchoolDataService.getSchoolData();
        schoolCode = schoolData?.schoolCode ?? "";
        print("🏫 School code initialized in fetchBanks: '$schoolCode'");
      }

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) {
        print("❌ No auth token found");
        setState(() {
          errorMessage = 'Please login again';
          isLoadingBanks = false;
        });
        return;
      }

      final headers = {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
        'scode': schoolCode ?? "",
      };

      print("📤 Sending banks request...");
      print("🔐 Using scode: '${schoolCode ?? ""}'");

      final response = await http.get(
        Uri.parse(APIEndpoints.getBanksEndpoint),
        headers: headers,
      ).timeout(Duration(seconds: 30));

      print("📥 Response Status: ${response.statusCode}");
      print("📥 Response Body: ${response.body}");

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);

        // Handle new nested response structure
        final state = responseData['state'] as Map<String, dynamic>?;
        final payload = responseData['payload'] as Map<String, dynamic>?;

        if (state != null && state['status'] == 1 && payload != null && payload['status'] == 1) {
          // Banks are now nested under payload.bank
          final List<dynamic> banksList = payload['bank'] ?? [];

          setState(() {
            banks = banksList.map((bank) => Bank.fromJson(bank)).toList();
            isLoadingBanks = false;
          });

          print("✅ Banks fetched successfully: ${banks.length} banks");
        } else {
          // Extract error message from new structure
          String errorMsg = payload?['message'] ?? state?['message'] ?? 'Failed to fetch banks';
          setState(() {
            errorMessage = errorMsg;
            isLoadingBanks = false;
          });
          print("❌ API Error: $errorMsg");
        }
      } else {
        print("❌ HTTP Error: ${response.statusCode}");
        setState(() {
          errorMessage = 'Server error: ${response.statusCode}';
          isLoadingBanks = false;
        });
      }
    } on SocketException catch (e) {
      print("❌ Socket Exception: $e");
      setState(() {
        errorMessage = 'Connection failed. Check your internet connection';
        isLoadingBanks = false;
      });
    } on TimeoutException catch (e) {
      print("❌ Timeout Exception: $e");
      setState(() {
        errorMessage = 'Request timeout. Please try again';
        isLoadingBanks = false;
      });
    } catch (error) {
      print("❌ General Error: $error");
      setState(() {
        errorMessage = 'Failed to load banks. Please try again';
        isLoadingBanks = false;
      });
    }
  }
  Future<void> fetchAccountDetails() async {
    if (accountNumberController.text.length != 10 || selectedBank == null) {
      return;
    }

    setState(() {
      isFetchingAccountDetails = true;
      accountDetailsError = null;
      accountDetails = null;
    });

    try {
      print("🔄 Fetching account details...");

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) {
        setState(() {
          accountDetailsError = 'Please login again';
          isFetchingAccountDetails = false;
        });
        return;
      }

      // Prepare the JSON body
      final Map<String, dynamic> requestBody = {
        'bank_code': selectedBank!.code,
        'acctno': accountNumberController.text.trim(),
      };

      print("🔍 Debug - Endpoint: ${APIEndpoints.getBanksDetailsEndpoint}");
      print("📤 Request Body: ${json.encode(requestBody)}");
      print("📤 Bank Code: ${selectedBank!.code}");
      print("📤 Account Number: ${accountNumberController.text.trim()}");

      final response = await http.post(
        Uri.parse(APIEndpoints.getBanksDetailsEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
          'scode': schoolCode ?? "",
        },
        body: json.encode(requestBody), // Send JSON body
      ).timeout(const Duration(seconds: 30));

      print("📥 Account Details Response Status: ${response.statusCode}");
      print("📥 Account Details Response Body: ${response.body}");

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        // Handle new nested response structure
        final state = responseData['state'] as Map<String, dynamic>?;
        final payload = responseData['payload'] as Map<String, dynamic>?;

        if (state != null && state['status'] == 1 && payload != null && payload['success'] == true) {
          // Check if account details were successfully retrieved
          if (payload['data'] != null) {
            print("🔍 Account data to parse: ${payload['data']}");

            setState(() {
              accountDetails = BankAccountDetails.fromString(
                json.encode(payload['data']),
              );
              isFetchingAccountDetails = false;
            });

            print("🔍 Parsed accountDetails: $accountDetails");
            print("🔍 Account Name: ${accountDetails?.accountName}");
            print("✅ Account details fetched successfully");
          } else {
            // Handle case where payload success is true but no valid data
            String errorMsg = payload['message'] ?? state['message'] ?? 'Account not found';
            setState(() {
              accountDetailsError = errorMsg;
              isFetchingAccountDetails = false;
            });
          }
        } else {
          // Handle API error response
          String errorMsg = payload?['message'] ?? state?['message'] ?? 'Account verification failed';
          setState(() {
            accountDetailsError = errorMsg;
            isFetchingAccountDetails = false;
          });
        }
      } else {
        // Handle HTTP error responses
        print("❌ HTTP Error: ${response.statusCode}");

        // Try to parse error message from response body if available
        try {
          final errorData = json.decode(response.body);
          final state = errorData['state'] as Map<String, dynamic>?;
          final payload = errorData['payload'] as Map<String, dynamic>?;
          String errorMsg = payload?['message'] ?? state?['message'] ?? 'Server error ${response.statusCode}';

          setState(() {
            accountDetailsError = 'Failed to verify account details: $errorMsg';
            isFetchingAccountDetails = false;
          });
        } catch (e) {
          setState(() {
            accountDetailsError = 'Failed to verify account details: Server error ${response.statusCode}';
            isFetchingAccountDetails = false;
          });
        }
      }
    } on SocketException catch (e) {
      print("❌ Socket Exception: $e");
      setState(() {
        accountDetailsError = 'Connection failed. Check your internet connection';
        isFetchingAccountDetails = false;
      });
    } on TimeoutException catch (e) {
      print("❌ Timeout Exception: $e");
      setState(() {
        accountDetailsError = 'Request timeout. Please try again';
        isFetchingAccountDetails = false;
      });
    } catch (error) {
      print("❌ Account Details Error: $error");
      setState(() {
        accountDetailsError = 'Failed to verify account details';
        isFetchingAccountDetails = false;
      });
    }
  }
  Future<void> _processWithdrawal() async {
    if (!_formKey.currentState!.validate()) return;
    if (selectedBank == null) {
      _showSnackBar('Please select a bank', Colors.red);
      return;
    }
    if (accountDetails == null) {
      _showSnackBar('Please verify account details first', Colors.red);
      return;
    }

    _showPinDialog();
  }

  void _showPinDialog() {
    List<TextEditingController> pinControllers = List.generate(4, (index) => TextEditingController());
    List<FocusNode> pinFocusNodes = List.generate(4, (index) => FocusNode());

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return WillPopScope(
              onWillPop: () async => false,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(25.r),
                    topRight: Radius.circular(25.r),
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.only(
                    left: 25.w,
                    right: 25.w,
                    top: 25.h,
                    bottom: MediaQuery.of(context).viewInsets.bottom + 25.h,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Handle bar
                      Container(
                        width: 50.w,
                        height: 5.h,
                        margin: EdgeInsets.only(bottom: 20.h),
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(3.r),
                        ),
                      ),

                      // Header with icon
                      Container(
                        padding: EdgeInsets.all(16.w),
                        decoration: BoxDecoration(
                          color: AppColors.primaryBlue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20.r),
                        ),
                        child: Icon(
                          Icons.security_rounded,
                          color: AppColors.primaryBlue,
                          size: 32.sp,
                        ),
                      ),

                      SizedBox(height: 20.h),

                      Text(
                        "Enter Your 4-Digit PIN",
                        style: TextStyle(
                          fontSize: 22.sp,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        "Please enter your wallet PIN to confirm withdrawal",
                        style: TextStyle(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[600],
                          fontFamily: 'Poppins',
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 30.h),

                      // PIN input fields
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(4, (index) {
                          return Container(
                            width: 55.w,
                            height: 65.h,
                            margin: EdgeInsets.symmetric(horizontal: 8.w),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(16.r),
                              border: Border.all(
                                color: Colors.grey.shade300,
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: RawKeyboardListener(
                              focusNode: FocusNode(),
                              onKey: (RawKeyEvent event) {
                                if (event is RawKeyDownEvent && event.logicalKey == LogicalKeyboardKey.backspace) {
                                  if (pinControllers[index].text.isEmpty && index > 0) {
                                    pinFocusNodes[index - 1].requestFocus();
                                    pinControllers[index - 1].clear();
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
                                  border: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                ),
                                style: TextStyle(
                                  fontSize: 24.sp,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                  fontFamily: 'Poppins',
                                ),
                                onChanged: (value) {
                                  if (value.isNotEmpty && index < 3) {
                                    pinFocusNodes[index + 1].requestFocus();
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

                      SizedBox(height: 40.h),

                      // Confirm button
                      Container(
                        width: double.infinity,
                        height: 56.h,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16.r),
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primaryBlue,
                              AppColors.primaryBlue.withOpacity(0.8),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primaryBlue.withOpacity(0.3),
                              blurRadius: 15,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: isProcessingTransfer ? null : () async {
                              String pin = pinControllers.map((controller) => controller.text).join();

                              if (pin.length == 4) {
                                // CRITICAL: Capture ALL values IMMEDIATELY and validate them
                                final capturedBankCode = selectedBank?.code;
                                final capturedBankName = selectedBank?.name;
                                final capturedAccountNumber = accountNumberController.text.trim();
                                final capturedAmount = amountController.text.trim();

                                // FIX: Use a more reliable way to get account name
                                String capturedAccountName = accountDetails?.accountName ?? '';

                                print("🔍 DEBUG - Captured values:");
                                print("Bank Code: $capturedBankCode");
                                print("Bank Name: $capturedBankName");
                                print("Account Number: $capturedAccountNumber");
                                print("Amount: $capturedAmount");
                                print("Account Name: '$capturedAccountName'");

                                // Validate all required data before proceeding
                                if (capturedBankCode == null || capturedBankName == null) {
                                  _showSnackBar('Missing bank details. Please try again', Colors.red);
                                  return;
                                }

                                if (capturedAccountNumber.isEmpty || capturedAmount.isEmpty) {
                                  _showSnackBar('Please enter valid account and amount', Colors.red);
                                  return;
                                }

                                // FIX: Provide better error handling for missing account name
                                if (capturedAccountName.isEmpty) {
                                  print("⚠️ Account name is empty, using fallback");
                                  capturedAccountName = 'Account Holder';
                                }

                                setState(() {
                                  isProcessingTransfer = true;
                                });

                                // Close the pin dialog first
                                if (Navigator.canPop(context)) {
                                  Navigator.pop(context);
                                }

                                try {
                                  final prefs = await SharedPreferences.getInstance();
                                  final token = prefs.getString('auth_token');

                                  if (token == null) {
                                    throw Exception("No auth token found");
                                  }

                                  // Prepare the JSON body with all required parameters
                                  final Map<String, dynamic> requestBody = {
                                    'bank_code': capturedBankCode,
                                    'acctno': capturedAccountNumber,
                                    'amount': capturedAmount,
                                    'pin': pin,
                                  };

                                  print("📤 Request body: ${jsonEncode(requestBody)}");

                                  final response = await http.post(
                                    Uri.parse('${APIEndpoints.baseUrl}wallet_api/withdraw'),
                                    headers: {
                                      'Content-Type': 'application/json',
                                      'Accept': 'application/json',
                                      'Authorization': 'Bearer $token',
                                      'scode': schoolCode ?? "",
                                    },
                                    body: jsonEncode(requestBody),
                                  ).timeout(const Duration(seconds: 30));

                                  print("📥 Response Status: ${response.statusCode}");
                                  print("📥 Response Body: ${response.body}");

                                  if (response.statusCode == 200) {
                                    String cleanResponseBody = response.body.trim();

                                    if (cleanResponseBody.isNotEmpty) {
                                      final responseData = jsonDecode(cleanResponseBody);
                                      print("📥 Parsed Response Data: $responseData");

                                      // Check if response has proper structure with state and payload
                                      if (responseData['state'] != null && responseData['state']['status'] == 1) {
                                        final payload = responseData['payload'];

                                        if (payload != null && payload['status'] == 1) {
                                          // Check if widget is still mounted before navigation
                                          if (!mounted) {
                                            print("⚠️ Widget not mounted, skipping navigation");
                                            return;
                                          }

                                          print("✅ Withdrawal successful, navigating to success screen");
                                          print("🔍 Using captured account name: '$capturedAccountName'");

                                          // FIX: Use a safe navigation approach
                                          await _navigateToSuccessScreen(
                                            bankName: capturedBankName!,
                                            amount: capturedAmount,
                                            accountName: capturedAccountName,
                                          );
                                        } else {
                                          // Payload error (e.g., incorrect PIN)
                                          if (!mounted) return;
                                          _showSnackBar(
                                            payload?['message'] ?? 'Withdrawal failed',
                                            Colors.red,
                                          );
                                        }
                                      } else {
                                        // State error
                                        if (!mounted) return;
                                        _showSnackBar(
                                          responseData['state']?['message'] ?? 'Request not approved',
                                          Colors.red,
                                        );
                                      }
                                    } else {
                                      if (!mounted) return;
                                      _showSnackBar('Empty response received', Colors.red);
                                    }
                                  } else {
                                    print("❌ HTTP Error: ${response.statusCode}");
                                    if (!mounted) return;
                                    _showSnackBar('Server error: ${response.statusCode}', Colors.red);
                                  }
                                } on SocketException catch (e) {
                                  print("❌ Socket Exception: $e");
                                  if (!mounted) return;
                                  _showSnackBar('Connection failed. Check your internet connection', Colors.red);
                                } on TimeoutException catch (e) {
                                  print("❌ Timeout Exception: $e");
                                  if (!mounted) return;
                                  _showSnackBar('Request timeout. Please try again', Colors.red);
                                } on FormatException catch (e) {
                                  print("❌ JSON Format Error: $e");
                                  if (!mounted) return;
                                  _showSnackBar('Invalid response format from server', Colors.red);
                                } catch (error) {
                                  print("❌ General Error: $error");
                                  if (!mounted) return;
                                  _showSnackBar('Withdrawal failed. Please try again', Colors.red);
                                } finally {
                                  if (mounted) {
                                    setState(() {
                                      isProcessingTransfer = false;
                                    });
                                  }
                                }
                              } else {
                                _showSnackBar('Please enter a valid 4-digit PIN', Colors.red);
                              }
                            },
                            child: Center(
                              child: isProcessingTransfer
                                  ? SizedBox(
                                width: 24.w,
                                height: 24.h,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                                  : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.check_rounded,
                                    color: Colors.white,
                                    size: 22.sp,
                                  ),
                                  SizedBox(width: 12.w),
                                  Text(
                                    "Confirm Withdrawal",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16.sp,
                                      fontWeight: FontWeight.w600,
                                      fontFamily: 'Poppins',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: 16.h),

                      // Cancel button
                      Container(
                        width: double.infinity,
                        height: 56.h,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16.r),
                          color: Colors.grey[100],
                          border: Border.all(
                            color: Colors.grey.shade300,
                            width: 1,
                          ),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => Navigator.pop(context),
                            borderRadius: BorderRadius.circular(16.r),
                            child: Center(
                              child: Text(
                                'Cancel',
                                style: TextStyle(
                                  color: Colors.grey.shade700,
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

// Add this helper method for safe navigation
  Future<void> _navigateToSuccessScreen({
    required String bankName,
    required String amount,
    required String accountName,
  }) async {
    // Add a small delay to ensure the previous dialog is completely closed
    await Future.delayed(Duration(milliseconds: 100));

    if (!mounted) {
      print("❌ Widget not mounted, cannot navigate");
      return;
    }

    try {
      print("🚀 Navigating to success screen with:");
      print("   Bank: $bankName");
      print("   Amount: $amount");
      print("   Account: $accountName");

      await Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => WithdrawSuccessful(
            BankName: bankName,
            amount: amount,
            AccountName: accountName,
          ),
        ),
      );

      print("✅ Navigation completed successfully");
    } catch (e) {
      print("❌ Navigation error: $e");
      // Fallback navigation
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/index',
              (route) => false,
          arguments: {'initialTab': 0},
        );
      }
    }
  }
  void _showConfirmationBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(25.r)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(25.r),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 50.w,
                height: 5.h,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(3.r),
                ),
              ),
              SizedBox(height: 25.h),

              Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Icon(
                  Icons.receipt_long_rounded,
                  color: AppColors.primaryBlue,
                  size: 32.sp,
                ),
              ),

              SizedBox(height: 20.h),

              Text(
                'Confirm Transfer',
                style: TextStyle(
                  fontSize: 22.sp,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                  fontFamily: 'Poppins',
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                'Please review your transfer details',
                style: TextStyle(
                  fontSize: 15.sp,
                  color: Colors.grey[600],
                  fontFamily: 'Poppins',
                ),
              ),

              SizedBox(height: 30.h),

              Container(
                padding: EdgeInsets.all(20.r),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(
                    color: Colors.grey.shade200,
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    _buildConfirmationRow(
                      'Account Name',
                      accountDetails?.accountName ?? 'N/A',
                      Icons.person_outline,
                    ),
                    _buildConfirmationRow(
                      'Account Number',
                      accountNumberController.text,
                      Icons.credit_card_outlined,
                    ),
                    _buildConfirmationRow(
                      'Bank',
                      selectedBank!.name,
                      Icons.account_balance_outlined,
                    ),
                    _buildConfirmationRow(
                      'Amount',
                      '₦${amountController.text}',
                      Icons.payments_outlined,
                    ),
                  ],
                ),
              ),

              SizedBox(height: 30.h),

              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 56.h,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16.r),
                        color: Colors.grey[100],
                        border: Border.all(
                          color: Colors.grey.shade300,
                          width: 1,
                        ),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => Navigator.pop(context),
                          borderRadius: BorderRadius.circular(16.r),
                          child: Center(
                            child: Text(
                              'Cancel',
                              style: TextStyle(
                                color: Colors.grey.shade700,
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 15.w),
                  Expanded(
                    child: Container(
                      height: 56.h,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16.r),
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primaryBlue,
                            AppColors.primaryBlue.withOpacity(0.8),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryBlue.withOpacity(0.3),
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: isProcessingTransfer
                              ? null
                              : () {
                            Navigator.pop(context);
                            _processWithdrawal();
                          },
                          borderRadius: BorderRadius.circular(16.r),
                          child: Center(
                            child: isProcessingTransfer
                                ? SizedBox(
                              width: 24.w,
                              height: 24.h,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                                : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.check_rounded,
                                  color: Colors.white,
                                  size: 20.sp,
                                ),
                                SizedBox(width: 8.w),
                                Text(
                                  'Confirm',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.w600,
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(
                height: MediaQuery.of(context).viewInsets.bottom + 20.h,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConfirmationRow(String label, String value, IconData icon) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 12.h),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(
              icon,
              color: AppColors.primaryBlue,
              size: 18.sp,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: Colors.grey[600],
                    fontFamily: 'Poppins',
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              color == Colors.red ? Icons.error_rounded : Icons.check_circle_rounded,
              color: Colors.white,
              size: 20.sp,
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                message,
                style: TextStyle(fontFamily: 'Poppins'),
              ),
            ),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
        margin: EdgeInsets.all(16.r),
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.7),
      child: Center(
        child: Container(
          padding: EdgeInsets.all(40.r),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 20,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppColors.primaryBlue,
                  ),
                ),
              ),
              SizedBox(height: 20.h),
              Text(
                'Processing Payment...',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                  fontFamily: 'Poppins',
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                'Please wait while we process\nyour transaction',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: Colors.grey.shade600,
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoWalletScreen() {
    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(30.r),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated wallet icon
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: Duration(milliseconds: 800),
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: Container(
                    padding: EdgeInsets.all(40.w),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.primaryBlue.withOpacity(0.1),
                          AppColors.primaryBlue.withOpacity(0.05),
                        ],
                      ),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.primaryBlue.withOpacity(0.2),
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      Icons.account_balance_wallet_outlined,
                      size: 50.sp,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                );
              },
            ),

            SizedBox(height: 40.h),

            // Title
            Text(
              'No Active Wallet',
              style: TextStyle(
                fontSize: 28.sp,
                fontWeight: FontWeight.w800,
                color: Colors.black87,
                fontFamily: 'Poppins',
                letterSpacing: -0.5,
              ),
            ),

            SizedBox(height: 12.h),

            // Description
            Text(
              'Activate Wallet',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16.sp,
                color: Colors.grey.shade600,
                fontFamily: 'Poppins',
                height: 1.5,
              ),
            ),

            SizedBox(height: 40.h),

            // Benefits section
            Container(
              padding: EdgeInsets.all(24.r),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(
                  color: Colors.grey.shade200,
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 20,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    'What you can do with a wallet:',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  SizedBox(height: 20.h),
                  _buildBenefitItem(
                    icon: Icons.payments_outlined,
                    title: 'Make Payments',
                    description: 'Get money from school & parents',
                  ),
                  _buildBenefitItem(
                    icon: Icons.send_rounded,
                    title: 'Make Withdrawals',
                    description: 'Transfer funds to your bank account',
                  ),
                  _buildBenefitItem(
                    icon: Icons.history_rounded,
                    title: 'Track Transactions',
                    description: 'View all your payment history',
                  ),
                ],
              ),
            ),

            SizedBox(height: 40.h),

            // Create Wallet Button
            Container(
              width: double.infinity,
              height: 60.h,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16.r),
                gradient: LinearGradient(
                  colors: [
                    AppColors.primaryBlue,
                    AppColors.primaryBlue.withOpacity(0.8),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryBlue.withOpacity(0.4),
                    blurRadius: 20,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context)=> CreateWallet(loginResponse: widget.loginResponse)));
                  },
                  borderRadius: BorderRadius.circular(16.r),
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_card_rounded,
                          color: Colors.white,
                          size: 24.sp,
                        ),
                        SizedBox(width: 12.w),
                        Text(
                          'Activate Wallet Now',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Poppins',
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            SizedBox(height: 16.h),

            // Back button
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.arrow_back_rounded,
                    color: Colors.grey.shade600,
                    size: 20.sp,
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    'Go Back',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBenefitItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(10.w),
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(
              icon,
              color: AppColors.primaryBlue,
              size: 22.sp,
            ),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                    fontFamily: 'Poppins',
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: Colors.grey.shade600,
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userData = widget.loginResponse.data;
    return Scaffold(
      key: widget.scaffoldKey,
      backgroundColor: Colors.grey[50],
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(70.h),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primaryBlue,
                AppColors.primaryBlue.withOpacity(0.8),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryBlue.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: true,
            leading: _buildAppBarLeading(),
            title: Text(
              'Withdraw to Bank Account',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                fontFamily: 'Poppins',
              ),
            ),
          ),
        ),
      ),
      drawer: TrialCustomDrawer(
        loginResponseModel: widget.loginResponse,
        profPic: userData?.fpicture ?? "asset/images/Student.png",
        userName:
        "${userData?.firstname} ${userData?.lastname}" ??
            "Ikegou faith Sochima",
        adno: userData?.adno ?? "RCN/2021/064",
      ),
      body: !hasWallet
          ? _buildNoWalletScreen() // Show no wallet screen
          : Stack( // Show normal withdrawal form
        children: [
          FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: isLoadingBanks
                  ? _buildLoadingState()
                  : errorMessage != null
                  ? _buildErrorState()
                  : _buildMainContent(),
            ),
          ),
          if (isProcessingTransfer) _buildLoadingOverlay(),
        ],
      ),
    );
  }


  Widget _buildAppBarLeading() {
    switch (widget.navigationSource) {
      case NavigationSource.bottomBar:
        return Container(
          margin: EdgeInsets.all(8.w),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: IconButton(
            icon: Icon(Icons.menu_rounded, color: Colors.white, size: 24.sp),
            onPressed: () {
              // Use widget.scaffoldKey instead of _scaffoldKey
              if (mounted && widget.scaffoldKey.currentState != null) {
                widget.scaffoldKey.currentState!.openDrawer();
              }
            },
          ),
        );
      case NavigationSource.button:
      case NavigationSource.drawer:
      case NavigationSource.other:
      default:
        return Container(
          margin: EdgeInsets.all(8.w),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: IconButton(
            icon: Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20.sp),
            onPressed: () => Navigator.pop(context),
          ),
        );
    }
  }
  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryBlue),
              strokeWidth: 3,
            ),
          ),
          SizedBox(height: 20.h),
          Text(
            'Loading Banks...',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
              fontFamily: 'Poppins',
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Please wait while we fetch available banks',
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.grey.shade600,
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(30.r),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: Icon(
                Icons.error_outline_rounded,
                color: Colors.red.shade400,
                size: 48.sp,
              ),
            ),
            SizedBox(height: 20.h),
            Text(
              'Unable to Load Banks',
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
                fontFamily: 'Poppins',
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.grey.shade600,
                fontFamily: 'Poppins',
              ),
            ),
            SizedBox(height: 30.h),
            Container(
              width: double.infinity,
              height: 56.h,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16.r),
                gradient: LinearGradient(
                  colors: [
                    AppColors.primaryBlue,
                    AppColors.primaryBlue.withOpacity(0.8),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryBlue.withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: fetchBanks,
                  borderRadius: BorderRadius.circular(16.r),
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.refresh_rounded,
                          color: Colors.white,
                          size: 22.sp,
                        ),
                        SizedBox(width: 12.w),
                        Text(
                          'Try Again',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    final naira = '\u20A6';
    return SingleChildScrollView(
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(20.r),
            child: _buildHeaderSection(),
          ),
          _buildFormSection(naira),
        ],
      ),
    );
  }



  Widget _buildHeaderSection() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24.r),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            Colors.grey.shade50,
          ],
        ),
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 15,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(20.r),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primaryBlue.withOpacity(0.15),
                  AppColors.primaryBlue.withOpacity(0.08),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.send_rounded,
              color: AppColors.primaryBlue,
              size: 36.sp,
            ),
          ),
          SizedBox(height: 16.h),
          Text(
            'Withdraw to Bank Account',
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.w800,
              color: Colors.black87,
              fontFamily: 'Poppins',
              letterSpacing: -0.5,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Transfer funds securely to any Nigerian bank',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.grey.shade600,
              fontFamily: 'Poppins',
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildSecurityBadges() {
    return Container(
      padding: EdgeInsets.all(16.w),
      margin: EdgeInsets.only(bottom: 20.h),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Row(
        children: [
          Icon(
            Icons.security_outlined,
            color: Colors.green.shade600,
            size: 20.sp,
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              'Bank-grade security • SSL encrypted • Real-time verification',
              style: TextStyle(
                fontSize: 12.sp,
                color: Colors.green.shade700,
                fontWeight: FontWeight.w500,
                fontFamily: 'Poppins',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormSection(String naira) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(35.r),
          topRight: Radius.circular(35.r),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(30.r),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader(),
              SizedBox(height: 20.h),

              _buildSecurityBadges(),
              SizedBox(height: 10.h),

              _buildInputField(
                label: 'Account Number',
                hint: 'Enter 10-digit account number',
                controller: accountNumberController,
                icon: Icons.credit_card_outlined,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10),
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter account number';
                  }
                  if (value.length != 10) {
                    return 'Account number must be 10 digits';
                  }
                  return null;
                },
                onChanged: (value) {
                  if (accountDetails != null) {
                    setState(() {
                      accountDetails = null;
                      accountDetailsError = null;
                    });
                  }
                },
              ),

              SizedBox(height: 20.h),

              _buildBankSelectionField(),

              if (selectedBank != null && accountNumberController.text.length == 10) ...[
                SizedBox(height: 20.h),
                _buildAccountDetailsSection(),
              ],

              SizedBox(height: 20.h),

              _buildInputField(
                label: 'Amount',
                hint: 'Enter amount to withdraw',
                controller: amountController,
                icon: Icons.payments_outlined,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                prefixText: naira,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter amount';
                  }
                  final amount = double.tryParse(value);
                  if (amount == null || amount <= 0) {
                    return 'Please enter a valid amount';
                  }
                  if (amount < 10) {
                    return 'Amount cannot be lower than ₦100';
                  }
                  if (amount > 10000000) {
                    return 'Amount cannot be higher than ₦10,000,000';
                  }
                  return null;
                },
              ),

              SizedBox(height: 8.h),
              Text(
                'Amount must be between ₦100 and ₦10,000,000',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: Colors.grey.shade600,
                  fontFamily: 'Poppins',
                ),
              ),

              SizedBox(height: 40.h),

              _buildContinueButton(),

              SizedBox(height: 120.h),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildSectionHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
          decoration: BoxDecoration(
            color: AppColors.primaryBlue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Text(
            'TRANSFER DETAILS',
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryBlue,
              letterSpacing: 1.2,
              fontFamily: 'Poppins',
            ),
          ),
        ),
        SizedBox(height: 12.h),
        Text(
          'Bank Transfer Information',
          style: TextStyle(
            fontSize: 24.sp,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
            fontFamily: 'Poppins',
          ),
        ),
        SizedBox(height: 6.h),
        Text(
          'Please fill in your bank account details to complete the withdrawal',
          style: TextStyle(
            fontSize: 14.sp,
            color: Colors.grey[600],
            fontFamily: 'Poppins',
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildInputField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required IconData icon,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
    String? prefixText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
            fontFamily: 'Poppins',
          ),
        ),
        SizedBox(height: 8.h),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16.r),
            color: Colors.grey[50],
            border: Border.all(
              color: Colors.grey.shade300,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            inputFormatters: inputFormatters,
            validator: validator,
            onChanged: onChanged,
            style: TextStyle(
              fontSize: 16.sp,
              fontFamily: 'Poppins',
              color: Colors.black87,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                fontSize: 16.sp,
                color: Colors.grey[500],
                fontFamily: 'Poppins',
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 20.w,
                vertical: 18.h,
              ),
              prefixIcon: Container(
                padding: EdgeInsets.all(8.w),
                margin: EdgeInsets.only(right: 12.w, left: 8.w,top: 8.h, bottom: 8.h),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(
                  icon,
                  color: AppColors.primaryBlue,
                  size: 20.sp,
                ),
              ),
              prefixText: prefixText != null ? '$prefixText ' : null,
              prefixStyle: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
                fontFamily: 'Poppins',
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBankSelectionField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Bank',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
            fontFamily: 'Poppins',
          ),
        ),
        SizedBox(height: 8.h),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16.r),
            color: Colors.grey[50],
            border: Border.all(
              color: Colors.grey.shade300,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _showBankSelectionBottomSheet(),
              borderRadius: BorderRadius.circular(16.r),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 18.h),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8.w),
                      decoration: BoxDecoration(
                        color: AppColors.primaryBlue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular( 10.r),
                      ),
                      child: Icon(
                        Icons.account_balance_outlined,
                        color: AppColors.primaryBlue,
                        size: 20.sp,
                      ),
                    ),
                    SizedBox(width: 16.w),
                    Expanded(
                      child: Text(
                        selectedBank?.name ?? 'Choose your bank',
                        style: TextStyle(
                          fontSize: 16.sp,
                          color: selectedBank != null
                              ? Colors.black87
                              : Colors.grey[500],
                          fontWeight: selectedBank != null
                              ? FontWeight.w500
                              : FontWeight.w400,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),
                    Icon(
                      Icons.expand_more_rounded,
                      color: Colors.grey.shade600,
                      size: 24.sp,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAccountDetailsSection() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: accountDetails != null
              ? Colors.green.shade300
              : accountDetailsError != null
              ? Colors.red.shade300
              : Colors.grey.shade300,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isFetchingAccountDetails) ...[
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: SizedBox(
                    width: 20.w,
                    height: 20.h,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.primaryBlue,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                Text(
                  'Verifying Account Details...',
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w500,
                    color: AppColors.primaryBlue,
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
          ] else if (accountDetails != null) ...[
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Icon(
                    Icons.check_circle_rounded,
                    color: Colors.green,
                    size: 20.sp,
                  ),
                ),
                SizedBox(width: 12.w),
                Text(
                  'Account Verified Successfully',
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.green,
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            Text(
              accountDetails!.accountName,
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
                fontFamily: 'Poppins',
              ),
            ),
          ] else if (accountDetailsError != null) ...[
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Icon(
                    Icons.error_rounded,
                    color: Colors.red,
                    size: 20.sp,
                  ),
                ),
                SizedBox(width: 12.w),
                Text(
                  'Verification Failed',
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.red,
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
            SizedBox(height: 8.h),
            Text(
              accountDetailsError!,
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.red.shade700,
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildContinueButton() {
    return Container(
      width: double.infinity,
      height: 56.h,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16.r),
        gradient: LinearGradient(
          colors: [
            AppColors.primaryBlue,
            AppColors.primaryBlue.withOpacity(0.8),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryBlue.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (_formKey.currentState!.validate() && selectedBank != null) {
              _showConfirmationBottomSheet();
            } else if (selectedBank == null) {
              _showSnackBar('Please select a bank', Colors.red);
            }
          },
          borderRadius: BorderRadius.circular(16.r),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.arrow_forward_rounded,
                  color: Colors.white,
                  size: 22.sp,
                ),
                SizedBox(width: 12.w),
                Text(
                  'Continue to Confirmation',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showBankSelectionBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
        ),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(20.r),
              child: Column(
                children: [
                  Container(
                    width: 40.w,
                    height: 4.h,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2.r),
                    ),
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    'Select Bank',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.symmetric(horizontal: 20.r),
                itemCount: banks.length,
                itemBuilder: (context, index) {
                  final bank = banks[index];
                  return ListTile(
                    contentPadding: EdgeInsets.symmetric(vertical: 4.h),
                    leading: Container(
                      padding: EdgeInsets.all(8.r),
                      decoration: BoxDecoration(
                        color: AppColors.primaryBlue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Icon(
                        Icons.account_balance,
                        color: AppColors.primaryBlue,
                        size: 20.sp,
                      ),
                    ),
                    title: Text(
                      bank.name,
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                      ),
                    ),
                    trailing:
                    selectedBank?.code == bank.code
                        ? Icon(
                      Icons.check_circle,
                      color: AppColors.primaryBlue,
                    )
                        : null,
                    onTap: () {
                      setState(() {
                        selectedBank = bank;
                      });
                      Navigator.pop(context);
                      fetchAccountDetails();
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
