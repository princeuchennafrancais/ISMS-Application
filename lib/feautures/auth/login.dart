import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:wallet/core/controllers/methods_controller.dart';
import 'package:wallet/core/controllers/token_service.dart';
import 'package:wallet/core/utils/color_utils/color_util.dart';
import 'package:wallet/core/utils/widget_utils/auth_txt_field.dart';
import 'package:wallet/core/utils/widget_utils/obscure_auth_textField.dart';
import 'package:wallet/feautures/auth/contact_admin.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';
import 'dart:io';

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

  // Network monitoring
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;
  bool _hasInternet = true;
  String _networkMessage = '';
  late AnimationController _networkBannerController;
  late Animation<Offset> _networkBannerSlideAnimation;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  AuthController loginuser = AuthController();

  @override
  void initState() {
    super.initState();

    // Main animation controller
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

    // Network banner animation controller
    _networkBannerController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _networkBannerSlideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _networkBannerController,
      curve: Curves.easeOut,
    ));

    _animationController.forward();

    // Start monitoring network
    _initNetworkMonitoring();
  }

  void _initNetworkMonitoring() {
    // Initial check
    _checkNetworkConnection();

    // Listen to connectivity changes
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen(
          (List<ConnectivityResult> results) {
        _checkNetworkConnection();
      },
    );
  }

  Future<void> _checkNetworkConnection() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();

      // Check if there's any connection
      final hasConnection = !connectivityResult.contains(ConnectivityResult.none);

      if (!hasConnection) {
        // No connection at all
        _updateNetworkStatus(false, 'No internet connection');
        return;
      }

      // Check actual internet connectivity (not just WiFi/mobile connection)
      try {
        final result = await InternetAddress.lookup('google.com')
            .timeout(const Duration(seconds: 5));

        if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
          // Internet is available
          _updateNetworkStatus(true, '');
        } else {
          _updateNetworkStatus(false, 'No internet connection');
        }
      } on SocketException catch (_) {
        _updateNetworkStatus(false, 'No internet connection');
      } on TimeoutException catch (_) {
        _updateNetworkStatus(false, 'Slow or no internet connection');
      }
    } catch (e) {
      print('Error checking network: $e');
      _updateNetworkStatus(false, 'Unable to verify connection');
    }
  }

  void _updateNetworkStatus(bool hasInternet, String message) {
    if (!mounted) return;

    setState(() {
      _hasInternet = hasInternet;
      _networkMessage = message;
    });

    if (!hasInternet) {
      // Show banner
      _networkBannerController.forward();
    } else {
      // Hide banner after a delay if connection restored
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted && _hasInternet) {
          _networkBannerController.reverse();
        }
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _networkBannerController.dispose();
    _connectivitySubscription.cancel();
    regNumber.dispose();
    password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          SafeArea(
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

          // Network status banner
          _buildNetworkBanner(),
        ],
      ),
    );
  }

  Widget _buildNetworkBanner() {
    if (_hasInternet) {
      return SlideTransition(
        position: _networkBannerSlideAnimation,
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          decoration: BoxDecoration(
            color: Colors.green.shade600,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: SafeArea(
            bottom: false,
            child: Row(
              children: [
                Icon(
                  Icons.wifi_rounded,
                  color: Colors.white,
                  size: 20.sp,
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Text(
                    'Connection restored',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
                Icon(
                  Icons.check_circle_rounded,
                  color: Colors.white,
                  size: 18.sp,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SlideTransition(
      position: _networkBannerSlideAnimation,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: Colors.red.shade600,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: SafeArea(
          bottom: false,
          child: Row(
            children: [
              Icon(
                Icons.wifi_off_rounded,
                color: Colors.white,
                size: 20.sp,
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _networkMessage,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      'Please check your connection',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 11.sp,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.refresh_rounded,
                  color: Colors.white,
                  size: 20.sp,
                ),
                onPressed: _checkNetworkConnection,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
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
            onPressed: (_isLoading || !_hasInternet)
                ? null
                : () async {
              if (_formKey.currentState!.validate()) {
                // Check network before attempting login
                await _checkNetworkConnection();

                if (!_hasInternet) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          Icon(Icons.wifi_off, color: Colors.white),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: Text('No internet connection. Please try again.'),
                          ),
                        ],
                      ),
                      backgroundColor: Colors.red.shade600,
                      behavior: SnackBarBehavior.floating,
                      margin: EdgeInsets.all(16.w),
                      duration: const Duration(seconds: 3),
                    ),
                  );
                  return;
                }

                setState(() => _isLoading = true);

                final fcmToken = await TokenService().getFCMToken();

                await loginuser.loginUser(
                  password: password.text,
                  userName: regNumber.text,
                  fcmToken: fcmToken ?? "",
                  context: context,
                );

                if (mounted) {
                  setState(() => _isLoading = false);
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: !_hasInternet
                  ? Colors.grey.shade400
                  : AppColors.primaryBlue,
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
                : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (!_hasInternet) ...[
                  Icon(
                    Icons.wifi_off_rounded,
                    size: 18.sp,
                  ),
                  SizedBox(width: 8.w),
                ],
                Text(
                  !_hasInternet ? "No Connection" : "Sign In",
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    fontFamily: "Poppins",
                  ),
                ),
              ],
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