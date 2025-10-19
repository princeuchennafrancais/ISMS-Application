import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:wallet/core/utils/color_utils/color_util.dart';
import 'package:wallet/core/utils/widget_utils/drawer.dart';
import 'package:wallet/core/utils/widget_utils/elv_button.dart';
import 'package:wallet/core/utils/widget_utils/norm_input_tField.dart';
import 'package:wallet/routing/app_routes.dart';

class CreditWallet extends StatelessWidget {
   CreditWallet({super.key, required this.scaffoldKey});

  final GlobalKey<ScaffoldState> scaffoldKey;
  TextEditingController accountNo = TextEditingController();
  TextEditingController  selectBank= TextEditingController();
  TextEditingController confirmDetails = TextEditingController();


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: GestureDetector(
          child: Icon(Icons.menu, color: AppColors.primaryBlue, size: 28.sp),
          onTap: () => scaffoldKey.currentState!.openDrawer(),
        ),
        actions: [
          Stack(
            children: [
              Icon(Icons.notifications, color: AppColors.primaryBlue, size: 28.sp),
              Positioned(
                top: 0,
                right: 0,
                child: CircleAvatar(
                  radius: 5.r,
                  backgroundColor: Colors.red,
                ),
              ),
            ],
          ),
        ],
      ),
      drawer: CustomDrawer(),
      body: Padding(
        padding:  EdgeInsets.only(top: 29.h, left: 50.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              "Credit Wallet",
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w400,
                fontSize: 16.sp,
              ),
            ),
            SizedBox(height: 60.h,),
            NormInputTfield(labelText: "Input Account No", controller: accountNo,),
            SizedBox(height: 30.h,),
            NormInputTfield(labelText: "Select Bank", controller: selectBank,),
            SizedBox(height: 30.h,),
            NormInputTfield(labelText: "Confirm Account Details", height: 52.h, controller: confirmDetails,),
            SizedBox(height: 60.h,),
            ElvButton(text: "Next", onPressed: () {
              Navigator.pushNamed(context, AppRoutes.transfer_to_wallet);
            }
            )
          ],
        ),
      ),

    );
  }
}
