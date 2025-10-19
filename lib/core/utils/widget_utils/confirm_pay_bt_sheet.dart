import 'package:flutter/material.dart';

import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:wallet/core/utils/widget_utils/elv_button.dart';

class ConfirmPaymentSheet extends StatelessWidget {
  final double amount;
  final String accountNumber;
  final String name;

  const ConfirmPaymentSheet({
    super.key,
    required this.amount,
    required this.accountNumber,
    required this.name,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 600.h,
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(24.w, 24.h, 24.w, 40.h),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F9FF),
        borderRadius: BorderRadius.vertical(top: Radius.circular(30.r)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Payment',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              fontFamily: 'Poppins'
            ),
          ),
          SizedBox(height: 30.h),
          Text(
            '₦ ${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 24.sp,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF204ECF),
                fontFamily: 'Poppins'
            ),
          ),
          SizedBox(height: 30.h),
          Container(
            padding: EdgeInsets.all(16.w),
            width: 346.w,
            height: 181.h,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 8.r,
                  offset: Offset(0, 4.h),
                ),
              ],
            ),
            child: Column(
              children: [
                _infoRow('Amount', '₦ ${amount.toStringAsFixed(2)}'),
                SizedBox(height: 20.h),
                _infoRow('Fee', '₦ 0.00'),
                SizedBox(height: 20.h),
                _infoRow('Account Number', accountNumber),
                SizedBox(height: 20.h),
                _infoRow('Name', name),
              ],
            ),
          ),
          SizedBox(height: 174.h),
          
          ElvButton(text: "Confirm to Pay",
              onPressed: (){}
          )
          
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(color: Colors.grey,fontWeight: FontWeight.w400, fontSize: 14.sp, fontFamily: 'Poppins'),
        ),
        Text(
          value,
          style: TextStyle(fontWeight: FontWeight.w400, fontSize: 14.sp, fontFamily: 'Poppins'),
        ),
      ],
    );
  }
}
