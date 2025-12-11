import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:wallet/core/utils/color_utils/color_util.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'dart:io';

import '../../../core/models/annual_result_model.dart';

class ViewAnnualResultScreen extends StatefulWidget {
  final AnnualResultResponse annualResultResponse;

  const ViewAnnualResultScreen({
    super.key,
    required this.annualResultResponse,
  });

  @override
  State<ViewAnnualResultScreen> createState() => _ViewAnnualResultScreenState();
}

class _ViewAnnualResultScreenState extends State<ViewAnnualResultScreen>
    with TickerProviderStateMixin {
  late AnnualResultResponse resultData;
  late TabController _tabController;
  bool isDownloading = false;
  double downloadProgress = 0.0;
  String? downloadedFilePath;

  // Term names and indices mapping
  final Map<String, String> termNames = {
    '1': 'First Term',
    '2': 'Second Term',
    '3': 'Third Term',
  };

  @override
  void initState() {
    super.initState();
    resultData = widget.annualResultResponse;
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Color _getGradeColorWidget(int total) {
    if (total >= 90) return Colors.green;
    if (total >= 80) return Colors.blue;
    if (total >= 70) return Colors.amber;
    if (total >= 60) return Colors.orange;
    if (total >= 50) return Colors.red;
    return Colors.red.shade900;
  }

  String _getGrade(int total) {
    if (total >= 90) return 'A';
    if (total >= 80) return 'B';
    if (total >= 70) return 'C';
    if (total >= 60) return 'D';
    if (total >= 50) return 'E';
    return 'F';
  }

  Future<void> _downloadResult() async {
    try {
      setState(() {
        isDownloading = true;
        downloadProgress = 0.0;
      });

      // Get the download directory
      Directory? directory;
      if (Platform.isAndroid) {
        directory = await getExternalStorageDirectory();
      } else {
        directory = await getApplicationDocumentsDirectory();
      }

      if (directory == null) {
        throw Exception("Could not access storage directory");
      }

      // Create a custom folder for results
      final resultFolder = Directory('${directory.path}/Results');
      if (!await resultFolder.exists()) {
        await resultFolder.create(recursive: true);
      }

      // Generate filename with timestamp - use .html extension since it's HTML content
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final student = resultData.data.student;
      final fileName = 'Annual_Result_${student.replaceAll('/', '_')}_$timestamp.html';
      final filePath = '${resultFolder.path}/$fileName';

      // Download the file
      Dio dio = Dio();
      await dio.download(
        resultData.url,
        filePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            setState(() {
              downloadProgress = received / total;
            });
          }
        },
      );

      setState(() {
        isDownloading = false;
        downloadedFilePath = filePath;
      });

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Result downloaded successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }

      // Open the file immediately after download
      await _openDownloadedFile();
    } catch (e) {
      setState(() {
        isDownloading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Download failed: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
      print("❌ Download error: $e");
    }
  }

  Future<void> _openDownloadedFile() async {
    if (downloadedFilePath != null) {
      try {
        final result = await OpenFile.open(downloadedFilePath!);
        if (result.type != ResultType.done) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Could not open file: ${result.message}'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error opening file: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Widget _buildScoreBar(int ca, int exam, int total) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'CA: $ca',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
            Text(
              'Exam: $exam',
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
            Text(
              'Total: $total',
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        SizedBox(height: 6.h),
        Row(
          children: [
            Expanded(
              flex: ca,
              child: Container(
                height: 6.h,
                decoration: BoxDecoration(
                  color: Colors.blue[400],
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(3.r),
                    bottomLeft: Radius.circular(3.r),
                  ),
                ),
              ),
            ),
            Expanded(
              flex: exam,
              child: Container(
                height: 6.h,
                color: Colors.blue[200],
              ),
            ),
            Expanded(
              flex: (100 - total).clamp(0, 100),
              child: Container(
                height: 6.h,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(3.r),
                    bottomRight: Radius.circular(3.r),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildResultCard(AnnualSubject subject, String termKey) {
    final termScore = subject.terms[termKey];
    if (termScore == null) return const SizedBox.shrink();

    final grade = _getGrade(termScore.totalm);
    final color = _getGradeColorWidget(termScore.totalm);

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border(
          left: BorderSide(
            color: color,
            width: 4.w,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  subject.name.isNotEmpty
                      ? subject.name[0].toUpperCase() + subject.name.substring(1)
                      : '',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(width: 12.w),
              Container(
                width: 44.w,
                height: 44.w,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: color.withOpacity(0.3),
                    width: 2.w,
                  ),
                ),
                child: Center(
                  child: Text(
                    grade,
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          _buildScoreBar(
            termScore.ca,
            termScore.exam,
            termScore.totalm,
          ),
        ],
      ),
    );
  }

  Widget _buildTermTab(String termKey) {
    final subjectsForTerm = resultData.data.subjects
        .where((subject) => subject.terms.containsKey(termKey))
        .toList();

    if (subjectsForTerm.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 50.sp,
              color: Colors.grey[400],
            ),
            SizedBox(height: 16.h),
            Text(
              'No results available',
              style: TextStyle(
                fontSize: 16.sp,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: EdgeInsets.all(16.w),
      children: [
        ...subjectsForTerm.map((subject) => _buildResultCard(subject, termKey)).toList(),
        SizedBox(height: 100.h),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = resultData.data;
    final overall = data.overall;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        leading: GestureDetector(
          child: Icon(Icons.arrow_back, color: AppColors.primaryBlue),
          onTap: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Text(
          'Annual Results',
          style: TextStyle(
            fontSize: 21.sp,
            fontWeight: FontWeight.w600,
            color: AppColors.primaryBlue,
          ),
        ),
        elevation: 0,
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // Student Info Card
              Container(
                width: double.infinity,
                margin: EdgeInsets.all(16.w),
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primaryBlue,
                      AppColors.primaryBlue.withOpacity(0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12.r),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryBlue.withOpacity(0.2),
                      spreadRadius: 2,
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.student.toUpperCase(),
                      style: TextStyle(
                        fontSize: 15.5.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 12.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Position',
                              style: TextStyle(
                                fontSize: 14.sp,
                                color: Colors.white.withOpacity(0.8),
                              ),
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              overall.position,
                              style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Class Average',
                              style: TextStyle(
                                fontSize: 13.sp,
                                color: Colors.white.withOpacity(0.8),
                              ),
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              overall.avgm.toStringAsFixed(2),
                              style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Total Score',
                              style: TextStyle(
                                fontSize: 13.sp,
                                color: Colors.white.withOpacity(0.8),
                              ),
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              overall.total.toStringAsFixed(2),
                              style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: 8.h,),
              Padding(
                padding: EdgeInsets.only(left: 15.w, right: 15.w),
                child: SizedBox(
                  width: double.infinity,
                  height: 50.h,
                  child: ElevatedButton.icon(
                    onPressed: isDownloading ? null : _downloadResult,
                    icon: Icon(
                      isDownloading ? Icons.downloading : Icons.download,
                      color: Colors.white,
                    ),
                    label: Text(
                      isDownloading ? 'Downloading...' : 'Download Annual Result',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      disabledBackgroundColor: Colors.grey[400],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      elevation: 2,
                    ),
                  ),
                ),
              ),
              // TabBar
              Container(
                color: Colors.white,
                child: TabBar(
                  controller: _tabController,
                  indicatorColor: AppColors.primaryBlue,
                  indicatorWeight: 3.w,
                  labelColor: AppColors.primaryBlue,
                  unselectedLabelColor: Colors.grey[600],
                  labelStyle: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                  ),
                  unselectedLabelStyle: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                  ),
                  tabs: [
                    Tab(
                      text: '1st Term',
                      icon: Icon(Icons.school_outlined, size: 20.sp),
                    ),
                    Tab(
                      text: '2nd Term',
                      icon: Icon(Icons.school_outlined, size: 20.sp),
                    ),
                    Tab(
                      text: '3rd Term',
                      icon: Icon(Icons.school_outlined, size: 20.sp),
                    ),
                  ],
                ),
              ),

              // TabBarView
              Expanded(
                child: TabBarView(
                  physics: NeverScrollableScrollPhysics(),
                  controller: _tabController,
                  children: [
                    _buildTermTab('1'),
                    _buildTermTab('2'),
                    _buildTermTab('3'),
                  ],
                ),
              ),
              SizedBox(height: 20.h,)
            ],
          ),

          // Download Button at Bottom
        ],
      ),
    );
  }
}