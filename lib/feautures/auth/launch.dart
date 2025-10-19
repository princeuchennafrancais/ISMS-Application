import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'school_code_screen.dart';

class Launch extends StatefulWidget {
  const Launch({super.key});

  @override
  State<Launch> createState() => _LaunchState();
}

class _LaunchState extends State<Launch>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.3, 1.0, curve: Curves.easeOutCubic),
    ));

    // Start the animation - this was missing!
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Container(
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFFFF8C00).withOpacity(0.1),
              const Color(0xFFF8FAFC),
              const Color(0xFFFF8C00).withOpacity(0.05),
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(height: 90.h),

                  // Animated Logo Container with Enhanced Styling
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Container(
                      height: 290.h,
                      width: 360.w,
                      padding: EdgeInsets.all(15.w),

                      child: Image.asset(
                        "assets/icons/Untitled-3.png",
                        // Added error handling for missing image
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF8C00).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(15.r),
                            ),
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.school,
                                    size: 80.sp,
                                    color: const Color(0xFFFF8C00),
                                  ),
                                  SizedBox(height: 10.h),
                                  Text(
                                    "ISMS",
                                    style: TextStyle(
                                      fontSize: 24.sp,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF1E3A5F),
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

                  SizedBox(height: 50.h),

                  // Animated Title Section
                  SlideTransition(
                    position: _slideAnimation,
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: Column(
                        children: [
                          ShaderMask(
                            shaderCallback: (bounds) => LinearGradient(
                              colors: [
                                const Color(0xFF1E3A5F),
                                const Color(0xFFFF8C00),
                              ],
                            ).createShader(bounds),
                            child: Text(
                              "ISMS",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 32.sp,
                                fontWeight: FontWeight.w700,
                                fontFamily: 'Poppins',
                                letterSpacing: 5,
                              ),
                            ),
                          ),

                          SizedBox(height: 12.h),

                          Text(
                            "INTELLIGENT SCHOOL MANAGEMENT\n SYSTEM",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF1E3A5F),
                              letterSpacing: 1,
                              height: 1.4,
                            ),
                          )
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: 80.h),

                  // Enhanced Get Started Button
                  SlideTransition(
                    position: _slideAnimation,
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: Container(
                        width: double.infinity,
                        height: 56.h,
                        margin: EdgeInsets.symmetric(horizontal: 20.w),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10.r),
                          // gradient: LinearGradient(
                          //   colors: [
                          //     const Color(0xFFFF8C00),
                          //     const Color(0xFFFF8C00).withOpacity(0.8),
                          //   ],
                          // ),
                          // boxShadow: [
                          //   BoxShadow(
                          //     color: const Color(0xFFFF8C00).withOpacity(0.3),
                          //     blurRadius: 20,
                          //     offset: const Offset(0, 10),
                          //   ),
                          // ],
                          color : Color(0xFF1E3A5F),
                        ),


                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                PageRouteBuilder(
                                  pageBuilder: (context, animation, secondaryAnimation) =>
                                  const SchoolCodeScreen(),
                                  transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                    return SlideTransition(
                                      position: Tween<Offset>(
                                        begin: const Offset(1.0, 0.0),
                                        end: Offset.zero,
                                      ).animate(animation),
                                      child: child,
                                    );
                                  },
                                  transitionDuration: const Duration(milliseconds: 500),
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(16.r),
                            child: Center(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    "Continue",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18.sp,
                                      fontWeight: FontWeight.w600,
                                      fontFamily: "Montserrat",
                                    ),
                                  ),
                                  SizedBox(width: 8.w),
                                  Icon(
                                    Icons.arrow_forward_ios,
                                    color: Colors.white,
                                    size: 18.sp,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: 50.h),

                  // Enhanced Contact Admin Section
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 24.w,
                        vertical: 16.h,
                      ),
                      // decoration: BoxDecoration(
                      //   color: Colors.white,
                      //   borderRadius: BorderRadius.circular(16.r),
                      //   border: Border.all(
                      //     color: const Color(0xFFE2E8F0),
                      //     width: 1.5,
                      //   ),
                      //   boxShadow: [
                      //     BoxShadow(
                      //       color: const Color(0xFF1E3A5F).withOpacity(0.08),
                      //       blurRadius: 12,
                      //       offset: const Offset(0, 4),
                      //     ),
                      //   ],
                      // ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Haven't registered?",
                            style: TextStyle(
                              color: const Color(0xFF64748B),
                              fontFamily: 'Montserrat',
                              fontWeight: FontWeight.w400,
                              fontSize: 15.sp,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              // TODO: Implement contact admin functionality
                            },
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 8.w,
                                vertical: 4.h,
                              ),
                              child: Text(
                                " Contact Admin",
                                style: TextStyle(
                                  color: const Color(0xFFFF8C00),
                                  fontFamily: 'Montserrat',
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15.sp,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 30.h),

                  // Enhanced Powered by Section
                  FadeTransition(
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
                        height: 30.h,
                        width: 166.w,
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
                  ),

                  SizedBox(height: 30.h),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}