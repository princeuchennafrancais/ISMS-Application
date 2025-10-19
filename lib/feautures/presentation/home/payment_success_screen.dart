import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lottie/lottie.dart';
import 'package:wallet/core/utils/color_utils/color_util.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/models/payment_response_model.dart';

class PaymentSuccessScreen extends StatelessWidget {
  final PaymentResponseModel paymentResponse;

  const PaymentSuccessScreen({super.key, required this.paymentResponse});

  String _formatCurrency(int amount) {
    return "₦${amount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}";
  }

  String _formatDateTime(String dateTime) {
    try {
      DateTime parsedDate = DateTime.parse(dateTime);
      return "${parsedDate.day}/${parsedDate.month}/${parsedDate.year} at ${parsedDate.hour.toString().padLeft(2, '0')}:${parsedDate.minute.toString().padLeft(2, '0')}";
    } catch (e) {
      return dateTime;
    }
  }

  void _copyToClipboard(BuildContext context, String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copied to clipboard'),
        duration: const Duration(seconds: 2),
        backgroundColor: AppColors.primaryBlue,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final paymentData = paymentResponse.data;
    print("This is the Data That we were hoping for $paymentData");

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(20.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: 20.h),

              SizedBox(height: 20.h),
              SizedBox(
                height: 120.h,
                width: 120.w,
                child: Lottie.asset(
                  'assets/anim/payment_success.json',
                  repeat: false,
                  onLoaded: (composition) {
                    debugPrint('Lottie duration: ${composition.duration}');
                  },
                ),
              ),

              SizedBox(height: 10.h),

              // Success Title
              Text(
                "Payment Successful!",
                style: TextStyle(
                  color: Colors.green.shade700,
                  fontSize: 24.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),

              SizedBox(height: 8.h),

              // Amount
              Text(
                _formatCurrency(paymentData.amount),
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 32.sp,
                  fontWeight: FontWeight.w800,
                ),
              ),

              SizedBox(height: 8.h),

              // Success message
              Text(
                paymentResponse.message,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14.sp, color: Colors.grey.shade600),
              ),

              SizedBox(height: 20.h),

              // Payment Details Card
              Expanded(
                child: SingleChildScrollView(
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(20.r),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(16.r),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Transaction Details",
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),

                        SizedBox(height: 16.h),

                        if (paymentData.narration != null &&
                            paymentData.narration!.isNotEmpty)
                          _buildDetailRow(
                            "Description",
                            paymentData.narration!,
                          ),

                        // Recipient Details Section
                        if (paymentData
                            .metadata
                            .destination
                            .accountName
                            .isNotEmpty) ...[
                          _buildDetailRow(
                            "Account Name",
                            paymentData.metadata.destination.accountName,
                          ),
                          _buildDetailRow(
                            "Account Number",
                            paymentData.metadata.destination.accountNumber,
                            copyable: true,
                            context: context,
                          ),
                          _buildDetailRow(
                            "Bank",
                            paymentData.metadata.destination.bank.bankName,
                          ),
                        ],

                        _buildDetailRow(
                          "Status",
                          paymentData.status.toUpperCase(),
                        ),
                        _buildDetailRow(
                          "Amount",
                          _formatCurrency(paymentData.amount),
                        ),
                        _buildDetailRow(
                          "Charges",
                          _formatCurrency(paymentData.charges),
                        ),
                        _buildDetailRow(
                          "Net Amount",
                          _formatCurrency(paymentData.settledAmount),
                        ),
                        _buildDetailRow(
                          "Date",
                          _formatDateTime(paymentData.createdAt),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              SizedBox(height: 20.h),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: AppColors.primaryBlue),
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                      ),
                      onPressed: () {
                        // Share or download receipt functionality
                        _shareViaWhatsApp();
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.share,
                            size: 18.sp,
                            color: AppColors.primaryBlue,
                          ),
                          SizedBox(width: 8.w),
                          Text(
                            "Share",
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: AppColors.primaryBlue,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(width: 12.w),

                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                        elevation: 0,
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
                        style: TextStyle(
                          fontSize: 16.sp,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 16.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    String label,
    String value, {
    bool copyable = false,
    BuildContext? context,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
          ),

          Expanded(
            flex: 3,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value,
                    textAlign: TextAlign.end,
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: Colors.black87,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                if (copyable && context != null) ...[
                  SizedBox(width: 8.w),
                  GestureDetector(
                    onTap: () => _copyToClipboard(context, value, label),
                    child: Icon(
                      Icons.copy,
                      size: 16.sp,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  //   void _shareReceipt(BuildContext context) {
  //     final paymentData = paymentResponse.data;
  //     final receiptText = '''
  // Payment Receipt
  // ===============
  // Amount: ${_formatCurrency(paymentData.amount)}
  // Reference: ${paymentData.reference}
  // Status: ${paymentData.status.toUpperCase()}
  // Date: ${_formatDateTime(paymentData.createdAt)}
  // Recipient: ${paymentData.metadata.destination.accountName}
  // Account: ${paymentData.metadata.destination.accountNumber}
  // Bank: ${paymentData.metadata.destination.bank.bankName}
  //     ''';
  //
  //     // Use share functionality here
  //     // Share.share(receiptText, subject: 'Payment Receipt');
  //
  //     // For now, show a snackbar
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(
  //         content: Text('Receipt details copied to clipboard'),
  //         duration: Duration(seconds: 2),
  //       ),
  //     );
  //
  //     Clipboard.setData(ClipboardData(text: receiptText));
  //
  //   }
  void _shareViaWhatsApp() {
    final paymentData = paymentResponse.data;
    final receiptText = '''
Payment Receipt
===============
Amount: ${_formatCurrency(paymentData.amount)}
Reference: ${paymentData.reference}
Status: ${paymentData.status.toUpperCase()}
Date: ${_formatDateTime(paymentData.createdAt)}
Recipient: ${paymentData.metadata.destination.accountName}
Account: ${paymentData.metadata.destination.accountNumber}
Bank: ${paymentData.metadata.destination.bank.bankName}
    ''';

    Share.share(receiptText);
  }
}
