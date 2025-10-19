import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:wallet/core/enum/navigation_source.dart';
import 'package:wallet/core/utils/color_utils/color_util.dart';
import 'package:wallet/feautures/presentation/home/home_screen.dart';
import 'package:wallet/feautures/presentation/home/payment_screen.dart';
import 'package:wallet/feautures/presentation/home/student_result_screen.dart';
import 'package:wallet/feautures/presentation/home/withdraw_from_wallet.dart';

import '../../../core/models/login_model.dart';

class IndexScreen extends StatefulWidget {
  final int? initialTab;
  final LoginResponseModel loginResponse;
  const IndexScreen({super.key, this.initialTab, required this.loginResponse,});

  @override
  State<IndexScreen> createState() => _IndexScreenState();
}

class _IndexScreenState extends State<IndexScreen> with TickerProviderStateMixin {
  late int _selectedIndex;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

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
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    if (_selectedIndex != index) {
      _animationController.reset();
      _animationController.forward();
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  Color _iconColor(int index) {
    return _selectedIndex == index ? AppColors.primaryBlue : Colors.grey[600]!;
  }

  // Helper method to get the middle screen based on role
  Widget _getMiddleScreen() {
    final userData = widget.loginResponse;
    final logRm = widget.loginResponse;

    if (userData.role == "student") {
      return StudentResultScreen(loginResponseModel: logRm, navigationSource: NavigationSource.bottomBar);
    } else {
      return PaymentScreen(loginResponseModel: logRm, navigationSource: NavigationSource.bottomBar);
    }
  }

  // Helper method to get the middle tab item based on role
  BottomNavigationBarItem _getMiddleTabItem() {
    final userData = widget.loginResponse;

    if (userData.role == "student") {
      return BottomNavigationBarItem(
        icon: _buildNavIcon(
          icon: Icons.menu_book_rounded,
          index: 1,
          isAsset: false,
        ),
        activeIcon: _buildActiveNavIcon(
          icon: Icons.menu_book_rounded,
          index: 1,
          isAsset: false,
        ),
        label: 'Check Result',
      );
    } else {
      return BottomNavigationBarItem(
        icon: _buildNavIcon(
          assetPath: "assets/icons/withdraw.png",
          index: 1,
          isAsset: true,
        ),
        activeIcon: _buildActiveNavIcon(
          assetPath: "assets/icons/withdraw.png",
          index: 1,
          isAsset: true,
        ),
        label: 'Payments',
      );
    }
  }

  Widget _buildNavIcon({
    IconData? icon,
    String? assetPath,
    required int index,
    required bool isAsset,
  }) {
    final isSelected = _selectedIndex == index;

    return Container(
      padding: EdgeInsets.all(8.w),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primaryBlue.withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: isAsset && assetPath != null
          ? Image.asset(
        assetPath,
        height: 24.h,
        width: 24.w,
        color: _iconColor(index),
      )
          : Icon(
        icon,
        size: 24.sp,
        color: _iconColor(index),
      ),
    );
  }

  Widget _buildActiveNavIcon({
    IconData? icon,
    String? assetPath,
    required int index,
    required bool isAsset,
  }) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primaryBlue,
              AppColors.primaryBlue.withOpacity(0.8),
            ],
          ),
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryBlue.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: isAsset && assetPath != null
            ? Image.asset(
          assetPath,
          height: 24.h,
          width: 24.w,
          color: Colors.white,
        )
            : Icon(
          icon,
          size: 24.sp,
          color: Colors.white,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userData = widget.loginResponse.data;
    final logRm = widget.loginResponse;

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
        body: IndexedStack(
          index: _selectedIndex,
          children: [
            _buildNavigator(0, HomeScreen(loginResponse: widget.loginResponse)),
            _buildNavigator(1, _getMiddleScreen()),
            _buildNavigator(2, WithdrawFromWallet(
              loginResponse: logRm,
              scaffoldKey: GlobalKey<ScaffoldState>(),
              navigationSource: NavigationSource.bottomBar,
            )),
          ],
        ),
        bottomNavigationBar: Container(
          height: 82.h,
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: SafeArea(
            child: Container(
              height: 85.h,
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildBottomNavItem(
                    index: 0,
                    icon: Icons.home_rounded,
                    assetPath: "assets/icons/Group 2.png",
                    label: 'Home',
                    isAsset: true,
                  ),
                  _buildBottomNavItem(
                    index: 1,
                    icon: logRm.role == "student"
                        ? Icons.menu_book_rounded
                        : null,
                    assetPath: logRm.role == "student"
                        ? null
                        : "assets/icons/withdraw.png",
                    label: logRm.role == "student" ? 'Results' : 'Payments',
                    isAsset: logRm.role != "student",
                  ),
                  _buildBottomNavItem(
                    index: 2,
                    icon: Icons.account_balance_wallet_rounded,
                    assetPath: "assets/icons/payment.png",
                    label: 'Withdraw',
                    isAsset: true,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavItem({
    required int index,
    IconData? icon,
    String? assetPath,
    required String label,
    required bool isAsset,
  }) {
    final isSelected = _selectedIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () => _onItemTapped(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.symmetric(vertical: 3.h),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primaryBlue.withOpacity(0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: EdgeInsets.all(isSelected ? 4.w : 4.w),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? LinearGradient(
                    colors: [
                      AppColors.primaryBlue,
                      AppColors.primaryBlue.withOpacity(0.8),
                    ],
                  )
                      : null,
                  color: isSelected ? null : Colors.grey[100],
                  borderRadius: BorderRadius.circular(12.r),
                  boxShadow: isSelected
                      ? [
                    BoxShadow(
                      color: AppColors.primaryBlue.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ]
                      : null,
                ),
                child: isAsset && assetPath != null
                    ? Image.asset(
                  assetPath,
                  height: 24.h,
                  width: 24.w,
                  color: isSelected ? Colors.white : Colors.grey[600],
                )
                    : Icon(
                  icon,
                  size: 24.sp,
                  color: isSelected ? Colors.white : Colors.grey[600],
                ),
              ),
              SizedBox(height: 6.h),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(
                  fontSize: isSelected ? 12.sp : 11.sp,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? AppColors.primaryBlue : Colors.grey[600],
                  fontFamily: 'Poppins',
                ),
                child: Text(label),
              ),
            ],
          ),
        ),
      ),
    );
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