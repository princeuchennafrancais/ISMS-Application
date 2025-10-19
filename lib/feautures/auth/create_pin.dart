import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:wallet/core/controllers/methods_controller.dart';
import 'package:wallet/core/utils/widget_utils/custom_snackbar.dart';
import 'package:wallet/core/utils/widget_utils/elv_button.dart';
import 'package:wallet/core/utils/widget_utils/norm_input_tField.dart';

import '../../core/models/login_model.dart';

class CreatePin extends StatefulWidget {
  final LoginResponseModel loginResponse;

  const CreatePin({
    super.key,
    required this.loginResponse,
  });

  @override
  State<CreatePin> createState() => _CreatePinState();
}

class _CreatePinState extends State<CreatePin> {
  final TextEditingController _pinController = TextEditingController();
  final TextEditingController _confirmPinController = TextEditingController();

  bool _isLoading = false;
  AuthController authController = AuthController();

  @override
  void dispose() {
    _pinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }

  void _createPin() async {
    final pin = _pinController.text.trim();
    final confirmPin = _confirmPinController.text.trim();

    if (pin.isEmpty || confirmPin.isEmpty) {
      CustomSnackbar.error("Please enter PIN and confirmation");
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await authController.createPin(
        pin: pin,
        confirmPin: confirmPin,
        context: context,
        loginResponse: widget.loginResponse,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      body: SizedBox(
        height: double.infinity,
        child: Padding(
          padding: EdgeInsets.only(top: 29.h, left: 50.w, right: 50.w),
          child: Center(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Create your Transaction Pin",
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w500,
                    fontSize: 20.sp,
                  ),
                ),
                SizedBox(height: 60.h),
                NormInputTfield(
                  labelText: "Enter your pin",
                  controller: _pinController,
                ),
                SizedBox(height: 30.h),
                NormInputTfield(
                  labelText: "Confirm your Pin",
                  height: 52.h,
                  controller: _confirmPinController,
                ),
                SizedBox(height: 60.h),
                ElvButton(
                  text: "",
                  onPressed: _isLoading ? null : () => _createPin(),
                  child: _isLoading
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text("Proceed",  style: TextStyle(
                      fontSize: 19.sp,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                      fontFamily: "Poppins"
                  ),),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}