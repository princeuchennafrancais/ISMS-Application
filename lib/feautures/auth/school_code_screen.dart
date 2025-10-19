import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:pinput/pinput.dart'; // Add this package

// Import your services
import '../../core/controllers/school_service.dart';
import '../../core/utils/color_utils/color_util.dart';

class SchoolCodeScreen extends StatefulWidget {
  const SchoolCodeScreen({super.key});

  @override
  State<SchoolCodeScreen> createState() => _SchoolCodeScreenState();
}

class _SchoolCodeScreenState extends State<SchoolCodeScreen>
    with SingleTickerProviderStateMixin {

  final TextEditingController _pinController = TextEditingController();
  final FocusNode _pinFocusNode = FocusNode();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  bool _isLoading = false;
  String _errorMessage = '';

  // API Configuration
  static const String _apiEndpoint = 'https://api.ceemact.com/api/intip';
  static const Duration _requestTimeout = Duration(seconds: 30);

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
    ));

    _animationController.forward();

    // Add listener to update button state
    _pinController.addListener(_updateButtonState);
  }

  void _updateButtonState() {
    if (mounted) {
      setState(() {
        if (_errorMessage.isNotEmpty) {
          _errorMessage = '';
        }
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pinController.dispose();
    _pinFocusNode.dispose();
    super.dispose();
  }

  // Check if at least first 3 boxes are filled
  bool get _isButtonEnabled {
    return _pinController.text.length >= 3;
  }

  String _getSchoolCode() {
    return _pinController.text.trim().toUpperCase();
  }

  Future<void> _verifySchoolCode(String schoolCode) async {
    print('=== SCHOOL CODE VERIFICATION STARTED ===');
    print('Endpoint: $_apiEndpoint');
    print('School Code: $schoolCode');

    try {
      // Check internet connectivity first
      print('Checking internet connectivity...');
      final result = await InternetAddress.lookup('google.com');
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        print('✓ Internet connection available');
      }
    } on SocketException {
      print('✗ No internet connection detected');
      throw Exception('No internet connection. Please check your network and try again.');
    }

    // Prepare request body
    final Map<String, dynamic> requestBody = {
      "scode": schoolCode,
    };

    final String jsonBody = json.encode(requestBody);
    print('Request Body: $jsonBody');

    try {
      print('Making HTTP request...');

      final http.Response response = await http.post(
        Uri.parse(_apiEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonBody,
      ).timeout(_requestTimeout);

      print('=== RESPONSE RECEIVED ===');
      print('Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        print('✓ Request successful (HTTP 200)');

        try {
          final Map<String, dynamic> responseData = json.decode(response.body);
          print('✓ JSON parsing successful');
          print('Parsed Response Data: $responseData');

          // Process successful response
          await _handleSuccessfulResponse(responseData, schoolCode);

        } catch (jsonError) {
          print('✗ JSON parsing failed');
          print('JSON Error: $jsonError');
          throw Exception('Invalid response format from server');
        }

      } else {
        print('✗ HTTP Error - Status Code: ${response.statusCode}');

        try {
          final Map<String, dynamic> errorData = json.decode(response.body);
          print('Error Response Data: $errorData');

          final String message = errorData['message']?.toString() ?? 'Server error occurred';
          throw Exception(message);

        } catch (jsonError) {
          if (response.statusCode == 400) {
            throw Exception('Invalid request. Please check your school code.');
          } else if (response.statusCode == 404) {
            throw Exception('School code not found. Please verify your code.');
          } else if (response.statusCode >= 500) {
            throw Exception('Server temporarily unavailable. Please try again later.');
          } else {
            throw Exception('Network error (${response.statusCode}). Please try again.');
          }
        }
      }

    } on SocketException catch (e) {
      print('✗ Socket Exception occurred: $e');
      throw Exception('Network connection failed. Please check your internet connection.');

    } on TimeoutException catch (e) {
      print('✗ Request timeout occurred: $e');
      throw Exception('Request timed out. Please check your connection and try again.');

    } catch (e) {
      print('✗ Unexpected error occurred: $e');
      if (e.toString().contains('Exception:')) {
        rethrow;
      } else {
        throw Exception('An unexpected error occurred. Please try again.');
      }
    }
  }

  Future<void> _handleSuccessfulResponse(Map<String, dynamic> responseData, String schoolCode) async {
    print('=== PROCESSING SUCCESSFUL RESPONSE ===');

    try {
      print('Processing school data...');

      // Extract school information from response
      final Map<String, dynamic>? schoolData = responseData['school'];
      if (schoolData == null) {
        print('✗ No school data found in response');
        throw Exception('Invalid response: missing school data');
      }

      print('School Data: $schoolData');

      // Extract required fields
      final String? schoolName = schoolData['school_name']?.toString();
      final String? colorHex = schoolData['color']?.toString();
      final String? logoUrl = schoolData['logo']?.toString();
      final String? retrievedSchoolCode = schoolData['scode']?.toString();
      final int? schoolId = schoolData['id'];

      print('Extracted Data:');
      print('- School Name: $schoolName');
      print('- Color: $colorHex');
      print('- Logo URL: $logoUrl');
      print('- School Code: $retrievedSchoolCode');
      print('- School ID: $schoolId');

      if (schoolName == null || colorHex == null || logoUrl == null) {
        print('✗ Missing required school data fields');
        throw Exception('Incomplete school data received');
      }

      // Use SchoolDataService to save all data (including logo download)
      print('Saving school data using SchoolDataService...');
      final bool saveSuccess = await SchoolDataService.saveSchoolData(
        schoolCode: retrievedSchoolCode ?? schoolCode,
        schoolName: schoolName,
        colorHex: colorHex,
        logoUrl: logoUrl,
        schoolId: schoolId,
      );

      if (!saveSuccess) {
        throw Exception('Failed to save school data locally');
      }

      // Update AppColors with new color
      print('Updating AppColors with new color...');
      final Color primaryColor = _hexToColor(colorHex);
      AppColors.updateColors(primaryColor: primaryColor);
      print('✓ AppColors updated successfully');

      print('✓ School code verification completed successfully');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Welcome to $schoolName!'),
            backgroundColor: AppColors.primaryBlue,
            duration: const Duration(seconds: 3),
          ),
        );

        // Navigate to login screen
        Navigator.pushReplacementNamed(context, '/login');
      }

    } catch (e) {
      print('✗ Error processing successful response: $e');
      throw Exception('Error processing server response: $e');
    }
  }

  Color _hexToColor(String hex) {
    try {
      // Remove # if present
      hex = hex.replaceAll('#', '');

      // Add alpha if not present (make it fully opaque)
      if (hex.length == 6) {
        hex = 'FF$hex';
      }

      final color = Color(int.parse(hex, radix: 16));
      print('Converted hex "$hex" to color: $color');
      return color;

    } catch (e) {
      print('✗ Error converting hex to color: $e');
      print('Using default color instead');
      return const Color(0xFF2658A9); // fallback color
    }
  }

  void _handleContinue() async {
    print('\n=== CONTINUE BUTTON PRESSED ===');

    if (!_isButtonEnabled) {
      print('✗ Button should be disabled - ignoring press');
      return;
    }

    final String schoolCode = _getSchoolCode();

    if (schoolCode.length < 3) {
      print('✗ Validation failed: School code too short');
      setState(() {
        _errorMessage = 'School code must be at least 3 characters';
      });
      return;
    }

    print('✓ Validation passed for school code: $schoolCode');

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      await _verifySchoolCode(schoolCode);
      print('✓ School code verification process completed successfully');

    } catch (e) {
      print('✗ School code verification failed: $e');

      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });
      }
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
    // Define pinput theme
    final defaultPinTheme = PinTheme(
      width: 70.w,
      height: 70.h,
      textStyle: TextStyle(
        fontSize: 32.sp,
        color: AppColors.primaryBlue,
        fontWeight: FontWeight.w700,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: AppColors.lightGray,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryBlue.withOpacity(0.08),
            blurRadius: 8.r,
            offset: Offset(0, 2.h),
          ),
        ],
      ),
    );

    final focusedPinTheme = defaultPinTheme.copyWith(
      decoration: defaultPinTheme.decoration!.copyWith(
        border: Border.all(
          color: AppColors.primaryBlue,
          width: 2,
        ),
      ),
    );

    final submittedPinTheme = defaultPinTheme.copyWith(
      decoration: defaultPinTheme.decoration!.copyWith(
        border: Border.all(
          color: AppColors.primaryBlue.withOpacity(0.5),
          width: 1.5,
        ),
      ),
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Padding(
        padding: EdgeInsets.only(left: 17.w, right: 17.w),
        child: SafeArea(
          child: Stack(
            children: [
              // Decorative background elements
              Positioned(
                top: -50.h,
                right: -50.w,
                child: Container(
                  width: 200.w,
                  height: 200.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.primaryBlue.withOpacity(0.1),
                        AppColors.primaryBlue.withOpacity(0.02),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: -30.h,
                left: -30.w,
                child: Container(
                  width: 150.w,
                  height: 150.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.primaryBlue.withOpacity(0.08),
                        AppColors.primaryBlue.withOpacity(0.01),
                      ],
                    ),
                  ),
                ),
              ),

              // Main content
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(height: 50.h),

                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: SlideTransition(
                          position: _slideAnimation,
                          child: Container(
                            width: 140.w,
                            height: 140.w,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primaryBlue.withOpacity(0.15),
                                  blurRadius: 20.r,
                                  offset: Offset(0, 8.h),
                                ),
                              ],
                            ),
                            padding: EdgeInsets.all(20.w),
                            child: Image.asset("assets/icons/Untitled-3.png"),
                          ),
                        ),
                      ),

                      SizedBox(height: 40.h),

                      // Header
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: Column(
                          children: [
                            Text(
                              'Welcome to Your',
                              style: TextStyle(
                                fontSize: 20.sp,
                                color: const Color(0xFF64748B),
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.3,
                              ),
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              'School Portal',
                              style: TextStyle(
                                fontSize: 32.sp,
                                color: AppColors.primaryBlue,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.5,
                              ),
                            ),
                            SizedBox(height: 12.h),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 16.w,
                                vertical: 8.h,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primaryBlue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20.r),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.school_rounded,
                                    size: 16.sp,
                                    color: AppColors.primaryBlue,
                                  ),
                                  SizedBox(width: 6.w),
                                  Text(
                                    'Enter your unique school code',
                                    style: TextStyle(
                                      fontSize: 13.sp,
                                      color: AppColors.primaryBlue,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 50.h),

                      // Code Input Section with Pinput
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: SlideTransition(
                          position: _slideAnimation,
                          child: Column(
                            children: [
                              Text(
                                'SCHOOL CODE',
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  color: const Color(0xFF94A3B8),
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 1.5,
                                ),
                              ),
                              SizedBox(height: 20.h),

                              // Pinput widget
                              Pinput(
                                controller: _pinController,
                                focusNode: _pinFocusNode,
                                length: 4,
                                defaultPinTheme: defaultPinTheme,
                                focusedPinTheme: focusedPinTheme,
                                submittedPinTheme: submittedPinTheme,
                                pinputAutovalidateMode: PinputAutovalidateMode.onSubmit,
                                showCursor: true,
                                keyboardType: TextInputType.text,
                                textCapitalization: TextCapitalization.characters,
                                inputFormatters: [
                                  // Allow only alphanumeric characters
                                  FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
                                ],
                                onCompleted: (pin) {
                                  print('Completed: $pin');
                                },
                                onChanged: (value) {
                                  // Clear error when typing
                                  if (_errorMessage.isNotEmpty) {
                                    setState(() {
                                      _errorMessage = '';
                                    });
                                  }
                                },
                                cursor: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: 2,
                                      height: 24.h,
                                      color: AppColors.primaryBlue,
                                    ),
                                  ],
                                ),
                              ),

                              if (_errorMessage.isNotEmpty) ...[
                                SizedBox(height: 16.h),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 16.w,
                                    vertical: 12.h,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade50,
                                    borderRadius: BorderRadius.circular(12.r),
                                    border: Border.all(
                                      color: Colors.red.shade200,
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.error_outline,
                                        size: 18.sp,
                                        color: Colors.red.shade600,
                                      ),
                                      SizedBox(width: 10.w),
                                      Expanded(
                                        child: Text(
                                          _errorMessage,
                                          style: TextStyle(
                                            fontSize: 13.sp,
                                            color: Colors.red.shade700,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),

                      SizedBox(height: 40.h),

                      // Features Section
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: Container(
                          padding: EdgeInsets.all(20.w),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20.r),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primaryBlue.withOpacity(0.08),
                                blurRadius: 12.r,
                                offset: Offset(0, 4.h),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              _buildFeatureItem(
                                Icons.assessment_outlined,
                                'View Results',
                                'Check your child\'s academic performance',
                              ),
                              Divider(height: 24.h, color: const Color(0xFFE2E8F0)),
                              _buildFeatureItem(
                                Icons.account_balance_wallet_outlined,
                                'Fund Account',
                                'Add money to your child\'s school account',
                              ),
                              Divider(height: 24.h, color: const Color(0xFFE2E8F0)),
                              _buildFeatureItem(
                                Icons.payment_outlined,
                                'Track Payments',
                                'Monitor all transactions and purchases',
                              ),
                            ],
                          ),
                        ),
                      ),

                      SizedBox(height: 40.h),

                      // Continue Button
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            gradient: _isButtonEnabled ? AppColors.BtbG : LinearGradient(
                              colors: [
                                const Color(0xFFCBD5E1),
                                const Color(0xFF94A3B8),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16.r),
                            boxShadow: _isButtonEnabled ? [
                              BoxShadow(
                                color: AppColors.primaryBlue.withOpacity(0.3),
                                blurRadius: 16.r,
                                offset: Offset(0, 6.h),
                              ),
                            ] : [
                              BoxShadow(
                                color: const Color(0xFF94A3B8).withOpacity(0.2),
                                blurRadius: 8.r,
                                offset: Offset(0, 3.h),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: _isButtonEnabled && !_isLoading ? _handleContinue : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16.r),
                              ),
                              padding: EdgeInsets.symmetric(vertical: 18.h),
                            ),
                            child: _isLoading
                                ? SizedBox(
                              width: 24.w,
                              height: 24.w,
                              child: const CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white),
                              ),
                            )
                                : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Access Portal',
                                  style: TextStyle(
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                SizedBox(width: 8.w),
                                Icon(
                                  Icons.arrow_forward_rounded,
                                  size: 20,
                                  color: _isButtonEnabled ? Colors.white : const Color(0xFFE2E8F0),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: 20.h),

                      // Help Text
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: TextButton.icon(
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20.r),
                                ),
                                title: Row(
                                  children: [
                                    Icon(
                                      Icons.help_outline,
                                      color: AppColors.primaryBlue,
                                    ),
                                    SizedBox(width: 8.w),
                                    const Text('Need Help?'),
                                  ],
                                ),
                                content: Text(
                                  'Your school code is provided by your school administrator. If you don\'t have it, please contact your school\'s IT department or front desk.\n\nThe code is typically 3-4 characters long and may contain both letters and numbers.',
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    height: 1.5,
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: Text(
                                      'Got it',
                                      style: TextStyle(
                                        color: AppColors.primaryBlue,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                          icon: Icon(
                            Icons.help_outline,
                            size: 18.sp,
                            color: const Color(0xFF64748B),
                          ),
                          label: Text(
                            'Don\'t have a school code?',
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: const Color(0xFF64748B),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: 40.h),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String title, String subtitle) {
    return Row(
      children: [
        Container(
          width: 44.w,
          height: 44.w,
          decoration: BoxDecoration(
            color: AppColors.primaryBlue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Icon(
            icon,
            color: AppColors.primaryBlue,
            size: 22,
          ),
        ),
        SizedBox(width: 14.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 15.sp,
                  color: AppColors.primaryBlue,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12.sp,
                  color: const Color(0xFF64748B),
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}