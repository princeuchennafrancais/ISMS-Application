import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:wallet/core/models/login_model.dart';
import 'package:wallet/core/utils/color_utils/color_util.dart';
import 'package:wallet/core/utils/widget_utils/elv_button.dart';
import 'package:wallet/core/utils/widget_utils/trial_custom_drawer.dart';
import 'package:wallet/feautures/presentation/home/payment_scanner.dart';
import 'package:wallet/core/enum/navigation_source.dart';

class PaymentScreen extends StatefulWidget {
  final LoginResponseModel loginResponseModel;
  final NavigationSource navigationSource;

  const PaymentScreen({
    super.key,
    required this.loginResponseModel,
    this.navigationSource = NavigationSource.other,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _remarkController = TextEditingController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final List<int> predefinedAmounts = [200, 300, 500, 1000, 2000, 3000];
  bool _showAmountLabel = true;

  @override
  void initState() {
    super.initState();
    _amountController.addListener(_updateAmountLabelVisibility);
    _handleNavigationSource();
  }

  void _handleNavigationSource() {
    switch (widget.navigationSource) {
      case NavigationSource.button:
        print("🔘 Navigated via Button - Show special behavior");
        break;
      case NavigationSource.bottomBar:
        print("📱 Navigated via Bottom Bar - Standard navigation");
        break;
      case NavigationSource.drawer:
        print("📋 Navigated via Drawer - Menu navigation");
        _showNavigationMessage("Payment accessed from menu.");
        break;
      case NavigationSource.other:
      default:
        print("❓ Navigation source unknown");
        break;
    }
  }

  void _showNavigationMessage(String message) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            duration: Duration(seconds: 2),
            backgroundColor: AppColors.primaryBlue,
          ),
        );
      }
    });
  }

  void _updateAmountLabelVisibility() {
    if (mounted) {
      setState(() {
        _showAmountLabel = _amountController.text.isEmpty;
      });
    }
  }

  @override
  void dispose() {
    _amountController.removeListener(_updateAmountLabelVisibility);
    _amountController.dispose();
    _remarkController.dispose();
    super.dispose();
  }

  void _setAmount(int amount) {
    _amountController.text = amount.toString();
  }

  @override
  Widget build(BuildContext context) {
    final naira = '\u20A6';
    final userData = widget.loginResponseModel.data;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: _buildAppBarLeading(),
        centerTitle: true,
        title: Text(
          _getAppBarTitle(),
          style: TextStyle(
            color: AppColors.primaryBlue,
            fontWeight: FontWeight.w600,
            fontSize: 18.sp,
          ),
        ),
      ),
      drawer: TrialCustomDrawer(
        loginResponseModel: widget.loginResponseModel,
        profPic: userData?.fpicture ?? "asset/images/Student.png",
        userName: "${userData?.firstname} ${userData?.lastname}" ?? "Ikegou faith Sochima",
        adno: userData?.adno ?? "RCN/2021/064",
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 24.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Section
              _buildHeaderSection(),
              SizedBox(height: 32.h),

              // Amount Section
              _buildAmountSection(naira),
              SizedBox(height: 24.h),

              // Remark Section
              _buildRemarkSection(),
              SizedBox(height: 32.h),

              // Continue Button - FIXED: Added constraints
              SizedBox(
                width: double.infinity,
                child: _buildContinueButton(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Make a Payment",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w700,
            fontSize: 28.sp,
            height: 1.2,
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          "Enter payment details to continue",
          style: TextStyle(
            color: Colors.black54,
            fontWeight: FontWeight.w400,
            fontSize: 14.sp,
          ),
        ),
      ],
    );
  }

  Widget _buildAmountSection(String naira) {
    return Container(
      padding: EdgeInsets.all(24.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: Colors.grey.shade100,
          width: 1,
        ),
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
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.currency_exchange,
                  color: AppColors.primaryBlue,
                  size: 20.sp,
                ),
              ),
              SizedBox(width: 12.w),
              Text(
                "Amount",
                style: TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.w600,
                  fontSize: 16.sp,
                ),
              ),
            ],
          ),
          SizedBox(height: 20.h),

          // Amount Input Field - FIXED: Better prefix icon alignment
          Container(
            decoration: BoxDecoration(
              color: AppColors.lightGray.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: TextFormField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              cursorColor: AppColors.primaryBlue,
              textInputAction: TextInputAction.done,
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
              decoration: InputDecoration(
                prefixIcon: Container(
                  width: 40.w,
                  alignment: Alignment.center,
                  child: Text(
                    naira,
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ),
                hintText: '50.00 - 100,000',
                hintStyle: TextStyle(
                  color: Colors.black54,
                  fontSize: 16.sp,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16.w,
                  vertical: 16.h,
                ),
              ),
            ),
          ),
          SizedBox(height: 24.h),

          // Quick Amount Section
          Text(
            "Quick Amount",
            style: TextStyle(
              color: Colors.black54,
              fontWeight: FontWeight.w500,
              fontSize: 14.sp,
            ),
          ),
          SizedBox(height: 12.h),

          // Predefined Amount Buttons - FIXED: Using Wrap instead of GridView
          _buildAmountButtonGrid(naira),
        ],
      ),
    );
  }

  Widget _buildAmountButtonGrid(String naira) {
    return Wrap(
      spacing: 12.w,
      runSpacing: 12.h,
      children: predefinedAmounts.map((amount) {
        return GestureDetector(
          onTap: () => _setAmount(amount),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(
                color: AppColors.primaryBlue.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Text(
              '$naira$amount',
              style: TextStyle(
                color: AppColors.primaryBlue,
                fontWeight: FontWeight.w600,
                fontSize: 14.sp,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRemarkSection() {
    return Container(
      padding: EdgeInsets.all(24.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: Colors.grey.shade100,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.r),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.note_alt_outlined,
                  color: Colors.orange,
                  size: 20.sp,
                ),
              ),
              SizedBox(width: 12.w),
              Text(
                "Remark",
                style: TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.w600,
                  fontSize: 16.sp,
                ),
              ),
            ],
          ),
          SizedBox(height: 20.h),
          Container(
            decoration: BoxDecoration(
              color: AppColors.lightGray.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: TextFormField(
              controller: _remarkController,
              textInputAction: TextInputAction.done,
              cursorColor: AppColors.primaryBlue,
              maxLines: 2,
              style: TextStyle(
                fontSize: 16.sp,
                color: Colors.black87,
              ),
              decoration: InputDecoration(
                hintText: "What's this for? (optional)",
                hintStyle: TextStyle(
                  color: Colors.black54,
                  fontSize: 14.sp,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16.w,
                  vertical: 16.h,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContinueButton() {
    return Container(
      height: 56.h,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryBlue,
            AppColors.primaryBlue.withOpacity(0.8),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryBlue.withOpacity(0.3),
            blurRadius: 15,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: () {
          if (_validateAmount()) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PaymentScanner(
                  amount: _amountController.text,
                  description: _remarkController.text,
                  ResponseModel: widget.loginResponseModel,
                ),
              ),
            );
          } else {
            _showAmountError();
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
        ),
        child: Text(
          "Continue",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 16.sp,
          ),
        ),
      ),
    );
  }

  Widget _buildAppBarLeading() {
    switch (widget.navigationSource) {
      case NavigationSource.bottomBar:
        return GestureDetector(
          child: Icon(Icons.menu, color: AppColors.primaryBlue, size: 28.sp),
          onTap: () => _scaffoldKey.currentState!.openDrawer(),
        );
      case NavigationSource.button:
      case NavigationSource.drawer:
      case NavigationSource.other:
      default:
        return GestureDetector(
          child: Icon(
            Icons.arrow_back_ios,
            color: AppColors.primaryBlue,
            size: 28.sp,
          ),
          onTap: () => Navigator.pop(context),
        );
    }
  }

  String _getAppBarTitle() {
    switch (widget.navigationSource) {
      case NavigationSource.button:
        return "Quick Payment";
      case NavigationSource.bottomBar:
        return "Payment";
      case NavigationSource.drawer:
        return "Menu Payment";
      case NavigationSource.other:
      default:
        return "Make Payment";
    }
  }

  bool _validateAmount() {
    if (_amountController.text.isEmpty) {
      return false;
    }
    final amount = int.tryParse(_amountController.text) ?? 0;
    return amount >= 5 && amount <= 100000;
  }

  void _showAmountError() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Please enter an amount between ₦5 and ₦100,000'),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
      ),
    );
  }
}