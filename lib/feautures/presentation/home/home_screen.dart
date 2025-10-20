import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:http/http.dart' as http;
import 'package:wallet/core/controllers/api_endpoints.dart';
import 'package:wallet/feautures/presentation/home/transaction_detail.dart';
import 'package:wallet/feautures/presentation/home/view_all_transactions.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wallet/core/utils/color_utils/color_util.dart';
import 'package:wallet/core/utils/widget_utils/actions_buttons_lists.dart';
import 'package:wallet/core/utils/widget_utils/header_Section.dart';
import 'package:wallet/core/utils/widget_utils/trial_custom_drawer.dart';
import 'package:wallet/core/utils/widget_utils/wallet_card.dart';
import '../../../core/controllers/school_service.dart';
import '../../../core/models/login_model.dart';
import '../../../core/models/transactionHist_model.dart';

class HomeScreen extends StatefulWidget {
  final LoginResponseModel loginResponse;

  const HomeScreen({
    super.key,
    required this.loginResponse,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Animation controllers
  late AnimationController _animationController;
  late AnimationController _transactionAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Balance state variables
  double? walletBalance;
  bool isLoadingBalance = true;
  String? balanceError;
  String? schoolCode;

  // Transaction state variables
  List<TransactionModel> recentTransactions = [];
  bool isLoadingTransactions = true;
  String? transactionError;

  @override
  void initState() {
    super.initState();

    // Initialize animations
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _transactionAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    // Start animations
    _animationController.forward();

    _initializeData();
  }

  Future<void> _initializeData() async {
    final schoolData = await SchoolDataService.getSchoolData();
    schoolCode = schoolData?.schoolCode ?? "";

    // Now fetch both balance and transactions after school code is initialized
    fetchWalletBalance();
    fetchWalletTransactions();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _transactionAnimationController.dispose();
    super.dispose();
  }

  /// Fetch wallet balance function
  Future<void> fetchWalletBalance() async {
    try {
      print("🔄 Fetching wallet balance...");

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) {
        setState(() {
          balanceError = "No authentication token found";
          isLoadingBalance = false;
        });
        return;
      }
      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
        'scode': schoolCode ?? "",
      };

      // Print headers for debugging
      print("📋 Balance Request Headers:");
      headers.forEach((key, value) {
        print("   $key: '$value'");
      });

      print("📤 Sending balance request to: ${APIEndpoints.getBalanceEndpoint}");
      print("🏫 School Code: '$schoolCode'");
      print("🔐 Auth Token: '${token.substring(0, 20)}...'"); // Only show first 20 chars for security

      final response = await http.get(
        Uri.parse(APIEndpoints.getBalanceEndpoint),
        headers: headers,
      ).timeout(Duration(seconds: 30));

      print("📥 Balance Response Status: ${response.statusCode}");
      print("📥 Balance Response Body: ${response.body}");

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        print("📊 Response Data Type: ${responseData.runtimeType}");
        print("📊 Response Data: $responseData");

        // Handle the specific nested structure: {"state": {...}, "payload": [16.25]}
        if (responseData is Map<String, dynamic>) {
          if (responseData.containsKey('payload')) {
            final payload = responseData['payload'];
            print("📦 Payload Type: ${payload.runtimeType}");
            print("📦 Payload Content: $payload");

            if (payload is List && payload.isNotEmpty) {
              // Balance is in payload array: {"payload": [16.25]}
              final balance = double.tryParse(payload[0].toString()) ?? 0.0;
              setState(() {
                walletBalance = balance;
                isLoadingBalance = false;
                balanceError = null;
              });
              print("✅ Balance fetched successfully from nested payload array: $walletBalance");
            } else if (payload is Map<String, dynamic>) {
              // Handle if payload is an object with balance properties
              double? balance;
              if (payload.containsKey('balance')) {
                balance = double.tryParse(payload['balance'].toString());
              } else if (payload.containsKey('wallet_balance')) {
                balance = double.tryParse(payload['wallet_balance'].toString());
              } else if (payload.containsKey('amount')) {
                balance = double.tryParse(payload['amount'].toString());
              }

              if (balance != null) {
                setState(() {
                  walletBalance = balance!;
                  isLoadingBalance = false;
                  balanceError = null;
                });
                print("✅ Balance fetched successfully from nested payload object: $walletBalance");
              } else {
                print("❌ Could not find balance in payload object: $payload");
                setState(() {
                  balanceError = 'Balance not found in payload';
                  isLoadingBalance = false;
                });
              }
            } else {
              print("❌ Invalid payload format: ${payload.runtimeType}");
              setState(() {
                balanceError = 'Invalid payload format';
                isLoadingBalance = false;
              });
            }
          } else {
            // Handle flat response without payload
            print("📄 Using flat response structure for balance");
            double? balance;
            if (responseData.containsKey('balance')) {
              balance = double.tryParse(responseData['balance'].toString());
            } else if (responseData.containsKey('wallet_balance')) {
              balance = double.tryParse(responseData['wallet_balance'].toString());
            } else if (responseData.containsKey('amount')) {
              balance = double.tryParse(responseData['amount'].toString());
            }

            if (balance != null) {
              setState(() {
                walletBalance = balance!;
                isLoadingBalance = false;
                balanceError = null;
              });
              print("✅ Balance fetched successfully from flat response: $walletBalance");
            } else {
              print("❌ Could not find balance in flat response: $responseData");
              setState(() {
                balanceError = 'Balance not found in response';
                isLoadingBalance = false;
              });
            }
          }
        } else if (responseData is List && responseData.isNotEmpty) {
          // Handle direct array response: [16.25]
          final balance = double.tryParse(responseData[0].toString()) ?? 0.0;
          setState(() {
            walletBalance = balance;
            isLoadingBalance = false;
            balanceError = null;
          });
          print("✅ Balance fetched successfully from direct array: $walletBalance");
        } else {
          print("❌ Invalid response format: ${responseData.runtimeType}");
          setState(() {
            balanceError = 'Invalid response format';
            isLoadingBalance = false;
          });
        }
      } else if (response.statusCode == 401) {
        print("❌ Unauthorized: Token may be expired");
        setState(() {
          balanceError = "Session expired. Please login again";
          isLoadingBalance = false;
        });
        // Optionally redirect to login screen
      } else {
        print("❌ HTTP Error: ${response.statusCode}");
        setState(() {
          balanceError = "Server error: ${response.statusCode}";
          isLoadingBalance = false;
        });
      }
    } on SocketException catch (e) {
      print("❌ Socket Exception: $e");
      setState(() {
        balanceError = "Connection failed. Check your internet connection";
        isLoadingBalance = false;
      });
    } on TimeoutException catch (e) {
      print("❌ Timeout Exception: $e");
      setState(() {
        balanceError = "Request timeout. Please try again";
        isLoadingBalance = false;
      });
    } on FormatException catch (e) {
      print("❌ JSON Format Exception: $e");
      setState(() {
        balanceError = "Invalid response format from server";
        isLoadingBalance = false;
      });
    } catch (error) {
      print("❌ General Error: $error");
      setState(() {
        balanceError = "Failed to fetch balance. Please try again";
        isLoadingBalance = false;
      });
    }
  }  Future<void> fetchWalletTransactions() async {
    try {
      print("🔄 Fetching wallet transactions...");

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) {
        setState(() {
          transactionError = "No authentication token found";
          isLoadingTransactions = false;
        });
        return;
      }

      final headers = {
        'Content-Type': 'application/json', // Added for consistency
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
        'scode': schoolCode ?? "",
      };

      // Print headers for debugging
      print("📋 Transaction Request Headers:");
      headers.forEach((key, value) {
        print("   $key: '$value'");
      });

      print("📤 Sending transactions request to: ${APIEndpoints.getTransactionHistEndpoint}");
      print("🏫 School Code: '$schoolCode'");
      print("🔐 Auth Token: '${token.substring(0, 20)}...'"); // Only show first 20 chars for security

      final response = await http.get(
        Uri.parse(APIEndpoints.getTransactionHistEndpoint),
        headers: headers,
      ).timeout(Duration(seconds: 30));

      print("📥 Transactions Response Status: ${response.statusCode}");
      print("📥 Transactions Response Body: ${response.body}");

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        // Check if response has nested structure like login
        Map<String, dynamic> actualData;
        if (responseData.containsKey('payload')) {
          // If response is nested like login response
          actualData = responseData['payload'];
          print("📦 Using nested payload structure");
        } else {
          // If response is flat
          actualData = responseData;
          print("📄 Using flat response structure");
        }

        if (actualData['status'] == 1) {
          final transactionResponse = TransactionResponse.fromJson(actualData);
          List<TransactionModel> allTransactions = transactionResponse.data.data.data;

          // Transform transfer actions to withdrawal
          allTransactions = allTransactions.map((transaction) {
            if (transaction.action.toLowerCase() == 'transfer') {
              return transaction.copyWith(action: 'withdrawal');
            }
            return transaction;
          }).toList();

          // Sort by date (newest first)
          allTransactions.sort((a, b) {
            try {
              DateTime dateA = DateTime.parse(a.createdAt);
              DateTime dateB = DateTime.parse(b.createdAt);
              return dateB.compareTo(dateA);
            } catch (e) {
              print("⚠️ Date parsing error: $e");
              return 0;
            }
          });

          // Take recent 4 transactions
          List<TransactionModel> recentTenTransactions = allTransactions.take(4).toList();

          setState(() {
            recentTransactions = recentTenTransactions;
            isLoadingTransactions = false;
            transactionError = null;
          });

          // Animate transactions
          _transactionAnimationController.forward();
          print("✅ Transactions fetched and modified: ${recentTransactions.length} transactions");
        } else {
          final errorMessage = actualData['message'] ?? 'Failed to fetch transactions';
          print("❌ Transaction fetch failed: $errorMessage");
          setState(() {
            transactionError = errorMessage;
            isLoadingTransactions = false;
          });
        }
      } else if (response.statusCode == 401) {
        print("❌ Unauthorized: Token may be expired");
        setState(() {
          transactionError = "Session expired. Please login again";
          isLoadingTransactions = false;
        });
        // Optionally redirect to login screen
      } else {
        print("❌ HTTP Error: ${response.statusCode}");
        setState(() {
          transactionError = "Server error: ${response.statusCode}";
          isLoadingTransactions = false;
        });
      }
    } on SocketException catch (e) {
      print("❌ Socket Exception: $e");
      setState(() {
        transactionError = "Connection failed. Check your internet connection";
        isLoadingTransactions = false;
      });
    } on TimeoutException catch (e) {
      print("❌ Timeout Exception: $e");
      setState(() {
        transactionError = "Request timeout. Please try again";
        isLoadingTransactions = false;
      });
    } on FormatException catch (e) {
      print("❌ JSON Format Exception: $e");
      setState(() {
        transactionError = "Invalid response format from server";
        isLoadingTransactions = false;
      });
    } catch (error) {
      print("❌ General Error: $error");
      setState(() {
        transactionError = "Failed to fetch transactions. Please try again";
        isLoadingTransactions = false;
      });
    }
  }  Future<void> refreshBalance() async {
    setState(() {
      isLoadingBalance = true;
      balanceError = null;
    });
    await fetchWalletBalance();
  }

  /// Refresh transactions function
  Future<void> refreshTransactions() async {
    setState(() {
      isLoadingTransactions = true;
      transactionError = null;
    });
    await fetchWalletTransactions();
  }

  /// Refresh both balance and transactions
  Future<void> refreshAll() async {
    await Future.wait([
      refreshBalance(),
      refreshTransactions(),
    ]);
  }

  /// Format transaction date
  String formatTransactionDate(String dateString) {
    try {
      DateTime date = DateTime.parse(dateString);
      DateTime now = DateTime.now();
      Duration difference = now.difference(date);

      if (difference.inDays == 0) {
        return "Today ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
      } else if (difference.inDays == 1) {
        return "Yesterday";
      } else if (difference.inDays < 7) {
        return "${difference.inDays} days ago";
      } else {
        return "${date.day}/${date.month}/${date.year}";
      }
    } catch (e) {
      return dateString;
    }
  }

  /// Get transaction icon based on action
  IconData getTransactionIcon(String action) {
    switch (action.toLowerCase()) {
      case 'transfer':
        return Icons.swap_horiz_rounded;
      case 'credit':
        return Icons.add_circle_outline_rounded;
      case 'debit':
        return Icons.remove_circle_outline_rounded;
      case 'withdrawal':
        return Icons.account_balance_wallet_outlined;
      default:
        return Icons.receipt_long_rounded;
    }
  }

  /// Get transaction color based on action
  Color getTransactionColor(String action) {
    switch (action.toLowerCase()) {
      case 'transfer':
        return const Color(0xFF2196F3);
      case 'credit':
        return const Color(0xFF4CAF50);
      case 'debit':
      case 'withdrawal':
        return const Color(0xFFF44336);
      default:
        return AppColors.primaryBlue;
    }
  }

  void navigateToTransactionDetails(TransactionModel transaction) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TransactionDetailsScreen(transaction: transaction),
      ),
    );
  }

  /// Build modern transaction item
  /// Build modern transaction item
  /// Build modern transaction item
  Widget buildTransactionItem(TransactionModel transaction, int index) {
    // Transform display text for transfer actions
    String displayAction = transaction.action.toLowerCase() == 'transfer'
        ? 'withdrawal'
        : transaction.action;

    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 0.2),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _transactionAnimationController,
        curve: Interval(
          (index * 0.1).clamp(0.0, 1.0),
          1.0,
          curve: Curves.easeOutCubic,
        ),
      )),
      child: FadeTransition(
        opacity: Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).animate(CurvedAnimation(
          parent: _transactionAnimationController,
          curve: Interval(
            (index * 0.1).clamp(0.0, 1.0),
            1.0,
            curve: Curves.easeOutCubic,
          ),
        )),
        child: GestureDetector(
          onTap: () => navigateToTransactionDetails(transaction),
          child: Container(
            margin: EdgeInsets.only(bottom: 16.h),
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white,
                  Colors.grey[50]!,
                ],
              ),
              borderRadius: BorderRadius.circular(20.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.08),
                  spreadRadius: 0,
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
                BoxShadow(
                  color: Colors.grey.withOpacity(0.05),
                  spreadRadius: 0,
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
              border: Border.all(
                color: Colors.grey.withOpacity(0.05),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 50.w,
                  height: 50.h,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        getTransactionColor(displayAction).withOpacity(0.15),
                        getTransactionColor(displayAction).withOpacity(0.05),
                      ],
                    ),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: getTransactionColor(displayAction).withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    getTransactionIcon(displayAction),
                    color: getTransactionColor(displayAction),
                    size: 24.sp,
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // FIXED: Use action instead of narration
                      Text(
                        transaction.displayTitle, // This will show "CREDIT" instead of the numbers
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13.5.sp,
                          color: Colors.black87,
                          fontFamily: 'Poppins',
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 6.h),
                      Text(
                        formatTransactionDate(transaction.createdAt),
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: Colors.grey[600],
                          fontFamily: 'Poppins',
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                        decoration: BoxDecoration(
                          color: transaction.status.toLowerCase() == 'successful'
                              ? Colors.green.withOpacity(0.1)
                              : Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8.r),
                          border: Border.all(
                            color: transaction.status.toLowerCase() == 'successful'
                                ? Colors.green.withOpacity(0.3)
                                : Colors.orange.withOpacity(0.3),
                            width: 0.5,
                          ),
                        ),
                        child: Text(
                          transaction.status.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10.sp,
                            color: transaction.status.toLowerCase() == 'successful'
                                ? Colors.green[700]
                                : Colors.orange[700],
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      transaction.displayAmount, // Use the model's displayAmount which handles +/-
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16.sp,
                        color: getTransactionColor(displayAction),
                        fontFamily: 'Poppins',
                      ),
                    ),
                    if (transaction.charges > 0)
                      Padding(
                        padding: EdgeInsets.only(top: 4.h),
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(6.r),
                          ),
                          child: Text(
                            "Fee: ₦${transaction.charges.toStringAsFixed(2)}",
                            style: TextStyle(
                              fontSize: 10.sp,
                              color: Colors.grey[700],
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }  /// Build modern section header
  Widget buildSectionHeader(String title, String? actionText, VoidCallback? onAction) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      child: Row(
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18.sp,
              color: Colors.black87,
              fontFamily: 'Poppins',
            ),
          ),
          const Spacer(),
          if (actionText != null && onAction != null)
            Container(
              height: 35.h,
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10.r),
                border: Border.all(
                  color: AppColors.primaryBlue.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: TextButton(
                onPressed: onAction,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      actionText,
                      style: TextStyle(
                        color: AppColors.primaryBlue,
                        fontFamily: "Poppins",
                        fontSize: 11.5.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(width: 4.w),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: AppColors.primaryBlue,
                      size: 12.sp,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Build modern empty state
  Widget buildEmptyState() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 60.h),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(30.w),
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
              ),
              child: Image.asset(
                "assets/icons/Group 9.png",
                width: 120.w,
                height: 120.h,
                fit: BoxFit.contain,
              ),
            ),
            SizedBox(height: 24.h),
            Text(
              "No Transactions Yet",
              style: TextStyle(
                color: Colors.black87,
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                fontFamily: 'Poppins',
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              "Your transaction history will appear here\nonce you start using your wallet",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14.sp,
                fontFamily: 'Poppins',
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userData = widget.loginResponse.data;
    return Scaffold(
      key: _scaffoldKey,
      drawer: TrialCustomDrawer(
        loginResponseModel: widget.loginResponse,
        profPic: userData?.fpicture ?? "asset/images/Student.png",
        userName: "${userData?.firstname} ${userData?.lastname}" ?? "Ikegou faith Sochima",
        adno: userData?.adno ?? "",
      ),
      backgroundColor: const Color(0xFFFAFAFA),
      body: RefreshIndicator(
        onRefresh: refreshAll,
        color: AppColors.primaryBlue,
        backgroundColor: Colors.white,
        child: Container(
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Stack(
              children: [
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Column(
                      children: [
                        HeaderSection(
                          scaffoldKey: _scaffoldKey,
                          userName: userData?.firstname ?? 'Student',
                          profPic: userData?.fpicture ?? "assets/images/Student.png",
                        ),

                        // Action Buttons
                        Padding(
                          padding: EdgeInsets.only(left: 20.w, right: 20.w, top: 140.h, bottom: 50.h),
                          child: ActionsButtonsLists(loginResponseModel: widget.loginResponse),
                        ),

                        SizedBox(height: 0.h),

                        // Transaction History Section
                        Padding(
                          padding: EdgeInsets.only(top: 0.h, left: 30.w, right: 30.w),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              buildSectionHeader(
                                "Recent Activity",
                                "View All",
                                    () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => AllTransactionsScreen(),
                                    ),
                                  );
                                },
                              ),

                              SizedBox(height: 24.h),

                              // Transaction List or States
                              if (isLoadingTransactions)
                                Container(
                                  alignment: Alignment.center,
                                  padding: EdgeInsets.symmetric(vertical: 60.h),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Container(
                                        width: 60.w,
                                        height: 55.h,
                                        padding: EdgeInsets.all(16.w),
                                        decoration: BoxDecoration(
                                          color: AppColors.primaryBlue.withOpacity(0.1),
                                          shape: BoxShape.circle,
                                        ),
                                        child: CircularProgressIndicator(
                                          color: AppColors.primaryBlue,
                                          strokeWidth: 3,
                                        ),
                                      ),
                                      SizedBox(height: 20.h),
                                      Text(
                                        "Loading your transactions...",
                                        style: TextStyle(
                                          color: AppColors.primaryBlue,
                                          fontSize: 16.sp,
                                          fontWeight: FontWeight.w500,
                                          fontFamily: 'Poppins',
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              else if (transactionError != null)
                                Container(
                                  alignment: Alignment.center,
                                  padding: EdgeInsets.symmetric(vertical: 60.h),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Container(
                                        width: 80.w,
                                        height: 80.h,
                                        decoration: BoxDecoration(
                                          color: Colors.red.withOpacity(0.1),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.error_outline_rounded,
                                          size: 40.sp,
                                          color: Colors.red[600],
                                        ),
                                      ),
                                      SizedBox(height: 20.h),
                                      Text(
                                        "Something went wrong",
                                        style: TextStyle(
                                          color: Colors.black87,
                                          fontSize: 18.sp,
                                          fontWeight: FontWeight.w600,
                                          fontFamily: 'Poppins',
                                        ),
                                      ),
                                      SizedBox(height: 8.h),
                                      Text(
                                        transactionError!,
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 14.sp,
                                          fontFamily: 'Poppins',
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      SizedBox(height: 24.h),
                                      Container(
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              AppColors.primaryBlue,
                                              AppColors.primaryBlue.withOpacity(0.8),
                                            ],
                                          ),
                                          borderRadius: BorderRadius.circular(12.r),
                                          boxShadow: [
                                            BoxShadow(
                                              color: AppColors.primaryBlue.withOpacity(0.3),
                                              blurRadius: 8,
                                              offset: const Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        child: ElevatedButton(
                                          onPressed: refreshTransactions,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.transparent,
                                            foregroundColor: Colors.white,
                                            shadowColor: Colors.transparent,
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 32.w,
                                              vertical: 12.h,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(12.r),
                                            ),
                                          ),
                                          child: Text(
                                            "Try Again",
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 16.sp,
                                              fontFamily: 'Poppins',
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              else if (recentTransactions.isEmpty)
                                  buildEmptyState()
                                else
                                  Column(
                                    children: [
                                      ...recentTransactions.asMap().entries.map((entry) =>
                                          buildTransactionItem(entry.value, entry.key)
                                      ),
                                    ],
                                  ),

                              SizedBox(height: 100.h),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Wallet Card with balance data
                WalletCard(
                  balance: walletBalance,
                  isLoadingBalance: isLoadingBalance,
                  balanceError: balanceError,
                  onRefreshBalance: refreshBalance,
                  loginResponseModel: widget.loginResponse,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}