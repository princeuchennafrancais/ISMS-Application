import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:http/http.dart' as http;
import 'package:wallet/feautures/presentation/home/view_annual_result_screen.dart';
import 'package:wallet/feautures/presentation/home/view_result_screen.dart';
import 'package:open_file/open_file.dart';
import 'package:wallet/core/utils/color_utils/color_util.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

import '../../../core/controllers/school_service.dart';
import '../../../core/enum/navigation_source.dart';
import '../../../core/models/annual_result_model.dart';
import '../../../core/models/login_model.dart';
import '../../../core/models/result_model.dart';
import '../../../core/utils/widget_utils/trial_custom_drawer.dart';

class StudentResultScreen extends StatefulWidget {
  final LoginResponseModel loginResponseModel;
  final NavigationSource navigationSource;
  const StudentResultScreen({super.key, required this.loginResponseModel, this.navigationSource = NavigationSource.other,});

  @override
  State<StudentResultScreen> createState() => _StudentResultScreenState();
}

class _StudentResultScreenState extends State<StudentResultScreen> with TickerProviderStateMixin {

  // Base URL - Update this to match your actual base URL
  static const String baseUrl = 'https://api.ceemact.com/';

  // Controllers and selected values
  String selectedSession = '';
  String selectedClass = '';
  String selectedClassArm = '';
  String selectedTerm = '';

  String selectedSessionName = '';
  String selectedClassName = '';
  String selectedClassArmName = '';
  String selectedTermName = '';
  String? schoolCode;

  bool isLoading = false;
  bool _hasStoragePermission = false;
  bool isLoadingSessions = false;
  bool isLoadingClasses = false;
  bool isLoadingClassArms = false;

  String? _lastDownloadedFile;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // API data
  List<Map<String, String>> sessions = [];
  List<Map<String, String>> classes = [];
  List<Map<String, String>> classArms = [];

