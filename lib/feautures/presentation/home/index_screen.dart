import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:wallet/core/enum/navigation_source.dart';
import 'package:wallet/core/utils/color_utils/color_util.dart';
import 'package:wallet/feautures/presentation/home/home_screen.dart';
import 'package:wallet/feautures/presentation/home/payment_screen.dart';
import 'package:wallet/feautures/presentation/home/student_result_screen.dart';
import 'package:wallet/feautures/presentation/home/withdraw_from_wallet.dart';
import 'package:wallet/feautures/presentation/home/notification_screen.dart'; // Add this import

import '../../../core/models/login_model.dart';

class IndexScreen extends StatefulWidget {
  final int? initialTab;
  final LoginResponseModel loginResponse;
  const IndexScreen({
    super.key,
    this.initialTab,
    required this.loginResponse,
  });

  @override
  State<IndexScreen> createState() => _IndexScreenState();
}

class _IndexScreenState extends State<IndexScreen> with TickerProviderStateMixin {
  late int _selectedIndex;
  late AnimationController _animationController;
  late AnimationController _fabAnimController;

  final List<GlobalKey<NavigatorState>> _navigatorKeys = [
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
  ];

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialTab ?? 0;

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _fabAnimController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // Debug the login response
    _debugLoginResponse();

    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        _fabAnimController.forward();
      }
    });
  }

  // Add this debug method
  void _debugLoginResponse() {
    print("🎯 ========== INDEX SCREEN DEBUG ==========");
    print("🔑 Login Response Details:");
    print("   - Role: ${widget.loginResponse.role}");
    print("   - Has Wallet: ${widget.loginResponse.hasWallet}");
    print("   - Payment Setting Exists: ${widget.loginResponse.paymentSettingExists}");
    print("   - Status: ${widget.loginResponse.status}");
    print("   - Message: ${widget.loginResponse.message}");
    print("   - Username: ${widget.loginResponse.username}");

    if (widget.loginResponse.data != null) {
      print("   - Data: Present");
      print("   - Firstname: ${widget.loginResponse.data!.firstname}");
      print("   - Lastname: ${widget.loginResponse.data!.lastname}");
    } else {
      print("   - Data: Null");
    }

    // Debug third screen decision
    print("🎯 Third Screen Configuration:");
    print("   - Payment Setting Exists: ${widget.loginResponse.paymentSettingExists}");
    print("   - Third Screen: ${widget.loginResponse.paymentSettingExists == true ? 'Withdraw' : 'News Letter'}");
    print("   - Third Icon: ${widget.loginResponse.paymentSettingExists == true ? 'Icons.send_rounded' : 'Icons.newspaper_rounded'}");
    print("🎯 ========== END DEBUG ==========");
  }


  @override
  void dispose() {
    _animationController.dispose();
    _fabAnimController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    if (_selectedIndex != index) {
      _animationController.forward(from: 0.0);
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  Widget _getMiddleScreen() {
    final userData = widget.loginResponse;
    final logRm = widget.loginResponse;

    if (userData.role == "student") {
      return StudentResultScreen(
        loginResponseModel: logRm,
        navigationSource: NavigationSource.bottomBar,
      );
    } else {
      return PaymentScreen(
        loginResponseModel: logRm,
        navigationSource: NavigationSource.bottomBar,
      );
    }
  }

  // New method to get the third screen based on payment settings
  Widget _getThirdScreen() {
    // If payment settings are enabled, show Withdraw screen
    if (widget.loginResponse.paymentSettingExists == true) {
      return WithdrawFromWallet(
        loginResponse: widget.loginResponse,
        scaffoldKey: GlobalKey<ScaffoldState>(),
        navigationSource: NavigationSource.bottomBar,
      );
    } else {
      // If payment settings are disabled, show News Letter screen
      return NotificationScreen();
    }
  }

  // New method to get the third screen icon based on payment settings
  IconData _getThirdScreenIcon() {
    // If payment settings are enabled, show send icon (Withdraw)
    if (widget.loginResponse.paymentSettingExists == false) {
      return Icons.send_rounded;
    } else {
      // If payment settings are disabled, show news icon (News Letter)
      return Icons.newspaper_rounded;
    }
  }

  // New method to get the third screen label based on payment settings
  String _getThirdScreenLabel() {
    // If payment settings are enabled, show "Withdraw"
    if (widget.loginResponse.paymentSettingExists == false) {
      return 'Withdraw';
    } else {
      // If payment settings are disabled, show "News"
      return 'News';
    }
  }

  @override
  Widget build(BuildContext context) {
    final logRm = widget.loginResponse;

    // Add build debug
    print("🔄 IndexScreen building...");
    print("   - Selected Index: $_selectedIndex");
    print("   - Payment Setting: ${logRm.paymentSettingExists}");
    print("   - Third Screen: ${_getThirdScreenLabel()}");

    return WillPopScope(
      onWillPop: () async {
        final isFirstRouteInCurrentTab =
        !await _navigatorKeys[_selectedIndex].currentState!.maybePop();

        if (isFirstRouteInCurrentTab) {
          if (_selectedIndex != 0) {
            _onItemTapped(0);
            return false;
          }
          return true;
        }
        return false;
      },
      child: Scaffold(
        body: Stack(
          children: [
            IndexedStack(
              index: _selectedIndex,
              children: [
                _buildNavigator(0, HomeScreen(loginResponse: widget.loginResponse)),
                _buildNavigator(1, _getMiddleScreen()),
                _buildNavigator(2, _getThirdScreen()), // Updated to use dynamic third screen
              ],
            ),
            // Floating Navigation Bar
            Positioned(
              left: 20.w,
              right: 20.w,
              bottom: 20.h + MediaQuery.viewPaddingOf(context).bottom,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 1),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: _fabAnimController,
                  curve: Curves.easeOutCubic,
                )),
                child: _buildFloatingNavBar(logRm),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingNavBar(LoginResponseModel logRm) {
    return Container(
      height: 70.h,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(35.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 30,
            offset: const Offset(0, 10),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildNavItem(
              index: 0,
              icon: Icons.home_rounded,
            ),
            _buildNavItem(
              index: 1,
              icon: logRm.role == "student"
                  ? Icons.menu_book_rounded
                  : Icons.qr_code_2_rounded,
            ),
            _buildNavItem(
              index: 2,
              icon: _getThirdScreenIcon(), // Dynamic icon based on payment settings
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
  }) {
    final isSelected = _selectedIndex == index;

    return GestureDetector(
      onTap: () => _onItemTapped(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 24.w : 16.w,
          vertical: 12.h,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryBlue.withOpacity(0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(25.r),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOutCubic,
              child: Icon(
                icon,
                size: isSelected ? 26.sp : 24.sp,
                color: isSelected
                    ? AppColors.primaryBlue
                    : Colors.grey[600],
              ),
            ),
            if (isSelected) ...[
              SizedBox(width: 8.w),
              AnimatedSize(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeOutCubic,
                child: Text(
                  _getLabel(index),
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryBlue,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _getLabel(int index) {
    switch (index) {
      case 0:
        return 'Home';
      case 1:
        return widget.loginResponse.role == "student" ? 'Results' : 'Payment';
      case 2:
        return _getThirdScreenLabel(); // Dynamic label based on payment settings
      default:
        return '';
    }
  }

  Widget _buildNavigator(int index, Widget child) {
    return Navigator(
      key: _navigatorKeys[index],
      onGenerateRoute: (settings) {
        return PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => child,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(0.0, 0.1);
            const end = Offset.zero;
            const curve = Curves.easeOutCubic;

            var tween = Tween(begin: begin, end: end).chain(
              CurveTween(curve: curve),
            );

            var fadeAnimation = Tween<double>(
              begin: 0.0,
              end: 1.0,
            ).animate(animation);

            return FadeTransition(
              opacity: fadeAnimation,
              child: SlideTransition(
                position: animation.drive(tween),
                child: child,
              ),
            );
          },
          transitionDuration: const Duration(milliseconds: 300),
        );
      },
    );
  }
}