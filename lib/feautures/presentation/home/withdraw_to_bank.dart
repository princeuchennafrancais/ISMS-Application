import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:wallet/core/utils/widget_utils/amount_t_field.dart';
import 'package:wallet/core/utils/widget_utils/confirm_pay_bt_sheet.dart';
import 'package:wallet/core/utils/widget_utils/elv_button.dart';

class WithdrawToBank extends StatefulWidget {
  const WithdrawToBank({super.key, required GlobalKey<ScaffoldState> scaffoldKey});

  @override
  State<WithdrawToBank> createState() => _WithdrawToBankState();
}

class _WithdrawToBankState extends State<WithdrawToBank> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: GestureDetector(
          child: Icon(Icons.arrow_back,
            color: Colors.black,
          ),
          onTap: () {
            Navigator.pop(context);
          },
        ),
        title: Text(
          "Withdraw to Bank",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w400,
            fontSize: 16.sp,
          ),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.only(top: 51.h),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  SizedBox(width: 40.w),
                  Text("Amount", style: TextStyle(color: Colors.black54)),
                ],
              ),
              SizedBox(height: 20.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [AmountTField()],
              ),

              Padding(
                padding: EdgeInsets.only(top: 59.h),
                child: Container(
                  height: 95.h,
                  width: 358.w,
                  padding: EdgeInsets.only(left: 20.w, right: 20.w),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: EdgeInsets.only(left: 10.w, top: 13.h),
                        child: Text(
                          "Note",
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.w500,
                            fontSize: 15.sp,
                            fontFamily: 'MontSerrat',
                          ),
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(color: Colors.black38),
                          ),
                          color: Colors.white,
                        ),
                        child: Row(
                          children: [
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 5.w),
                            ),
                            Expanded(
                              child: TextField(
                                keyboardType: TextInputType.number,
                                style: TextStyle(fontSize: 16.sp),
                                decoration: InputDecoration(
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(
                                    vertical: 12.h,
                                  ),
                                  hintText: "What's this for (optional)",
                                  hintStyle: TextStyle(
                                    color: Colors.black54,
                                    fontFamily: 'Montserrat',
                                  ),
                                  border: InputBorder.none,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 126.h),
              ElvButton(
                text: "Next",
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,

                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(30),
                      ),
                    ),
                    builder:
                        (context) => ConfirmPaymentSheet(
                      amount: 7000.00,
                      accountNumber: '3087512978',
                      name: 'Ikeogu Faith Sochima',
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
