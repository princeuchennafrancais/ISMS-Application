import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wallet/feautures/presentation/home/payment_processing.dart';
import 'dart:convert';

import '../../../core/controllers/school_service.dart';
import '../../../core/enum/navigation_source.dart';
import '../../../core/models/login_model.dart';
import '../../../core/utils/color_utils/color_util.dart';
import '../../../core/utils/widget_utils/trial_custom_drawer.dart';

class SchoolFeesScreen extends StatefulWidget {
  final LoginResponseModel loginResponseModel;
  final NavigationSource navigationSource;

  const SchoolFeesScreen({
    super.key,
    required this.loginResponseModel,
    this.navigationSource = NavigationSource.other,
  });

  @override
  State<SchoolFeesScreen> createState() => _SchoolFeesScreenState();
}

class _SchoolFeesScreenState extends State<SchoolFeesScreen> with TickerProviderStateMixin {
  // Controllers and selected values
  String selectedSession = '';
  String selectedSessionName = '';
  String selectedTerm = '';
  String selectedTermName = '';
  String selectedClassm = '';
  String selectedClassmName = '';
  String? schoolCode;

  // Loading states
  bool isLoading = false;
  bool isLoadingSessions = false;
  bool isLoadingClasses = false;
  bool isLoadingFees = false;

  // API data
  List<Map<String, String>> sessions = [];
  List<Map<String, String>> classes = [];

  // Static terms data
  final List<Map<String, String>> terms = [
    {'id': '1', 'name': 'First Term'},
    {'id': '2', 'name': 'Second Term'},
    {'id': '3', 'name': 'Third Term'},
  ];

  // Fees details
  Map<String, dynamic>? feesDetails;

  // Track if fees have been fetched
  bool showFeesDetails = false;

  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
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

  // Fetch Sessions
  Future<void> fetchSessions() async {
    setState(() {
      isLoadingSessions = true;
    });

    try {
      print("🔄 Fetching sessions from: https://api.ceemact.com/class_api/getSessions");

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? '';

      final response = await http.get(
        Uri.parse("https://api.ceemact.com/class_api/getSessions"),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
          'scode': schoolCode ?? "",
        },
      ).timeout(const Duration(seconds: 30));

      print("📥 Sessions Response Status: ${response.statusCode}");

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
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

  // Fetch Classes
  Future<void> fetchClasses() async {
    setState(() {
      isLoadingClasses = true;
    });

    try {
      print("🔄 Fetching classes from: https://api.ceemact.com/class_api/getClasses");

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? '';

      final response = await http.get(
        Uri.parse("https://api.ceemact.com/class_api/getClasses"),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
          'scode': schoolCode ?? "",
        },
      ).timeout(const Duration(seconds: 30));

      print("📥 Classes Response Status: ${response.statusCode}");

      if (response.statusCode == 200) {
        String responseBody = response.body.trim();

        // Extract valid JSON from response
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
    } catch (error) {
      print("❌ Classes General Error: $error");
      _showErrorSnackbar("Failed to load classes. Please try again");
    } finally {
      setState(() {
        isLoadingClasses = false;
      });
    }
  }

  // Fetch Fees Details
  Future<void> fetchFeesDetails() async {
    setState(() {
      isLoadingFees = true;
      feesDetails = null;
    });

    try {
      print("🔄 Fetching fees details from: https://rosarycollegenise.com/api/payment_api/getCustompayment");

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? '';

      final Map<String, dynamic> requestBody = {
        'session': selectedSession,
        'term': selectedTerm,
        'classm': selectedClassm,
      };

      print("📤 Request Body: ${jsonEncode(requestBody)}");

      final response = await http.post(
        Uri.parse("https://rosarycollegenise.com/api/payment_api/getCustompayment"),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(requestBody),
      ).timeout(const Duration(seconds: 30));

      print("📥 Fees Response Status: ${response.statusCode}");
      print("📥 Fees Response Body: ${response.body}");

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        if (responseData['status'] == 1) {
          setState(() {
            feesDetails = responseData;
            showFeesDetails = true; // Set to true when fees are fetched
          });
          print("✅ Fees details loaded successfully");
        } else {
          print("❌ Fees API Error: ${responseData['message']}");
          _showErrorSnackbar(responseData['message'] ?? 'Failed to load fees details');
        }
      } else {
        print("❌ Fees HTTP Error: ${response.statusCode}");
        _showErrorSnackbar("Failed to load fees details: Server error ${response.statusCode}");
      }
    } on SocketException catch (e) {
      print("❌ Fees Socket Exception: $e");
      _showErrorSnackbar("Connection failed. Check your internet connection");
    } on TimeoutException catch (e) {
      print("❌ Fees Timeout Exception: $e");
      _showErrorSnackbar("Request timeout. Please try again");
    } catch (error) {
      print("❌ Fees General Error: $error");
      _showErrorSnackbar("Failed to load fees details. Please try again");
    } finally {
      setState(() {
        isLoadingFees = false;
      });
    }
  }

