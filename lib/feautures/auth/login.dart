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
  late Animation<Offset> _slideAnimation;

  AuthController loginuser = AuthController();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
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
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
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
      body: Form(
        key: _formKey,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primaryBlue,
                AppColors.primaryBlue.withOpacity(0.8),
                AppColors.primaryBlue.withOpacity(0.9),
              ],
            ),
          ),
          child: Column(
            children: [
              SizedBox(height: 20.h,),
              _buildModernHeader(),
              _buildMainContent(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernHeader() {
    return Container(
      height: 270.h,
      padding: EdgeInsets.only(left: 30.w, top: 50.h, right: 30.w),
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: EdgeInsets.all(12.w),
                    height: 120.h,
                    width: 120.w,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14.r),
                      border: Border.all(
                        color: Colors.transparent,
                        width: 1,
                      ),
                    ),
                    child: SchoolLogoWidget(
                      width: 46.w,
                      height: 46.w,
                      borderRadius: BorderRadius.circular(60.r), // makes it circular
                      fallbackAsset: "assets/icons/Untitled-3.png", // optional
                      fit: BoxFit.cover,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10.h),
              Text(
                "Welcome Back!",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32.sp,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                "Sign in to continue",
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 16.sp,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainContent(BuildContext context) {
    return Expanded(
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Container(
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
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 30.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(height: 50.h),
                  _buildWelcomeSection(),
                  SizedBox(height: 40.h),
                  _buildModernLoginForm(context),
                  SizedBox(height: 30.h),
                  _buildForgotPassword(),
                  _buildRegisterSection(),
                  SizedBox(height: 30.h),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
          decoration: BoxDecoration(
            color: AppColors.primaryBlue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10.r),
          ),
          child: Text(
            "Student Portal",
            style: TextStyle(
              color: AppColors.primaryBlue,
              fontSize: 14.sp,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
        ),
        SizedBox(height: 15.h),
        Text(
          "Enter your credentials to access\nyour wallet system",
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 16.sp,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w400,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildModernLoginForm(BuildContext context) {
    return Column(
      children: [
        // Registration Number Field
        Container(
          margin: EdgeInsets.only(bottom: 20.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(11.r),
            color: Colors.grey[50],
            border: Border.all(color: Colors.grey[200]!),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: AuthTxtField(
            controller: regNumber,
            prfix_url: "assets/icons/Vector.png",
            text: "Registration Number",
            err_txt: "Enter Your RegNumber",
          ),
        ),

        // Password Field
        Container(
          margin: EdgeInsets.only(bottom: 40.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(11.r),
            color: Colors.grey[50],
            border: Border.all(color: Colors.grey[200]!),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
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
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: AppColors.primaryBlue.withOpacity(0.7),
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

        // Modern Sign In Button
        Container(
          width: double.infinity,
          height: 56.h,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10.r),
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
              onTap: _isLoading
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
              borderRadius: BorderRadius.circular(16.r),
              child: Center(
                child: _isLoading
                    ? SizedBox(
                  width: 24.w,
                  height: 24.h,
                  child: const CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                )
                    : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Sign In",
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        fontFamily: "Poppins",
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Icon(
                      Icons.arrow_forward_rounded,
                      color: Colors.white,
                      size: 20.sp,
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

  Widget _buildForgotPassword() {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 20.h),
      child: TextButton(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (context)=> ContactAdminScreen() ));
        },
        style: TextButton.styleFrom(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
        ),
        child: Text(
          "Forgot Password?",
          style: TextStyle(
            color: AppColors.primaryBlue,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w500,
            fontSize: 16.sp,
          ),
        ),
      ),
    );
  }

  Widget _buildRegisterSection() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: 16.w,
          vertical: 8.h,
        ),
        // decoration: BoxDecoration(
        //   color: Colors.white,
        //   borderRadius: BorderRadius.circular(12.r),
        //   border: Border.all(
        //     color: const Color(0xFFE2E8F0),
        //     width: 1,
        //   ),
        //   boxShadow: [
        //     BoxShadow(
        //       color: const Color(0xFF1E3A5F).withOpacity(0.05),
        //       blurRadius: 8,
        //       offset: const Offset(0, 2),
        //     ),
        //   ],
        // ),
        child: Image.asset(
          "assets/images/Powered by.png",
          height: 50.h,
          width: 216.w,
          // Added error handling for missing image
          errorBuilder: (context, error, stackTrace) {
            return SizedBox(
              height: 30.h,
              width: 166.w,
              child: Center(
                child: Text(
                  "Powered by Your Company",
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: const Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}