

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:wallet/core/utils/color_utils/color_util.dart';

class ElvButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final Color? color;
  final Color? textColor;
  final String? fontfamily;
  final Widget? child;

  const ElvButton({
    super.key,
    required this.text,
    this.onPressed,
    this.fontfamily,
    this.color,
    this.textColor,
    this.child
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 288.w,
      height: 60.h,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color ?? AppColors.primaryBlue,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(5.r),
          ),
        ),
        child:child ?? Text(
          text,
          style: TextStyle(
            fontSize: 19.sp,
            fontWeight: FontWeight.w500,
            color: textColor ?? Colors.white,
            fontFamily: fontfamily ?? "Poppins"
          ),
        ),
      ),
    );
  }
}
