import 'package:flutter/material.dart';


class AppColors {
  // Default colors (fallback)
  static Color _primaryBlue = const Color(0xFF2658A9);
  static Color _secondaryColor = const Color(0xFF000000);
  static const Color lightGray = Color(0xFFEFEFEF);
  static const Color midGray = Color(0xFFCDCDCD);
  static List<double> _gradientStops = [0.09, 0.4];

  // Getters for colors
  static Color get primaryBlue => _primaryBlue;
  static Color get secondaryColor => _secondaryColor;
  static List<double> get gradientStops => _gradientStops;

  static LinearGradient get BtbG => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [_primaryBlue, _secondaryColor],
  );

  static LinearGradient get CustomBTBG => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [_primaryBlue, _secondaryColor],
    stops: _gradientStops,
  );

  // Method to update colors dynamically
  static void updateColors({
    required Color primaryColor,
    Color? secondaryColor,
    List<double>? gradientStops,
  }) {
    _primaryBlue = primaryColor;
    _secondaryColor = secondaryColor ?? const Color(0xFF000000);
    _gradientStops = gradientStops ?? [0.09, 0.4];
  }

  // Reset to default colors
  static void resetToDefault() {
    _primaryBlue = const Color(0xFF2658A9);
    _secondaryColor = const Color(0xFF000000);
    _gradientStops = [0.09, 0.4];
  }
}

// Data class to hold school information
class SchoolData {
  final String schoolCode;
  final String schoolName;
  final String? colorHex;
  final String? logoUrl;
  final String? logoPath;
  final int? schoolId;
  final DateTime? timestamp;

  SchoolData({
    required this.schoolCode,
    required this.schoolName,
    this.colorHex,
    this.logoUrl,
    this.logoPath,
    this.schoolId,
    this.timestamp,
  });

  @override
  String toString() {
    return 'SchoolData(code: $schoolCode, name: $schoolName, color: $colorHex, logoUrl: $logoUrl, logoPath: $logoPath, id: $schoolId, timestamp: $timestamp)';
  }
}