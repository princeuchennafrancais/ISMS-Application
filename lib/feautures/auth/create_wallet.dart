import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:wallet/core/controllers/methods_controller.dart';
import 'package:wallet/core/utils/color_utils/color_util.dart';
import 'package:wallet/core/utils/widget_utils/auth_txt_field.dart';
import 'package:wallet/core/utils/widget_utils/obscure_auth_textField.dart';

import '../../core/models/login_model.dart';

class CreateWallet extends StatefulWidget {
  final LoginResponseModel loginResponse;
  const CreateWallet({super.key, required this.loginResponse});

  @override
  State<CreateWallet> createState() => _CreateWalletState();
}

class _CreateWalletState extends State<CreateWallet> {

  TextEditingController email = TextEditingController();
  TextEditingController phonenumber = TextEditingController();
  TextEditingController  bvn = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isPasswordVisible = false;
  bool _isLoading = false;
  AuthController authController  = AuthController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Form(
        key: _formKey,
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: double.infinity,
              maxHeight: double.infinity,
            ),
            child: IntrinsicHeight(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    "Create Students Wallet To\n Continue",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.primaryBlue,
                      fontWeight: FontWeight.w600,
                      fontSize: 24.sp,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildMainContent(context),
                ],
              ),
            ),
          ),
        ),
      ),
    );


  }

  Widget _buildMainContent(BuildContext context) {
    return Expanded(
      child: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 30.w),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(height: 45.h),
                  SizedBox(height: 30.h),
                  _buildLoginForm(context),
                  SizedBox(height: 30.h),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoginForm(BuildContext context) {
    const double fieldWidth = 348.0;
    const double fieldHeight = 65.0;

    return Column(
      children: [
        SizedBox(
          width: fieldWidth.w,
          height: fieldHeight.h,
          child: AuthTxtField(
            controller: email,
            prfix_url: "assets/icons/Vector.png",
            text: "Email Address",
            err_txt: "Enter Your Email",
          ),
        ),
        SizedBox(height: 20.h),
        SizedBox(
          width: fieldWidth.w,
          height: fieldHeight.h,
          child: AuthTxtField(
            controller: phonenumber,
            prfix_url: "assets/icons/Vector.png",
            text: "Phone Number",
            err_txt: "Enter Your Phone Number",
          ),
        ),
        SizedBox(height: 20.h),
        SizedBox(
          width: fieldWidth.w,
          height: fieldHeight.h,
          child: ObscureAuthTxtField(
            controller: bvn,
            err_txt: "Enter Your Bvn",
            prfix_url: "assets/icons/Vector (1).png",
            text: "BVN Number",
            isPassword: true,
            obscureText: !_isPasswordVisible,
            suffixIcon: IconButton(
              icon: Icon(
                _isPasswordVisible
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: Colors.grey[700],
                size: 20,
              ),
              onPressed: () {
                setState(() {
                  _isPasswordVisible = !_isPasswordVisible;
                });
              },
            ),
          ),
        ),
        SizedBox(height: 61.h),

        SizedBox(
          width: 288.w,
          height: 60.h,
          child: ElevatedButton(
            onPressed: _isLoading
                ? null
                : () async {
              if (_formKey.currentState!.validate()) {
                setState(() => _isLoading = true);
                await authController.createWallet(
                  bvn: bvn.text,
                  email: email.text,
                  phone: phonenumber.text,
                  loginResponse: widget.loginResponse,
                  context: context,
                );
                setState(() => _isLoading = false);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(5.r),
              ),
            ),
            child: _isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : Text(
              "Create Wallet",
              style: TextStyle(
                fontSize: 19.sp,
                fontWeight: FontWeight.w500,
                color: Colors.white,
                fontFamily: "Poppins",
              ),
            ),
          ),
        ),
      ],
    );
  }
}
