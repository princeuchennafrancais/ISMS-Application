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
  final NavigationSource
  navigationSource; // Optional parameter to track navigation source

  const PaymentScreen({
    super.key,
    required this.loginResponseModel,
    this.navigationSource = NavigationSource.other, // Default value
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _remarkController = TextEditingController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Predefined amount values
  final List<int> predefinedAmounts = [200, 300, 500, 1000, 2000, 3000];

  bool _showAmountLabel = true;

  @override
  void initState() {
    super.initState();
    // Add listener to track when the amount field is empty
    _amountController.addListener(_updateAmountLabelVisibility);

    // Handle different navigation sources
    _handleNavigationSource();
  }

  // Handle behavior based on navigation source
  void _handleNavigationSource() {
    switch (widget.navigationSource) {
      case NavigationSource.button:
        print("🔘 Navigated via Button - Show special behavior");
        // You can show a welcome message, analytics, etc.
        break;
      case NavigationSource.bottomBar:
        print("📱 Navigated via Bottom Bar - Standard navigation");
        // Standard behavior for bottom bar navigation
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

  // Show a message based on navigation source
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

  // Separate method for updating amount label visibility
  void _updateAmountLabelVisibility() {
    if (mounted) {
      setState(() {
        _showAmountLabel = _amountController.text.isEmpty;
      });
    }
  }

  @override
  void dispose() {
    // Remove listeners first to prevent callback on disposed state
    _amountController.removeListener(_updateAmountLabelVisibility);
    _amountController.dispose();
    _remarkController.dispose();
    super.dispose();
  }

  // Update amount when predefined button is pressed
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
      ),
      drawer: TrialCustomDrawer(
        loginResponseModel: widget.loginResponseModel,
        profPic: userData?.fpicture ?? "asset/images/Student.png",
        userName:
            "${userData?.firstname} ${userData?.lastname}" ??
            "Ikegou faith Sochima",
        adno: userData?.adno ?? "RCN/2021/064",
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 29.h),
          child: Center(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  "Make a Payment",
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w500,
                    fontSize: 19.sp,
                  ),
                ),
                SizedBox(height: 30.h),

                // Amount Input Container
                _buildAmountContainer(naira),

                SizedBox(height: 30.h),

                // Remark Field Container
                _buildRemarkContainer(),

                SizedBox(height: 30.h),

                // Continue Button
                ElvButton(
                  text: "Continue",
                  onPressed: () {
                    // Validate amount before navigating
                    if (_validateAmount()) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => PaymentScanner(
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
                ),

                SizedBox(height: 20.h),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Build appropriate app bar leading based on navigation source
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

  // Get appropriate app bar title based on navigation source
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

  // Handle back navigation based on source
  void _handleBackNavigation() {
    switch (widget.navigationSource) {
      case NavigationSource.button:
      case NavigationSource.drawer:
        // Go back to home for button/drawer navigation
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/home',
          (route) => false,
          arguments: widget.loginResponseModel,
        );
        break;
      case NavigationSource.bottomBar:
        // Just pop for bottom bar navigation (likely going back to the same screen with bottom bar)
        Navigator.pop(context);
        break;
      case NavigationSource.other:
      default:
        Navigator.pop(context);
        break;
    }
  }

  // Amount Container Widget
  Widget _buildAmountContainer(String naira) {
    return Container(
      alignment: Alignment.center,
      padding: EdgeInsets.all(22.r),
      decoration: BoxDecoration(
        color: AppColors.lightGray,
        borderRadius: BorderRadius.circular(10.r),
      ),
      width: 380.w,
      constraints: BoxConstraints(minHeight: 265.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Amount",
            style: TextStyle(
              color: Colors.black54,
              fontWeight: FontWeight.w500,
              fontSize: 18.sp,
              fontFamily: "Poppins",
            ),
          ),
          SizedBox(height: 10.h),
          TextFormField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            cursorColor: AppColors.primaryBlue,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              prefixIcon: Padding(
                padding: EdgeInsets.all(12.r),
                child: Text(naira, style: TextStyle(fontSize: 18.sp)),
              ),
              labelText: _showAmountLabel ? '50.00 - 100,000' : null,
              labelStyle: const TextStyle(color: Colors.black54),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: AppColors.primaryBlue),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: AppColors.primaryBlue, width: 2),
              ),
              filled: false,
            ),
          ),
          SizedBox(height: 20.h),

          // Predefined Amount Buttons
          _buildAmountButtonGrid(naira),
        ],
      ),
    );
  }

  // Grid of Predefined Amount Buttons
  Widget _buildAmountButtonGrid(String naira) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: predefinedAmounts.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 10.h,
        crossAxisSpacing: 10.w,
        childAspectRatio: 2.5,
      ),
      itemBuilder: (context, index) {
        return ElevatedButton(
          onPressed: () => _setAmount(predefinedAmounts[index]),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryBlue,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.r),
            ),
          ),
          child: Text(
            '$naira${predefinedAmounts[index]}',
            style: TextStyle(color: Colors.white, fontSize: 14.sp),
          ),
        );
      },
    );
  }

  // Remark Container Widget
  Widget _buildRemarkContainer() {
    return Container(
      alignment: Alignment.center,
      padding: EdgeInsets.all(22.r),
      decoration: BoxDecoration(
        color: AppColors.lightGray,
        borderRadius: BorderRadius.circular(10.r),
      ),
      width: 380.w,
      constraints: BoxConstraints(minHeight: 140.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Remark",
            style: TextStyle(
              color: Colors.black54,
              fontWeight: FontWeight.w500,
              fontSize: 18.sp,
              fontFamily: "Poppins",
            ),
          ),
          TextFormField(
            controller: _remarkController,
            textInputAction: TextInputAction.done,
            cursorColor: AppColors.primaryBlue,
            decoration: InputDecoration(
              labelText: "What's this for? (optional)",
              labelStyle: TextStyle(fontSize: 14.sp),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: AppColors.primaryBlue),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: AppColors.primaryBlue, width: 2),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Validate amount before proceeding
  bool _validateAmount() {
    if (_amountController.text.isEmpty) {
      return false;
    }

    final amount = int.tryParse(_amountController.text) ?? 0;
    return amount >= 5 && amount <= 100000;
  }

  // Show error message for invalid amount
  void _showAmountError() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Please enter an amount between ₦5 and ₦100,000'),
        backgroundColor: Colors.red,
      ),
    );
  }
}
