import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:wallet/core/utils/color_utils/color_util.dart';


class NormInputTfield extends StatelessWidget {
  final String labelText;
  final Widget? prefix_url;
  final double? height;
  final TextEditingController? controller;

  const NormInputTfield({super.key, this.height, this.prefix_url, required this.labelText, this.controller});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height ?? 72.h,
      width: 328.w,
      child: TextFormField(
        controller: controller,

        decoration: InputDecoration(
          filled: true,
          fillColor: AppColors.lightGray,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.r),
            borderSide: BorderSide(color: Colors.transparent),
          ),
          labelText: labelText,
          labelStyle: TextStyle(color: Colors.black54, fontSize: 16.sp, fontWeight: FontWeight.w500),
          prefixIcon: Padding(
            padding:  EdgeInsets.all(8.0),
            child: prefix_url
            // Image.asset(
            //   prefix_url ?? "",
            //   width: 14.w,
            //   height: 21.h,
            //   fit: BoxFit.contain,
            // ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.r),
            borderSide: BorderSide(color: Colors.transparent),
          ),
        ),
      ),
    );
  }
}
