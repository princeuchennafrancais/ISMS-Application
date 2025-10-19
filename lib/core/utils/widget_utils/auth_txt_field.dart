import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:wallet/core/utils/color_utils/color_util.dart';

class AuthTxtField extends StatelessWidget {
  final String text;
  final String prfix_url;
  final String err_txt;
  final bool? isPassword;
  final TextEditingController controller;
  const AuthTxtField({super.key, required this.prfix_url, required this.err_txt, required this.text, this.isPassword, required this.controller});


  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return err_txt;
        }
        return null;
      },
      decoration: InputDecoration(
        filled: true,
        fillColor: AppColors.lightGray,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
          borderSide: BorderSide(color: Colors.transparent),
        ),
        labelText: text,
        labelStyle: TextStyle(color: Colors.black54, fontSize: 16.sp, fontWeight: FontWeight.w500),
        prefixIcon:Icon(Icons.person, color: AppColors.primaryBlue.withOpacity(0.7),),
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
      ),
    );
  }
}
