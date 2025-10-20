import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:wallet/core/enum/navigation_source.dart';
import 'package:wallet/core/models/login_model.dart';
import 'package:wallet/core/utils/widget_utils/actions_button.dart';
import 'package:wallet/feautures/presentation/home/payment_screen.dart';
import 'package:wallet/feautures/presentation/home/withdraw_from_wallet.dart';

import '../../../feautures/presentation/home/notification_screen.dart';
import '../../../feautures/presentation/home/student_result_screen.dart';

class ActionsButtonsLists extends StatefulWidget {
  final LoginResponseModel loginResponseModel;

  const ActionsButtonsLists({super.key, required this.loginResponseModel});

  static final GlobalKey<ScaffoldState> scaffoldKey =
  GlobalKey<ScaffoldState>();

  @override
  State<ActionsButtonsLists> createState() => _ActionsButtonsListsState();
}

class _ActionsButtonsListsState extends State<ActionsButtonsLists> {
  @override
  Widget build(BuildContext context) {
    final userData = widget.loginResponseModel.data;
    final lrgm = widget.loginResponseModel;

    return Padding(
      padding: EdgeInsets.only(top: 60.h, left: 15.w, right: 15.w),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // GestureDetector(
          //   child: ActionsButton(
          //     image: "assets/icons/Group 4.png",
          //     label: "Deposit",
          //   ),
          //   onTap: () {
          //     Navigator.pushNamed(context, AppRoutes.creditWallet);
          //   },
          // ),
          lrgm.role != "student"
              ? GestureDetector(
            child: ActionsButton(
              image: "assets/icons/Vector_something.png",
              label: "QR payment",
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PaymentScreen(
                    loginResponseModel: lrgm,
                    navigationSource: NavigationSource.button,
                  ),
                ),
              );
            },
          )
              : GestureDetector(
            child: ActionsButton(
              image: "assets/icons/check result.png",
              label: "Check Result",
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => StudentResultScreen(
                    loginResponseModel: lrgm,
                    navigationSource: NavigationSource.button,
                  ),
                ),
              );
            },
          ),
          GestureDetector(
            child: ActionsButton(
              image: "assets/icons/images-removebg-preview.png",
              label: "News Letter",
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => NotificationScreen(),
                )
              );
            },
          ),
        ],
      ),
    );
  }
}