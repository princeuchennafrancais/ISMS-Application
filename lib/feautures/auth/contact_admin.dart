import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wallet/core/utils/color_utils/color_util.dart';
import '../../core/controllers/school_service.dart';
import '../../core/utils/widget_utils/school_logo.dart';

class ContactAdminScreen extends StatefulWidget {
  const ContactAdminScreen({super.key});

  @override
  State<ContactAdminScreen> createState() => _ContactAdminScreenState();
}

class _ContactAdminScreenState extends State<ContactAdminScreen> {
  String? adminPhone;
  String? adminEmail;
  String? schoolName;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSchoolData();
  }

  Future<void> _loadSchoolData() async {
    try {
      final schoolData = await SchoolDataService.getSchoolData();

      if (schoolData != null) {
        setState(() {
          adminPhone = schoolData.phone;
          adminEmail = schoolData.email;
          schoolName = schoolData.schoolName;
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading school data: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  // Function to launch phone dialer
  Future<void> _launchPhone(String phoneNumber) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    try {
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
      } else {
        _showErrorSnackbar('Could not launch phone dialer');
      }
    } catch (e) {
      _showErrorSnackbar('Error launching phone: $e');
    }
  }

  // Function to launch email composer
  Future<void> _launchEmail(String email) async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: email,
      queryParameters: {
        'subject': 'Support Request - ${schoolName ?? "School"} Wallet System',
        'body': 'Hello Admin,\n\nI need assistance with the wallet system.\n\nDetails:\n\n\nThank you.'
      },
    );

    try {
      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri);
      } else {
        _showErrorSnackbar('Could not launch email app');
      }
    } catch (e) {
      _showErrorSnackbar('Error launching email: $e');
    }
  }

  void _showErrorSnackbar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'Contact Administrator',
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: isLoading
          ? Center(
        child: CircularProgressIndicator(
          color: AppColors.primaryBlue,
        ),
      )
          : SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(24.w),
          child: Column(
            children: [
              SizedBox(height: 20.h),

              // Header Icon
              Container(
                width: 170.w,
                height: 170.w,
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: SchoolLogoWidget(
                  width: 140.w,
                  height: 140.w,
                  borderRadius: BorderRadius.circular(50.r),
                  fallbackAsset: "assets/icons/Untitled-3.png",
                  fit: BoxFit.cover,
                ),
              ),

              SizedBox(height: 24.h),

              // Title
              Text(
                'Need Assistance?',
                style: TextStyle(
                  fontSize: 28.sp,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1E293B),
                ),
              ),

              SizedBox(height: 8.h),

              // Subtitle
              Text(
                'Our administrators are here to help you',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15.sp,
                  color: const Color(0xFF64748B),
                  fontWeight: FontWeight.w400,
                ),
              ),

              SizedBox(height: 40.h),

              // Contact Information Card
              Container(
                padding: EdgeInsets.all(24.w),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20.r),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryBlue.withOpacity(0.08),
                      blurRadius: 20.r,
                      offset: Offset(0, 4.h),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Contact Information',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryBlue,
                      ),
                    ),
                    SizedBox(height: 20.h),

                    // School Name (if available)
                    if (schoolName != null) ...[
                      _buildInfoRow(
                        icon: Icons.school_rounded,
                        label: 'School',
                        value: schoolName!,
                      ),
                      SizedBox(height: 16.h),
                    ],

                    // Phone Number
                    if (adminPhone != null) ...[
                      _buildInfoRow(
                        icon: Icons.phone_rounded,
                        label: 'Phone',
                        value: adminPhone!,
                      ),
                      SizedBox(height: 16.h),
                    ],

                    // Email Address
                    if (adminEmail != null) ...[
                      _buildInfoRow(
                        icon: Icons.email_rounded,
                        label: 'Email',
                        value: adminEmail!,
                      ),
                    ],
                  ],
                ),
              ),

              SizedBox(height: 32.h),

              // Action Buttons
              if (adminPhone != null) ...[
                _buildActionButton(
                  icon: Icons.phone_rounded,
                  label: 'Call Administrator',
                  subtitle: 'Speak directly with support',
                  onPressed: () => _launchPhone(adminPhone!),
                  isPrimary: true,
                ),
                SizedBox(height: 16.h),
              ],

              if (adminEmail != null) ...[
                _buildActionButton(
                  icon: Icons.email_rounded,
                  label: 'Send Email',
                  subtitle: 'Send us a detailed message',
                  onPressed: () => _launchEmail(adminEmail!),
                  isPrimary: false,
                ),
              ],

              // No contact info available
              if (adminPhone == null && adminEmail == null) ...[
                Container(
                  padding: EdgeInsets.all(20.w),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(
                      color: Colors.orange.shade200,
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        color: Colors.orange.shade700,
                        size: 24.sp,
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Text(
                          'Contact information is not available. Please check back later or contact your school directly.',
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: Colors.orange.shade900,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              SizedBox(height: 40.h),

              // Help Tips
              Container(
                padding: EdgeInsets.all(20.w),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(16.r),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.lightbulb_outline_rounded,
                          color: AppColors.primaryBlue,
                          size: 20.sp,
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          'Quick Tips',
                          style: TextStyle(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryBlue,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12.h),
                    _buildTipItem('Have your student ID ready when contacting'),
                    _buildTipItem('Check your account details before calling'),
                    _buildTipItem('Note any error messages you received'),
                  ],
                ),
              ),

              SizedBox(height: 20.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40.w,
          height: 40.w,
          decoration: BoxDecoration(
            color: AppColors.primaryBlue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10.r),
          ),
          child: Icon(
            icon,
            color: AppColors.primaryBlue,
            size: 20.sp,
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12.sp,
                  color: const Color(0xFF94A3B8),
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                value,
                style: TextStyle(
                  fontSize: 15.sp,
                  color: const Color(0xFF1E293B),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required String subtitle,
    required VoidCallback onPressed,
    required bool isPrimary,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: isPrimary
                ? AppColors.primaryBlue.withOpacity(0.2)
                : Colors.black.withOpacity(0.05),
            blurRadius: 12.r,
            offset: Offset(0, 4.h),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16.r),
          child: Container(
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              color: isPrimary ? AppColors.primaryBlue : Colors.white,
              borderRadius: BorderRadius.circular(16.r),
              border: isPrimary
                  ? null
                  : Border.all(
                color: AppColors.primaryBlue.withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 50.w,
                  height: 50.w,
                  decoration: BoxDecoration(
                    color: isPrimary
                        ? Colors.white.withOpacity(0.2)
                        : AppColors.primaryBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Icon(
                    icon,
                    color: isPrimary ? Colors.white : AppColors.primaryBlue,
                    size: 24.sp,
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w700,
                          color: isPrimary ? Colors.white : const Color(0xFF1E293B),
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: isPrimary
                              ? Colors.white.withOpacity(0.8)
                              : const Color(0xFF64748B),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 18.sp,
                  color: isPrimary
                      ? Colors.white.withOpacity(0.8)
                      : AppColors.primaryBlue.withOpacity(0.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTipItem(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: EdgeInsets.only(top: 6.h),
            width: 5.w,
            height: 5.w,
            decoration: BoxDecoration(
              color: AppColors.primaryBlue,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13.sp,
                color: const Color(0xFF475569),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}