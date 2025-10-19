import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:wallet/core/utils/color_utils/color_util.dart';

class CustomDrawer extends StatelessWidget {
  const CustomDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: 320.w,
      child: Container(
        decoration: BoxDecoration(
          gradient: AppColors.BtbG,
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              Padding(
                padding: EdgeInsets.only(top: 30.h),
                child: Container(
                  width: 204.w,
                  height: 50.h, // You can adjust the height
                  decoration: BoxDecoration(
                    color: Colors.black26, // Your preferred color
                    borderRadius: BorderRadius.only(
                      topRight: Radius.circular(120),   // High radius for full curve
                      bottomRight: Radius.circular(120),
                    ),
                  ),
                  padding: EdgeInsets.only(left: 40.w),
                  child: Row(
                    children: [
                      Image.asset("assets/icons/ROSARY-COLLEG 1.png", height: 42.h, width: 44.w, fit: BoxFit.contain,),
                      SizedBox(width: 12.w),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Rosary College",
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 12.sp,
                                fontFamily: 'Poppins'),
                          ),
                          Text(
                            "Nise",
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 12.sp, fontFamily: 'Poppins'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(
                height: 20.h,
              ),
              // Top profile section
              Container(
                height: 80.w,
                padding: EdgeInsets.only(left: 40.w),
                color: Colors.black26,
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 25.r,
                      backgroundImage: AssetImage("assets/images/Student.png"),
                    ),
                    SizedBox(width: 12.w),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Ikegou Faith Sochima",
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 14.sp, fontFamily: 'Poppins'),
                        ),
                        Text(
                          "RCN/2021/064",
                          style:
                          TextStyle(color: Colors.white70, fontSize: 12.sp, fontFamily: 'Poppins'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.only(top: 30.h),
                child: CustomListRow(
                  svgIcon: "assets/icons/Vector.svg",
                  title: "Profile",
                  color: Colors.blue,
                  onTap: () {
                    // Handle tap
                  },
                ),
              ),
              CustomListRow(
                // Using regular icon instead of SVG
                icon: Icons.notifications,
                title: "Notification",
                color: Colors.blue,
                onTap: () {
                  // Handle tap
                },
              ),
              CustomListRow(
                svgIcon: "assets/icons/Vector (2).svg",
                title: "Change Password",
                color: Colors.blue,
                onTap: () {
                  // Handle tap
                },
              ),
              CustomListRow(
                icon: Icons.lock_reset,
                title: "Change Pin",
                color: Colors.blue,
                onTap: () {
                  // Handle tap
                },
              ),
              CustomListRow(
                icon: Icons.help_center,
                title: "Customer Service",
                color: Colors.blue,
                onTap: () {
                  // Handle tap
                },
              ),
              CustomListRow(
                icon: Icons.logout,
                title: "Logout",
                color: Colors.blue,
                onTap: () {
                  // Handle tap
                },
              ),

            ],
          ),
        ),
      ),
    );
  }
}

class CustomListRow extends StatelessWidget {
  final String? svgIcon;  // Optional SVG icon path
  final IconData? icon;   // Optional regular icon
  final String title;
  final Color color;
  final VoidCallback? onTap;

  const CustomListRow({
    super.key,
    this.svgIcon,
    this.icon,
    required this.title,
    required this.color,
    this.onTap,
  }) : assert(svgIcon != null || icon != null, 'Either svgIcon or icon must be provided');

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: 30.h),
      child: Stack(
        children: [
          GestureDetector(
            onTap: onTap,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              decoration: BoxDecoration(
                color: Colors.white, // light background
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      // Use SVG if provided, otherwise use regular icon
                      if (svgIcon != null)
                        SvgPicture.asset(
                          svgIcon!,
                          width: 20.w,
                          height: 20.h,
                        )
                      else if (icon != null)
                        Icon(
                          icon,
                          color: AppColors.primaryBlue,
                          size: 25.sp,
                        )
                      else
                        Icon(
                          Icons.help_outline,
                          color: AppColors.primaryBlue,
                          size: 20.sp,
                        ), // fallback icon
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                              color: AppColors.primaryBlue,
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w500,
                              fontFamily: 'Poppins'
                          ),
                        ),
                      ),
                      Icon(Icons.chevron_right, color: AppColors.primaryBlue, size: 20.sp),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 16.w, // match horizontal padding of row
            right: 16.w,
            child: Container(
              height: 1.5.h,
              decoration: BoxDecoration(
                color: AppColors.primaryBlue,
                borderRadius: BorderRadius.circular(10.r),
              ),
            ),
          ),
        ],
      ),
    );
  }
}