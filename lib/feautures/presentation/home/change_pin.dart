import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:wallet/core/controllers/methods_controller.dart';
import 'package:wallet/core/utils/color_utils/color_util.dart';
import 'package:wallet/core/utils/widget_utils/custom_snackbar.dart';
import 'package:wallet/feautures/presentation/home/notification_screen.dart';

class ChangePin extends StatefulWidget {
  const ChangePin({super.key});

  @override
  State<ChangePin> createState() => _ChangePinState();
}

class _ChangePinState extends State<ChangePin> with TickerProviderStateMixin {
  final TextEditingController _oldPinController = TextEditingController();
  final TextEditingController _newPinController = TextEditingController();
  final TextEditingController _confirmPinController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  AuthController authController = AuthController();

  bool _isLoading = false;
  bool _isPasswordVisible = false;

  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  @override
  void dispose() {
    _oldPinController.dispose();
    _newPinController.dispose();
    _confirmPinController.dispose();
    _passwordController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
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

  void _handleChangePin() async {
    // Validation
    if (_oldPinController.text.isEmpty) {
      CustomSnackbar.error("Please enter your old pin");
      return;
    }

    if (_newPinController.text.isEmpty) {
      CustomSnackbar.error("Please enter your new pin");
      return;
    }

    if (_confirmPinController.text.isEmpty) {
      CustomSnackbar.error("Please confirm your new pin");
      return;
    }

    if (_passwordController.text.isEmpty) {
      CustomSnackbar.error("Please enter your password");
      return;
    }

    if (_newPinController.text != _confirmPinController.text) {
      CustomSnackbar.error("New pin and confirm pin do not match");
      return;
    }

    if (_newPinController.text.length != 4) {
      CustomSnackbar.error("Pin must be 4 digits");
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await authController.changePin(
        oldPin: _oldPinController.text,
        newPin: _newPinController.text,
        password: _passwordController.text,
        context: context,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                icon: Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20.sp),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            title: Text(
              'Change PIN',
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
                child: Stack(
                  children: [
                    IconButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => NotificationScreen()),
                        );
                      },
                      icon: Icon(
                        Icons.notifications_outlined,
                        color: Colors.white,
                        size: 20.sp,
                      ),
                    ),
                    Positioned(
                      top: 8.h,
                      right: 8.w,
                      child: Container(
                        width: 8.w,
                        height: 8.h,
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: Container(
            height: MediaQuery.of(context).size.height,
            decoration: const BoxDecoration(
              color: Colors.white,
            ),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildHeaderSection(),
                  _buildFormSection(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(30.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryBlue,
            AppColors.primaryBlue.withOpacity(0.8),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(color: Colors.white.withOpacity(0.3)),
            ),
            child: Icon(
              Icons.pin_outlined,
              color: Colors.white,
              size: 40.sp,
            ),
          ),
          SizedBox(height: 20.h),
          Text(
            'Change Transaction PIN',
            style: TextStyle(
              fontSize: 28.sp,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              fontFamily: 'Poppins',
              letterSpacing: 0.5,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Update your transaction PIN to keep\nyour account secure',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16.sp,
              color: Colors.white.withOpacity(0.8),
              fontFamily: 'Poppins',
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormSection() {
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
        padding: EdgeInsets.all(30.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(),
            SizedBox(height: 30.h),
            _buildFormField(
              label: 'Current PIN',
              hint: 'Enter your current PIN',
              controller: _oldPinController,
              icon: Icons.lock_outline_rounded,
              isPin: true,
            ),
            SizedBox(height: 20.h),
            _buildFormField(
              label: 'New PIN',
              hint: 'Enter your new PIN',
              controller: _newPinController,
              icon: Icons.fiber_new_rounded,
              isPin: true,
            ),
            SizedBox(height: 20.h),
            _buildFormField(
              label: 'Confirm New PIN',
              hint: 'Confirm your new PIN',
              controller: _confirmPinController,
              icon: Icons.check_circle_outline_rounded,
              isPin: true,
            ),
            SizedBox(height: 20.h),
            _buildPasswordField(),
            SizedBox(height: 40.h),
            _buildChangeButton(),
            SizedBox(height: 30.h),
            _buildSecurityTip(),
          ],
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
            'SECURITY UPDATE',
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
          'PIN Details',
          style: TextStyle(
            fontSize: 24.sp,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
            fontFamily: 'Poppins',
          ),
        ),
        SizedBox(height: 6.h),
        Text(
          'Please fill in the required information to update your transaction PIN',
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

  Widget _buildFormField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required IconData icon,
    bool isPin = false,
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
          child: TextField(
            controller: controller,
            keyboardType: isPin ? TextInputType.number : TextInputType.text,
            maxLength: isPin ? 4 : null,
            obscureText: isPin,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w500,
              fontFamily: 'Poppins',
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: Colors.grey[500],
                fontSize: 16.sp,
                fontFamily: 'Poppins',
              ),
              prefixIcon: Container(
                padding: EdgeInsets.all(12.w),
                margin: EdgeInsets.only(right: 12.w),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(
                  icon,
                  color: AppColors.primaryBlue,
                  size: 20.sp,
                ),
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 18.h),
              counterText: '',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Password Verification',
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
          child: TextField(
            controller: _passwordController,
            obscureText: !_isPasswordVisible,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w500,
              fontFamily: 'Poppins',
            ),
            decoration: InputDecoration(
              hintText: 'Enter your password',
              hintStyle: TextStyle(
                color: Colors.grey[500],
                fontSize: 16.sp,
                fontFamily: 'Poppins',
              ),
              prefixIcon: Container(
                padding: EdgeInsets.all(12.w),
                margin: EdgeInsets.only(right: 12.w),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(
                  Icons.password_rounded,
                  color: AppColors.primaryBlue,
                  size: 20.sp,
                ),
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _isPasswordVisible
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: Colors.grey[600],
                  size: 20.sp,
                ),
                onPressed: () {
                  setState(() {
                    _isPasswordVisible = !_isPasswordVisible;
                  });
                },
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 18.h),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChangeButton() {
    return Container(
      width: double.infinity,
      height: 56.h,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16.r),
        gradient: _isLoading
            ? LinearGradient(
          colors: [Colors.grey.shade400, Colors.grey.shade500],
        )
            : LinearGradient(
          colors: [
            AppColors.primaryBlue,
            AppColors.primaryBlue.withOpacity(0.8),
          ],
        ),
        boxShadow: !_isLoading
            ? [
          BoxShadow(
            color: AppColors.primaryBlue.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isLoading ? null : _handleChangePin,
          borderRadius: BorderRadius.circular(16.r),
          child: Center(
            child: _isLoading
                ? Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 20.w,
                  height: 20.h,
                  child: const CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                ),
                SizedBox(width: 12.w),
                Text(
                  'Processing...',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            )
                : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.security_update_good_rounded,
                  color: Colors.white,
                  size: 22.sp,
                ),
                SizedBox(width: 12.w),
                Text(
                  'Update PIN',
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
    );
  }

  Widget _buildSecurityTip() {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: AppColors.primaryBlue.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.security_rounded,
              color: AppColors.primaryBlue,
              size: 20.sp,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Security Tip',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryBlue,
                    fontFamily: 'Poppins',
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  'Choose a PIN that\'s easy for you to remember but hard for others to guess. Avoid using sequential numbers or your birth date.',
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: Colors.grey[700],
                    fontFamily: 'Poppins',
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}