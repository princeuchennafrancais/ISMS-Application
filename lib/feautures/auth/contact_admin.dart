import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wallet/core/utils/color_utils/color_util.dart';

class ContactAdminScreen extends StatelessWidget {
  const ContactAdminScreen({super.key});

  // Admin contact details
  final String adminPhone = "+1234567890"; // Replace with actual admin phone
  final String adminEmail = "admin@rosarycollegewallet.edu"; // Replace with actual admin email

  // Function to launch phone dialer
  Future<void> _launchPhone(String phoneNumber) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    }
  }

  // Function to launch email composer
  Future<void> _launchEmail(String email) async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: email,
      queryParameters: {
        'subject': 'Password Reset Request - Wallet System',
        'body': 'Hello Admin,\n\nI need help with password reset.\n\nMy Registration Number: \n\nThank you.'
      },
    );

    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Contact Admin',
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Need Help?',
              style: TextStyle(
                fontSize: 24.sp,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            SizedBox(height: 16.h),
            Text(
              'Contact the administrator for password reset assistance',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16.sp,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 40.h),

            // Phone Contact Button
            SizedBox(
              width: double.infinity,
              height: 56.h,
              child: ElevatedButton.icon(
                onPressed: () => _launchPhone(adminPhone),
                icon: Icon(Icons.phone, size: 24.sp),
                label: Text(
                  'Call Admin',
                  style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
              ),
            ),

            SizedBox(height: 16.h),

            // Email Contact Button
            SizedBox(
              width: double.infinity,
              height: 56.h,
              child: OutlinedButton.icon(
                onPressed: () => _launchEmail(adminEmail),
                icon: Icon(Icons.email, size: 24.sp),
                label: Text(
                  'Email Admin',
                  style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primaryBlue,
                  side: BorderSide(color: AppColors.primaryBlue, width: 2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
              ),
            ),

            SizedBox(height: 32.h),

            // Contact Details
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.phone, color: Colors.grey[600], size: 20.sp),
                      SizedBox(width: 8.w),
                      Text(
                        adminPhone,
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  Row(
                    children: [
                      Icon(Icons.email, color: Colors.grey[600], size: 20.sp),
                      SizedBox(width: 8.w),
                      Flexible(
                        child: Text(
                          adminEmail,
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}