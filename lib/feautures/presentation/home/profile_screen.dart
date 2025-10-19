import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:http/http.dart' as http;
import 'package:wallet/core/controllers/api_endpoints.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wallet/core/utils/color_utils/color_util.dart';
import 'package:wallet/feautures/presentation/home/notification_screen.dart';

import '../../../core/controllers/school_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with TickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  bool _isLoading = true;

  String studentName = "N/A";
  String gender = "N/A";
  String regNo = "N/A";
  String guardianName = "N/A";
  String studentClass = "N/A";
  String profileImageUrl = "";
  String? schoolCode;

  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeData(); // Call this FIRST to get school code
    fetchProfileData(); // Then fetch profile data
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Future<void> _initializeData() async {
    print("=== INITIALIZING DATA ===");

    try {
      final schoolData = await SchoolDataService.getSchoolData();

      if (mounted) {
        setState(() {
          schoolCode = schoolData?.schoolCode ?? "";
        });

        print("School code retrieved: $schoolCode");

        // Now that we have school code, fetch profile data
        if (schoolCode != null && schoolCode!.isNotEmpty) {
          await fetchProfileData();
        } else {
          print("❌ No school code found");
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print("❌ Error initializing data: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _fadeController.forward();
    _slideController.forward();
  }

  Future<void> fetchProfileData() async {
    print("=== FETCHING PROFILE DATA ===");
    print("Using school code: $schoolCode");

    if (schoolCode == null || schoolCode!.isEmpty) {
      print("❌ Cannot fetch profile: No school code available");
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) throw Exception("No auth token");

      final uri = Uri.parse(APIEndpoints.getProfileEndpoint);
      print("Making request to: $uri");

      final response = await http.get(
        uri,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
          'scode': schoolCode!, // Now we have the school code
        },
      ).timeout(Duration(seconds: 30));

      print("Response status: ${response.statusCode}");
      print("Response body: ${response.body}");

      if (response.statusCode == 200) {
        // Handle response that may contain PHP warnings before JSON
        String responseBody = response.body.trim();

        if (responseBody.isEmpty) {
          throw Exception("Empty response from server");
        }

        // Extract JSON from response (skip PHP warnings/errors)
        int jsonStartIndex = responseBody.indexOf('{');
        if (jsonStartIndex != -1) {
          String jsonString = responseBody.substring(jsonStartIndex);
          print("🔧 Cleaned JSON: $jsonString");

          final data = jsonDecode(jsonString);
          print("✓ JSON parsing successful");
          print("Parsed data: $data");

          // Check if response has proper structure with state and payload
          Map<String, dynamic> dataSource;
          if (data.containsKey('state') && data['state']['status'] == 1) {
            // Handle state/payload structure
            final payload = data['payload'];
            if (payload != null && payload['status'] == 1) {
              dataSource = payload;
            } else {
              throw Exception("Payload error: ${payload?['message'] ?? 'Unknown error'}");
            }
          } else if (data['status'] == 1) {
            // Handle direct structure
            dataSource = data;
          } else {
            throw Exception("API returned status: ${data['status']} - ${data['message'] ?? 'Unknown error'}");
          }

          final profile = dataSource['data'];
          print("Profile data: $profile");

          setState(() {
            studentName = profile['firstname'] ?? "N/A";
            gender = profile['gender'] ?? "N/A";
            regNo = profile['adno'] ?? "N/A";
            guardianName = profile['parent_name'] ?? "N/A";
            studentClass = profile['class_name'] ?? "N/A";
            profileImageUrl = profile['fpicture'] ?? "";
            _isLoading = false;
          });

          print("✅ Profile data loaded successfully");
          print("Student: $studentName, Class: $studentClass, Reg: $regNo");

        } else {
          print("❌ Response doesn't contain valid JSON: ${responseBody.substring(0, math.min(100, responseBody.length))}");
          throw Exception("Server returned non-JSON response");
        }
      } else {
        print("❌ HTTP Error ${response.statusCode}");
        throw Exception("Server error ${response.statusCode}: ${response.body}");
      }
    } on TimeoutException catch (e) {
      print("❌ Request timeout: $e");
      setState(() {
        _isLoading = false;
      });
    } on FormatException catch (e) {
      print("❌ JSON Format Error: $e");
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print("❌ Profile fetch error: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }  String toTitleCase(String text) {
    if (text.isEmpty) return text;

    return text.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word.substring(0, 1).toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  @override
  Widget build(BuildContext context) {
    print("Debug - profPic: '$profileImageUrl'");
    print("Debug - Complete URL: '$profileImageUrl'");

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.grey[50],
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(70.h),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primaryBlue,
                AppColors.primaryBlue.withOpacity(0.8),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryBlue.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: true,
            leading: Container(
              margin: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: IconButton(
                icon: Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20.sp),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            title: Text(
              'My Profile',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20.sp,
                fontWeight: FontWeight.w600,
                fontFamily: 'Poppins',
              ),
            ),
            actions: [
              Container(
                margin: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: IconButton(
                  icon: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Icon(
                        Icons.notifications_outlined,
                        color: Colors.white,
                        size: 22.sp,
                      ),
                      Positioned(
                        top: -2,
                        right: -2,
                        child: Container(
                          width: 8.w,
                          height: 8.h,
                          decoration: BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 1),
                          ),
                        ),
                      ),
                    ],
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const NotificationScreen()),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      body: _isLoading
          ? _buildLoadingState()
          : FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: SingleChildScrollView(
            child: Column(
              children: [
                _buildHeaderSection(),
                _buildProfileDetailsSection(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {

    return Container(
      height: MediaQuery.of(context).size.height,
      decoration: const BoxDecoration(
        color: Colors.white,
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: AppColors.primaryBlue,
              ),
            ),
            SizedBox(height: 24.h),
            Text(
              'Loading Profile...',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w500,
                color: AppColors.primaryBlue,
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderSection() {
    String baseUrl = "https://api.ceemact.com/";
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(30.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryBlue,
            AppColors.primaryBlue.withOpacity(0.8),
          ],
        ),
      ),
      child: Column(
        children: [
          // Profile Picture Container
          Container(
            padding: EdgeInsets.all(6.w),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.2),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Container(
              height: 140.h,
              width: 140.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipOval(
                child: profileImageUrl.isNotEmpty
                    ? Image.network(
                  "$profileImageUrl",
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    print("❌ Image Error: $error");
                    print("❌ Attempted URL: $profileImageUrl");
                    return Container(
                      decoration: BoxDecoration(
                        color: AppColors.primaryBlue.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.person_outline,
                        size: 50.sp,
                        color: AppColors.primaryBlue,
                      ),
                    );
                  },
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      decoration: BoxDecoration(
                        color: AppColors.primaryBlue.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primaryBlue,
                        ),
                      ),
                    );
                  },
                )
                    : Container(
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.person_outline,
                    size: 50.sp,
                    color: AppColors.primaryBlue,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: 24.h),
          // Student Name
          Text(
            toTitleCase(studentName),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24.sp,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              fontFamily: 'Poppins',
              letterSpacing: 0.5,
            ),
          ),
          SizedBox(height: 8.h),
          // Registration Number
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(color: Colors.white.withOpacity(0.3)),
            ),
            child: Text(
              regNo,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
                color: Colors.white,
                fontFamily: 'Poppins',
                letterSpacing: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileDetailsSection() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(35.r),
          topRight: Radius.circular(35.r),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(30.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(),
            SizedBox(height: 30.h),
            _buildDetailCard(
              icon: Icons.person_outline,
              label: 'Full Name',
              value: studentName,
            ),
            SizedBox(height: 16.h),
            _buildDetailCard(
              icon: Icons.wc_outlined,
              label: 'Gender',
              value: gender,
            ),
            SizedBox(height: 16.h),
            _buildDetailCard(
              icon: Icons.school_outlined,
              label: 'Class',
              value: studentClass,
            ),
            SizedBox(height: 16.h),
            _buildDetailCard(
              icon: Icons.family_restroom_outlined,
              label: 'Parent/Guardian',
              value: guardianName,
            ),
            SizedBox(height: 16.h),
            _buildDetailCard(
              icon: Icons.badge_outlined,
              label: 'Registration Number',
              value: regNo,
            ),
            SizedBox(height: 30.h),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
          decoration: BoxDecoration(
            color: AppColors.primaryBlue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Text(
            'STUDENT INFORMATION',
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryBlue,
              letterSpacing: 1.2,
              fontFamily: 'Poppins',
            ),
          ),
        ),
        SizedBox(height: 12.h),
        Text(
          'Profile Details',
          style: TextStyle(
            fontSize: 24.sp,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
            fontFamily: 'Poppins',
          ),
        ),
        SizedBox(height: 6.h),
        Text(
          'Your academic and personal information',
          style: TextStyle(
            fontSize: 14.sp,
            color: Colors.grey[600],
            fontFamily: 'Poppins',
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: Colors.grey.shade200,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(
              icon,
              color: AppColors.primaryBlue,
              size: 22.sp,
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[600],
                    fontFamily: 'Poppins',
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  toTitleCase(value),
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                    fontFamily: 'Poppins',
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}