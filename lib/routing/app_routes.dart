import 'package:flutter/material.dart';
import 'package:wallet/feautures/auth/launch.dart';
import 'package:wallet/feautures/auth/login.dart';
import 'package:wallet/feautures/presentation/home/credit_wallet.dart';
import 'package:wallet/feautures/presentation/home/index_screen.dart';
import 'package:wallet/feautures/presentation/home/payment_scanner.dart';
import 'package:wallet/feautures/presentation/home/payment_screen.dart';
import 'package:wallet/feautures/presentation/home/transfer_to_wallet.dart';
import 'package:wallet/feautures/presentation/home/withdraw_from_wallet.dart';
import 'package:wallet/feautures/presentation/home/withdraw_to_bank.dart';

import '../core/models/login_model.dart';

class AppRoutes {
  static const String launch = '/launch';
  static const String login = '/login';
  static const String index = '/index';
  static const String home = '/home';
  static const String creditWallet = '/credit_wallet';
  static const String withdraw_from_wallet = '/withdraw_from_wallet';
  static const String withdraw = '/withdraw';
  static const String transfer_to_wallet = '/transfer_to_wallet';
  static const String withdraw_to_bank = '/withdraw_to_bank';
  static const String make_payment = '/make_payment';
  static const String make_payment_qr_code = '/make_payment_qr_code';

  static const String amount = "";

  // Navigation key to access navigator from anywhere
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
    // Authentication routes - these should replace the entire screen
      case launch:
        return MaterialPageRoute(builder: (_) => Launch());
      case login:
        return MaterialPageRoute(builder: (_) => LoginScreen());
      case index:
      // Handle arguments for IndexScreen
        final args = settings.arguments as Map<String, dynamic>?;
        final initialTab = args?['initialTab'] as int?;
        final loginResponse = args?['loginResponse'] as LoginResponseModel;
        return MaterialPageRoute(
          builder: (_) => IndexScreen(initialTab: initialTab, loginResponse: loginResponse,),
        );
      case make_payment:
        return MaterialPageRoute(
          builder: (_) => PaymentScreen(loginResponseModel: LoginResponseModel(),),
        );

    // Inner app routes - these should be handled within the tab navigator
      default:
      // For routes that should maintain the bottom nav bar,
      // we return a transparent route that doesn't actually navigate
      // but instead triggers the navigation through our custom navigator
        if (settings.name == creditWallet ||
            settings.name == transfer_to_wallet ||
            settings.name == withdraw_from_wallet ||
            settings.name == withdraw_to_bank ||
            settings.name == make_payment ||
            settings.name == make_payment_qr_code) {

          WidgetsBinding.instance.addPostFrameCallback((_) {
            // Access the IndexScreen's state to handle inner navigation
            if (settings.name == creditWallet) {
              navigateToInnerScreen(CreditWallet(scaffoldKey: GlobalKey<ScaffoldState>()));
            } else if (settings.name == transfer_to_wallet) {
              navigateToInnerScreen(TransferToWallet());
            } else if (settings.name == withdraw_from_wallet) {
              navigateToInnerScreen(WithdrawFromWallet( loginResponse: LoginResponseModel(),scaffoldKey: GlobalKey<ScaffoldState>()));
            } else if (settings.name == withdraw_to_bank) {
              navigateToInnerScreen(WithdrawToBank(scaffoldKey: GlobalKey<ScaffoldState>()));
            } else if (settings.name == make_payment) {
              navigateToInnerScreen(PaymentScreen(loginResponseModel: LoginResponseModel(),));
            } else if (settings.name == make_payment_qr_code) {
              navigateToInnerScreen(PaymentScanner(amount: amount,ResponseModel: LoginResponseModel(),));
            }
          });

          // Return a route that does nothing visually
          return PageRouteBuilder(
            pageBuilder: (_, __, ___) => Container(),
            transitionDuration: Duration.zero,
            opaque: false,
          );
        }

        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(child: Text('No route defined for ${settings.name}')),
          ),
        );
    }
  }

  // Method to push screens while keeping bottom nav
  static void navigateToInnerScreen(Widget screen) {
    final context = navigatorKey.currentContext;
    if (context != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => Scaffold(
            body: screen,
            bottomNavigationBar: _getBottomNavFromContext(context),
          ),
        ),
      );
    }
  }

  // Helper method to extract the current bottom nav bar
  static Widget? _getBottomNavFromContext(BuildContext context) {
    final scaffold = context.findAncestorWidgetOfExactType<Scaffold>();
    return scaffold?.bottomNavigationBar;
  }

  // Helper method to navigate to IndexScreen with specific tab
  static void navigateToIndexWithTab(BuildContext context, int tabIndex) {
    Navigator.of(context).pushNamedAndRemoveUntil(
      index,
          (route) => false,
      arguments: {'initialTab': tabIndex},
    );
  }

  // Helper method to navigate to home tab specifically
  static void navigateToHome(BuildContext context) {
    navigateToIndexWithTab(context, 0);
  }
}