import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:wallet/core/utils/color_utils/color_util.dart';
import 'package:wallet/feautures/presentation/home/fund_account.dart';

class WalletCard extends StatefulWidget {
  final double? balance;
  final bool isLoadingBalance;
  final String? balanceError;
  final VoidCallback? onRefreshBalance;

  const WalletCard({
    super.key,
    this.balance,
    this.isLoadingBalance = false,
    this.balanceError,
    this.onRefreshBalance,
  });

  @override
  State<WalletCard> createState() => _WalletCardState();
}

class _WalletCardState extends State<WalletCard> with TickerProviderStateMixin {
  bool _isBalanceVisible = true;
  late AnimationController _animationController;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
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
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    // Start animations
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) {
        _animationController.forward();
      }
    });

    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  String _formatBalance() {
    if (widget.balance == null) return "0.00";
    return widget.balance!.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    final naira = '\u20A6';

    return Positioned(
      top: 200.h,
      left: 40.w,
      right: 40.w,
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: widget.isLoadingBalance ? _pulseAnimation.value : 1.0,
                child: Container(
                  // Made height dynamic based on content
                  constraints: BoxConstraints(
                    minHeight: 128.h,
                    maxHeight: 160.h,
                  ),
                  width: double.infinity,
                  padding: EdgeInsets.all(20.w), // Reduced padding
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white,
                        Colors.grey[50]!,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(24.r),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.20),
                        spreadRadius: 0,
                        blurRadius: 30,
                        offset: const Offset(0, 8),
                      ),
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        spreadRadius: 0,
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                    border: Border.all(
                      color: Colors.grey.withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min, // Important: shrink to content
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Row
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(8.w),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.primaryBlue.withOpacity(0.15),
                                  AppColors.primaryBlue.withOpacity(0.05),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                            child: Icon(Icons.wallet, color: AppColors.primaryBlue,size: 25.w.h,)
                          ),
                          SizedBox(width: 12.w),

                          // Visibility Toggle
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _isBalanceVisible = !_isBalanceVisible;
                              });
                            },
                            child: Container(
                              padding: EdgeInsets.all(8.w),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(12.r),
                                border: Border.all(
                                  color: Colors.grey[200]!,
                                  width: 1,
                                ),
                              ),
                              child: Icon(
                                _isBalanceVisible
                                    ? Icons.visibility_off_rounded
                                    : Icons.visibility_rounded,
                                size: 18.sp,
                                color: AppColors.primaryBlue,
                              ),
                            ),
                          ),

                          const Spacer(),

                          // Refresh Button
                          if (!widget.isLoadingBalance && widget.onRefreshBalance != null)
                            GestureDetector(
                              onTap: widget.onRefreshBalance,
                              child: Container(
                                padding: EdgeInsets.all(8.w),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryBlue.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12.r),
                                  border: Border.all(
                                    color: AppColors.primaryBlue.withOpacity(0.2),
                                    width: 1,
                                  ),
                                ),
                                child: Icon(
                                  Icons.refresh_rounded,
                                  size: 18.sp,
                                  color: AppColors.primaryBlue,
                                ),
                              ),
                            ),
                        ],
                      ),

                      SizedBox(height: 16.h), // Increased spacing

                      // Balance Section - Made flexible
                      Flexible(
                        child: Row(
                          children: [
                            Expanded(
                              child: _buildBalanceDisplay(naira),
                            ),

                            // Add Money Button - Only show if not in error state
                            if (widget.balanceError == null)
                              Container(
                                height: 40.h,
                                width: 90.w,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      AppColors.primaryBlue,
                                      AppColors.primaryBlue.withOpacity(0.8),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(10.r),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primaryBlue.withOpacity(0.3),
                                      blurRadius: 12,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => FundAccountScreen(),
                                        ),
                                      );
                                    },
                                    borderRadius: BorderRadius.circular(10.r),
                                    child: Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 3.w,
                                        vertical: 12.h,
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.add_rounded,
                                            size: 12.sp,
                                            color: Colors.white,
                                          ),
                                          SizedBox(width: 6.w),
                                          Text(
                                            "Add Money",
                                            style: TextStyle(
                                              fontSize: 10.sp,
                                              color: Colors.white,
                                              fontWeight: FontWeight.w600,
                                              fontFamily: 'Poppins',
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildBalanceDisplay(String naira) {
    // Loading state with modern spinner
    if (widget.isLoadingBalance) {
      return Row(
        children: [
          SizedBox(
            width: 20.w,
            height: 20.h,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryBlue),
            ),
          ),
          SizedBox(width: 12.w),
          Text(
            "Loading balance...",
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryBlue,
              fontFamily: 'Poppins',
            ),
          ),
        ],
      );
    }

    // Error state with compact design
    if (widget.balanceError != null) {
      return GestureDetector(
        onTap: widget.onRefreshBalance,
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(6.w),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: 16.sp,
                color: Colors.red[600],
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Failed to load balance",
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.red[700],
                      fontFamily: 'Poppins',
                    ),
                  ),
                  Text(
                    "Tap to retry",
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: Colors.red[600],
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Balance display (hidden or visible)
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          _isBalanceVisible ? "*" : naira,
          style: TextStyle(
            fontSize: 23.sp,
            fontWeight: FontWeight.w600,
            color: _isBalanceVisible ? Colors.grey[600] : AppColors.primaryBlue,
            fontFamily: 'Poppins',
          ),
        ),
        SizedBox(width: 4.w),
        Flexible(
          child: Text(
            _isBalanceVisible ? "*********" : _formatBalance(),
            style: TextStyle(
              fontSize: 23.sp,
              fontWeight: FontWeight.w800,
              color: _isBalanceVisible ? Colors.grey[600] : AppColors.primaryBlue,
              fontFamily: 'Poppins',
              letterSpacing: _isBalanceVisible ? 2.0 : 0.5,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}