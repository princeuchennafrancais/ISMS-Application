import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AmountTField extends StatelessWidget {
  const AmountTField({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100.h,
      width: 358.w,
      padding: EdgeInsets.only(left: 20.w, right: 20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.black38),
              ),
              color: Colors.white,
            ),
            child: Row(
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.w),
                  child: Image.asset("assets/icons/Group 12.png", height: 20.h, width: 20.w,fit: BoxFit.contain,),
                ),
                Expanded(
                  child: TextField(
                    keyboardType: TextInputType.number,
                    style: TextStyle(fontSize: 16.sp),
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 12.h),
                      hintText: '10.00 - 200,000',
                      hintStyle: TextStyle(color: Colors.black54, fontFamily: 'Montserrat'),
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ],
            ),
          ),





          Padding(
            padding: EdgeInsets.only(top: 10.sp, left: 10.w),
            child: Text(
              "Balance : # 2,150.60",
              style: TextStyle(
                color: Colors.black54,
                fontSize: 15.sp,
                fontWeight: FontWeight.w500,
                fontFamily: 'MontSerrat'

              ),
            ),
          ),
        ],
      ),
    );
  }
}
