import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
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
import '../presentation/home/index_screen.dart';

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
  bool _showFingerprintOption = false;
  bool _isCheckingBiometrics = false;

  // Network monitoring
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;
  bool _hasInternet = true;
  String _networkMessage = '';
  late AnimationController _networkBannerController;
  late Animation<Offset> _networkBannerSlideAnimation;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Fingerprint authentication
  final LocalAuthentication _localAuth = LocalAuthentication();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  bool _isBiometricAvailable = false;
  List<BiometricType> _availableBiometrics = [];

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

    // FIX: Check biometrics first, THEN check if should show fingerprint
    _initializeFingerprint();
  }

// NEW METHOD: Properly sequence the biometric checks
  Future<void> _initializeFingerprint() async {
    // Step 1: Check biometric availability
    await _checkBiometricAvailability();

    // Step 2: After biometrics are checked, see if we should show fingerprint
    await _checkIfShouldShowFingerprint();

    print('✅ FINGERPRINT INITIALIZATION COMPLETE');
    print('   - Show fingerprint option: $_showFingerprintOption');
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

  Future<void> _checkBiometricAvailability() async {
    try {
      setState(() {
        _isCheckingBiometrics = true;
      });

      // Ensure these complete before continuing
      _isBiometricAvailable = await _localAuth.canCheckBiometrics;
      _availableBiometrics = await _localAuth.getAvailableBiometrics();

      print('🔍 BIOMETRICS DEBUG:');
      print('   - Can check biometrics: $_isBiometricAvailable');
      print('   - Available biometrics: $_availableBiometrics');

      setState(() {
        _isCheckingBiometrics = false;
      });
    } catch (e) {
      print('❌ Error checking biometrics: $e');
      setState(() {
        _isCheckingBiometrics = false;
        _isBiometricAvailable = false;
      });
    }
  }

  Future<void> _checkIfShouldShowFingerprint() async {
    // Check if user has previously logged in and saved credentials
    final hasStoredCredentials = await _hasStoredAuthToken();

    // Use the CURRENT state values (not recalculating)
    final isBiometricAvailable = _isBiometricAvailable && _availableBiometrics.isNotEmpty;

    print('🔍 FINGERPRINT DEBUG:');
    print('   - Has stored credentials: $hasStoredCredentials');
    print('   - Is biometric available: $isBiometricAvailable');
    print('   - Biometric types: $_availableBiometrics');
    print('   - Should show fingerprint: ${hasStoredCredentials && isBiometricAvailable}');

    if (mounted) {
      setState(() {
        _showFingerprintOption = hasStoredCredentials && isBiometricAvailable;
      });
    }
  }
  Future<bool> _hasStoredAuthToken() async {
    try {
      final tokenService = TokenService();
      final token = await tokenService.getAuthToken();

      print('🔍 TOKEN DEBUG:');
      print('   - Retrieved token: ${token != null ? "${token.substring(0, 20)}..." : "NULL"}');
      print('   - Token is not empty: ${token != null && token.isNotEmpty}');

      return token != null && token.isNotEmpty;
    } catch (e) {
      print('❌ Error reading auth token: $e');
      return false;
    }
  }

  Future<String?> _getStoredAuthToken() async {
    try {
      final tokenService = TokenService();
      return await tokenService.getAuthToken();
    } catch (e) {
      print('Error getting auth token: $e');
      return null;
    }
  }

  Future<void> _storeAuthToken(String token) async {
    try {
      final tokenService = TokenService();
      await tokenService.storeAuthToken(token);

      // After storing token, check if we can show fingerprint option next time
      await _checkBiometricAvailability();
      if (_isBiometricAvailable && _availableBiometrics.isNotEmpty) {
        if (mounted) {
          setState(() {
            _showFingerprintOption = true;
          });
        }
      }
    } catch (e) {
      print('Error storing auth token: $e');
    }
  }

  Future<void> _clearStoredAuthToken() async {
    try {
      final tokenService = TokenService();
      await tokenService.clearAllTokens();
      if (mounted) {
        setState(() {
          _showFingerprintOption = false;
        });
      }
    } catch (e) {
      print('Error clearing auth token: $e');
    }
  }

  Future<bool> _authenticateWithFingerprint() async {
    try {
      print('🔐 Starting fingerprint authentication...');

      // Check if biometrics are available
      final canAuthenticate = await _localAuth.canCheckBiometrics;
      if (!canAuthenticate) {
        _showBiometricError('Biometric authentication not available');
        return false;
      }

      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Authenticate with fingerprint \n      to login to your wallet',
        biometricOnly: true,
        // useErrorDialogs: true,
        // stickyAuth: false,
      );

      print('🔐 Fingerprint result: $authenticated');
      return authenticated;

    } catch (e) {
      print('❌ Fingerprint authentication error: $e');

      // Handle specific error types
      if (e.toString().contains('FragmentActivity')) {
        _showBiometricError('Please update the app for fingerprint support');
      } else if (e.toString().contains('NotAvailable')) {
        _showBiometricError('Biometric hardware not available');
      } else if (e.toString().contains('PasscodeNotSet')) {
        _showBiometricError('Please set up device lock screen first');
      } else if (e.toString().contains('LockedOut')) {
        _showBiometricError('Too many failed attempts. Try again later.');
      } else {
        _showBiometricError('Authentication failed: ${e.toString()}');
      }

      return false;
    }
  }

  void _showBiometricError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.orange.shade600,
          duration: Duration(seconds: 4),
        ),
      );
    }
  }

  Future<void> _handleFingerprintLogin() async {
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

    try {
      final authenticated = await _authenticateWithFingerprint();

      if (authenticated) {
        // Retrieve stored login data and navigate directly
        final tokenService = TokenService();
        final loginResponse = await tokenService.getLoginResponse();

        print('🔍 FINGERPRINT LOGIN - STORED DATA:');
        print('   - Login Response: ${loginResponse?.toJson()}');
        print('   - User Role: ${loginResponse?.role}');
        print('   - Is Student: ${loginResponse?.role == "student"}');

        if (loginResponse != null) {
          // Navigate directly to the main screen using stored login data
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => IndexScreen(loginResponse: loginResponse),
              ),
            );
          }
        } else {
          // Fallback to regular login if stored data not found
          await _clearStoredAuthToken();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Session expired. Please login again.'),
              backgroundColor: Colors.orange.shade600,
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fingerprint authentication failed'),
            backgroundColor: Colors.red.shade600,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Authentication error: $e'),
          backgroundColor: Colors.red.shade600,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleRegularLogin() async {
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

      // The token is already stored in the loginUser method
      // We just need to check if we should show fingerprint option next time
      await _checkBiometricAvailability();
      if (_isBiometricAvailable && _availableBiometrics.isNotEmpty) {
        if (mounted) {
          setState(() {
            _showFingerprintOption = true;
          });
        }
      }
    }
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

                        // Fingerprint option (shown only when available and user has logged in before)


                        _buildLoginForm(context),
                        SizedBox(height: 20.h),
                        _buildForgotPassword(),
                        if (_showFingerprintOption) ...[
                          _buildFingerprintOption(),
                          SizedBox(height: 30.h),
                          _buildDivider(),
                        ],
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

  Widget _buildFingerprintOption() {
    return Column(
      children: [
        Text(
          "Quick Login",
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14.sp,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 16.h),
        Container(
          width: double.infinity,
          height: 54.h,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: AppColors.primaryBlue.withOpacity(0.3),
              width: 1.5,
            ),
          ),
          child: ElevatedButton(
            onPressed: (_isLoading || !_hasInternet) ? null : _handleFingerprintLogin,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              foregroundColor: AppColors.primaryBlue,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
            child: _isLoading
                ? SizedBox(
              width: 22.w,
              height: 22.h,
              child: CircularProgressIndicator(
                color: AppColors.primaryBlue,
                strokeWidth: 2.5,
              ),
            )
                : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.fingerprint_rounded,
                  size: 22.sp,
                ),
                SizedBox(width: 12.w),
                Text(
                  "Login with Fingerprint",
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

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(
          child: Divider(
            color: Colors.grey[300],
            thickness: 1,
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Text(
            "OR",
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 12.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Divider(
            color: Colors.grey[300],
            thickness: 1,
          ),
        ),
      ],
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
                _isPasswordVisible ? Icons.visibility_rounded : Icons.visibility_off_rounded,
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
            onPressed: (_isLoading || !_hasInternet) ? null : _handleRegularLogin,
            style: ElevatedButton.styleFrom(
              backgroundColor: !_hasInternet ? Colors.grey.shade400 : AppColors.primaryBlue,
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