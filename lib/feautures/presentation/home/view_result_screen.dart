import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:wallet/core/utils/color_utils/color_util.dart';
import 'package:wallet/core/models/result_model.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'dart:io';

class ViewResultScreen extends StatefulWidget {
  final ResultResponse resultResponse;

  const ViewResultScreen({
    super.key,
    required this.resultResponse,
  });

  @override
  State<ViewResultScreen> createState() => _ViewResultScreenState();
}

class _ViewResultScreenState extends State<ViewResultScreen> {
  late ResultResponse resultData;
  bool isDownloading = false;
  double downloadProgress = 0.0;
  String? downloadedFilePath;

  @override
  void initState() {
    super.initState();
    resultData = widget.resultResponse;
  }

  Color _getGradeColorWidget(String grade) {
    switch (grade.toUpperCase()) {
      case 'A':
        return Colors.green;
      case 'B':
        return Colors.blue;
      case 'C':
        return Colors.amber;
      case 'D':
        return Colors.red;
      case 'E':
        return Colors.red.shade700;
      case 'F':
      case 'P':
        return Colors.red.shade900;
      default:
        return Colors.grey;
    }
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
      final fileName = 'Result_${student.regno.replaceAll('/', '_')}_$timestamp.html';
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
          SnackBar(
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
            duration: Duration(seconds: 3),
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
    double caPercent = ca / 100;
    double examPercent = exam / 100;
    double totalPercent = total / 100;

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
              flex: (100 - total),
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

  Widget _buildResultCard(SubjectResult result) {
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
            color: _getGradeColorWidget(result.grade),
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
                  result.displayName.isNotEmpty
                      ? result.displayName[0].toUpperCase() + result.displayName.substring(1)
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
                  color: _getGradeColorWidget(result.grade).withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _getGradeColorWidget(result.grade).withOpacity(0.3),
                    width: 2.w,
                  ),
                ),
                child: Center(
                  child: Text(
                    result.grade,
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                      color: _getGradeColorWidget(result.grade),
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          _buildScoreBar(result.ca, result.exam, result.total),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final student = resultData.data.student;
    final classPos = resultData.data.classPosition;
    final results = resultData.data.results;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        leading: GestureDetector(
          child: Icon(Icons.arrow_back_ios, color: AppColors.primaryBlue),
          onTap: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Text(
          'Academic Results',
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
          SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Student Info Card
                  Container(
                    width: double.infinity,
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
                          student.fullName.toUpperCase(),
                          style: TextStyle(
                            fontSize: 15.5.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          'Reg: ${student.regno}',
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                        SizedBox(height: 12.h),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildInfoItem(
                              'Position',
                              '${classPos.position} of ${classPos.totalStudents}',
                            ),
                            _buildInfoItem(
                              'Class Avg',
                              classPos.classAverage.toStringAsFixed(2),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 20.h),
                  SizedBox(height: 12.h),
                  SizedBox(
                    width: double.infinity,
                    height: 48.h,
                    child: ElevatedButton.icon(
                      onPressed: isDownloading ? null : _downloadResult,
                      icon: Icon(
                        isDownloading ? Icons.downloading : Icons.download,
                        color: Colors.white,
                        size: 20.sp,
                      ),
                      label: Text(
                        isDownloading ? 'Downloading...' : 'Download Full Result',
                        style: TextStyle(
                          fontSize: 15.sp,
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
                      ),
                    ),
                  ),

                  // Performance Summary
                  Container(
                    width: double.infinity,
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
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Performance Overview',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        SizedBox(height: 12.h),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildStatItem(
                              'A Grade',
                              results
                                  .where((r) => r.grade.toUpperCase() == 'A')
                                  .length
                                  .toString(),
                              Colors.green,
                            ),
                            _buildStatItem(
                              'C Grade',
                              results
                                  .where((r) => r.grade.toUpperCase() == 'C')
                                  .length
                                  .toString(),
                              Colors.amber,
                            ),
                            _buildStatItem(
                              'Below C',
                              results
                                  .where((r) =>
                              r.grade.toUpperCase() == 'D' ||
                                  r.grade.toUpperCase() == 'E' ||
                                  r.grade.toUpperCase() == 'F' ||
                                  r.grade.toUpperCase() == 'P')
                                  .length
                                  .toString(),
                              Colors.red,
                            ),
                            _buildStatItem(
                              'Total Subjects',
                              results.length.toString(),
                              AppColors.primaryBlue,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 20.h),

                  // Results Header
                  Text(
                    'Subject Results',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 12.h),

                  // Results List
                  ...results.map((result) => _buildResultCard(result)).toList(),

                  SizedBox(height: 120.h), // Extra space for download button
                ],
              ),
            ),
          ),

          // Download Button at Bottom
          // Positioned(
          //   bottom: 30,
          //   left: 0,
          //   right: 0,
          //   child: Container(
          //     padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          //     decoration: BoxDecoration(
          //       color: Colors.white,
          //       boxShadow: [
          //         BoxShadow(
          //           color: Colors.grey.withOpacity(0.2),
          //           spreadRadius: 1,
          //           blurRadius: 8,
          //           offset: const Offset(0, -2),
          //         ),
          //       ],
          //     ),
          //     child: Column(
          //       mainAxisSize: MainAxisSize.min,
          //       children: [
          //         // Download Progress Bar
          //         if (isDownloading)
          //           Column(
          //             children: [
          //               LinearProgressIndicator(
          //                 value: downloadProgress,
          //                 backgroundColor: Colors.grey[200],
          //                 valueColor: AlwaysStoppedAnimation<Color>(
          //                   AppColors.primaryBlue,
          //                 ),
          //               ),
          //               SizedBox(height: 8.h),
          //               Text(
          //                 'Downloading... ${(downloadProgress * 100).toStringAsFixed(0)}%',
          //                 style: TextStyle(
          //                   fontSize: 12.sp,
          //                   color: Colors.grey[600],
          //                 ),
          //               ),
          //               SizedBox(height: 8.h),
          //             ],
          //           ),
          //
          //         // Main Download Button
          //         SizedBox(
          //           width: double.infinity,
          //           height: 50.h,
          //           child: ElevatedButton.icon(
          //             onPressed: isDownloading ? null : _downloadResult,
          //             icon: Icon(
          //               isDownloading ? Icons.downloading : Icons.download,
          //               color: Colors.white,
          //             ),
          //             label: Text(
          //               isDownloading ? 'Downloading...' : 'Download Result',
          //               style: TextStyle(
          //                 fontSize: 16.sp,
          //                 fontWeight: FontWeight.w600,
          //                 color: Colors.white,
          //               ),
          //             ),
          //             style: ElevatedButton.styleFrom(
          //               backgroundColor: AppColors.primaryBlue,
          //               disabledBackgroundColor: Colors.grey[400],
          //               shape: RoundedRectangleBorder(
          //                 borderRadius: BorderRadius.circular(12.r),
          //               ),
          //               elevation: 2,
          //             ),
          //           ),
          //         ),
          //       ],
          //     ),
          //   ),
          // ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16.5.sp,
            color: Colors.white.withOpacity(0.8),
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          value,
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Container(
          width: 40.w,
          height: 40.w,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 17.sp,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ),
        SizedBox(height: 6.h),
        Text(
          label,
          style: TextStyle(
            fontSize: 13.5.sp,
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}