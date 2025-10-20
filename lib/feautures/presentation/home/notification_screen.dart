// newsletter_screen.dart
import 'dart:io';
import 'dart:async';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:wallet/core/models/news_letter_model.dart';
import 'package:wallet/core/utils/color_utils/color_util.dart';

import '../../../core/controllers/methods_controller.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> with TickerProviderStateMixin {
  bool _isLoading = true;
  bool _isDownloading = false;
  String? _downloadingId;
  bool _hasStoragePermission = false;
  String? _downloadPath;
  String? _lastDownloadedFile;
  bool _showOpenFileButton = false;

  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeStorage();
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

  Future<void> _initializeStorage() async {
    await _checkPermissions();
    await _setupDownloadPath();
    await _fetchNewsletters();
  }


  Future<void> _setupDownloadPath() async {
    try {
      if (Platform.isAndroid) {
        final androidInfo = await DeviceInfoPlugin().androidInfo;

        if (androidInfo.version.sdkInt >= 30) {
          // Android 11+ - First check if we have MANAGE_EXTERNAL_STORAGE permission
          final hasManagePermission = await Permission.manageExternalStorage.isGranted;

          if (hasManagePermission) {
            // Try public Downloads first
            try {
              _downloadPath = '/storage/emulated/0/Download/Newsletters';
              final dir = Directory(_downloadPath!);
              if (!await dir.exists()) {
                await dir.create(recursive: true);
              }
              // Test if we can actually write to this location
              final testFile = File('$_downloadPath/test.txt');
              await testFile.writeAsString('test');
              await testFile.delete();
              print('✅ Using public Downloads: $_downloadPath');
            } catch (e) {
              print('❌ Cannot use public Downloads: $e');
              // Fallback to Documents
              try {
                _downloadPath = '/storage/emulated/0/Documents/Newsletters';
                final dir = Directory(_downloadPath!);
                if (!await dir.exists()) {
                  await dir.create(recursive: true);
                }
                // Test write access
                final testFile = File('$_downloadPath/test.txt');
                await testFile.writeAsString('test');
                await testFile.delete();
                print('✅ Using public Documents: $_downloadPath');
              } catch (e2) {
                print('❌ Cannot use public Documents: $e2');
                // Final fallback to app-specific storage
                final directory = await getExternalStorageDirectory();
                _downloadPath = '${directory?.path}/Newsletters';
                print('🔄 Using app-specific storage: $_downloadPath');
              }
            }
          } else {
            // No MANAGE_EXTERNAL_STORAGE permission - use app-specific storage directly
            print('📱 No MANAGE_EXTERNAL_STORAGE permission, using app-specific storage');
            final directory = await getExternalStorageDirectory();
            _downloadPath = '${directory?.path}/Newsletters';
            print('📁 Using app-specific storage: $_downloadPath');
          }
        } else {
          // Android 10 and below - Use public Downloads
          _downloadPath = '/storage/emulated/0/Download/Newsletters';
          final dir = Directory(_downloadPath!);
          if (!await dir.exists()) {
            await dir.create(recursive: true);
          }
          print('✅ Using Downloads (Android 10-): $_downloadPath');
        }
      } else {
        // iOS - Use Documents directory
        final directory = await getApplicationDocumentsDirectory();
        _downloadPath = '${directory.path}/Newsletters';
        final dir = Directory(_downloadPath!);
        if (!await dir.exists()) {
          await dir.create(recursive: true);
        }
        print('✅ Using iOS Documents: $_downloadPath');
      }

      // Ensure the directory exists
      if (_downloadPath != null) {
        final dir = Directory(_downloadPath!);
        if (!await dir.exists()) {
          await dir.create(recursive: true);
        }
      }

      print('📁 Final download path: $_downloadPath');
    } catch (e) {
      print('❌ Error setting up download path: $e');
      // Ultimate fallback
      try {
        final directory = await getApplicationDocumentsDirectory();
        _downloadPath = '${directory.path}/Newsletters';
        final dir = Directory(_downloadPath!);
        if (!await dir.exists()) {
          await dir.create(recursive: true);
        }
        print('🔄 Ultimate fallback path: $_downloadPath');
      } catch (fallbackError) {
        print('❌ Even fallback failed: $fallbackError');
        _downloadPath = null;
      }
    }
  }

  Future<void> _checkPermissions() async {
    if (!Platform.isAndroid) {
      setState(() {
        _hasStoragePermission = true;
      });
      return;
    }

    try {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      PermissionStatus status = PermissionStatus.denied;

      if (androidInfo.version.sdkInt >= 33) {
        // Android 13+ (API 33+) - For downloading files, we don't need media permissions
        // We can use app-specific storage or request MANAGE_EXTERNAL_STORAGE for public directories

        // Try to use MANAGE_EXTERNAL_STORAGE for public Downloads access
        status = await Permission.manageExternalStorage.status;
        if (!status.isGranted) {
          status = await Permission.manageExternalStorage.request();
        }

        // If MANAGE_EXTERNAL_STORAGE is denied, we can still use app-specific storage
        // which doesn't require permissions
        if (!status.isGranted) {
          print('📱 MANAGE_EXTERNAL_STORAGE denied, will use app-specific storage');
          status = PermissionStatus.granted; // App-specific storage doesn't need permission
        }

      } else if (androidInfo.version.sdkInt >= 30) {
        // Android 11-12 (API 30-32) - Try manage external storage first
        status = await Permission.manageExternalStorage.status;
        if (!status.isGranted) {
          status = await Permission.manageExternalStorage.request();
        }

        // If manage external storage is denied, we can still use app-specific storage
        if (!status.isGranted) {
          status = PermissionStatus.granted; // App-specific storage doesn't need permission
        }
      } else {
        // Android 10 and below - Use traditional storage permission
        status = await Permission.storage.status;
        if (!status.isGranted) {
          status = await Permission.storage.request();
        }
      }

      setState(() {
        _hasStoragePermission = status.isGranted;
      });

      print('🔄 Permission status: $status');
      print('📱 Android SDK: ${androidInfo.version.sdkInt}');
      print('📋 Has storage permission: $_hasStoragePermission');
    } catch (e) {
      print('❌ Permission check error: $e');
      // Set to true so app can function with app-specific storage
      setState(() {
        _hasStoragePermission = true;
      });
    }
  }
  Future<void> _fetchNewsletters() async {
    setState(() {
      _isLoading = true;
    });

    await AuthController.getNewsletters(context: context);

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _downloadNewsletter(Newsletter newsletter) async {
    // Check permissions and path before downloading
    if (_downloadPath == null) {
      await _setupDownloadPath();
    }

    if (!_hasStoragePermission) {
      await _checkPermissions();
    }

    setState(() {
      _isDownloading = true;
      _downloadingId = newsletter.id;
    });

    try {
      // Pass the download path to the controller
      final downloadedFile = await AuthController.downloadNewsletter(
        context: context,
        newsletter: newsletter,
        downloadPath: _downloadPath,
      );

      if (mounted) {
        setState(() {
          _lastDownloadedFile = downloadedFile;
          _showOpenFileButton = true;
        });

        // Hide the button after 10 seconds
        Timer(Duration(seconds: 10), () {
          if (mounted) {
            setState(() {
              _showOpenFileButton = false;
            });
          }
        });

        _showSuccessSnackbar("Newsletter downloaded successfully!");
      }
    } catch (e) {
      print('❌ Download error: $e');

      if (mounted) {
        String errorMessage = "Download failed";

        if (e.toString().contains('Permission denied')) {
          errorMessage = "Storage permission required. Please grant permission and try again.";
          // Re-check permissions
          await _checkPermissions();
        } else if (e.toString().contains('No space left')) {
          errorMessage = "Insufficient storage space";
        } else if (e.toString().contains('Network')) {
          errorMessage = "Network error. Please check your connection.";
        }

        _showErrorSnackbar(errorMessage);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDownloading = false;
          _downloadingId = null;
        });
      }
    }
  }

  // Open the downloaded file or show its location
  Future<void> _openDownloadedFile() async {
    if (_lastDownloadedFile == null) return;

    try {
      // Try to open the file with default app
      await AuthController.openFile(_lastDownloadedFile!);
    } catch (e) {
      print('❌ Error opening file: $e');
      if (mounted) {
        _showInfoSnackbar("File downloaded to: $_lastDownloadedFile");
      }
    }
  }

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.white, size: 20.sp),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
        action: SnackBarAction(
          label: 'OPEN',
          textColor: Colors.white,
          onPressed: () => _openDownloadedFile(),
        ),
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
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      ),
    );
  }

  void _showInfoSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.info_rounded, color: Colors.white, size: 20.sp),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.primaryBlue,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      ),
    );
  }

  // Show permission dialog when needed
  Future<void> _showPermissionDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
          title: Row(
            children: [
              Icon(Icons.folder_outlined, color: AppColors.primaryBlue, size: 24.sp),
              SizedBox(width: 12.w),
              Text(
                'Storage Permission Required',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          content: Text(
            'This app needs storage permission to download newsletters. Please grant permission in the next dialog or go to Settings to enable storage access.',
            style: TextStyle(
              fontFamily: 'Poppins',
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontFamily: 'Poppins',
                ),
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _checkPermissions();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
              ),
              child: Text(
                'Grant Permission',
                style: TextStyle(
                  color: Colors.white,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    print('🐛 DEBUG - newsletters count: ${AuthController.newsletters.length}');
    print('🐛 DEBUG - isLoading: $_isLoading');
    print('🐛 DEBUG - hasStoragePermission: $_hasStoragePermission');
    return Scaffold(
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
                icon: Icon(Icons.arrow_back, color: Colors.white, size: 20.sp),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            title: Text(
              'Newsletters',
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
                  onPressed: _fetchNewsletters,
                  icon: Icon(
                    Icons.refresh_rounded,
                    color: Colors.white,
                    size: 20.sp,
                  ),
                ),
              ),
            ],
          ),
        ),
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
            child: Column(
              children: [
                _buildHeaderSection(),
                Expanded(
                  child: _buildContentSection(),
                ),
              ],
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
              Icons.campaign_outlined,
              color: Colors.white,
              size: 40.sp,
            ),
          ),
          SizedBox(height: 20.h),
          Text(
            'School Newsletters',
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
            'Stay updated with the latest news\nand announcements from your school',
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
      child: Column(
        children: [
          // Open file button (shows temporarily after download)
          if (_showOpenFileButton && _lastDownloadedFile != null)
            Container(
              width: double.infinity,
              margin: EdgeInsets.fromLTRB(30.w, 20.h, 30.w, 10.h),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green, Colors.green.shade600],
                ),
                borderRadius: BorderRadius.circular(16.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _openDownloadedFile,
                  borderRadius: BorderRadius.circular(16.r),
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 20.w),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.folder_open_rounded, color: Colors.white, size: 20.sp),
                        SizedBox(width: 12.w),
                        Text(
                          "Open Downloaded File",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 16.sp,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // Main content
          Expanded(
            child: _isLoading
                ? _buildLoadingState()
                : AuthController.newsletters.isEmpty
                ? _buildEmptyState()
                : _buildNewsletterList(),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: CircularProgressIndicator(
              color: AppColors.primaryBlue,
              strokeWidth: 3,
            ),
          ),
          SizedBox(height: 24.h),
          Text(
            'Loading newsletters...',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
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
                Icons.campaign_outlined,
                size: 60.sp,
                color: Colors.grey[400],
              ),
            ),
            SizedBox(height: 24.h),
            Text(
              'No newsletters available',
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
                fontFamily: 'Poppins',
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'Check back later for new updates\nfrom your school',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.grey[500],
                fontFamily: 'Poppins',
                height: 1.4,
              ),
            ),
            SizedBox(height: 30.h),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primaryBlue,
                    AppColors.primaryBlue.withOpacity(0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(16.r),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryBlue.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _fetchNewsletters,
                  borderRadius: BorderRadius.circular(16.r),
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 24.w),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.refresh_rounded, color: Colors.white, size: 20.sp),
                        SizedBox(width: 8.w),
                        Text(
                          'Refresh',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                            fontSize: 16.sp,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNewsletterList() {
    return RefreshIndicator(
      onRefresh: _fetchNewsletters,
      color: AppColors.primaryBlue,
      child: ListView.builder(
        padding: EdgeInsets.fromLTRB(30.w, 20.h, 30.w, 30.h),
        itemCount: AuthController.newsletters.length,
        itemBuilder: (context, index) {
          final newsletter = AuthController.newsletters[index];
          return _buildNewsletterCard(newsletter, index);
        },
      ),
    );
  }

  Widget _buildNewsletterCard(Newsletter newsletter, int index) {
    final isCurrentlyDownloading = _isDownloading && _downloadingId == newsletter.id;

    return Container(
      margin: EdgeInsets.only(bottom: 20.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: Colors.grey.shade200,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header section
          Container(
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primaryBlue.withOpacity(0.05),
                  AppColors.primaryBlue.withOpacity(0.02),
                ],
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20.r),
                topRight: Radius.circular(20.r),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primaryBlue,
                        AppColors.primaryBlue.withOpacity(0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16.r),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryBlue.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.article_outlined,
                    color: Colors.white,
                    size: 24.sp,
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        newsletter.caption,
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Poppins',
                          color: Colors.black87,
                          height: 1.2,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
                        decoration: BoxDecoration(
                          color: AppColors.primaryBlue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.schedule_rounded,
                              color: AppColors.primaryBlue,
                              size: 14.sp,
                            ),
                            SizedBox(width: 6.w),
                            Text(
                              newsletter.formattedDate,
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: AppColors.primaryBlue,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Content section
          if (newsletter.note.isNotEmpty)
            Padding(
              padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 20.h),
              child: Text(
                newsletter.note,
                style: TextStyle(
                  fontSize: 15.sp,
                  color: Colors.grey[700],
                  fontFamily: 'Poppins',
                  height: 1.5,
                ),
              ),
            ),

          // Download button section
          Padding(
            padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 20.h),
            child: Container(
              width: double.infinity,
              height: 56.h,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16.r),
                gradient: isCurrentlyDownloading
                    ? LinearGradient(
                  colors: [Colors.grey.shade400, Colors.grey.shade500],
                )
                    : LinearGradient(
                  colors: [
                    AppColors.primaryBlue,
                    AppColors.primaryBlue.withOpacity(0.8),
                  ],
                ),
                boxShadow: !isCurrentlyDownloading
                    ? [
                  BoxShadow(
                    color: AppColors.primaryBlue.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ]
                    : null,
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: isCurrentlyDownloading ? null : () => _downloadNewsletter(newsletter),
                  borderRadius: BorderRadius.circular(16.r),
                  child: Center(
                    child: isCurrentlyDownloading
                        ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20.sp,
                          height: 20.sp,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Text(
                          "Downloading...",
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Poppins',
                            color: Colors.white,
                          ),
                        ),
                      ],
                    )
                        : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.download_rounded,
                          size: 22.sp,
                          color: Colors.white,
                        ),
                        SizedBox(width: 12.w),
                        Text(
                          "Download Newsletter",
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Poppins',
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}