import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:wallet/core/utils/color_utils/color_util.dart';

class TrialWalletCard extends StatefulWidget {
  const TrialWalletCard({super.key});

  @override
  State<TrialWalletCard> createState() => _TrialWalletCardState();
}

class _TrialWalletCardState extends State<TrialWalletCard> {
  bool _isBalanceVisible = false;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 200.h,
      left: 45.w,
      child: Container(
        width: 360.w,
        height: 115.h,
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: AppColors.primaryBlue,
          borderRadius: BorderRadius.circular(10.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              spreadRadius: 1,
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 5.h,),
            Row(
              children: [
                SizedBox(width: 10.w),
                Text(
                  "Total Balance",
                  style: TextStyle(
                    color: Colors.white,
                    fontFamily: "Poppins",
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
            SizedBox(height: 10.h),
            Row(
              children: [
                SizedBox(width: 10.w),
                Text(
                  _isBalanceVisible ? "₦ 2,150.60" : "***********",
                  style: TextStyle(
                    fontSize: 22.sp,
                    fontWeight: FontWeight.w600,
                    color: _isBalanceVisible ? Colors.white : Colors.white,
                    fontFamily: 'Poppins',
                  ),
                ),
                Spacer(),

                // TOGGLE SWITCH
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _isBalanceVisible = !_isBalanceVisible;
                    });
                  },
                  child: Container(
                    width: 50.w,
                    height: 26.h,
                    padding: EdgeInsets.symmetric(horizontal: 4.w),
                    decoration: BoxDecoration(
                      color: _isBalanceVisible ? Colors.grey[300] : Colors.grey[300],
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    child: AnimatedAlign(
                      duration: Duration(milliseconds: 250),
                      curve: Curves.easeInOut,
                      alignment: _isBalanceVisible
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        width: 18.w,
                        height: 18.w,
                        decoration: BoxDecoration(
                          color:  _isBalanceVisible ? AppColors.primaryBlue : Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Row(
              children: [
                SizedBox(width: 10.w),
                Text("Wallet Balance",
                    style: TextStyle(fontSize: 12.sp, color: Colors.white)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
