import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:wallet/core/utils/color_utils/color_util.dart';

class DropDown extends StatelessWidget {
  final String label;
  const DropDown({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12.sp, fontFamily: 'Poppins')),
        SizedBox(height: 4.h),
        SizedBox(
          width: 50.w,
          child: DropdownButton<String>(
            dropdownColor: Colors.white,
            value: "2025",
            style: TextStyle(color: AppColors.primaryBlue,),
            isExpanded: true,
            isDense: true,
            icon: Icon(Icons.arrow_drop_down, color: AppColors.primaryBlue),
            underline: Container(height: 1.h, color: AppColors.primaryBlue),
            items:
            ["2025", "2024", "2023"]
                .map(
                  (year) => DropdownMenuItem(
                value: year,
                child: Text(year, style: TextStyle(fontSize: 9.sp)),
              ),
            )
                .toList(),
            onChanged: (_) {},
          ),
        ),
      ],
    );
  }
}
