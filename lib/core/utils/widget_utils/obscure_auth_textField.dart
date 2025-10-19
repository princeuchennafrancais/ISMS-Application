import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:wallet/core/utils/color_utils/color_util.dart';

class ObscureAuthTxtField extends StatelessWidget {
  final String prfix_url;
  final String text;
  final String err_txt;
  final bool isPassword;
  final bool obscureText;
  final Widget? suffixIcon;
  final TextEditingController controller;
  final Widget? pref;

  const ObscureAuthTxtField({
    super.key,
    required this.prfix_url,
    required this.text,
    required this.err_txt,
    this.isPassword = false,
    this.obscureText = false,
    this.suffixIcon,
    this.pref,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      style: TextStyle(
        fontSize: 16.sp,
        color: Colors.black,
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return err_txt;
        }
        return null;
      },
      decoration: InputDecoration(
        hintText: text,
        hintStyle: TextStyle(
            color: Colors.black54, fontSize: 16.sp, fontWeight: FontWeight.w500

        ),
        prefixIcon:Icon(Icons.lock, color: AppColors.primaryBlue.withOpacity(0.7),),

      suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.grey[100],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(
            color: AppColors.primaryBlue,
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(
            color: Colors.red,
            width: 1.5,
          ),
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: 16.w,
          vertical: 14.h,
        ),
      ),
    );
  }
}
