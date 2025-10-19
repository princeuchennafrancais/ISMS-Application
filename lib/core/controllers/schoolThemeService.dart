import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/color_utils/color_util.dart';
class SchoolTheme {
  final String schoolCode;
  final Color primaryColor;
  final Color secondaryColor;
  final Color lightGray;
  final Color midGray;
  final Color gradientStart;
  final Color gradientEnd;
  final List<double> gradientStops;

  SchoolTheme({
    required this.schoolCode,
    required this.primaryColor,
    this.secondaryColor = const Color(0xFF000000),
    this.lightGray = const Color(0xFFEFEFEF),
    this.midGray = const Color(0xFFCDCDCD),
    Color? gradientStart,
    Color? gradientEnd,
    this.gradientStops = const [0.09, 0.4],
  }) :
        gradientStart = gradientStart ?? primaryColor,
        gradientEnd = gradientEnd ?? secondaryColor;

  // Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'school_code': schoolCode,
      'primary_color': primaryColor.value,
      'secondary_color': secondaryColor.value,
      'light_gray': lightGray.value,
      'mid_gray': midGray.value,
      'gradient_start': gradientStart.value,
      'gradient_end': gradientEnd.value,
      'gradient_stops': gradientStops,
    };
  }

  // Create from JSON
  factory SchoolTheme.fromJson(Map<String, dynamic> json) {
    return SchoolTheme(
      schoolCode: json['school_code'],
      primaryColor: Color(json['primary_color']),
      secondaryColor: Color(json['secondary_color'] ?? 0xFF000000),
      lightGray: Color(json['light_gray'] ?? 0xFFEFEFEF),
      midGray: Color(json['mid_gray'] ?? 0xFFCDCDCD),
      gradientStart: Color(json['gradient_start']),
      gradientEnd: Color(json['gradient_end']),
      gradientStops: List<double>.from(json['gradient_stops'] ?? [0.09, 0.4]),
    );
  }
}

// 4. School Theme Service
class SchoolThemeService {
  static const String _themeKey = 'school_theme';
  static const String _schoolCodeKey = 'school_code';

  static Future<SchoolTheme?> fetchSchoolTheme(String schoolCode) async {
    // TODO: Replace with actual API call
    await Future.delayed(const Duration(seconds: 1));

    final mockThemes = {
      'SCH001': SchoolTheme(
        schoolCode: 'SCH001',
        primaryColor: const Color(0xFF2658A9),
        secondaryColor: const Color(0xFF000000),
      ),
      'SCH002': SchoolTheme(
        schoolCode: 'SCH002',
        primaryColor: const Color(0xFFFF5722),
        secondaryColor: const Color(0xFFFFC107),
      ),
      'SCH003': SchoolTheme(
        schoolCode: 'SCH003',
        primaryColor: const Color(0xFF4CAF50),
        secondaryColor: const Color(0xFF2196F3),
      ),
    };

    return mockThemes[schoolCode.toUpperCase()];
  }

  static Future<void> saveThemeLocally(SchoolTheme theme) async {
    final prefs = await SharedPreferences.getInstance();
    final themeJson = jsonEncode(theme.toJson());
    await prefs.setString(_themeKey, themeJson);
    await prefs.setString(_schoolCodeKey, theme.schoolCode);
  }

  static Future<SchoolTheme?> loadThemeFromLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final themeJson = prefs.getString(_themeKey);

    if (themeJson != null) {
      final themeMap = jsonDecode(themeJson);
      return SchoolTheme.fromJson(themeMap);
    }
    return null;
  }

  static Future<String?> getStoredSchoolCode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_schoolCodeKey);
  }

  static Future<void> clearStoredTheme() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_themeKey);
    await prefs.remove(_schoolCodeKey);
  }

  static void applyTheme(SchoolTheme theme) {
    AppColors.updateColors(
      primaryColor: theme.primaryColor,
      secondaryColor: theme.secondaryColor,
      gradientStops: theme.gradientStops,
    );
  }
}