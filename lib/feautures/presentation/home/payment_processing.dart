import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:clipboard/clipboard.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wallet/core/utils/color_utils/color_util.dart';

class PaymentProcessingScreen extends StatefulWidget {
  final Map<String, dynamic> feesDetails;
  final String session;
  final String term;
  final String classm;
  final String sessionName;
  final String termName;
  final String className;

  const PaymentProcessingScreen({
    super.key,
    required this.feesDetails,
    required this.session,
    required this.term,
    required this.classm,
    required this.sessionName,
    required this.termName,
    required this.className,
  });

  @override
  State<PaymentProcessingScreen> createState() => _PaymentProcessingScreenState();
}

class _PaymentProcessingScreenState extends State<PaymentProcessingScreen> with TickerProviderStateMixin {
  // Payment state
  bool isLoading = false;
  bool isCheckingPayment = false;
  bool paymentFound = false;
  String? errorMessage;

  // Payment data
  Map<String, dynamic>? paymentInitData;
  List<Map<String, dynamic>>? paymentItems;
  Map<String, dynamic>? foundTransaction;

  // Animation controllers
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Colors
  final Color primaryColor = AppColors.primaryBlue;
  final Color successColor = Colors.green;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializePayment();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _animationController.forward();
  }

  Future<void> _initializePayment() async {
    await _initiatePayment();
  }

  Future<void> _initiatePayment() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      print("🔄 Initiating payment...");

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? '';

      final Map<String, dynamic> requestBody = {
        "session": widget.session,
        "term": widget.term,
        "classm": widget.classm,
      };

      print("📤 Payment Request Body: ${jsonEncode(requestBody)}");

      final response = await http.post(
        Uri.parse("https://rosarycollegenise.com/api/transaction_api/initTransaction"),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(requestBody),
      ).timeout(const Duration(seconds: 30));

      print("📥 Payment Response Status: ${response.statusCode}");
      print("📥 Payment Response Body: ${response.body}");

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        if (responseData['status'] == 1) {
          setState(() {
            paymentInitData = responseData['data'];
            paymentItems = List<Map<String, dynamic>>.from(responseData['Txtf'] ?? []);
            isLoading = false;
          });

          print("✅ Payment initiated successfully");
        } else {
          setState(() {
            errorMessage = responseData['message'] ?? 'Failed to initiate payment';
            isLoading = false;
          });
          print("❌ Payment initiation failed: $errorMessage");
        }
      } else {
        setState(() {
          errorMessage = "Server error: ${response.statusCode}";
          isLoading = false;
        });
        print("❌ HTTP Error: ${response.statusCode}");
      }
    } on TimeoutException {
      setState(() {
        errorMessage = "Request timeout. Please try again";
        isLoading = false;
      });
      print("❌ Request timeout");
    } on Exception catch (e) {
      setState(() {
        errorMessage = "Failed to initiate payment: ${e.toString()}";
        isLoading = false;
      });
      print("❌ Error: $e");
    }
  }

  Future<void> _checkForPayment() async {
    setState(() {
      isCheckingPayment = true;
      errorMessage = null;
    });

    try {
      print("🔄 Checking for payment...");

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? '';

      final response = await http.post(
        Uri.parse("https://rosarycollegenise.com/api/transaction_api/getStudenTxt"),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 30));

      print("📥 Status Response Status: ${response.statusCode}");

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        if (responseData['status'] == 1) {
          final List<dynamic> transactions = responseData['data'] ?? [];

          // Find recent transactions (within last 2 minutes)
          final DateTime twoMinutesAgo = DateTime.now().subtract(const Duration(minutes: 2));

          for (var studentData in transactions) {
            if (studentData['txt'] != null && studentData['txt'] is List) {
              final List<dynamic> txtList = studentData['txt'];

              for (var transaction in txtList) {
                if (transaction['received_at'] != null &&
                    transaction['status']?.toString().toLowerCase() == 'successful') {

                  final DateTime receivedAt = DateTime.parse(transaction['received_at']);

                  if (receivedAt.isAfter(twoMinutesAgo)) {
                    // Found a successful transaction from the last 2 minutes
                    setState(() {
                      paymentFound = true;
                      foundTransaction = Map<String, dynamic>.from(transaction);
                      isCheckingPayment = false;
                    });

                    print("✅ Payment found: ${transaction['amount_paid']} at ${transaction['received_at']}");
                    return;
                  }
                }
              }
            }
          }

          // No transaction found
          setState(() {
            paymentFound = false;
            isCheckingPayment = false;
          });

          // Show message that no payment was found
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('No recent payment found. Please make sure you\'ve transferred the amount to the account details above.'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 5),
            ),
          );

          print("⚠️ No recent successful transactions found");
        } else {
          setState(() {
            errorMessage = responseData['message'] ?? 'Failed to check payment status';
            isCheckingPayment = false;
          });
          print("⚠️ Status check failed: ${responseData['message']}");
        }
      } else {
        setState(() {
          errorMessage = "Server error: ${response.statusCode}";
          isCheckingPayment = false;
        });
        print("⚠️ Status check HTTP error: ${response.statusCode}");
      }
    } on TimeoutException {
      setState(() {
        errorMessage = "Request timeout. Please try again";
        isCheckingPayment = false;
      });
      print("⚠️ Status check timeout");
    } on Exception catch (e) {
      setState(() {
        errorMessage = "Failed to check payment: ${e.toString()}";
        isCheckingPayment = false;
      });
      print("⚠️ Status check error: $e");
    }
  }

  void _cancelPayment() {
    Navigator.pop(context);
  }

  void _goBackToFeesScreen() {
    Navigator.pop(context);
  }

  void _copyToClipboard(String text) {
    FlutterClipboard.copy(text).then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Copied to clipboard'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    });
  }

  Future<void> _shareViaWhatsApp() async {
    if (paymentInitData == null) return;

    final bankName = paymentInitData!['bank_name'] ?? '';
    final accountName = paymentInitData!['account_name'] ?? '';
    final accountNumber = paymentInitData!['account_number'] ?? '';
    final reference = paymentInitData!['reference'] ?? '';
    final totalAmount = _calculateTotalAmount();

    final message = '''
*SCHOOL FEES PAYMENT DETAILS*

🏦 *Bank:* $bankName
👤 *Account Name:* $accountName
🔢 *Account Number:* $accountNumber
🏷️ *Reference:* $reference
💰 *Amount:* ₦$totalAmount

*ITEMS TO PAY:*
${paymentItems?.map((item) => "• ${item['component']}: ₦${item['amount']}").join('\n')}
    ''';

    String url = "whatsapp://send?text=${Uri.encodeComponent(message)}";

    try {
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url));
      } else {
        throw 'Could not launch WhatsApp';
      }
    } catch (e) {
      _showShareOptions(message);
    }
  }

  Future<void> _shareViaSMS() async {
    if (paymentInitData == null) return;

    final bankName = paymentInitData!['bank_name'] ?? '';
    final accountName = paymentInitData!['account_name'] ?? '';
    final accountNumber = paymentInitData!['account_number'] ?? '';
    final reference = paymentInitData!['reference'] ?? '';
    final totalAmount = _calculateTotalAmount();

    final message = '''
SCHOOL FEES PAYMENT DETAILS

Bank: $bankName
Account Name: $accountName
Account Number: $accountNumber
Reference: $reference
Amount: ₦$totalAmount

ITEMS TO PAY:
${paymentItems?.map((item) => "- ${item['component']}: ₦${item['amount']}").join('\n')}
    ''';

    String url = "sms:?body=${Uri.encodeComponent(message)}";

    try {
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url));
      } else {
        throw 'Could not launch SMS';
      }
    } catch (e) {
      _showShareOptions(message);
    }
  }

  void _showShareOptions(String message) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: EdgeInsets.all(20.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Share Payment Details',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 20.h),
            Text(
              'Select sharing method',
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 20.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildShareOptionButton(
                  icon: Icons.message,
                  label: 'SMS',
                  onTap: () => _shareViaSMS(),
                ),
                _buildShareOptionButton(
                  icon: Icons.message_outlined,
                  label: 'WhatsApp',
                  onTap: () => _shareViaWhatsApp(),
                ),
                _buildShareOptionButton(
                  icon: Icons.copy,
                  label: 'Copy',
                  onTap: () {
                    _copyToClipboard(message);
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
            SizedBox(height: 20.h),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShareOptionButton({required IconData icon, required String label, required VoidCallback onTap}) {
    return Column(
      children: [
        Container(
          width: 60.w,
          height: 60.h,
          decoration: BoxDecoration(
            color: primaryColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: Icon(icon, color: primaryColor),
            onPressed: onTap,
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          label,
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  PreferredSizeWidget _buildAppBar() {
    String appBarTitle = 'Make Payment';
    if (isLoading) {
      appBarTitle = 'Setting up Payment';
    } else if (paymentFound) {
      appBarTitle = 'Payment Found';
    }

    return PreferredSize(
      preferredSize: Size.fromHeight(70.h),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              primaryColor,
              primaryColor.withOpacity(0.8),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: primaryColor.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: Container(),
          title: Text(
            appBarTitle,
            style: TextStyle(
              color: Colors.white,
              fontSize: 20.sp,
              fontWeight: FontWeight.w600,
              fontFamily: 'Poppins',
            ),
          ),
          centerTitle: true,
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80.w,
            height: 80.h,
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: CircularProgressIndicator(
              color: primaryColor,
              strokeWidth: 4,
            ),
          ),
          SizedBox(height: 24.h),
          Text(
            'Initiating Payment...',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
              fontFamily: 'Poppins',
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Please wait while we set up your payment',
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.grey[600],
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
        padding: EdgeInsets.all(30.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
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
            SizedBox(height: 24.h),
            Text(
              'Payment Failed',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
                fontFamily: 'Poppins',
              ),
            ),
            SizedBox(height: 12.h),
            Text(
              errorMessage ?? 'Something went wrong',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.grey[600],
                fontFamily: 'Poppins',
              ),
            ),
            SizedBox(height: 32.h),
            Container(
              width: double.infinity,
              height: 56.h,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16.r),
                gradient: LinearGradient(
                  colors: [
                    primaryColor,
                    primaryColor.withOpacity(0.8),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _initializePayment,
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
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
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

  Widget _buildPaymentDetails() {
    if (paymentInitData == null) return Container();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [


        // Items Breakdown
        Text(
          'Items to Pay',
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
            fontFamily: 'Poppins',
          ),
        ),
        SizedBox(height: 16.h),

        // Items List
        ...(paymentItems ?? []).asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;

          return Container(
            margin: EdgeInsets.only(bottom: 12.h),
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: Colors.grey.withOpacity(0.1)),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 40.w,
                  height: 40.h,
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        color: primaryColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 16.sp,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['component']?.toString().toUpperCase() ?? 'ITEM',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(4.r),
                            ),
                            child: Text(
                              'Session: ${item['session'] ?? widget.sessionName}',
                              style: TextStyle(
                                fontSize: 10.sp,
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                          SizedBox(width: 4.w),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(4.r),
                            ),
                            child: Text(
                              'Term: ${item['term'] ?? widget.termName}',
                              style: TextStyle(
                                fontSize: 10.sp,
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 16.w),
                Text(
                  '₦${item['amount'] ?? '0.00'}',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                    color: primaryColor,
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
          );
        }).toList(),

        SizedBox(height: 25.h),

        // Total Amount
        Container(
          padding: EdgeInsets.all(20.w),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Amount',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                  fontFamily: 'Poppins',
                ),
              ),
              Text(
                '₦${_calculateTotalAmount()}',
                style: TextStyle(
                  fontSize: 22.sp,
                  fontWeight: FontWeight.w800,
                  color: primaryColor,
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
        ),

        SizedBox(height: 30.h),

        // Account Information Card
        Container(
          padding: EdgeInsets.all(20.w),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                primaryColor.withOpacity(0.1),
                primaryColor.withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(
              color: primaryColor.withOpacity(0.2),
              width: 1.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8.w),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Icon(
                      Icons.account_balance_outlined,
                      color: primaryColor,
                      size: 22.sp,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Text(
                    'Account Information',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20.h),
              _buildDetailRow('Bank Name', paymentInitData!['bank_name'] ?? 'N/A'),
              SizedBox(height: 12.h),
              _buildDetailRow('Account Name', paymentInitData!['account_name'] ?? 'N/A'),
              SizedBox(height: 12.h),
              _buildDetailRow(
                'Account Number',
                paymentInitData!['account_number'] ?? 'N/A',
                isImportant: true,
              ),
              // Copy and Share Buttons
              SizedBox(height: 20.h),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 45.h,
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            final details = '''
Bank: ${paymentInitData!['bank_name']}
Account Name: ${paymentInitData!['account_name']}
Account Number: ${paymentInitData!['account_number']}                            ''';
                            _copyToClipboard(details);
                          },
                          borderRadius: BorderRadius.circular(12.r),
                          child: Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.copy_all_rounded,
                                  color: primaryColor,
                                  size: 18.sp,
                                ),
                                SizedBox(width: 8.w),
                                Text(
                                  'Copy Details',
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w600,
                                    color: primaryColor,
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
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Container(
                      height: 45.h,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12.r),
                        gradient: LinearGradient(
                          colors: [
                            primaryColor,
                            primaryColor.withOpacity(0.8),
                          ],
                        ),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            final bankName = paymentInitData!['bank_name'] ?? '';
                            final accountName = paymentInitData!['account_name'] ?? '';
                            final accountNumber = paymentInitData!['account_number'] ?? '';
                            final reference = paymentInitData!['reference'] ?? '';
                            final totalAmount = _calculateTotalAmount();

                            final message = '''
SCHOOL FEES PAYMENT DETAILS

Bank: $bankName
Account Name: $accountName
Account Number: $accountNumber
Amount: ₦$totalAmount

ITEMS TO PAY:
${paymentItems?.map((item) => "- ${item['component']}: ₦${item['amount']}").join('\n')}
                            ''';
                            _showShareOptions(message);
                          },
                          borderRadius: BorderRadius.circular(12.r),
                          child: Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.share_rounded,
                                  color: Colors.white,
                                  size: 18.sp,
                                ),
                                SizedBox(width: 8.w),
                                Text(
                                  'Share',
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
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
            ],
          ),
        ),

        SizedBox(height: 25.h),

        // I Have Made Payment Button
        Container(
          width: double.infinity,
          height: 56.h,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16.r),
            gradient: LinearGradient(
              colors: [
                primaryColor,
                primaryColor.withOpacity(0.8),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: primaryColor.withOpacity(0.3),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: isCheckingPayment ? null : _checkForPayment,
              borderRadius: BorderRadius.circular(16.r),
              child: Center(
                child: isCheckingPayment
                    ? SizedBox(
                  width: 24.w,
                  height: 24.h,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: Colors.white,
                  ),
                )
                    : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.check_circle_outline_rounded,
                      color: Colors.white,
                      size: 22.sp,
                    ),
                    SizedBox(width: 12.w),
                    Text(
                      'I Have Made Payment',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Cancel Button
        SizedBox(height: 20.h),
        Container(
          width: double.infinity,
          height: 56.h,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: Colors.red.withOpacity(0.3),
              width: 1.5,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _cancelPayment,
              borderRadius: BorderRadius.circular(16.r),
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.close_rounded,
                      color: Colors.red,
                      size: 22.sp,
                    ),
                    SizedBox(width: 12.w),
                    Text(
                      'Cancel Payment',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.red,
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
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isImportant = false}) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.grey[600],
              fontFamily: 'Poppins',
            ),
          ),
        ),
        SizedBox(width: 16.w),
        Expanded(
          flex: 2,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: isImportant ? primaryColor.withOpacity(0.1) : Colors.grey[50],
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(
                color: isImportant ? primaryColor.withOpacity(0.3) : Colors.grey[300]!,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: SelectableText(
                    value,
                    style: TextStyle(
                      fontSize: isImportant ? 18.sp : 14.sp,
                      fontWeight: isImportant ? FontWeight.w700 : FontWeight.w500,
                      color: isImportant ? primaryColor : Colors.black87,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.copy_all_rounded,
                    size: 18.sp,
                    color: primaryColor.withOpacity(0.7),
                  ),
                  onPressed: () => _copyToClipboard(value),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFoundPaymentScreen() {
    if (foundTransaction == null) return Container();

    return SingleChildScrollView(
      padding: EdgeInsets.all(30.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Payment Found Header
          Container(
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  successColor.withOpacity(0.1),
                  successColor.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(
                color: successColor.withOpacity(0.2),
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: successColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Icon(
                    Icons.check_circle_rounded,
                    color: successColor,
                    size: 30.sp,
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Payment Found!',
                        style: TextStyle(
                          fontSize: 20.sp,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        'We have detected your payment',
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: Colors.grey[600],
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 30.h),

          // Transaction Details Card
          Container(
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(color: Colors.grey.withOpacity(0.1)),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8.w),
                      decoration: BoxDecoration(
                        color: successColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      child: Icon(
                        Icons.receipt_long_rounded,
                        color: successColor,
                        size: 22.sp,
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Text(
                      'Transaction Details',
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20.h),
                _buildTransactionDetailRow('Amount Paid', '₦${foundTransaction!['amount_paid'] ?? '0.00'}'),
                SizedBox(height: 12.h),
                _buildTransactionDetailRow('Resolved Amount', '₦${foundTransaction!['amount_resolved'] ?? '0.00'}'),
                SizedBox(height: 12.h),
                _buildTransactionDetailRow('From Account', '${foundTransaction!['src_account_name']} (${foundTransaction!['src_account_number']})'),
                SizedBox(height: 12.h),
                _buildTransactionDetailRow('From Bank', foundTransaction!['src_bank_name'] ?? 'N/A'),
                SizedBox(height: 12.h),
                _buildTransactionDetailRow('Reference', foundTransaction!['main_reference'] ?? 'N/A'),
                SizedBox(height: 12.h),
                _buildTransactionDetailRow('Date & Time', _formatDateTime(foundTransaction!['received_at'])),
                SizedBox(height: 12.h),
                _buildTransactionDetailRow('Status', foundTransaction!['status']?.toString().toUpperCase() ?? 'SUCCESSFUL'),
              ],
            ),
          ),

          SizedBox(height: 30.h),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 56.h,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        final details = '''
Payment Details:
Amount Paid: ${foundTransaction!['amount_paid']}
From: ${foundTransaction!['src_account_name']} (${foundTransaction!['src_account_number']})
Bank: ${foundTransaction!['src_bank_name']}
Reference: ${foundTransaction!['main_reference']}
Date: ${_formatDateTime(foundTransaction!['received_at'])}
                        ''';
                        _copyToClipboard(details);
                      },
                      borderRadius: BorderRadius.circular(12.r),
                      child: Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.copy_all_rounded,
                              color: primaryColor,
                              size: 18.sp,
                            ),
                            SizedBox(width: 8.w),
                            Text(
                              'Copy Details',
                              style: TextStyle(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w600,
                                color: primaryColor,
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
              SizedBox(width: 12.w),
              Expanded(
                child: Container(
                  height: 56.h,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12.r),
                    gradient: LinearGradient(
                      colors: [
                        primaryColor,
                        primaryColor.withOpacity(0.8),
                      ],
                    ),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _goBackToFeesScreen,
                      borderRadius: BorderRadius.circular(12.r),
                      child: Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.arrow_back_rounded,
                              color: Colors.white,
                              size: 18.sp,
                            ),
                            SizedBox(width: 8.w),
                            Text(
                              'Back to Fees',
                              style: TextStyle(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
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
        ],
      ),
    );
  }

  Widget _buildTransactionDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
              fontFamily: 'Poppins',
            ),
          ),
        ),
        SizedBox(width: 16.w),
        Expanded(
          flex: 3,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                    fontFamily: 'Poppins',
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.copy_all_rounded,
                  size: 18.sp,
                  color: primaryColor.withOpacity(0.7),
                ),
                onPressed: () => _copyToClipboard(value.replaceAll('₦', '')),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDateTime(String dateTimeString) {
    try {
      final DateTime dateTime = DateTime.parse(dateTimeString);
      return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateTimeString;
    }
  }

  String _calculateTotalAmount() {
    if (paymentItems == null) return '0.00';

    double total = 0;
    for (var item in paymentItems!) {
      try {
        total += double.parse(item['amount']?.toString() ?? '0');
      } catch (e) {
        print('Error parsing amount: ${item['amount']}');
      }
    }
    return total.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: _buildAppBar(),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Stack(
          children: [
            if (!paymentFound)
              SingleChildScrollView(
                padding: EdgeInsets.all(30.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isLoading)
                      _buildLoadingState()
                    else if (errorMessage != null)
                      _buildErrorState()
                    else
                      _buildPaymentDetails(),
                    SizedBox(height: 40.h),
                  ],
                ),
              ),

            if (paymentFound)
              _buildFoundPaymentScreen(),
          ],
        ),
      ),
    );
  }
}