  // Static terms data
  final List<Map<String, String>> terms = [
    {'id': '1', 'name': 'First Term'},
    {'id': '2', 'name': 'Second Term'},
    {'id': '3', 'name': 'Third Term'},
    {'id': '4', 'name': 'Annual'},
  ];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _checkPermissions();
    _initializeData();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
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
      curve: Curves.easeOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _fadeController.forward();
    _slideController.forward();
  }

  Future<void> _initializeData() async {
    final schoolData = await SchoolDataService.getSchoolData();
    schoolCode = schoolData?.schoolCode ?? "";
    await fetchSessions();
    await fetchClasses();
  }

  Widget _buildAppBarLeading() {
    switch (widget.navigationSource) {
      case NavigationSource.bottomBar:
        return Container(
          margin: EdgeInsets.all(8.w),
          decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1,
              )
          ),
          child: IconButton(
            icon: Icon(Icons.menu_rounded, color: Colors.white, size: 24.sp),
            onPressed: () {
              if (mounted && _scaffoldKey.currentState != null) {
                _scaffoldKey.currentState!.openDrawer();
              }
            },
          ),
        );
      case NavigationSource.button:
      case NavigationSource.drawer:
      case NavigationSource.other:
      default:
        return Container(
          margin: EdgeInsets.all(8.w),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: IconButton(
            icon: Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20.sp),
            onPressed: () => Navigator.pop(context),
          ),
        );
    }
  }

  // [All the existing API methods remain unchanged - _fetchSessions, _fetchClasses, _fetchClassArms, etc.]
  Future<void> fetchSessions() async {
    setState(() {
      isLoadingSessions = true;
    });

    try {
      print("🔄 Fetching sessions from: ${baseUrl}class_api/getSessions");

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? '';

      final response = await http.get(
        Uri.parse("${baseUrl}class_api/getSessions"),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
          'scode': schoolCode ?? "",
        },
      ).timeout(const Duration(seconds: 30));

      print("📥 Sessions Response Status: ${response.statusCode}");
      print("📥 Sessions Response Body: ${response.body}");

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        // FIX: Access payload first, then check status and data
        final payload = responseData['payload'];
        if (payload != null && payload['status'] == 1) {
          final List<dynamic> sessionsData = payload['data'] ?? [];

          setState(() {
            sessions = sessionsData.map<Map<String, String>>((session) {
              return {
                'id': session['id'].toString(),
                'name': session['name'] ?? 'Unknown Session',
              };
            }).toList();
          });

          print("✅ Sessions loaded successfully: ${sessions.length} sessions");
        } else {
          print("❌ Sessions API Error: ${payload?['message']}");
          _showErrorSnackbar(payload?['message'] ?? 'Failed to load sessions');
        }
      } else {
        print("❌ Sessions HTTP Error: ${response.statusCode}");
        _showErrorSnackbar("Failed to load sessions: Server error ${response.statusCode}");
      }
    } on SocketException catch (e) {
      print("❌ Sessions Socket Exception: $e");
      _showErrorSnackbar("Connection failed. Check your internet connection");
    } on TimeoutException catch (e) {
      print("❌ Sessions Timeout Exception: $e");
      _showErrorSnackbar("Request timeout. Please try again");
    } catch (error) {
      print("❌ Sessions General Error: $error");
      _showErrorSnackbar("Failed to load sessions. Please try again");
    } finally {
      setState(() {
        isLoadingSessions = false;
      });
    }
  }

  Future<void> fetchClasses() async {
    setState(() {
      isLoadingClasses = true;
    });

    try {
      print("🔄 Fetching classes from: ${baseUrl}class_api/getClasses");

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? '';

      final response = await http.get(
        Uri.parse("${baseUrl}class_api/getClasses"),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
          'scode': schoolCode ?? "",
        },
      ).timeout(const Duration(seconds: 30));

      print("📥 Classes Response Status: ${response.statusCode}");
      print("📥 Classes Response Body: ${response.body}");

      if (response.statusCode == 200) {
        // Handle malformed JSON by extracting the first valid JSON object
        String responseBody = response.body.trim();

        // Find the first complete JSON object
        int firstBraceIndex = responseBody.indexOf('{');
        int braceCount = 0;
        int endIndex = firstBraceIndex;

        for (int i = firstBraceIndex; i < responseBody.length; i++) {
          if (responseBody[i] == '{') {
            braceCount++;
          } else if (responseBody[i] == '}') {
            braceCount--;
            if (braceCount == 0) {
              endIndex = i;
              break;
            }
          }
        }

        String validJsonString = responseBody.substring(firstBraceIndex, endIndex + 1);
        print("🔧 Extracted JSON: $validJsonString");

        final responseData = jsonDecode(validJsonString);

        // Check if this is the direct format or nested in payload
        Map<String, dynamic> dataSource;
        if (responseData.containsKey('payload')) {
          dataSource = responseData['payload'];
        } else {
          dataSource = responseData;
        }

        if (dataSource['status'] == 1) {
          final List<dynamic> classesData = dataSource['data'] ?? [];

          setState(() {
            classes = classesData.map<Map<String, String>>((classItem) {
              return {
                'id': classItem['id'].toString(),
                'name': classItem['name'] ?? 'Unknown Class',
              };
            }).toList();
          });

          print("✅ Classes loaded successfully: ${classes.length} classes");
        } else {
          print("❌ Classes API Error: ${dataSource['message']}");
          _showErrorSnackbar(dataSource['message'] ?? 'Failed to load classes');
        }
      } else {
        print("❌ Classes HTTP Error: ${response.statusCode}");
        _showErrorSnackbar("Failed to load classes: Server error ${response.statusCode}");
      }
    } on SocketException catch (e) {
      print("❌ Classes Socket Exception: $e");
      _showErrorSnackbar("Connection failed. Check your internet connection");
    } on TimeoutException catch (e) {
      print("❌ Classes Timeout Exception: $e");
      _showErrorSnackbar("Request timeout. Please try again");
    } on FormatException catch (e) {
      print("❌ Classes JSON Format Error: $e");
      _showErrorSnackbar("Invalid response format from server");
    } catch (error) {
      print("❌ Classes General Error: $error");
      _showErrorSnackbar("Failed to load classes. Please try again");
    } finally {
      setState(() {
        isLoadingClasses = false;
      });
    }
  }

  Future<void> _fetchClassArms(String classId) async {
    setState(() {
      isLoadingClassArms = true;
      classArms = [];
      selectedClassArm = '';
      selectedClassArmName = '';
    });

    try {
      print("🔄 Fetching class arms from: ${baseUrl}class_api/getClassArms");
      print("🔄 Sending class_id: $classId");

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? '';

      // Prepare the JSON body
      final Map<String, dynamic> requestBody = {
        'class_id': classId,
      };

      final response = await http.post(
        Uri.parse("${baseUrl}class_api/getClassArms"),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
          'scode': schoolCode ?? "",
        },
        body: jsonEncode(requestBody), // Send JSON body
      ).timeout(const Duration(seconds: 30));

      print("📥 Class Arms Response Status: ${response.statusCode}");
      print("📥 Class Arms Response Body: ${response.body}");

      if (response.statusCode == 200) {
        // Handle malformed JSON by extracting the first valid JSON object
        String responseBody = response.body.trim();

        // Find the first complete JSON object
        int firstBraceIndex = responseBody.indexOf('{');
        int braceCount = 0;
        int endIndex = firstBraceIndex;

        for (int i = firstBraceIndex; i < responseBody.length; i++) {
          if (responseBody[i] == '{') {
            braceCount++;
          } else if (responseBody[i] == '}') {
            braceCount--;
            if (braceCount == 0) {
              endIndex = i;
              break;
            }
          }
        }

        String validJsonString = responseBody.substring(firstBraceIndex, endIndex + 1);
        print("🔧 Extracted JSON: $validJsonString");

        final responseData = jsonDecode(validJsonString);

        // Check if this is the direct format or nested in payload
        Map<String, dynamic> dataSource;
        if (responseData.containsKey('payload')) {
          dataSource = responseData['payload'];
        } else {
          dataSource = responseData;
        }

        if (dataSource['status'] == 1) {
          final List<dynamic> classArmsData = dataSource['data'] ?? [];

          setState(() {
            classArms = classArmsData.map<Map<String, String>>((classArm) {
              return {
                'id': classArm['id'].toString(),
                'name': classArm['arm_name'] ?? classArm['name'] ?? 'Unknown Arm',
              };
            }).toList();
          });

          print("✅ Class Arms loaded successfully: ${classArms.length} class arms");
        } else {
          print("❌ Class Arms API Error: ${dataSource['message']}");
          _showErrorSnackbar(dataSource['message'] ?? 'Failed to load class arms');
        }
      } else {
        print("❌ Class Arms HTTP Error: ${response.statusCode}");
        _showErrorSnackbar("Failed to load class arms: Server error ${response.statusCode}");
      }
    } on SocketException catch (e) {
      print("❌ Class Arms Socket Exception: $e");
      _showErrorSnackbar("Connection failed. Check your internet connection");
    } on TimeoutException catch (e) {
      print("❌ Class Arms Timeout Exception: $e");
      _showErrorSnackbar("Request timeout. Please try again");
    } on FormatException catch (e) {
      print("❌ Class Arms JSON Format Error: $e");
      _showErrorSnackbar("Invalid response format from server");
    } catch (error) {
      print("❌ Class Arms General Error: $error");
      _showErrorSnackbar("Failed to load class arms. Please try again");
    } finally {
      setState(() {
        isLoadingClassArms = false;
      });
    }
  }

  Future<void> _checkPermissions() async {
    try {
      PermissionStatus status;

      if (Platform.isAndroid) {
        final androidInfo = await DeviceInfoPlugin().androidInfo;

        if (androidInfo.version.sdkInt >= 33) {
          status = await Permission.manageExternalStorage.status;
          if (!status.isGranted) {
            status = await Permission.manageExternalStorage.request();
          }
        } else {
          status = await Permission.storage.status;
          if (!status.isGranted) {
            status = await Permission.storage.request();
          }
        }
      } else {
        status = await Permission.storage.status;
        if (!status.isGranted) {
          status = await Permission.storage.request();
        }
      }

      setState(() {
        _hasStoragePermission = status.isGranted;
      });

      print('🔄 Permission status: $status');
      print('📋 Has storage permission: $_hasStoragePermission');

      // if (!_hasStoragePermission) {
      //   _showPermissionDialog();
      // }
    } catch (e) {
      print('❌ Permission error: $e');
      setState(() {
        _hasStoragePermission = false;
      });
    }
  }

  // void _showPermissionDialog() {
  //   showDialog(
  //     context: context,
  //     builder: (BuildContext context) {
  //       return AlertDialog(
  //         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
  //         title: Row(
  //           children: [
  //             Icon(Icons.folder_outlined, color: AppColors.primaryBlue, size: 24.sp),
  //             SizedBox(width: 12.w),
  //             Text('Storage Permission Required', style: TextStyle(fontSize: 15.sp),),
  //           ],
  //         ),
  //         content: const Text(
  //           'This app needs storage permission to download result files. Please grant permission in app settings.',
  //         ),
  //         actions: [
  //           TextButton(
  //             onPressed: () => Navigator.of(context).pop(),
  //             child: Text('Cancel', style: TextStyle(color: Colors.grey[600])),
  //           ),
  //           ElevatedButton(
  //             onPressed: () {
  //               Navigator.of(context).pop();
  //               openAppSettings();
  //             },
  //             style: ElevatedButton.styleFrom(
  //               backgroundColor: AppColors.primaryBlue,
  //               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
  //             ),
  //             child: const Text('Open Settings', style: TextStyle(color: Colors.white)),
  //           ),
  //         ],
  //       );
  //     },
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    final userData = widget.loginResponseModel.data;
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
            leading: _buildAppBarLeading(),
            title: Text(
              'Student Results',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20.sp,
                fontWeight: FontWeight.w600,
                fontFamily: 'Poppins',
              ),
            ),
          ),
        ),
      ),
      drawer: TrialCustomDrawer(
        loginResponseModel: widget.loginResponseModel,
        profPic: userData?.fpicture ?? "asset/images/Student.png",
        userName: "${userData?.firstname} ${userData?.lastname}" ?? "Ikegou faith Sochima",
        adno: userData?.adno ?? "RCN/2021/064",
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: Container(
            height: MediaQuery.of(context).size.height,
            decoration: const BoxDecoration(
              color: Colors.white,
            ),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildHeaderSection(),
                  _buildFormSection(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderSection() {
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
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(color: Colors.white.withOpacity(0.3)),
            ),
            child: Icon(
              Icons.assessment_outlined,
              color: Colors.white,
              size: 40.sp,
            ),
          ),
          SizedBox(height: 20.h),
          Text(
            'Academic Results',
            style: TextStyle(
              fontSize: 28.sp,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              fontFamily: 'Poppins',
              letterSpacing: 0.5,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Select your academic criteria to download\nyour result statement',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16.sp,
              color: Colors.white.withOpacity(0.8),
              fontFamily: 'Poppins',
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormSection() {
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
            _buildSelectionHeader(),
            SizedBox(height: 30.h),
            _buildDropdownField(
              label: 'Academic Session',
              hint: 'Select academic session',
              value: selectedSessionName,
              icon: Icons.calendar_today_outlined,
              onTap: () => _showDropdown(context, 'session'),
              isLoading: isLoadingSessions,
            ),
            SizedBox(height: 20.h),
            _buildDropdownField(
              label: 'Class',
              hint: 'Select class',
              value: selectedClassName,
              icon: Icons.school_outlined,
              onTap: () => _showDropdown(context, 'class'),
              isLoading: isLoadingClasses,
            ),
            SizedBox(height: 20.h),
            _buildDropdownField(
              label: 'Class Arm',
              hint: selectedClass.isEmpty ? 'Select class first' : 'Select class arm',
              value: selectedClassArmName,
              icon: Icons.group_outlined,
              onTap: selectedClass.isEmpty ? null : () => _showDropdown(context, 'class_arm'),
              isLoading: isLoadingClassArms,
            ),
            SizedBox(height: 20.h),
            _buildDropdownField(
              label: 'Term',
              hint: 'Select term',
              value: selectedTermName,
              icon: Icons.date_range_outlined,
              onTap: () => _showDropdown(context, 'term'),
            ),
            SizedBox(height: 50.h),
            _buildFetchButton(),
            SizedBox(height: 30.h),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectionHeader() {
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
            'SELECTION CRITERIA',
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
          'Choose Parameters',
          style: TextStyle(
            fontSize: 24.sp,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
            fontFamily: 'Poppins',
          ),
        ),
        SizedBox(height: 6.h),
        Text(
          'Please select the required academic parameters to generate and download your result',
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

  Widget _buildDropdownField({
    required String label,
    required String hint,
    required String value,
    required IconData icon,
    VoidCallback? onTap,
    bool isLoading = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
            fontFamily: 'Poppins',
          ),
        ),
        SizedBox(height: 8.h),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16.r),
            color: Colors.grey[50],
            border: Border.all(
              color: onTap == null ? Colors.grey.shade300 :
              value.isNotEmpty ? AppColors.primaryBlue.withOpacity(0.3) : Colors.grey.shade300,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(16.r),
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 18.h),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8.w),
                      decoration: BoxDecoration(
                        color: onTap == null
                            ? Colors.grey.withOpacity(0.3)
                            : AppColors.primaryBlue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      child: Icon(
                        icon,
                        color: onTap == null ? Colors.grey : AppColors.primaryBlue,
                        size: 20.sp,
                      ),
                    ),
                    SizedBox(width: 16.w),
                    Expanded(
                      child: Text(
                        value.isEmpty ? hint : value,
                        style: TextStyle(
                          fontSize: 16.sp,
                          color: value.isEmpty ? Colors.grey[500] : Colors.black87,
                          fontWeight: value.isEmpty ? FontWeight.w400 : FontWeight.w500,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),
                    if (isLoading)
                      SizedBox(
                        width: 20.w,
                        height: 20.h,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primaryBlue,
                        ),
                      )
                    else
                      Icon(
                        Icons.expand_more_rounded,
                        color: onTap == null ? Colors.grey : Colors.grey.shade600,
                        size: 24.sp,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFetchButton() {
    return Container(
      width: double.infinity,
      height: 56.h,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16.r),
        gradient: _canFetchResults()
            ? LinearGradient(
          colors: [
            AppColors.primaryBlue,
            AppColors.primaryBlue.withOpacity(0.8),
          ],
        )
            : null,
        color: _canFetchResults() ? null : Colors.grey[300],
        boxShadow: _canFetchResults()
            ? [
          BoxShadow(
            color: AppColors.primaryBlue.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _canFetchResults() ? _fetchResults : null,
          borderRadius: BorderRadius.circular(16.r),
          child: Center(
            child: isLoading
                ? SizedBox(
              width: 24.w,
              height: 24.h,
              child: const CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2.5,
              ),
            )
                : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.download_rounded,
                  color: _canFetchResults() ? Colors.white : Colors.grey[600],
                  size: 22.sp,
                ),
                SizedBox(width: 12.w),
                Text(
                  'Fetch & Download Results',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: _canFetchResults() ? Colors.white : Colors.grey[600],
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDropdown(BuildContext context, String type) {
    List<Map<String, String>> items;
    String title;
    IconData titleIcon;

    switch (type) {
      case 'session':
        items = sessions;
        title = 'Academic Session';
        titleIcon = Icons.calendar_today_outlined;
        break;
      case 'class':
        items = classes;
        title = 'Class';
        titleIcon = Icons.school_outlined;
        break;
      case 'class_arm':
        items = classArms;
        title = 'Class Arm';
        titleIcon = Icons.group_outlined;
        break;
      case 'term':
        items = terms;
        title = 'Term';
        titleIcon = Icons.date_range_outlined;
        break;
      default:
        return;
    }

    if ((type == 'session' && isLoadingSessions) ||
        (type == 'class' && isLoadingClasses) ||
        (type == 'class_arm' && isLoadingClassArms)) {
      _showErrorSnackbar('Loading data, please wait...');
      return;
    }

    if (items.isEmpty && type != 'term') {
      _showErrorSnackbar('No ${type}s available. Please check your connection and try again.');
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(25.r),
            topRight: Radius.circular(25.r),
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 50.w,
              height: 5.h,
              margin: EdgeInsets.only(top: 12.h),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(3.r),
              ),
            ),
            Container(
              padding: EdgeInsets.all(25.w),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primaryBlue,
                    AppColors.primaryBlue.withOpacity(0.8),
                  ],
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(25.r),
                  topRight: Radius.circular(25.r),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(10.w),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Icon(
                      titleIcon,
                      color: Colors.white,
                      size: 24.sp,
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: Text(
                      'Select $title',
                      style: TextStyle(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: IconButton(
                      icon: Icon(Icons.close_rounded, color: Colors.white, size: 20.sp),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: items.isEmpty
                  ? Container(
                padding: EdgeInsets.all(40.w),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: EdgeInsets.all(20.w),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                      child: Icon(
                        Icons.inbox_outlined,
                        size: 40.sp,
                        color: Colors.grey[400],
                      ),
                    ),
                    SizedBox(height: 20.h),
                    Text(
                      'No items available',
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[600],
                        fontFamily: 'Poppins',
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      'Please check your connection and try again',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: Colors.grey[500],
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
              )
                  : ListView.builder(
                padding: EdgeInsets.all(20.w),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  return Container(
                    margin: EdgeInsets.only(bottom: 12.h),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16.r),
                      border: Border.all(
                        color: Colors.grey[200]!,
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          _selectItem(type, item['id']!, item['name']!);
                          Navigator.pop(context);
                        },
                        borderRadius: BorderRadius.circular(16.r),
                        child: Padding(
                          padding: EdgeInsets.all(20.w),
                          child: Row(
                            children: [
                              Container(
                                width: 12.w,
                                height: 12.h,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      AppColors.primaryBlue,
                                      AppColors.primaryBlue.withOpacity(0.7),
                                    ],
                                  ),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              SizedBox(width: 16.w),
                              Expanded(
                                child: Text(
                                  item['name']!,
                                  style: TextStyle(
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black87,
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                              ),
                              Icon(
                                Icons.arrow_forward_ios_rounded,
                                color: Colors.grey[400],
                                size: 16.sp,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _selectItem(String type, String id, String name) {
    setState(() {
      switch (type) {
        case 'session':
          selectedSession = id;
          selectedSessionName = name;
          break;
        case 'class':
          selectedClass = id;
          selectedClassName = name;
          selectedClassArm = '';
          selectedClassArmName = '';
          classArms = [];
          _fetchClassArms(id);
          break;
        case 'class_arm':
          selectedClassArm = id;
          selectedClassArmName = name;
          break;
        case 'term':
          selectedTerm = id;
          selectedTermName = name;
          break;
      }
    });
  }

  bool _canFetchResults() {
    return selectedSession.isNotEmpty &&
        selectedClass.isNotEmpty &&
        selectedClassArm.isNotEmpty &&
        selectedTerm.isNotEmpty &&
        !isLoading &&
        !isLoadingSessions &&
        !isLoadingClasses &&
        !isLoadingClassArms;
  }

  // [Keep all existing API methods unchanged from here...]
  Future<void> fetchResults({
    required String session,
    required String classId,
    required String classArm,
    required String term,
    required BuildContext context,
  }) async {
    try {
      print("🔄 Attempting to fetch results");
      print("📝 Session: $session");
      print("📝 Term: $term");

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? '';

      // Determine which endpoint to use based on term selection
      String endpoint;
      Map<String, dynamic> requestBody;

      if (term == '4') { // Annual term
        endpoint = "https://rosarycollegenise.com/api/result_api/getAnnualresult";
        requestBody = {
          'session': session,
        };
        print("📌 Using Annual Result Endpoint");
      } else {
        endpoint = "https://rosarycollegenise.com/api/result_api/getTermresult";
        requestBody = {
          'session': session,
          'class_id': classId,
          'class_arm': classArm,
          'term': term,
        };
        print("📌 Using Term Result Endpoint");
      }

      print("📤 Request body: ${jsonEncode(requestBody)}");

      final response = await http.post(
        Uri.parse(endpoint),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(requestBody),
      ).timeout(const Duration(seconds: 30));

      print("📥 Response Status: ${response.statusCode}");
      print("📥 Response Body: ${response.body}");

      if (response.statusCode == 200) {
        String responseBody = response.body.trim();
        int jsonStartIndex = responseBody.indexOf('{');

        if (jsonStartIndex != -1) {
          String jsonString = responseBody.substring(jsonStartIndex);
          final responseData = jsonDecode(jsonString);

          print("🔍 Response keys: ${responseData.keys.toList()}");
          print("🔍 Status value: ${responseData['status']}");

          if (responseData['status'] == 1) {
            try {
              // Handle Annual Result
              if (term == '4') {
                AnnualResultResponse annualResponse = AnnualResultResponse.fromJson(responseData);

                if (context.mounted) {
                  _showSuccessSnackbar(responseData['message'] ?? 'Annual results fetched successfully');

                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => ViewAnnualResultScreen(
                        annualResultResponse: annualResponse,
                      ),
                    ),
                  );
                }
              } else {
                // Handle Term Result (existing logic)
                ResultResponse resultResponse = ResultResponse.fromJson(responseData);

                if (context.mounted) {
                  _showSuccessSnackbar(responseData['message'] ?? 'Results fetched successfully');

                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => ViewResultScreen(
                        resultResponse: resultResponse,
                      ),
                    ),
                  );
                }
              }
            } catch (e) {
              print("❌ Error parsing result response: $e");
              if (context.mounted) {
                _showErrorSnackbar("Error processing results data");
              }
            }
          } else {
            print("❌ API returned error status: ${responseData['status']}");
            if (context.mounted) {
              _showErrorSnackbar(responseData['message'] ?? 'Failed to fetch results');
            }
          }
        } else {
          throw FormatException("No valid JSON found in response");
        }
      } else {
        print("❌ HTTP Error: ${response.statusCode}");
        try {
          final responseData = jsonDecode(response.body);
          _handleResultError(responseData, context);
        } catch (e) {
          if (context.mounted) {
            _showErrorSnackbar("Server error: ${response.statusCode}");
          }
        }
      }
    } on SocketException catch (e) {
      print("❌ Socket Exception: $e");
      if (context.mounted) {
        _showErrorSnackbar("Connection failed. Check your internet connection");
      }
    } on TimeoutException catch (e) {
      print("❌ Timeout Exception: $e");
      if (context.mounted) {
        _showErrorSnackbar("Request timeout. Please try again");
      }
    } on FormatException catch (e) {
      print("❌ JSON Format Error: $e");
      if (context.mounted) {
        _showErrorSnackbar("Invalid response format from server");
      }
    } catch (error) {
      print("❌ General Error: $error");
      if (context.mounted) {
        _showErrorSnackbar("Failed to fetch results. Please try again");
      }
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _downloadPDF(String fileUrl) async {
    try {
      print("📥 Starting PDF download from: $fileUrl");

      if (!_hasStoragePermission) {
        await _checkPermissions();
        if (!_hasStoragePermission) {
          _showErrorSnackbar("Storage permission is required to download files");
          return;
        }
      }

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? '';

      // Clean up the URL - remove double slashes
      String cleanUrl = fileUrl.replaceAll('//ceeinc/', '/ceeinc/');
      print("🔧 Cleaned URL: $cleanUrl");

      // Try multiple download strategies
      http.Response? response;

      // Strategy 1: Try with full authentication headers (like your API calls)
      try {
        print("🔄 Trying Strategy 1: Full authentication headers...");
        response = await http.get(
          Uri.parse(cleanUrl),
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/pdf, */*',
            'scode': schoolCode ?? "",
            'User-Agent': 'Flutter App',
            'Content-Type': 'application/json',
            'Cache-Control': 'no-cache',
            'Pragma': 'no-cache',
          },
        ).timeout(const Duration(seconds: 60));

        print("📥 Strategy 1 Response Status: ${response.statusCode}");
      } catch (e) {
        print("❌ Strategy 1 failed: $e");
      }

      // Strategy 2: If Strategy 1 fails, try POST request (some APIs require POST for file downloads)
      if (response == null || response.statusCode != 200) {
        try {
          print("🔄 Trying Strategy 2: POST request...");

          // Extract filename from URL for POST body
          final uri = Uri.parse(cleanUrl);
          final pathSegments = uri.pathSegments;
          final filename = pathSegments.isNotEmpty ? pathSegments.last : '';

          final Map<String, dynamic> requestBody = {
            'file_url': cleanUrl,
            'filename': filename,
          };

          response = await http.post(
            Uri.parse("${baseUrl}result_api/downloadResult"), // You might need to adjust this endpoint
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
              'Accept': 'application/pdf, */*',
              'scode': schoolCode ?? "",
            },
            body: jsonEncode(requestBody),
          ).timeout(const Duration(seconds: 60));

          print("📥 Strategy 2 Response Status: ${response.statusCode}");
        } catch (e) {
          print("❌ Strategy 2 failed: $e");
        }
      }

      // Strategy 3: Try with session cookies (if the server uses session-based auth)
      if (response == null || response.statusCode != 200) {
        try {
          print("🔄 Trying Strategy 3: With cookies...");
          response = await http.get(
            Uri.parse(cleanUrl),
            headers: {
              'Authorization': 'Bearer $token',
              'Accept': 'application/pdf, */*',
              'scode': schoolCode ?? "",
              'User-Agent': 'Mozilla/5.0 (Linux; Android 10; Mobile) AppleWebKit/537.36',
              'Referer': baseUrl,
              'Cookie': 'auth_token=$token; scode=${schoolCode ?? ""}',
            },
          ).timeout(const Duration(seconds: 60));

          print("📥 Strategy 3 Response Status: ${response.statusCode}");
        } catch (e) {
          print("❌ Strategy 3 failed: $e");
        }
      }

      // Strategy 4: Try the original URL (without cleaning)
      if (response == null || response.statusCode != 200) {
        try {
          print("🔄 Trying Strategy 4: Original URL...");
          response = await http.get(
            Uri.parse(fileUrl), // Original URL
            headers: {
              'Authorization': 'Bearer $token',
              'Accept': 'application/pdf, */*',
              'scode': schoolCode ?? "",
            },
          ).timeout(const Duration(seconds: 60));

          print("📥 Strategy 4 Response Status: ${response.statusCode}");
        } catch (e) {
          print("❌ Strategy 4 failed: $e");
        }
      }

      // Check if any strategy worked
      if (response != null && response.statusCode == 200) {
        // Check if response is actually a PDF
        final contentType = response.headers['content-type'] ?? '';
        print("📋 Content-Type: $contentType");

        if (contentType.contains('application/pdf') || response.bodyBytes.length > 1000) {
          final downloadPath = await _getDownloadsDirectoryPath();
          print('📁 Using download path: $downloadPath');

          final timestamp = DateTime.now().millisecondsSinceEpoch;
          final fileName = 'student_result_$timestamp.pdf';
          final filePath = '$downloadPath/$fileName';

          final file = File(filePath);
          await file.writeAsBytes(response.bodyBytes);

          print("✅ PDF downloaded successfully to: $filePath");

          if (mounted) {
            setState(() {
              _lastDownloadedFile = filePath;
            });

            _showSuccessSnackbar("Result downloaded successfully!");
          }

          // Open file immediately after download
          await _openDownloadedFile();
        } else {
          print("❌ Response is not a PDF file");
          print("📄 Response content: ${response.body.substring(0, 500)}...");
          _showErrorSnackbar("Server returned invalid file format");
        }
      } else {
        print("❌ All download strategies failed");
        print("📥 Final response status: ${response?.statusCode}");
        print("📄 Final response body: ${response?.body}");

        // Show specific error message based on status code
        if (response?.statusCode == 403) {
          _showErrorSnackbar("Access denied. The file may have expired or you don't have permission to download it.");
        } else if (response?.statusCode == 404) {
          _showErrorSnackbar("File not found. Please generate a new result.");
        } else {
          _showErrorSnackbar("Failed to download file. Please try again later.");
        }
      }
    } on TimeoutException catch (e) {
      print("❌ Download timeout: $e");
      if (mounted) {
        _showErrorSnackbar("Download timeout. Please try again with a stable connection.");
      }
    } on SocketException catch (e) {
      print("❌ Download network error: $e");
      if (mounted) {
        _showErrorSnackbar("Network error. Please check your internet connection.");
      }
    } catch (e) {
      print("❌ Download error: $e");
      if (mounted) {
        String errorMessage = "Failed to download result";

        if (e.toString().contains('Permission denied')) {
          errorMessage = "Storage permission required. Please grant permission in app settings.";
          await _checkPermissions();
        } else if (e.toString().contains('No space left')) {
          errorMessage = "Insufficient storage space";
        }

        _showErrorSnackbar("$errorMessage: ${e.toString()}");
      }
    }
  }

  Future<String> _getDownloadsDirectoryPath() async {
    try {
      if (Platform.isAndroid) {
        // Try to get the Downloads directory
        Directory? downloadsDir = await getExternalStorageDirectory();

        if (downloadsDir != null) {
          // For Android, the external storage directory is usually the root
          // We need to navigate to the Downloads folder
          String downloadsPath = '${downloadsDir.path}/Download';
          if (downloadsDir.path.contains('emulated')) {
            downloadsPath = '/storage/emulated/0/Download';
          }

          // Create directory if it doesn't exist
          final dir = Directory(downloadsPath);
          if (!await dir.exists()) {
            await dir.create(recursive: true);
          }

          // Create a subfolder for our app
          final appDir = Directory('$downloadsPath/RosaryResults');
          if (!await appDir.exists()) {
            await appDir.create(recursive: true);
          }

          print('✅ Using Downloads path: ${appDir.path}');
          return appDir.path;
        }
      }

      // Fallback for iOS or if Android method fails
      final directory = await getApplicationDocumentsDirectory();
      final path = '${directory.path}/RosaryResults';
      final dir = Directory(path);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      return path;
    } catch (e) {
      print('❌ Error getting Downloads path: $e');
      // Ultimate fallback
      final directory = await getTemporaryDirectory();
      return directory.path;
    }
  }

  Future<void> _openDownloadedFile() async {
    if (_lastDownloadedFile == null) return;

    try {
      print("📂 Opening file: $_lastDownloadedFile");
      final result = await OpenFile.open(_lastDownloadedFile!);
      print('📂 Open file result: ${result.message}');

      if (result.type != ResultType.done && mounted) {
        _showErrorSnackbar("Could not open file. The file is saved at: $_lastDownloadedFile");
      }
    } catch (e) {
      print('❌ Error opening file: $e');
      if (mounted) {
        _showErrorSnackbar("File downloaded to: $_lastDownloadedFile");
      }
    }
  }

  void _handleResultError(Map body, BuildContext context) {
    final errorMessage = body["message"] ?? "Failed to fetch results";
    print("❌ Result Error: $errorMessage");

    if (context.mounted) {
      _showErrorSnackbar(errorMessage);
    }
  }

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.white, size: 20.sp),
            SizedBox(width: 12.w),
            Expanded(child: Text(message, style: TextStyle(fontFamily: 'Poppins'))),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      ),
    );
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_rounded, color: Colors.white, size: 20.sp),
            SizedBox(width: 12.w),
            Expanded(child: Text(message, style: TextStyle(fontFamily: 'Poppins'))),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      ),
    );
  }

  void _fetchResults() {
    setState(() {
      isLoading = true;
    });

    fetchResults(
      session: selectedSession,
      classId: selectedClass,
      classArm: selectedClassArm,
      term: selectedTerm,
      context: context,
    );
  }
}