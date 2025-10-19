import 'package:flutter/material.dart';

class WithdrawScreen extends StatefulWidget {
  const WithdrawScreen({super.key});

  @override
  State<WithdrawScreen> createState() => _WithdrawScreenState();
}

class _WithdrawScreenState extends State<WithdrawScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.purple,
      body: Center(
        child: Text("THIS IS Withdraw Screen", style: TextStyle(color: Colors.orange),),
      ),
    );
  }
}