  // Make Payment
  void _makePayment() {
    if (feesDetails == null || feesDetails!['status'] != 1) return;

    // Extract fees items
    final List<dynamic> feesList = feesDetails!['data'] ?? [];

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentProcessingScreen(
          feesDetails: feesDetails!,
          session: selectedSession,
          term: selectedTerm,
          classm: selectedClassm,
          sessionName: selectedSessionName,
          termName: selectedTermName,
          className: selectedClassmName,
        ),
      ),
    );
  }

  bool _canFetchFees() {
    return selectedSession.isNotEmpty &&
        selectedTerm.isNotEmpty &&
        selectedClassm.isNotEmpty &&
        !isLoadingFees;
  }

  bool _canMakePayment() {
    return feesDetails != null &&
        feesDetails!['status'] == 1 &&
        !isLoading;
  }

  void _selectItem(String type, String id, String name) {
    setState(() {
      switch (type) {
        case 'session':
          selectedSession = id;
          selectedSessionName = name;
          // Clear fees details when session changes
          feesDetails = null;
          showFeesDetails = false;
          break;
        case 'term':
          selectedTerm = id;
          selectedTermName = name;
          // Clear fees details when term changes
          feesDetails = null;
          showFeesDetails = false;
          break;
        case 'classm':
          selectedClassm = id;
          selectedClassmName = name;
          // Clear fees details when class changes
          feesDetails = null;
          showFeesDetails = false;
          break;
      }
    });
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
      case 'term':
        items = terms;
        title = 'Term';
        titleIcon = Icons.date_range_outlined;
        break;
      case 'classm':
        items = classes;
        title = 'Class';
        titleIcon = Icons.school_outlined;
        break;
      default:
        return;
    }

    if ((type == 'session' && isLoadingSessions) ||
        (type == 'classm' && isLoadingClasses)) {
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
        return IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white, size: 20.sp),
          onPressed: () => Navigator.pop(context),
        );
    }
  }

  Widget _buildDropdownField({
    required String label,
    required String hint,
    required String value,
    required IconData icon,
    VoidCallback? onTap,
    bool isLoading = false,
  }) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      margin: EdgeInsets.only(bottom: 20.h),
      child: Column(
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
      ),
    );
  }

  Widget _buildFeesDetails() {
    if (feesDetails == null) return Container();

    if (isLoadingFees) {
      return Container(
        margin: EdgeInsets.only(top: 20.h),
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Center(
          child: Column(
            children: [
              CircularProgressIndicator(
                color: AppColors.primaryBlue,
              ),
              SizedBox(height: 15.h),
              Text(
                'Loading fees details...',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (feesDetails!['status'] != 1) {
      return Container(
        margin: EdgeInsets.only(top: 20.h),
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: Colors.red.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 60.w,
              height: 60.h,
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 30.sp,
              ),
            ),
            SizedBox(height: 15.h),
            Text(
              'No Fees Details Found',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              feesDetails!['message'] ?? 'No fees details available for the selected parameters',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    // Extract fees data
    final List<dynamic> feesList = feesDetails!['data'] ?? [];

    if (feesList.isEmpty) {
      return Container(
        margin: EdgeInsets.only(top: 20.h),
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: Colors.blue.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 60.w,
              height: 60.h,
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.info_outline,
                color: Colors.blue,
                size: 30.sp,
              ),
            ),
            SizedBox(height: 15.h),
            Text(
              'No Fees Items',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'No fees items found for this selection',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    // Calculate total amount
    double totalAmount = 0;
    for (var item in feesList) {
      if (item is Map && item['amount'] != null) {
        try {
          totalAmount += double.parse(item['amount'].toString());
        } catch (e) {
          print("❌ Error parsing amount: ${item['amount']}");
        }
      }
    }

    return Container(
      margin: EdgeInsets.only(top: 20.h),
      child: Column(
        children: [
          // Header for fees breakdown
          Container(
            padding: EdgeInsets.symmetric(horizontal: 4.w),
            child: Row(
              children: [
                Text(
                  'Fees Breakdown',
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                    fontFamily: 'Poppins',
                  ),
                ),
                const Spacer(),
                Container(
                  height: 35.h,
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10.r),
                    border: Border.all(
                      color: AppColors.primaryBlue.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: TextButton(
                    onPressed: () {
                      setState(() {
                        showFeesDetails = false;
                        feesDetails = null;
                      });
                    },
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.edit_outlined,
                          color: AppColors.primaryBlue,
                          size: 14.sp,
                        ),
                        SizedBox(width: 6.w),
                        Text(
                          "Change Selection",
                          style: TextStyle(
                            color: AppColors.primaryBlue,
                            fontFamily: "Poppins",
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 20.h),

          // Selected parameters card
          Container(
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primaryBlue.withOpacity(0.1),
                  AppColors.primaryBlue.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(
                color: AppColors.primaryBlue.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildParameterItem(Icons.calendar_today_outlined, 'Session', selectedSessionName),
                _buildParameterItem(Icons.date_range_outlined, 'Term', selectedTermName),
                _buildParameterItem(Icons.school_outlined, 'Class', selectedClassmName),
              ],
            ),
          ),
          SizedBox(height: 25.h),

          // Fees items list
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: feesList.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;

                return Container(
                  margin: EdgeInsets.only(bottom: 12.h),
                  padding: EdgeInsets.all(20.w),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white,
                        Colors.grey[50]!,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20.r),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.08),
                        spreadRadius: 0,
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    border: Border.all(
                      color: Colors.grey.withOpacity(0.05),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 45.w,
                        height: 45.h,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppColors.primaryBlue.withOpacity(0.15),
                              AppColors.primaryBlue.withOpacity(0.05),
                            ],
                          ),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.primaryBlue.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: TextStyle(
                              color: AppColors.primaryBlue,
                              fontWeight: FontWeight.w700,
                              fontSize: 16.sp,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 16.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['component']?.toString().toUpperCase() ?? 'FEE ITEM',
                              style: TextStyle(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                                fontFamily: 'Poppins',
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: 6.h),
                            Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryBlue.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(6.r),
                                  ),
                                  child: Text(
                                    'Session: ${item['session'] ?? 'N/A'}',
                                    style: TextStyle(
                                      fontSize: 10.sp,
                                      color: AppColors.primaryBlue,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 6.w),
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(6.r),
                                  ),
                                  child: Text(
                                    'Term: ${item['term'] ?? 'N/A'}',
                                    style: TextStyle(
                                      fontSize: 10.sp,
                                      color: Colors.green,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 16.w),
                      Text(
                        '₦${item['amount'] ?? '0.00'}',
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primaryBlue,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),

          SizedBox(height: 25.h),

          // Total amount card
          Container(
            padding: EdgeInsets.all(25.w),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primaryBlue.withOpacity(0.1),
                  AppColors.primaryBlue.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(
                color: AppColors.primaryBlue.withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TOTAL AMOUNT',
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[600],
                        fontFamily: 'Poppins',
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      '${feesList.length} item${feesList.length == 1 ? '' : 's'}',
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '₦${totalAmount.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 28.sp,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryBlue,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Text(
                        'Payable Now',
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: Colors.green[700],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          SizedBox(height: 25.h),
        ],
      ),
    );
  }

  Widget _buildParameterItem(IconData icon, String title, String value) {
    return Column(
      children: [
        Container(
          width: 50.w,
          height: 50.h,
          decoration: BoxDecoration(
            color: AppColors.primaryBlue.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: AppColors.primaryBlue,
            size: 22.sp,
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          title,
          style: TextStyle(
            fontSize: 12.sp,
            color: Colors.grey[600],
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          value,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildFetchFeesButton() {
    if (showFeesDetails) return SizedBox.shrink();

    return Container(
      width: double.infinity,
      height: 56.h,
      margin: EdgeInsets.only(top: 10.h),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16.r),
        gradient: _canFetchFees()
            ? LinearGradient(
          colors: [
            AppColors.primaryBlue,
            AppColors.primaryBlue.withOpacity(0.8),
          ],
        )
            : null,
        color: _canFetchFees() ? null : Colors.grey[300],
        boxShadow: _canFetchFees()
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
          onTap: _canFetchFees() ? fetchFeesDetails : null,
          borderRadius: BorderRadius.circular(16.r),
          child: Center(
            child: isLoadingFees
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
                  Icons.search_rounded,
                  color: _canFetchFees() ? Colors.white : Colors.grey[600],
                  size: 22.sp,
                ),
                SizedBox(width: 12.w),
                Text(
                  'View Fees Details',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: _canFetchFees() ? Colors.white : Colors.grey[600],
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

  Widget _buildMakePaymentButton() {
    if (feesDetails == null || feesDetails!['status'] != 1) {
      return Container();
    }

    return Container(
      width: double.infinity,
      height: 56.h,
      margin: EdgeInsets.only(top: 20.h),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16.r),
        gradient: LinearGradient(
          colors: [
            Colors.green,
            Colors.green.withOpacity(0.8),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _makePayment,
          borderRadius: BorderRadius.circular(16.r),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.payment_rounded,
                  color: Colors.white,
                  size: 22.sp,
                ),
                SizedBox(width: 12.w),
                Text(
                  'Make Payment',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
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

  @override
  Widget build(BuildContext context) {
    final userData = widget.loginResponseModel.data;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFFAFAFA),
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
              'School Fees',
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
        userName: "${userData?.firstname} ${userData?.lastname}" ?? "Student",
        adno: userData?.adno ?? "",
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: RefreshIndicator(
            onRefresh: () async {
              await fetchSessions();
              await fetchClasses();
            },
            color: AppColors.primaryBlue,
            backgroundColor: Colors.white,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                children: [
                  _buildHeaderSection(),
                  _buildContentSection(),
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
      padding: EdgeInsets.only(top: 30.w, left: 30.w, right: 30.w, bottom: 40.w),
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
              Icons.payment_outlined,
              color: Colors.white,
              size: 40.sp,
            ),
          ),
          SizedBox(height: 20.h),
          Text(
            'School Fees Payment',
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
            'Select academic details to view your school fees breakdown',
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

  Widget _buildContentSection() {
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

            // Show dropdowns only when fees haven't been fetched yet
            if (!showFeesDetails) ...[
              _buildDropdownField(
                label: 'Academic Session',
                hint: 'Select academic session',
                value: selectedSessionName,
                icon: Icons.calendar_today_outlined,
                onTap: () => _showDropdown(context, 'session'),
                isLoading: isLoadingSessions,
              ),
              _buildDropdownField(
                label: 'Term',
                hint: 'Select term',
                value: selectedTermName,
                icon: Icons.date_range_outlined,
                onTap: () => _showDropdown(context, 'term'),
              ),
              _buildDropdownField(
                label: 'Class',
                hint: 'Select class',
                value: selectedClassmName,
                icon: Icons.school_outlined,
                onTap: () => _showDropdown(context, 'classm'),
                isLoading: isLoadingClasses,
              ),
              SizedBox(height: 20.h),
            ],

            _buildFetchFeesButton(),
            _buildFeesDetails(),
            _buildMakePaymentButton(),
            SizedBox(height: 40.h),
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
            showFeesDetails ? 'FEES SUMMARY' : 'FEES SELECTION',
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
          showFeesDetails ? 'Fees Breakdown' : 'Choose Parameters',
          style: TextStyle(
            fontSize: 24.sp,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
            fontFamily: 'Poppins',
          ),
        ),
        SizedBox(height: 6.h),
        Text(
          showFeesDetails
              ? 'Review your school fees breakdown and make payment'
              : 'Select academic parameters to view your school fees breakdown',
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
}