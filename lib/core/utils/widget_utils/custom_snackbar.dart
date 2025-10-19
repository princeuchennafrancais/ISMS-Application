import 'package:flutter/material.dart';

class CustomSnackbar {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  static OverlayEntry? _currentSnackbar;

  static void show(
      String message, {
        Color? backgroundColor,
        Duration duration = const Duration(seconds: 3),
        Color textColor = Colors.white,
      }) {
    // Remove any existing snackbar
    _currentSnackbar?.remove();
    _currentSnackbar = null;

    final overlay = navigatorKey.currentState?.overlay;
    if (overlay == null) return;

    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).viewPadding.top + 20,
        left: 20,
        right: 20,
        child: _AnimatedSnackbar(
          message: message,
          backgroundColor: backgroundColor ?? const Color(0xFF2658A9).withOpacity(0.9),
          textColor: textColor,
        ),
      ),
    );

    overlay.insert(overlayEntry);
    _currentSnackbar = overlayEntry;

    Future.delayed(duration, () {
      _currentSnackbar?.remove();
      _currentSnackbar = null;
    });
  }

  static void success(String message) {
    show(
      message,
      backgroundColor: const Color(0xFF2658A9).withOpacity(0.9),
      textColor: Colors.white,
    );
  }

  static void error(String message) {
    show(
      message,
      backgroundColor: Colors.redAccent.withOpacity(0.95),
      textColor: Colors.white,
    );
  }

  static void info(String message) {
    show(
      message,
      backgroundColor: Colors.grey.shade800.withOpacity(0.95),
      textColor: Colors.white,
    );
  }
}

class _AnimatedSnackbar extends StatefulWidget {
  final String message;
  final Color backgroundColor;
  final Color textColor;

  const _AnimatedSnackbar({
    required this.message,
    required this.backgroundColor,
    required this.textColor,
  });

  @override
  State<_AnimatedSnackbar> createState() => _AnimatedSnackbarState();
}

class _AnimatedSnackbarState extends State<_AnimatedSnackbar> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.reverse();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _offsetAnimation,
      child: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(12),
        color: widget.backgroundColor,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Text(
            widget.message,
            style: TextStyle(
              color: widget.textColor,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}
