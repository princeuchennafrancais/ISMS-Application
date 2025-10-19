import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:wallet/core/controllers/api_endpoints.dart';
import 'package:wallet/core/utils/color_utils/color_util.dart';
import 'package:wallet/core/utils/widget_utils/custom_snackbar.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/controllers/school_service.dart';

class FundAccountScreen extends StatefulWidget {
  const FundAccountScreen({super.key});

  @override
  State<FundAccountScreen> createState() => _FundAccountScreenState();
}

class _FundAccountScreenState extends State<FundAccountScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // User wallet details - will be populated from API
  String accountNumber = "";
  String accountName = "";
  String bankName = "";
  String bankCode = "";
  String walletId = "";
  double balance = 0.0;
  bool isLoading = true;
  String? errorMessage;
  String? schoolCode;

  String toTitleCase(String text) {
    if (text.isEmpty) return text;

    return text.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word.substring(0, 1).toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initializeData();

  }
  Future<void> _initializeData() async {
    final schoolData = await SchoolDataService.getSchoolData();
    schoolCode = schoolData?.schoolCode ?? "";
    fetchWalletDetails();
  }


  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> fetchWalletDetails() async {
    try {
      print("🔄 Attempting to fetch wallet details from: ${APIEndpoints.getWalletDetailsEndpoint}");

      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      // Get token from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) {
        print("❌ No auth token found");
        setState(() {
          errorMessage = 'Please login again';
          isLoading = false;
        });
        return;
      }

      print("🔐 Using token: $token");

      final headers = {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
        'scode': schoolCode ?? "",
      };

      print("📤 Sending wallet details request...");
      print("schoolCode $schoolCode");

      final response = await http.get(
        Uri.parse(APIEndpoints.getWalletDetailsEndpoint),
        headers: headers,
      ).timeout(Duration(seconds: 30));

      print("📥 Response Status: ${response.statusCode}");
      print("📥 Response Body: ${response.body}");

      if (response.statusCode == 200) {
        // Handle potential malformed JSON with multiple objects
        String responseBody = response.body.trim();

        // Check if the response contains multiple JSON objects
        if (responseBody.contains('}{')) {
          print("⚠️ Detected multiple JSON objects in response, extracting first valid JSON");
          int firstObjectEnd = responseBody.indexOf('}{');
          if (firstObjectEnd != -1) {
            responseBody = responseBody.substring(0, firstObjectEnd + 1);
          }
        }

        // Additional check for malformed JSON at the end
        if (!responseBody.endsWith('}') && responseBody.contains('}')) {
          int lastValidBrace = responseBody.lastIndexOf('}');
          responseBody = responseBody.substring(0, lastValidBrace + 1);
        }

        try {
          final Map<String, dynamic> responseData = json.decode(responseBody);

          // Check for the nested structure with 'state' and 'payload'
          bool isSuccess = false;
          dynamic walletsData;

          // Check if response has the nested 'state' and 'payload' structure
          if (responseData.containsKey('state') && responseData.containsKey('payload')) {
            final state = responseData['state'];
            final payload = responseData['payload'];

            if (state['status'] == 1 && payload['status'] == 1) {
              isSuccess = true;
              // Navigate to the actual wallet data
              final payloadData = payload['data'];
              if (payloadData is Map && payloadData.containsKey('data')) {
                walletsData = payloadData['data'];
              } else {
                walletsData = payloadData;
              }
            }
          }
          // Fallback to original structure check
          else if (responseData['status'] == 1) {
            isSuccess = true;
            final outerData = responseData['data'];
            if (outerData is Map<String, dynamic>) {
              walletsData = outerData['data'];
            } else {
              walletsData = outerData;
            }
          }

          if (isSuccess && walletsData is List && walletsData.isNotEmpty) {
            final wallet = walletsData[0];

            // Extract bank details from nested 'bank' object if it exists
            String accNumber = '';
            String accName = '';
            String bnkName = '';
            String bnkCode = '';

            if (wallet.containsKey('bank') && wallet['bank'] is Map) {
              // Bank details are nested
              final bankDetails = wallet['bank'];
              accNumber = bankDetails['account_number']?.toString() ?? '';
              accName = bankDetails['account_name']?.toString() ?? '';
              bnkName = bankDetails['bank_name']?.toString() ?? '';
              bnkCode = bankDetails['bank_code']?.toString() ?? '';
            } else {
              // Bank details are at wallet level
              accNumber = wallet['account_number']?.toString() ?? '';
              accName = wallet['account_name']?.toString() ?? '';
              bnkName = wallet['bank_name']?.toString() ?? '';
              bnkCode = wallet['bank_code']?.toString() ?? '';
            }

            setState(() {
              accountNumber = accNumber;
              accountName = accName;
              bankName = bnkName;
              bankCode = bnkCode;
              walletId = wallet['wallet_id']?.toString() ?? '';

              // Safely handle balance conversion
              if (wallet['balance'] != null) {
                if (wallet['balance'] is int) {
                  balance = (wallet['balance'] as int).toDouble();
                } else if (wallet['balance'] is double) {
                  balance = wallet['balance'] as double;
                } else if (wallet['balance'] is String) {
                  balance = double.tryParse(wallet['balance'] as String) ?? 0.0;
                } else {
                  balance = 0.0;
                }
              } else {
                balance = 0.0;
              }

              isLoading = false;
            });

            print("✅ Wallet details loaded successfully");
            print("📊 Account: $accountNumber, Balance: $balance");

            if (mounted) {
              CustomSnackbar.success("Wallet details loaded successfully");
            }
          } else {
            print("❌ No wallet data found in response");
            setState(() {
              errorMessage = 'No wallet data found';
              isLoading = false;
            });

            if (mounted) {
              CustomSnackbar.error("No wallet data found");
            }
          }
        } catch (jsonError) {
          print("❌ JSON Decoding Error: $jsonError");
          print("📥 Problematic Response: $responseBody");

          // Try to extract any useful information from the malformed response
          _handleMalformedResponse(responseBody);
        }
      } else {
        print("❌ HTTP Error: ${response.statusCode}");
        setState(() {
          errorMessage = 'Server error: ${response.statusCode}';
          isLoading = false;
        });

        if (mounted) {
          CustomSnackbar.error("Server error: ${response.statusCode}");
        }
      }
    } on SocketException catch (e) {
      print("❌ Socket Exception: $e");
      setState(() {
        errorMessage = 'Connection failed. Check your internet connection';
        isLoading = false;
      });

      if (mounted) {
        CustomSnackbar.error("Connection failed. Check your internet connection");
      }
    } on TimeoutException catch (e) {
      print("❌ Timeout Exception: $e");
      setState(() {
        errorMessage = 'Request timeout. Please try again';
        isLoading = false;
      });

      if (mounted) {
        CustomSnackbar.error("Request timeout. Please try again");
      }
    } catch (error) {
      print("❌ General Error: $error");
      setState(() {
        errorMessage = 'Failed to load wallet details. Please try again';
        isLoading = false;
      });

      if (mounted) {
        CustomSnackbar.error("Failed to load wallet details. Please try again");
      }
    }
  }
  void _handleMalformedResponse(String responseBody) {
    print("🔄 Attempting to extract data from malformed response");

    // Try to extract account details using string methods as fallback
    try {
      String? extractedAccountNumber;
      String? extractedAccountName;
      String? extractedBankName;

      // Simple pattern matching for critical fields
      if (responseBody.contains('"account_number"')) {
        int start = responseBody.indexOf('"account_number"') + 17;
        int end = responseBody.indexOf('"', start);
        if (end != -1) {
          extractedAccountNumber = responseBody.substring(start, end);
        }
      }

      if (responseBody.contains('"account_name"')) {
        int start = responseBody.indexOf('"account_name"') + 15;
        int end = responseBody.indexOf('"', start);
        if (end != -1) {
          extractedAccountName = responseBody.substring(start, end);
        }
      }

      if (responseBody.contains('"bank_name"')) {
        int start = responseBody.indexOf('"bank_name"') + 12;
        int end = responseBody.indexOf('"', start);
        if (end != -1) {
          extractedBankName = responseBody.substring(start, end);
        }
      }

      // If we managed to extract some data, use it
      if (extractedAccountNumber != null && extractedAccountName != null) {
        setState(() {
          accountNumber = extractedAccountNumber!;
          accountName = extractedAccountName!;
          bankName = extractedBankName ?? 'Bank';
          isLoading = false;
        });

        print("✅ Recovered data from malformed response");
        if (mounted) {
          CustomSnackbar.success("Wallet details recovered");
        }
      } else {
        throw FormatException("Could not extract data from malformed response");
      }
    } catch (extractionError) {
      print("❌ Extraction failed: $extractionError");
      setState(() {
        errorMessage = 'Invalid response format from server';
        isLoading = false;
      });

      if (mounted) {
        CustomSnackbar.error("Invalid response format from server");
      }
    }
  }
  void handleWalletError(Map<String, dynamic> body, BuildContext context) {
    final errorMessage = body["message"] ?? "Failed to fetch wallet details";
    print("❌ Wallet Error: $errorMessage");

    setState(() {
      this.errorMessage = errorMessage;
      isLoading = false;
    });

    if (context.mounted) {
      CustomSnackbar.error(errorMessage);
    }
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copied to clipboard'),
        backgroundColor: AppColors.primaryBlue,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
        margin: EdgeInsets.all(16.r),
      ),
    );
  }

  void _shareViaWhatsApp() {
    final String message = '''
💳 *Account Details for Transfer*

📋 Account Number: $accountNumber
👤 Account Name: $accountName
🏦 Bank Name: $bankName
  ''';

    Share.share(message);
  }

  void _retryFetch() {
    fetchWalletDetails();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: AppColors.primaryBlue, size: 20.sp),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Fund Account',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: isLoading
          ? _buildLoadingState()
          : errorMessage != null
          ? _buildErrorState()
          : _buildMainContent(),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryBlue),
          ),
          SizedBox(height: 16.h),
          Text(
            'Loading wallet details...',
            style: TextStyle(
              fontSize: 16.sp,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(20.r),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.red.shade400,
              size: 48.sp,
            ),
            SizedBox(height: 16.h),
            Text(
              'Oops! Something went wrong',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.grey.shade600,
                height: 1.4,
              ),
            ),
            SizedBox(height: 24.h),
            ElevatedButton(
              onPressed: _retryFetch,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
                padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 12.h),
              ),
              child: Text(
                'Try Again',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Header Section
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(20.r),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(20.r),
                bottomRight: Radius.circular(20.r),
              ),
            ),
            child: Column(
              children: [
                Container(
                  padding: EdgeInsets.all(16.r),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.account_balance_wallet,
                    color: AppColors.primaryBlue,
                    size: 40.sp,
                  ),
                ),
                SizedBox(height: 16.h),
                Text(
                  'Add Money to Your Wallet',
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  'Transfer money to the account below\nto fund your wallet instantly',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: Colors.grey.shade600,
                    height: 1.4,
                  ),
                ),
                SizedBox(height: 12.h),
              ],
            ),
          ),

          SizedBox(height: 20.h),

          // Account Details Content
          _buildAccountTab(
            accountNumber: accountNumber,
            accountName: accountName,
            bankName: bankName,
          ),
        ],
      ),
    );
  }

  Widget _buildAccountTab({
    required String accountNumber,
    required String accountName,
    required String bankName,
  }) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 20.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Account Details Card
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(20.r),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
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
                    SizedBox(width: 12.w),
                    Text(
                      'Your Account Details',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 20.h),

                _buildDetailRow(
                  'Account Number',
                  accountNumber,
                  Icons.credit_card,
                  onTap: () => _copyToClipboard(accountNumber, 'Account number'),
                ),

                _buildDetailRow(
                  'Account Name',
                  accountName,
                  Icons.person,
                  onTap: () => _copyToClipboard(accountName, 'Account name'),
                ),

                _buildDetailRow(
                  'Bank Name',
                  bankName,
                  Icons.account_balance,
                  onTap: () => _copyToClipboard(bankName, 'Bank name'),
                ),

                SizedBox(height: 16.h),

                // WhatsApp Share Button
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 250.w,
                      height: 52.h,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                            backgroundColor: AppColors.primaryBlue
                        ),
                        onPressed: _shareViaWhatsApp,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.share,
                              color: Colors.white,
                              size: 20.sp,
                            ),
                            SizedBox(width: 8.w),
                            Text(
                              'Share Details',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 15.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          SizedBox(height: 20.h),

          // Instructions Card
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(20.r),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primaryBlue.withOpacity(0.1),
                  AppColors.primaryBlue.withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(
                color: AppColors.primaryBlue.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: AppColors.primaryBlue,
                      size: 20.sp,
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      'How to Fund Your Account',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryBlue,
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 16.h),

                _buildInstructionStep(
                  '1',
                  'Copy the account details above or share via WhatsApp',
                ),

                _buildInstructionStep(
                  '2',
                  'Open your bank app or visit any bank branch',
                ),

                _buildInstructionStep(
                  '3',
                  'Transfer any amount to the account details',
                ),

                _buildInstructionStep(
                  '4',
                  'Your wallet will be credited instantly',
                ),
              ],
            ),
          ),

          SizedBox(height: 20.h),

          // Warning Note
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16.r),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: Colors.orange.shade200,
                width: 1,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.orange.shade600,
                  size: 20.sp,
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Important Note',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.orange.shade800,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        'Only transfer from your registered bank account. Transfers from other accounts may take longer to process.',
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: Colors.orange.shade700,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 40.h),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: 16.h),
        padding: EdgeInsets.all(12.r),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(
            color: Colors.grey.shade200,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: Colors.grey.shade600,
              size: 18.sp,
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    toTitleCase(value.isEmpty ? 'Loading...' : value),
                    style: TextStyle(
                      fontSize: 15.sp,
                      color: Colors.black,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            if (value.isNotEmpty)
              Icon(
                Icons.copy,
                color: AppColors.primaryBlue,
                size: 18.sp,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructionStep(String number, String instruction) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24.w,
            height: 24.h,
            decoration: BoxDecoration(
              color: AppColors.primaryBlue,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              instruction,
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.grey.shade700,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}