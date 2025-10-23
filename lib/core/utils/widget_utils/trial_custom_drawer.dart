import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:wallet/core/controllers/methods_controller.dart';
import 'package:wallet/core/models/login_model.dart';
import 'package:wallet/core/utils/color_utils/color_util.dart';
import 'package:wallet/core/utils/widget_utils/school_logo.dart';
import 'package:wallet/feautures/presentation/home/change_password.dart';
import 'package:wallet/feautures/presentation/home/change_pin.dart';
import 'package:wallet/feautures/presentation/home/notification_screen.dart';
import 'package:wallet/feautures/presentation/home/profile_screen.dart';

class TrialCustomDrawer extends StatefulWidget {
  final String userName;
  final String profPic;
  final String adno;
  final LoginResponseModel loginResponseModel;

  const TrialCustomDrawer({
    super.key,
    required this.profPic,
    required this.userName,
    required this.adno,
    required this.loginResponseModel,
  });

  @override
  State<TrialCustomDrawer> createState() => _TrialCustomDrawerState();
}

class _TrialCustomDrawerState extends State<TrialCustomDrawer> with TickerProviderStateMixin {
  final AuthController authController = AuthController();
  final bool _isLoggingOut = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

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
      curve: Curves.easeOutCubic,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(-0.3, 0),
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

  String toTitleCase(String text) {
    if (text.isEmpty) return text;
    return text
        .split(' ')
        .map((word) {
      if (word.isEmpty) return word;
      return word.substring(0, 1).toUpperCase() +
          word.substring(1).toLowerCase();
    })
        .join(' ');
  }

  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.r),
          ),
          backgroundColor: Colors.white,
          elevation: 20,
          title: Container(
            padding: EdgeInsets.only(top: 10.h),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Icon(
                    Icons.logout_rounded,
                    color: Colors.red,
                    size: 24.sp,
                  ),
                ),
                SizedBox(width: 12.w),
                Text(
                  "Confirm Logout",
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
          ),
          content: Container(
            padding: EdgeInsets.symmetric(vertical: 10.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Are you sure you want to logout?",
                  style: TextStyle(
                    fontSize: 16.sp,
                    color: Colors.black87,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  "You will need to login again to access your account.",
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: Colors.grey[600],
                    fontFamily: 'Poppins',
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          actionsPadding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 20.h),
          actions: [
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () {
                      Navigator.of(dialogContext).pop();
                    },
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                        side: BorderSide(color: Colors.grey[300]!),
                      ),
                    ),
                    child: Text(
                      "Cancel",
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      try {
                        await authController.logoutUser(context: context);
                        if (context.mounted) {
                          Navigator.of(context, rootNavigator: true)
                              .pushNamedAndRemoveUntil('/login', (route) => false);
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Logout failed: $e')),
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      "Yes, Logout",
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    String baseUrl = "https://rosarycollegenise.com/";
    final userData = widget.loginResponseModel;

    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Drawer(
          width: 320.w,
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          child: Container(
            decoration: const BoxDecoration(color: Colors.white),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildEnhancedHeader(baseUrl),
                Expanded(
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 5.w),
                    child: Column(
                      children: [
                        SizedBox(height: 20.h),
                        _buildMenuItems(userData),
                        SizedBox(height: 60.h),
                        _buildFooter(userData),
                        SizedBox(height: 20.h),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEnhancedHeader(String baseUrl) {
    return Container(
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
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryBlue.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      height: 220.h,
      padding: EdgeInsets.only(left: 20.w, top: 50.h, right: 20.w, bottom: 20.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Icon(
                    Icons.close_rounded,
                    color: Colors.white,
                    size: 20.sp,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 25.h),
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withOpacity(0.3), width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 32.r,
                  backgroundImage: NetworkImage("${widget.profPic}"),
                  backgroundColor: Colors.white.withOpacity(0.2),
                  onBackgroundImageError: (exception, stackTrace) {
                    print("❌ Image Error: $exception");
                  },
                ),
              ),
              SizedBox(width: 15.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      toTitleCase(widget.userName),
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 18.sp,
                        fontFamily: 'Poppins',
                        letterSpacing: 0.5,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4.h),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Text(
                        widget.adno,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 12.sp,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItems(LoginResponseModel userData) {
    final menuItems = [
      {
        'icon': Icons.home_rounded,
        'title': 'Home',
        'onTap': () {
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/home',
                (route) => false,
            arguments: widget.loginResponseModel,
          );
        },
      },
      {
        'icon': Icons.person_outline_rounded,
        'title': 'Profile',
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ProfileScreen()),
          );
        },
      },
      {
        'icon': Icons.lock_outline_rounded,
        'title': 'Change Pin',
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ChangePin()),
          );
        },
      },
        {
          'icon': Icons.password,
          'title': 'Change Password',
          'onTap': () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ChangePassword(loginResponse: widget.loginResponseModel)),
            );
          },
        },

      {
        'icon': Icons.logout_rounded,
        'title': 'Logout',
        'isLogout': true,
        'onTap': _showLogoutConfirmation,
      },
    ];

    return Column(
      children: menuItems.map((item) => _buildEnhancedMenuItem(item)).toList(),
    );
  }

  Widget _buildEnhancedMenuItem(Map<String, dynamic> item) {
    final isLogout = item['isLogout'] == true;

    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: item['onTap'],
          borderRadius: BorderRadius.circular(16.r),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
            decoration: BoxDecoration(
              color: isLogout
                  ? Colors.red.withOpacity(0.05)
                  : Colors.grey[50],
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(
                color: isLogout
                    ? Colors.red.withOpacity(0.2)
                    : Colors.grey[200]!,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(10.w),
                  decoration: BoxDecoration(
                    color: isLogout
                        ? Colors.red.withOpacity(0.1)
                        : AppColors.primaryBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Icon(
                    item['icon'],
                    color: isLogout ? Colors.red : AppColors.primaryBlue,
                    size: 20.sp,
                  ),
                ),
                SizedBox(width: 15.w),
                Expanded(
                  child: Text(
                    item['title'],
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w500,
                      color: isLogout ? Colors.red : Colors.black87,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: isLogout
                      ? Colors.red.withOpacity(0.5)
                      : Colors.grey[400],
                  size: 16.sp,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFooter(LoginResponseModel userData) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: Colors.transparent,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: SchoolLogoWidget(
                  width: 39.w,
                  height: 39.w,
                  borderRadius: BorderRadius.circular(60.r), // makes it circular
                  fallbackAsset: "assets/icons/Untitled-3.png", // optional
                  fit: BoxFit.cover,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Rosary College Nise',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryBlue,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    Text(
                      userData.role == "student" ? 'Student Portal' : 'Sales Portal',
                      style: TextStyle(
                        fontSize: 15.sp,
                        color: Colors.grey[600],
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }}