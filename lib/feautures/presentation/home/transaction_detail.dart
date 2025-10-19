import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/services.dart';
import 'package:wallet/core/utils/color_utils/color_util.dart';

import '../../../core/models/transactionHist_model.dart';


class TransactionDetailsScreen extends StatelessWidget {
  final TransactionModel transaction;

  const TransactionDetailsScreen({
    super.key,
    required this.transaction,
  });

  /// Copy text to clipboard
  void copyToClipboard(BuildContext context, String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copied to clipboard'),
        duration: Duration(seconds: 2),
        backgroundColor: AppColors.primaryBlue,
      ),
    );
  }

  /// Format full date and time
  String formatFullDateTime(String dateString) {
    try {
      DateTime date = DateTime.parse(dateString);
      return "${date.day}/${date.month}/${date.year} at ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
    } catch (e) {
      return dateString;
    }
  }

  /// Get transaction icon based on action
  IconData getTransactionIcon(String action) {
    switch (action.toLowerCase()) {
      case 'transfer':
        return Icons.swap_horiz;
      case 'credit':
        return Icons.add_circle_outline;
      case 'debit':
        return Icons.remove_circle_outline;
      case 'withdrawal':
        return Icons.account_balance_wallet_outlined;
      case 'funding':
        return Icons.account_balance;
      default:
        return Icons.receipt_long;
    }
  }

  /// Get transaction color based on action
  Color getTransactionColor(String action) {
    switch (action.toLowerCase()) {
      case 'transfer':
        return Colors.blue;
      case 'credit':
      case 'funding':
        return Colors.green;
      case 'debit':
      case 'withdrawal':
        return Colors.red;
      default:
        return AppColors.primaryBlue;
    }
  }

  /// Get status color
  Color getStatusColor(TransactionModel transaction) {
    if (transaction.isSuccessful) return Colors.green;
    if (transaction.isPending) return Colors.orange;
    return Colors.red;
  }

  /// Get status text
  String getStatusText(TransactionModel transaction) {
    if (transaction.isSuccessful) return "Successful";
    if (transaction.isPending) return "Pending";
    return "Failed";
  }

  /// Build detail row
  Widget buildDetailRow({
    required String label,
    required String value,
    bool copyable = false,
    BuildContext? context,
    Color? valueColor,
    FontWeight? valueFontWeight,
    bool showDivider = true,
  }) {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 12.h),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
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
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: valueColor ?? Colors.black87,
                          fontWeight: valueFontWeight ?? FontWeight.w600,
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ),
                    if (copyable && context != null)
                      GestureDetector(
                        onTap: () => copyToClipboard(context, value, label),
                        child: Padding(
                          padding: EdgeInsets.only(left: 8.w),
                          child: Icon(
                            Icons.copy,
                            size: 16.sp,
                            color: AppColors.primaryBlue,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (showDivider)
          Divider(
            color: Colors.grey[200],
            thickness: 1,
          ),
      ],
    );
  }

  /// Build section header
  Widget buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 16.h),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20.sp,
            color: AppColors.primaryBlue,
          ),
          SizedBox(width: 8.w),
          Text(
            title,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        leading: GestureDetector(
          child: Icon(Icons.arrow_back_ios, color: AppColors.primaryBlue,),
          onTap: () {
            Navigator.pop(context);
          },
        ),
        title: Text(
          'Transaction Details',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
            color: AppColors.primaryBlue
          ),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Transaction Header Card
            Container(
              width: double.infinity,
              margin: EdgeInsets.all(16.w),
              padding: EdgeInsets.all(24.w),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Transaction Icon
                  Container(
                    width: 60.w,
                    height: 60.h,
                    decoration: BoxDecoration(
                      color: getTransactionColor(transaction.action).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      getTransactionIcon(transaction.action),
                      color: getTransactionColor(transaction.action),
                      size: 28.sp,
                    ),
                  ),

                  SizedBox(height: 16.h),

                  // Transaction Title
                  Text(
                    transaction.displayTitle,
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  SizedBox(height: 8.h),

                  // Transaction Amount
                  Text(
                    "${transaction.action.toLowerCase() == 'credit' || transaction.action.toLowerCase() == 'funding' ? '+' : '-'}${transaction.formattedAmount}",
                    style: TextStyle(
                      fontSize: 28.sp,
                      fontWeight: FontWeight.bold,
                      color: getTransactionColor(transaction.action),
                    ),
                  ),

                  SizedBox(height: 12.h),

                  // Transaction Status
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 6.h,
                    ),
                    decoration: BoxDecoration(
                      color: getStatusColor(transaction).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    child: Text(
                      getStatusText(transaction).toUpperCase(),
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: getStatusColor(transaction),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Transaction Details Card
            Container(
              width: double.infinity,
              margin: EdgeInsets.symmetric(horizontal: 16.w),
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  buildSectionHeader('Transaction Information', Icons.info_outline),

                  buildDetailRow(
                    label: 'Reference',
                    value: transaction.reference,
                    copyable: true,
                    context: context,
                  ),

                  if (transaction.clientReference != null && transaction.clientReference!.isNotEmpty)
                    buildDetailRow(
                      label: 'Client Reference',
                      value: transaction.clientReference!,
                      copyable: true,
                      context: context,
                    ),

                  if (transaction.externalReference != null && transaction.externalReference!.isNotEmpty)
                    buildDetailRow(
                      label: 'External Reference',
                      value: transaction.externalReference!,
                      copyable: true,
                      context: context,
                    ),

                  buildDetailRow(
                    label: 'Transaction Type',
                    value: transaction.action.toUpperCase(),
                    valueColor: getTransactionColor(transaction.action),
                  ),

                  buildDetailRow(
                    label: 'Category',
                    value: transaction.type.toUpperCase(),
                    valueColor: Colors.blue,
                  ),

                  buildDetailRow(
                    label: 'Amount',
                    value: transaction.formattedAmount,
                    valueColor: getTransactionColor(transaction.action),
                    valueFontWeight: FontWeight.bold,
                  ),

                  if (transaction.charges > 0)
                    buildDetailRow(
                      label: 'Transaction Fee',
                      value: transaction.formattedCharges,
                      valueColor: Colors.red,
                    ),

                  if (transaction.settledAmount != transaction.amount)
                    buildDetailRow(
                      label: 'Settled Amount',
                      value: transaction.formattedSettledAmount,
                      valueColor: Colors.green,
                      valueFontWeight: FontWeight.bold,
                    ),

                  buildDetailRow(
                    label: 'Status',
                    value: getStatusText(transaction),
                    valueColor: getStatusColor(transaction),
                    valueFontWeight: FontWeight.w600,
                  ),

                  buildDetailRow(
                    label: 'Currency',
                    value: transaction.currency,
                  ),

                  if (transaction.settlementDate != null)
                    buildDetailRow(
                      label: 'Settlement Date',
                      value: formatFullDateTime(transaction.settlementDate!),
                    ),

                  buildDetailRow(
                    label: 'Date & Time',
                    value: formatFullDateTime(transaction.createdAt),
                  ),

                  // Transaction Description (for debit transactions or when available)
                  if (transaction.description != null && transaction.description!.isNotEmpty)
                    buildDetailRow(
                      label: 'Description',
                      value: transaction.description!,
                    ),

                  // Narration
                  if (transaction.narration != null && transaction.narration!.isNotEmpty)
                    buildDetailRow(
                      label: 'Narration',
                      value: transaction.narration!,
                      showDivider: false,
                    ),
                ],
              ),
            ),
            SizedBox(height: 20.h),
          ],
        ),
      ),
    );
  }
}