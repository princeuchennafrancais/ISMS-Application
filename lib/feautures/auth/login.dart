import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:wallet/core/controllers/methods_controller.dart';
import 'package:wallet/core/controllers/token_service.dart';
import 'package:wallet/core/utils/color_utils/color_util.dart';
import 'package:wallet/core/utils/widget_utils/auth_txt_field.dart';
import 'package:wallet/core/utils/widget_utils/obscure_auth_textField.dart';
import 'package:wallet/feautures/auth/contact_admin.dart';

import '../../core/utils/widget_utils/school_logo.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {
  TextEditingController regNumber = TextEditingController();
  TextEditingController password = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isPasswordVisible = false;
  bool _isLoading = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  AuthController loginuser = AuthController();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(height: 120.h),
                    _buildLogoSection(),
                    SizedBox(height: 70.h),
                    _buildWelcomeText(),
                    SizedBox(height: 40.h),
                    _buildLoginForm(context),
                    SizedBox(height: 20.h),
                    _buildForgotPassword(),
                    SizedBox(height: 40.h),
                    _buildFooter(),
                    SizedBox(height: 30.h),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogoSection() {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: AppColors.primaryBlue.withOpacity(0.08),
            shape: BoxShape.circle,
          ),
          child: Container(
            width: 100.w,
            height: 100.w,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryBlue.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: SchoolLogoWidget(
              width: 100.w,
              height: 100.w,
              borderRadius: BorderRadius.circular(50.r),
              fallbackAsset: "assets/icons/Untitled-3.png",
              fit: BoxFit.cover,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWelcomeText() {
    return Column(
      children: [
        Text(
          "Welcome Back!",
          style: TextStyle(
            color: AppColors.primaryBlue,
            fontSize: 28.sp,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          "Sign in to your wallet",
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 15.sp,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  Widget _buildLoginForm(BuildContext context) {
    return Column(
      children: [
        // Registration Number Field
        Container(
          decoration: BoxDecoration(
            color: AppColors.primaryBlue.withOpacity(0.04),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: AppColors.primaryBlue.withOpacity(0.1),
              width: 1.5,
            ),
          ),
          child: AuthTxtField(
            controller: regNumber,
            prfix_url: "assets/icons/Vector.png",
            text: "Registration Number",
            err_txt: "Enter Your RegNumber",
          ),
        ),

        SizedBox(height: 16.h),

        // Password Field
        Container(
          decoration: BoxDecoration(
            color: AppColors.primaryBlue.withOpacity(0.04),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: AppColors.primaryBlue.withOpacity(0.1),
              width: 1.5,
            ),
          ),
          child: ObscureAuthTxtField(
            controller: password,
            err_txt: "Enter Your Password",
            prfix_url: "assets/icons/Vector (1).png",
            text: "Password",
            isPassword: true,
            obscureText: !_isPasswordVisible,
            suffixIcon: IconButton(
              icon: Icon(
                _isPasswordVisible
                    ? Icons.visibility_rounded
                    : Icons.visibility_off_rounded,
                color: AppColors.primaryBlue.withOpacity(0.6),
                size: 22.sp,
              ),
              onPressed: () {
                setState(() {
                  _isPasswordVisible = !_isPasswordVisible;
                });
              },
            ),
          ),
        ),

        SizedBox(height: 32.h),

        // Sign In Button
        Container(
          width: double.infinity,
          height: 54.h,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12.r),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryBlue.withOpacity(0.25),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: _isLoading
                ? null
                : () async {
              if (_formKey.currentState!.validate()) {
                setState(() => _isLoading = true);

                final fcmToken = await TokenService().getFCMToken();

                await loginuser.loginUser(
                  password: password.text,
                  userName: regNumber.text,
                  fcmToken: fcmToken ?? "",
                  context: context,
                );
                setState(() => _isLoading = false);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
            child: _isLoading
                ? SizedBox(
              width: 22.w,
              height: 22.h,
              child: const CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2.5,
              ),
            )
                : Text(
              "Sign In",
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                fontFamily: "Poppins",
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildForgotPassword() {
    return TextButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ContactAdminScreen()),
        );
      },
      style: TextButton.styleFrom(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      ),
      child: Text(
        "Forgot Password?",
        style: TextStyle(
          color: AppColors.primaryBlue.withOpacity(0.8),
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w500,
          fontSize: 14.sp,
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Column(
      children: [
        // Container(
        //   padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 20.w),
        //   decoration: BoxDecoration(
        //     color: AppColors.primaryBlue.withOpacity(0.05),
        //     borderRadius: BorderRadius.circular(20.r),
        //   ),
        //   child: Text(
        //     "Student & Vendor Portal",
        //     style: TextStyle(
        //       color: AppColors.primaryBlue.withOpacity(0.7),
        //       fontSize: 12.sp,
        //       fontFamily: 'Poppins',
        //       fontWeight: FontWeight.w500,
        //     ),
        //   ),
        // ),
        SizedBox(height: 20.h),
        Image.asset(
          "assets/images/Powered by.png",
          height: 40.h,
          width: 180.w,
          errorBuilder: (context, error, stackTrace) {
            return Text(
              "Powered by Your Company",
              style: TextStyle(
                fontSize: 11.sp,
                color: Colors.grey[400],
                fontWeight: FontWeight.w500,
              ),
            );
          },
        ),
      ],
    );
  }
}