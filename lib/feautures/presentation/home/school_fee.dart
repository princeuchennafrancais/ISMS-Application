import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wallet/core/controllers/api_endpoints.dart';
import 'package:wallet/core/controllers/school_service.dart';
import 'package:wallet/core/utils/color_utils/color_util.dart';
import 'package:wallet/feautures/presentation/home/notification_screen.dart';

class SchoolFeesScreen extends StatefulWidget {
  const SchoolFeesScreen({super.key});

  @override
  State<SchoolFeesScreen> createState() => _SchoolFeesScreenState();
}

class _SchoolFeesScreenState extends State<SchoolFeesScreen> with TickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  bool _isLoading = true;
  bool _isProcessingPayment = false;

  String studentName = "N/A";
  String regNo = "N/A";
  String studentClass = "N/A";
  String? schoolCode;

  // Fee details
  double totalFees = 0.0;
  double paidFees = 0.0;
  double outstandingFees = 0.0;
  List<Map<String, dynamic>> feeBreakdown = [];

  // Payment amount controller
  final TextEditingController _amountController = TextEditingController();
  String selectedPaymentMethod = 'card';

  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeData();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _amountController.dispose();
    super.dispose();
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
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _fadeController.forward();
    _slideController.forward();
  }

  Future<void> _initializeData() async {
    print("=== INITIALIZING FEES DATA ===");

    try {
      final schoolData = await SchoolDataService.getSchoolData();

      if (mounted) {
        setState(() {
          schoolCode = schoolData?.schoolCode ?? "";
        });

        print("School code retrieved: $schoolCode");

        if (schoolCode != null && schoolCode!.isNotEmpty) {
          await fetchFeesData();
        } else {
          print("❌ No school code found");
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print("❌ Error initializing data: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> fetchFeesData() async {
    print("=== FETCHING FEES DATA ===");
    print("Using school code: $schoolCode");

    if (schoolCode == null || schoolCode!.isEmpty) {
      print("❌ Cannot fetch fees: No school code available");
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) throw Exception("No auth token");

      // Replace with your actual fees endpoint
      final uri = Uri.parse("");
      print("Making request to: $uri");

      final response = await http.get(
        uri,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
          'scode': schoolCode!,
        },
      ).timeout(Duration(seconds: 30));

      print("Response status: ${response.statusCode}");
      print("Response body: ${response.body}");

      if (response.statusCode == 200) {
        String responseBody = response.body.trim();

        if (responseBody.isEmpty) {
          throw Exception("Empty response from server");
        }

        int jsonStartIndex = responseBody.indexOf('{');
        if (jsonStartIndex != -1) {
          String jsonString = responseBody.substring(jsonStartIndex);
          final data = jsonDecode(jsonString);

          Map<String, dynamic> dataSource;
          if (data.containsKey('state') && data['state']['status'] == 1) {
            final payload = data['payload'];
            if (payload != null && payload['status'] == 1) {
              dataSource = payload;
            } else {
              throw Exception("Payload error: ${payload?['message'] ?? 'Unknown error'}");
            }
          } else if (data['status'] == 1) {
            dataSource = data;
          } else {
            throw Exception("API returned status: ${data['status']}");
          }

          final feesData = dataSource['data'];

          setState(() {
            studentName = feesData['student_name'] ?? "N/A";
            regNo = feesData['reg_no'] ?? "N/A";
            studentClass = feesData['class_name'] ?? "N/A";
            totalFees = (feesData['total_fees'] ?? 0).toDouble();
            paidFees = (feesData['paid_fees'] ?? 0).toDouble();
            outstandingFees = totalFees - paidFees;

            // Parse fee breakdown
            if (feesData['breakdown'] != null) {
              feeBreakdown = List<Map<String, dynamic>>.from(feesData['breakdown']);
            }

            _isLoading = false;
          });

          print("✅ Fees data loaded successfully");
        } else {
          throw Exception("Server returned non-JSON response");
        }
      } else {
        throw Exception("Server error ${response.statusCode}");
      }
    } on TimeoutException catch (e) {
      print("❌ Request timeout: $e");
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print("❌ Fees fetch error: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _processPayment() async {
    if (_amountController.text.isEmpty) {
      _showErrorDialog("Please enter an amount");
      return;
    }

    double amount = double.tryParse(_amountController.text) ?? 0;

    if (amount <= 0) {
      _showErrorDialog("Please enter a valid amount");
      return;
    }

    if (amount > outstandingFees) {
      _showErrorDialog("Amount exceeds outstanding fees");
      return;
    }

    setState(() {
      _isProcessingPayment = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) throw Exception("No auth token");

      // Replace with your actual payment endpoint
      final uri = Uri.parse("APIEndpoints.initiatePaymentEndpoint");

      final response = await http.post(
        uri,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
          'scode': schoolCode!,
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'amount': amount,
          'payment_method': selectedPaymentMethod,
          'reg_no': regNo,
        }),
      ).timeout(Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['status'] == 1) {
          _showSuccessDialog(amount);
          await fetchFeesData(); // Refresh fees data
        } else {
          _showErrorDialog(data['message'] ?? 'Payment failed');
        }
      } else {
        _showErrorDialog('Payment processing failed');
      }
    } catch (e) {
      print("❌ Payment error: $e");
      _showErrorDialog('An error occurred. Please try again.');
    } finally {
      setState(() {
        _isProcessingPayment = false;
      });
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        title: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red, size: 28.sp),
            SizedBox(width: 12.w),
            Text('Error', style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w600)),
          ],
        ),
        content: Text(message, style: TextStyle(fontSize: 14.sp)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK', style: TextStyle(color: AppColors.primaryBlue)),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(double amount) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        title: Row(
          children: [
            Icon(Icons.check_circle_outline, color: Colors.green, size: 28.sp),
            SizedBox(width: 12.w),
            Text('Success', style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w600)),
          ],
        ),
        content: Text(
          'Payment of ₦${amount.toStringAsFixed(2)} processed successfully!',
          style: TextStyle(fontSize: 14.sp),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _amountController.clear();
            },
            child: Text('OK', style: TextStyle(color: AppColors.primaryBlue)),
          ),
        ],
      ),
    );
  }

  String toTitleCase(String text) {
    if (text.isEmpty) return text;
    return text.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word.substring(0, 1).toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
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
            leading: Container(
              margin: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: IconButton(
                icon: Icon(Icons.arrow_back, color: Colors.white, size: 20.sp),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            title: Text(
              'School Fees Payment',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20.sp,
                fontWeight: FontWeight.w600,
                fontFamily: 'Poppins',
              ),
            ),
            actions: [
              Container(
                margin: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: IconButton(
                  icon: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Icon(
                        Icons.notifications_outlined,
                        color: Colors.white,
                        size: 22.sp,
                      ),
                      Positioned(
                        top: -2,
                        right: -2,
                        child: Container(
                          width: 8.w,
                          height: 8.h,
                          decoration: BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 1),
                          ),
                        ),
                      ),
                    ],
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const NotificationScreen()),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      body: _isLoading
          ? _buildLoadingState()
          : FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: SingleChildScrollView(
            child: Column(
              children: [
                // _buildHeaderSection(),
                _buildFeesOverviewSection(),
                _buildPaymentSection(),
                SizedBox(height: 120.h),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      height: MediaQuery.of(context).size.height,
      decoration: const BoxDecoration(
        color: Colors.white,
      ),
      child: Center(
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
                strokeWidth: 3,
                color: AppColors.primaryBlue,
              ),
            ),
            SizedBox(height: 24.h),
            Text(
              'Loading Fees Information...',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w500,
                color: AppColors.primaryBlue,
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ),
      ),
    );
  }
  //
  // Widget _buildHeaderSection() {
  //   return Container(
  //     width: double.infinity,
  //     padding: EdgeInsets.all(25.w),
  //     decoration: BoxDecoration(
  //       gradient: LinearGradient(
  //         begin: Alignment.topLeft,
  //         end: Alignment.bottomRight,
  //         colors: [
  //           AppColors.primaryBlue,
  //           AppColors.primaryBlue.withOpacity(0.8),
  //         ],
  //       ),
  //     ),
  //     child: Column(
  //       children: [
  //         Container(
  //           padding: EdgeInsets.all(16.w),
  //           decoration: BoxDecoration(
  //             shape: BoxShape.circle,
  //             color: Colors.white.withOpacity(0.2),
  //             border: Border.all(
  //               color: Colors.white.withOpacity(0.3),
  //               width: 2,
  //             ),
  //           ),
  //           child: Icon(
  //             Icons.account_balance_wallet_outlined,
  //             size: 48.sp,
  //             color: Colors.white,
  //           ),
  //         ),
  //         SizedBox(height: 20.h),
  //         Text(
  //           toTitleCase(studentName),
  //           textAlign: TextAlign.center,
  //           style: TextStyle(
  //             fontSize: 22.sp,
  //             fontWeight: FontWeight.w700,
  //             color: Colors.white,
  //             fontFamily: 'Poppins',
  //             letterSpacing: 0.5,
  //           ),
  //         ),
  //         SizedBox(height: 8.h),
  //         Container(
  //           padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
  //           decoration: BoxDecoration(
  //             color: Colors.white.withOpacity(0.2),
  //             borderRadius: BorderRadius.circular(20.r),
  //             border: Border.all(color: Colors.white.withOpacity(0.3)),
  //           ),
  //           child: Text(
  //             '$regNo • $studentClass',
  //             style: TextStyle(
  //               fontSize: 14.sp,
  //               fontWeight: FontWeight.w500,
  //               color: Colors.white,
  //               fontFamily: 'Poppins',
  //             ),
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  Widget _buildFeesOverviewSection() {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.all(20.w),
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryBlue,
            AppColors.primaryBlue.withOpacity(0.9),
          ],
        ),
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryBlue.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Outstanding Balance',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
              color: Colors.white.withOpacity(0.9),
              fontFamily: 'Poppins',
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            '₦${outstandingFees.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 36.sp,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              fontFamily: 'Poppins',
              letterSpacing: 1,
            ),
          ),
          SizedBox(height: 24.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildFeeStatCard(
                'Total Fees',
                '₦${totalFees.toStringAsFixed(2)}',
                Icons.receipt_long_outlined,
              ),
              Container(
                width: 1,
                height: 50.h,
                color: Colors.white.withOpacity(0.3),
              ),
              _buildFeeStatCard(
                'Paid',
                '₦${paidFees.toStringAsFixed(2)}',
                Icons.check_circle_outline,
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Container(
            width: double.infinity,
            height: 8.h,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(4.r),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: totalFees > 0 ? (paidFees / totalFees).clamp(0.0, 1.0) : 0.0,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4.r),
                ),
              ),
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            '${totalFees > 0 ? ((paidFees / totalFees) * 100).toStringAsFixed(1) : '0'}% Paid',
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w500,
              color: Colors.white.withOpacity(0.9),
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeeStatCard(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          color: Colors.white.withOpacity(0.9),
          size: 24.sp,
        ),
        SizedBox(height: 8.h),
        Text(
          label,
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: FontWeight.w500,
            color: Colors.white.withOpacity(0.8),
            fontFamily: 'Poppins',
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          value,
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            fontFamily: 'Poppins',
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentSection() {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(horizontal: 20.w),
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
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
                  color: AppColors.primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(
                  Icons.payment,
                  color: AppColors.primaryBlue,
                  size: 20.sp,
                ),
              ),
              SizedBox(width: 12.w),
              Text(
                'Make Payment',
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
          SizedBox(height: 24.h),
          Text(
            'Amount to Pay',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
              fontFamily: 'Poppins',
            ),
          ),
          SizedBox(height: 12.h),
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: TextField(
              controller: _amountController,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                fontFamily: 'Poppins',
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
              ],
              decoration: InputDecoration(
                hintText: '0.00',
                prefixText: '₦ ',
                prefixStyle: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryBlue,
                  fontFamily: 'Poppins',
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
              ),
            ),
          ),
          SizedBox(height: 12.h),
          Wrap(
            spacing: 8.w,
            children: [
              _buildQuickAmountChip(5000),
              _buildQuickAmountChip(10000),
              _buildQuickAmountChip(20000),
              _buildQuickAmountChip(outstandingFees, label: 'Full'),
            ],
          ),
          SizedBox(height: 24.h),
          Text(
            'Payment Method',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
              fontFamily: 'Poppins',
            ),
          ),
          SizedBox(height: 12.h),
          _buildPaymentMethodCard(
            'wallet',
            'Wallet',
            Icons.account_balance_wallet,
          ),
          SizedBox(height: 30.h),
          SizedBox(
            width: double.infinity,
            height: 56.h,
            child: ElevatedButton(
              onPressed: _isProcessingPayment ? null : _processPayment,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
                elevation: 3,
              ),
              child: _isProcessingPayment
                  ? SizedBox(
                height: 24.h,
                width: 24.w,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
                  : Text(
                'Proceed to Payment',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  fontFamily: 'Poppins',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAmountChip(double amount, {String? label}) {
    return ActionChip(
      label: Text(
        label ?? '₦${amount.toStringAsFixed(0)}',
        style: TextStyle(
          fontSize: 12.sp,
          fontWeight: FontWeight.w600,
          fontFamily: 'Poppins',
        ),
      ),
      onPressed: () {
        setState(() {
          _amountController.text = amount.toStringAsFixed(2);
        });
      },
      backgroundColor: Colors.grey[100],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.r),
        side: BorderSide(color: Colors.grey.shade300),
      ),
    );
  }

  Widget _buildPaymentMethodCard(String value, String label, IconData icon) {
    bool isSelected = selectedPaymentMethod == value;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedPaymentMethod = value;
        });
      },
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryBlue.withOpacity(0.1) : Colors.grey[50],
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: isSelected ? AppColors.primaryBlue : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(10.w),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primaryBlue.withOpacity(0.2)
                    : Colors.grey[200],
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Icon(
                icon,
                color: isSelected ? AppColors.primaryBlue : Colors.grey[600],
                size: 24.sp,
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? AppColors.primaryBlue : Colors.grey[700],
                  fontFamily: 'Poppins',
                ),
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: AppColors.primaryBlue,
                size: 24.sp,
              ),
          ],
        ),
      ),
    );
  }
}