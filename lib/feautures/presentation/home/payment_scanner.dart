import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:wallet/feautures/presentation/home/payment_pin.dart';

import '../../../core/models/login_model.dart';

class PaymentScanner extends StatefulWidget {
  final String amount;
  final String? description;
  final LoginResponseModel ResponseModel;
  const PaymentScanner({super.key, required this.amount, this.description, required this.ResponseModel});


  @override
  State<PaymentScanner> createState() => _PaymentScannerState();
}

class _PaymentScannerState extends State<PaymentScanner> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  bool isScanning = true;

  @override
  void initState() {
    super.initState();
    _requestCameraPermission();
  }

  Future<void> _requestCameraPermission() async {
    final status = await Permission.camera.request();
    if (status != PermissionStatus.granted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Camera permission is required to scan QR codes.',
            style: TextStyle(fontSize: 14.sp),
          ),
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  void reassemble() {
    super.reassemble();
    if (Platform.isAndroid) {
      controller?.pauseCamera();
    }
    controller?.resumeCamera();
  }

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) {
      if (isScanning) {
        setState(() => isScanning = false);
        controller.pauseCamera();

        final studentId = scanData.code;
        print("I Got That Piece Of shit motherfucker $studentId");
        Navigator.push(context, MaterialPageRoute(builder: (context)=>PaymentPin(amount: widget.amount, description: widget.description, studentId: studentId.toString(), loginResponseModel: widget.ResponseModel,)));
      }
    });
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          "Scan Student ID",
          style: TextStyle(
            fontSize: 18.sp,
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: GestureDetector(
          onTap: () {
            Navigator.pop(context);
          },
          child: Icon(Icons.arrow_back_ios, color: Colors.white),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: QRView(
              key: qrKey,
              onQRViewCreated: _onQRViewCreated,
              overlay: QrScannerOverlayShape(
                borderColor: Colors.blueAccent,
                borderRadius: 12.r,
                borderLength: 25.w,
                borderWidth: 8.w,
                cutOutSize: 300.w, // Increase cut-out size if needed
              ),
            ),
          ),
        ],
      ),
    );
  }
}
