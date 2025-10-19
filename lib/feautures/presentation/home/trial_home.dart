import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:wallet/core/models/login_model.dart';
import 'package:wallet/core/utils/color_utils/color_util.dart';
import 'package:wallet/core/utils/widget_utils/drop_down.dart';
import 'package:wallet/core/utils/widget_utils/mini_search_bar.dart';
import 'package:wallet/core/utils/widget_utils/trial_wallet_card.dart';

import '../../../core/utils/widget_utils/actions_buttons_lists.dart';

class TrialHome extends StatefulWidget {
  const TrialHome({super.key});

  @override
  State<TrialHome> createState() => _TrialHomeState();
}

class _TrialHomeState extends State<TrialHome> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        leading: GestureDetector(
          child: Icon(Icons.menu, color: Colors.white, size: 28.sp),
          onTap: () => _scaffoldKey.currentState!.openDrawer(),
        ),
        backgroundColor: AppColors.primaryBlue,
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 10.w),
            child: Image.asset(
              "assets/icons/ROSARY-COLLEG 1.png",
              height: 44.h,
              width: 44.w,
              fit: BoxFit.contain,
            ),
          ),
        ],
        title: Text(
          "Rosary College",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
            fontSize: 24.sp,
            fontFamily: "Poppins",
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: EdgeInsets.only(top: 40.h),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TrialWalletCard(),
              ],
            ),


          ActionsButtonsLists(loginResponseModel: LoginResponseModel(),),
          // Filters
          Padding(
            padding: EdgeInsets.only(top: 40.h, left: 55.w, right: 55.w),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                DropDown(label: "Start Year"),
                DropDown(label: "End Year"),
              ],
            ),
          ),
          SizedBox(height: 20.h),

          // Transaction Search & Placeholder
          Padding(
            padding: EdgeInsets.only(top: 40.h, left: 55.w, right: 55.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      "Transaction History",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14.sp,
                        color: AppColors.primaryBlue,
                      ),
                    ),
                    Spacer(),
                    MiniSearchBar(),
                  ],
                ),

                SizedBox(height: 10.h),

                Center(
                  child: Image.asset(
                    "assets/icons/Group 9.png",
                    width: 157.w,
                    height: 170.h,
                    fit: BoxFit.contain,
                  ),
                ),
                SizedBox(height: 15.h),
                Center(
                  child: Text(
                    "No Transactions Available",
                    style: TextStyle(
                      color: AppColors.primaryBlue,
                      fontSize: 13.sp,
                    ),
                  ),
                ),
                SizedBox(height: 40.h),
              ],
            ),
          ),
      ]
        ),
      ),
    );
  }
}
