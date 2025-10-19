import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lottie/lottie.dart';
import 'package:wallet/core/utils/color_utils/color_util.dart';

class WithdrawSuccessful extends StatelessWidget {
  final String amount;
  final String BankName;
  final String AccountName;

  const WithdrawSuccessful({
    super.key,
    required this.amount,
    required this.BankName,
    required this.AccountName,
  });

  @override
  Widget build(BuildContext context) {
    // FIX: Use safe values with fallbacks
    final safeAmount = amount.isNotEmpty ? amount : '0';
    final safeBankName = BankName.isNotEmpty ? BankName : 'Bank';
    final safeAccountName = AccountName.isNotEmpty ? AccountName : 'Account Holder';

    print("🎯 WithdrawSuccessful built with:");
    print("   Amount: $safeAmount");
    print("   Bank: $safeBankName");
    print("   Account: $safeAccountName");

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(20.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: 40.h),

              // ✅ Lottie Checkmark
              SizedBox(
                height: 150.h,
                width: 150.w,
                child: Lottie.asset(
                  'assets/anim/payment_success.json',
                  repeat: false,
                  onLoaded: (composition) {
                    debugPrint('Lottie duration: ${composition.duration}');
                  },
                  errorBuilder: (context, error, stackTrace) {
                    // Fallback if Lottie fails to load
                    return Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 100.sp,
                    );
                  },
                ),
              ),

              SizedBox(height: 20.h),

              Text(
                "Withdrawal Successful",
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 22.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),

              SizedBox(height: 10.h),

              Text(
                "Your withdrawal of ₦$safeAmount has been processed successfully.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: Colors.black87,
                ),
              ),

              SizedBox(height: 30.h),

              Container(
                padding: EdgeInsets.all(16.r),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailRow("Bank Name", safeBankName),
                    _buildDetailRow("Account Name", safeAccountName),
                    _buildDetailRow("Amount", "₦$safeAmount"),
                  ],
                ),
              ),

              const Spacer(),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(context).pushNamedAndRemoveUntil(
                      '/index',
                          (route) => false,
                      arguments: {'initialTab': 0},
                    );
                  },
                  child: Text(
                    "Back to Home",
                    style: TextStyle(fontSize: 16.sp, color: Colors.white),
                  ),
                ),
              ),

              SizedBox(height: 16.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.black54,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }
}