import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../controllers/school_service.dart';

// Import your SchoolDataService


class SchoolLogoWidget extends StatelessWidget {
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final String? fallbackAsset;
  final BoxFit fit;

  const SchoolLogoWidget({
    super.key,
    this.width,
    this.height,
    this.borderRadius,
    this.fallbackAsset = "assets/icons/Untitled-3.png",
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<File?>(
      future: SchoolDataService.getSchoolLogoFile(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // Show loading indicator
          return Container(
            width: width ?? 100.w,
            height: height ?? 100.w,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: borderRadius ?? BorderRadius.circular(12.r),
            ),
            child: const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        }

        if (snapshot.hasData && snapshot.data != null) {
          // Show stored school logo
          return Container(
            width: width ?? 100.w,
            height: height ?? 100.w,
            decoration: BoxDecoration(
              borderRadius: borderRadius ?? BorderRadius.circular(12.r),
            ),
            child: ClipRRect(
              borderRadius: borderRadius ?? BorderRadius.circular(12.r),
              child: Image.file(
                snapshot.data!,
                width: width ?? 100.w,
                height: height ?? 100.w,
                fit: fit,
                errorBuilder: (context, error, stackTrace) {
                  // If file is corrupted, show fallback
                  return _buildFallbackImage();
                },
              ),
            ),
          );
        } else {
          // Show fallback logo
          return _buildFallbackImage();
        }
      },
    );
  }

  Widget _buildFallbackImage() {
    return Container(
      width: width ?? 100.w,
      height: height ?? 100.w,
      decoration: BoxDecoration(
        borderRadius: borderRadius ?? BorderRadius.circular(12.r),
      ),
      child: ClipRRect(
        borderRadius: borderRadius ?? BorderRadius.circular(12.r),
        child: fallbackAsset != null
            ? Image.asset(
          fallbackAsset!,
          width: width ?? 100.w,
          height: height ?? 100.w,
          fit: fit,
        )
            : Container(
          width: width ?? 100.w,
          height: height ?? 100.w,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: borderRadius ?? BorderRadius.circular(12.r),
          ),
          child: const Icon(
            Icons.school,
            color: Colors.grey,
          ),
        ),
      ),
    );
  }
}

// Helper widget for school info display
class SchoolInfoWidget extends StatelessWidget {
  final TextStyle? schoolNameStyle;
  final TextStyle? schoolCodeStyle;
  final CrossAxisAlignment crossAxisAlignment;

  const SchoolInfoWidget({
    super.key,
    this.schoolNameStyle,
    this.schoolCodeStyle,
    this.crossAxisAlignment = CrossAxisAlignment.start,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<SchoolData?>(
      future: SchoolDataService.getSchoolData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Column(
            crossAxisAlignment: crossAxisAlignment,
            children: [
              Container(
                width: 150.w,
                height: 20.h,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(4.r),
                ),
              ),
              SizedBox(height: 4.h),
              Container(
                width: 100.w,
                height: 16.h,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(4.r),
                ),
              ),
            ],
          );
        }

        if (snapshot.hasData && snapshot.data != null) {
          final schoolData = snapshot.data!;
          return Column(
            crossAxisAlignment: crossAxisAlignment,
            children: [
              Text(
                schoolData.schoolName,
                style: schoolNameStyle ??
                    TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              SizedBox(height: 4.h),
              Text(
                'Code: ${schoolData.schoolCode}',
                style: schoolCodeStyle ??
                    TextStyle(
                      fontSize: 14.sp,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w400,
                    ),
              ),
            ],
          );
        } else {
          return Column(
            crossAxisAlignment: crossAxisAlignment,
            children: [
              Text(
                'School Name',
                style: schoolNameStyle ??
                    TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[400],
                    ),
              ),
              SizedBox(height: 4.h),
              Text(
                'Code: ---',
                style: schoolCodeStyle ??
                    TextStyle(
                      fontSize: 14.sp,
                      color: Colors.grey[400],
                      fontWeight: FontWeight.w400,
                    ),
              ),
            ],
          );
        }
      },
    );
  }
}