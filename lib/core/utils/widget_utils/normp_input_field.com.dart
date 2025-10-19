import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:wallet/core/utils/color_utils/color_util.dart';

class NormPInputTfield extends StatelessWidget {
  final String labelText;
  final Widget? prefix_url;
  final double? height;
  final TextEditingController? controller;
  final bool obscureText;

  const NormPInputTfield({
    super.key,
    this.height,
    this.prefix_url,
    required this.labelText,
    this.controller,
    this.obscureText = true, // Default to true for PIN fields
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height ?? 72.h,
      width: 328.w,
      child: TextFormField(
        controller: controller,
        keyboardType: TextInputType.number,
        obscureText: obscureText,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(4),
        ],
        decoration: InputDecoration(
          filled: true,
          fillColor: AppColors.lightGray,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.r),
            borderSide: BorderSide(color: Colors.transparent),
          ),
          labelText: labelText,
          labelStyle: TextStyle(
              color: Colors.black54,
              fontSize: 16.sp,
              fontWeight: FontWeight.w500
          ),
          prefixIcon: prefix_url != null ? Padding(
            padding: EdgeInsets.all(8.0),
            child: prefix_url,
          ) : null,
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.r),
            borderSide: BorderSide(color: Colors.transparent),
          ),
          // This removes the counter text (0/4)
          counterText: "",
          // Alternative: you can also use counterStyle to hide it
          // counterStyle: TextStyle(height: double.minPositive),
        ),
      ),
    );
  }
}