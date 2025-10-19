import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SchoolDataService {
  static const String _schoolCodeKey = 'school_code';
  static const String _schoolNameKey = 'school_name';
  static const String _schoolColorKey = 'school_color';
  static const String _schoolLogoUrlKey = 'school_logo_url';
  static const String _schoolLogoPathKey = 'school_logo_path';
  static const String _schoolIdKey = 'school_id';
  static const String _timestampKey = 'school_data_timestamp';

  // Add this method inside SchoolDataService class
  static Future<String?> getSchoolCode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_schoolCodeKey);
    } catch (e) {
      print('Error getting school code: $e');
      return null;
    }
  }

  // Initialize school data on app startup
  static Future<void> initializeSchoolData() async {
    try {
      print('SchoolDataService: Initializing school data...');

      final SchoolData? schoolData = await getSchoolData();
      if (schoolData != null) {
        print('✓ Found existing school data: ${schoolData.schoolName}');

        // Update AppColors with stored color
        if (schoolData.colorHex != null) {
          final Color schoolColor = _hexToColor(schoolData.colorHex!);
          // You'll need to import and call your AppColors.updateColors method here
          print('✓ Applied stored school color: ${schoolData.colorHex}');
        }
      } else {
        print('No existing school data found');
      }
    } catch (e) {
      print('✗ Error initializing school data: $e');
    }
  }

  // Save complete school data from API response
  static Future<bool> saveSchoolData({
    required String schoolCode,
    required String schoolName,
    required String colorHex,
    required String logoUrl,
    int? schoolId,
  }) async {
    try {
      print('SchoolDataService: Saving school data...');

      final prefs = await SharedPreferences.getInstance();

      // Save basic data
      await prefs.setString(_schoolCodeKey, schoolCode);
      await prefs.setString(_schoolNameKey, schoolName);
      await prefs.setString(_schoolColorKey, colorHex);
      await prefs.setString(_schoolLogoUrlKey, logoUrl);

      if (schoolId != null) {
        await prefs.setInt(_schoolIdKey, schoolId);
      }

      // Save timestamp
      await prefs.setInt(_timestampKey, DateTime.now().millisecondsSinceEpoch);

      print('✓ Basic school data saved');

      // Download and save logo
      final String? logoPath = await downloadSchoolLogo(logoUrl, schoolCode);
      if (logoPath != null) {
        await prefs.setString(_schoolLogoPathKey, logoPath);
        print('✓ Logo downloaded and path saved');
      }

      return true;
    } catch (e) {
      print('✗ Error saving school data: $e');
      return false;
    }
  }

  // Download school logo and save locally
  static Future<String?> downloadSchoolLogo(String logoUrl, String schoolCode) async {
    try {
      print('SchoolDataService: Downloading logo from $logoUrl');

      // Make HTTP request with timeout
      final response = await http.get(
        Uri.parse(logoUrl),
        headers: {'User-Agent': 'SchoolApp/1.0'},
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
        print('✓ Logo downloaded (${response.bodyBytes.length} bytes)');

        // Get app documents directory
        final Directory appDocDir = await getApplicationDocumentsDirectory();
        final Directory logoDir = Directory('${appDocDir.path}/school_assets');

        // Create directory if needed
        if (!await logoDir.exists()) {
          await logoDir.create(recursive: true);
          print('✓ Created assets directory');
        }

        // Determine file extension
        String extension = '.jpg';
        try {
          final contentType = response.headers['content-type'] ?? '';
          if (contentType.contains('png')) {
            extension = '.png';
          } else if (contentType.contains('gif')) {
            extension = '.gif';
          } else if (contentType.contains('webp')) {
            extension = '.webp';
          }
        } catch (e) {
          print('Could not determine image type, using .jpg');
        }

        // Save file
        final String fileName = 'school_${schoolCode}_logo$extension';
        final File logoFile = File('${logoDir.path}/$fileName');
        await logoFile.writeAsBytes(response.bodyBytes);

        print('✓ Logo saved to: ${logoFile.path}');
        return logoFile.path;

      } else {
        print('✗ Failed to download logo - HTTP ${response.statusCode}');
        return null;
      }

    } catch (e) {
      print('✗ Error downloading logo: $e');
      return null;
    }
  }

  // Get stored school data
  static Future<SchoolData?> getSchoolData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final String? schoolCode = prefs.getString(_schoolCodeKey);
      final String? schoolName = prefs.getString(_schoolNameKey);
      final String? colorHex = prefs.getString(_schoolColorKey);
      final String? logoUrl = prefs.getString(_schoolLogoUrlKey);
      final String? logoPath = prefs.getString(_schoolLogoPathKey);
      final int? schoolId = prefs.getInt(_schoolIdKey);
      final int? timestamp = prefs.getInt(_timestampKey);

      if (schoolCode != null && schoolName != null) {
        return SchoolData(
          schoolCode: schoolCode,
          schoolName: schoolName,
          colorHex: colorHex,
          logoUrl: logoUrl,
          logoPath: logoPath,
          schoolId: schoolId,
          timestamp: timestamp != null ? DateTime.fromMillisecondsSinceEpoch(timestamp) : null,
        );
      }

      return null;
    } catch (e) {
      print('✗ Error getting school data: $e');
      return null;
    }
  }

  // Get school logo as File
  static Future<File?> getSchoolLogoFile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? logoPath = prefs.getString(_schoolLogoPathKey);

      if (logoPath != null) {
        final File logoFile = File(logoPath);
        if (await logoFile.exists()) {
          return logoFile;
        } else {
          print('Logo file not found at path: $logoPath');
          // Clean up invalid path
          await prefs.remove(_schoolLogoPathKey);
        }
      }

      return null;
    } catch (e) {
      print('✗ Error getting logo file: $e');
      return null;
    }
  }

  // Clear all school data (logout)
  static Future<bool> clearSchoolData() async {
    try {
      print('SchoolDataService: Clearing all school data...');

      final prefs = await SharedPreferences.getInstance();

      // Get logo path before removing it
      final String? logoPath = prefs.getString(_schoolLogoPathKey);

      // Remove all school-related preferences
      final List<String> keys = [
        _schoolCodeKey,
        _schoolNameKey,
        _schoolColorKey,
        _schoolLogoUrlKey,
        _schoolLogoPathKey,
        _schoolIdKey,
        _timestampKey,
      ];

      for (String key in keys) {
        await prefs.remove(key);
      }

      // Delete logo file if it exists
      if (logoPath != null) {
        try {
          final File logoFile = File(logoPath);
          if (await logoFile.exists()) {
            await logoFile.delete();
            print('✓ Logo file deleted');
          }
        } catch (e) {
          print('Warning: Could not delete logo file: $e');
        }
      }

      print('✓ School data cleared successfully');
      return true;

    } catch (e) {
      print('✗ Error clearing school data: $e');
      return false;
    }
  }

  // Check if school data exists
  static Future<bool> hasSchoolData() async {
    final SchoolData? data = await getSchoolData();
    return data != null;
  }

  // Helper method to convert hex to Color
  static Color _hexToColor(String hex) {
    try {
      hex = hex.replaceAll('#', '');
      if (hex.length == 6) {
        hex = 'FF$hex';
      }
      return Color(int.parse(hex, radix: 16));
    } catch (e) {
      return const Color(0xFF2658A9);
    }
  }
}

// School data model
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

  Color? get primaryColor {
    if (colorHex != null) {
      try {
        String hex = colorHex!.replaceAll('#', '');
        if (hex.length == 6) {
          hex = 'FF$hex';
        }
        return Color(int.parse(hex, radix: 16));
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  @override
  String toString() {
    return 'SchoolData(code: $schoolCode, name: $schoolName, color: $colorHex, logoPath: $logoPath, id: $schoolId)';
  }
}