import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:wallet/core/utils/color_utils/color_util.dart';

class MiniSearchBar extends StatelessWidget {
  const MiniSearchBar({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42.h,
      width: 94.w,
      child: TextFormField(
        cursorHeight: 17.h,
        textAlign: TextAlign.left,
        cursorColor: AppColors.primaryBlue,
        textDirection: TextDirection.ltr,
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.grey[200],
          border: InputBorder.none,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.r),
            borderSide: BorderSide(
              color: Colors.transparent,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.r),
            borderSide: BorderSide(
              color: Colors.transparent,
            ),
          ),
          errorBorder: InputBorder.none,
          disabledBorder: InputBorder.none,
          prefixIcon: Icon(Icons.search, size: 20.h.w),
        ),
      ),
    );
  }
}
