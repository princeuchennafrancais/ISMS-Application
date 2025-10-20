import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:wallet/core/utils/color_utils/color_util.dart';
import 'package:wallet/core/utils/widget_utils/school_logo.dart';

class HeaderSection extends StatefulWidget {
  final GlobalKey<ScaffoldState> scaffoldKey;
  final String userName;
  final String profPic;

  const HeaderSection({
    super.key,
    required this.scaffoldKey,
    required this.userName,
    required this.profPic,
  });

  @override
  State<HeaderSection> createState() => _HeaderSectionState();
}

class _HeaderSectionState extends State<HeaderSection> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

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
      begin: const Offset(0, -0.1),
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
    print("Debug - profPic: '${widget.profPic}'");
    print("Debug - Complete URL: '${widget.profPic}'");

    String toTitleCase(String text) {
      if (text.isEmpty) return text;

      return text.split(' ').map((word) {
        if (word.isEmpty) return word;
        return word.substring(0, 1).toUpperCase() + word.substring(1).toLowerCase();
      }).join(' ');
    }

    String getGreeting() {
      final hour = DateTime.now().hour;
      if (hour < 12) {
        return 'Good Morning';
      } else if (hour < 17) {
        return 'Good Afternoon';
      } else {
        return 'Good Evening';
      }
    }

    return Container(
      width: double.infinity,
      height: 235.h,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryBlue,
            AppColors.primaryBlue.withOpacity(0.9),
            AppColors.primaryBlue.withOpacity(0.8),
          ],
          stops: const [0.0, 0.6, 1.0],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(35.r),
          bottomRight: Radius.circular(35.r),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryBlue.withOpacity(0.70),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Stack(
            children: [
              // Background Pattern
              Positioned(
                top: 0,
                right: -50.w,
                child: Opacity(
                  opacity: 0.1,
                  child: Container(
                    width: 200.w,
                    height: 200.h,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: -80.h,
                left: -80.w,
                child: Opacity(
                  opacity: 0.05,
                  child: Container(
                    width: 160.w,
                    height: 160.h,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              // Main Content
              Padding(
                padding: EdgeInsets.only(
                  top: 50.h,
                  left: 24.w,
                  right: 24.w,
                  bottom: 20.h,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Navigation
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GestureDetector(
                          onTap: () => widget.scaffoldKey.currentState!.openDrawer(),
                          child: Container(
                            padding: EdgeInsets.all(9.w),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12.r),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Icon(
                              Icons.menu_rounded,
                              color: Colors.white,
                              size: 24.sp,
                            ),
                          ),
                        ),

                        // Logo with glassmorphism
                        Container(
                          padding: EdgeInsets.all(12.w),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(16.r),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child:  SchoolLogoWidget(
                            width: 46.w,
                            height: 46.w,
                            borderRadius: BorderRadius.circular(60.r), // makes it circular
                            fallbackAsset: "assets/icons/Untitled-3.png", // optional
                            fit: BoxFit.cover,
                          ),
                        ),
                      ],
                    ),



                    // Profile Section
                    Row(
                      children: [
                        // Profile Picture with Modern Styling
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.white.withOpacity(0.3),
                                Colors.white.withOpacity(0.1),
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.15),
                                blurRadius: 15,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          padding: EdgeInsets.all(3.w),
                          child: CircleAvatar(
                            radius: 32.r,
                            backgroundColor: Colors.white,
                            child: CircleAvatar(
                              radius: 29.r,
                              backgroundImage: NetworkImage("${widget.profPic}"),
                              backgroundColor: Colors.grey[300],
                              onBackgroundImageError: (exception, stackTrace) {
                                print("❌ Image Error: $exception");
                                print("❌ Attempted URL: ${widget.profPic}");
                              },
                              child: widget.profPic.isEmpty
                                  ? Icon(
                                Icons.person,
                                size: 32.sp,
                                color: Colors.grey[600],
                              )
                                  : null,
                            ),
                          ),
                        ),

                        SizedBox(width: 16.w),

                        // Profile Info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                getGreeting(),
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w500,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                              SizedBox(height: 4.h),
                              Text(
                                toTitleCase(widget.userName.isNotEmpty ? widget.userName : "Student"),
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 22.sp,
                                  fontWeight: FontWeight.w700,
                                  fontFamily: 'Poppins',
                                  letterSpacing: 0.5,
                                ),
                              ),

                            ],
                          ),
                        ),
                      ],
                    ),



                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}