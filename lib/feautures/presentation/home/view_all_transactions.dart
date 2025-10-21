import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:http/http.dart' as http;
import 'package:wallet/core/controllers/api_endpoints.dart';
import 'package:wallet/feautures/presentation/home/transaction_detail.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wallet/core/utils/color_utils/color_util.dart';
import '../../../core/models/transactionHist_model.dart';
import '../../../core/controllers/school_service.dart'; // Add this import


class AllTransactionsScreen extends StatefulWidget {
  const AllTransactionsScreen({super.key});

  @override
  State<AllTransactionsScreen> createState() => _AllTransactionsScreenState();
}

class _AllTransactionsScreenState extends State<AllTransactionsScreen> {
  List<TransactionModel> allTransactions = [];
  List<TransactionModel> filteredTransactions = [];
  bool isLoadingTransactions = true;
  String? transactionError;
  String? schoolCode;

  String selectedFilter = 'All';
  String searchQuery = '';
  final TextEditingController searchController = TextEditingController();

  int currentPage = 1;
  final int itemsPerPage = 20;
  bool hasMoreData = true;

  @override
  void initState() {
    super.initState();
    _initializeDataAndFetchTransactions();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> _initializeDataAndFetchTransactions() async {
    try {
      final schoolData = await SchoolDataService.getSchoolData();
      schoolCode = schoolData?.schoolCode ?? "";

      print("🏫 School code initialized: '$schoolCode'");

      await fetchAllTransactions();
    } catch (e) {
      print("❌ Error initializing data: $e");
      setState(() {
        transactionError = 'Failed to initialize app data';
        isLoadingTransactions = false;
      });
    }
  }

  Future<void> fetchAllTransactions({bool loadMore = false}) async {
    try {
      if (!loadMore) {
        setState(() {
          isLoadingTransactions = true;
          transactionError = null;
        });
      }

      print("🔄 Fetching all transactions...");

      // Ensure school code is initialized
      if (schoolCode == null || schoolCode!.isEmpty) {
        print("🔄 School code not initialized, fetching now...");
        final schoolData = await SchoolDataService.getSchoolData();
        schoolCode = schoolData?.schoolCode ?? "";
        print("🏫 School code initialized in fetchAllTransactions: '$schoolCode'");
      }

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) {
        setState(() {
          transactionError = "No authentication token found";
          isLoadingTransactions = false;
        });
        return;
      }

      // Use regular HTTP GET request instead of MultipartRequest for JSON API
      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
        'scode': schoolCode ?? "",
      };

      // Print headers for debugging
      print("📋 All Transactions Request Headers:");
      headers.forEach((key, value) {
        print("   $key: '$value'");
      });

      print("📤 Sending all transactions request to: ${APIEndpoints.baseUrl}wallet_api/getWalletTransactions");
      print("🏫 School Code: '$schoolCode'");
      print("🔐 Auth Token: '${token.substring(0, 20)}...'"); // Only show first 20 chars for security

      final response = await http.get(
        Uri.parse('${APIEndpoints.baseUrl}wallet_api/getWalletTransactions'),
        headers: headers,
      ).timeout(Duration(seconds: 30));

      print("📥 All Transactions Response Status: ${response.statusCode}");
      print("📥 All Transactions Response Body: ${response.body}");

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        print("📊 Response Data Type: ${responseData.runtimeType}");
        print("📊 Response Data Keys: ${responseData is Map ? responseData.keys.toList() : 'Not a Map'}");

        // Handle nested response structure - payload should be an array like balance
        if (responseData.containsKey('payload')) {
          final payload = responseData['payload'];
          print("📦 Payload Type: ${payload.runtimeType}");
          print("📦 Payload Content: $payload");

          if (payload is List && payload.isNotEmpty) {
            // If payload is an array of transactions
            List<TransactionModel> fetchedTransactions = [];

            for (var transactionJson in payload) {
              if (transactionJson is Map<String, dynamic>) {
                try {
                  final transaction = TransactionModel.fromJson(transactionJson);
                  fetchedTransactions.add(transaction);
                } catch (e) {
                  print("⚠️ Error parsing transaction: $e");
                  print("⚠️ Transaction data: $transactionJson");
                }
              }
            }

            if (fetchedTransactions.isNotEmpty) {
              // Transform transfer actions to withdrawal (if needed)
              fetchedTransactions = fetchedTransactions.map((transaction) {
                if (transaction.action.toLowerCase() == 'transfer') {
                  return transaction.copyWith(action: 'withdrawal');
                }
                return transaction;
              }).toList();

              // Sort transactions by date (newest first)
              fetchedTransactions.sort((a, b) {
                try {
                  DateTime dateA = DateTime.parse(a.createdAt);
                  DateTime dateB = DateTime.parse(b.createdAt);
                  return dateB.compareTo(dateA); // Most recent first
                } catch (e) {
                  print("⚠️ Date parsing error: $e");
                  return 0;
                }
              });

              setState(() {
                if (loadMore) {
                  // Remove duplicates when loading more - use a unique field like createdAt + amount
                  Set<String> existingKeys = allTransactions.map((t) => '${t.createdAt}_${t.amount}').toSet();
                  List<TransactionModel> newTransactions = fetchedTransactions
                      .where((t) => !existingKeys.contains('${t.createdAt}_${t.amount}'))
                      .toList();
                  allTransactions.addAll(newTransactions);
                  print("📈 Added ${newTransactions.length} new transactions");
                } else {
                  allTransactions = fetchedTransactions;
                }
                applyFilters();
                isLoadingTransactions = false;
                transactionError = null;
              });

              print("✅ All transactions fetched successfully: ${allTransactions.length} transactions");
            } else {
              print("❌ No valid transactions found in payload array");
              setState(() {
                transactionError = 'No transactions found';
                isLoadingTransactions = false;
              });
            }
          } else if (payload is Map<String, dynamic>) {
            // Handle if payload is an object (fallback to original structure)
            if (payload['status'] == 1) {
              final transactionResponse = TransactionResponse.fromJson(payload);
              List<TransactionModel> fetchedTransactions = transactionResponse.data.data.data;

              // Transform transfer actions to withdrawal (if needed)
              fetchedTransactions = fetchedTransactions.map((transaction) {
                if (transaction.action.toLowerCase() == 'transfer') {
                  return transaction.copyWith(action: 'withdrawal');
                }
                return transaction;
              }).toList();

              // Sort transactions by date (newest first)
              fetchedTransactions.sort((a, b) {
                try {
                  DateTime dateA = DateTime.parse(a.createdAt);
                  DateTime dateB = DateTime.parse(b.createdAt);
                  return dateB.compareTo(dateA); // Most recent first
                } catch (e) {
                  print("⚠️ Date parsing error: $e");
                  return 0;
                }
              });

              setState(() {
                if (loadMore) {
                  // Remove duplicates when loading more
                  Set<String> existingKeys = allTransactions.map((t) => '${t.createdAt}_${t.amount}').toSet();
                  List<TransactionModel> newTransactions = fetchedTransactions
                      .where((t) => !existingKeys.contains('${t.createdAt}_${t.amount}'))
                      .toList();
                  allTransactions.addAll(newTransactions);
                  print("📈 Added ${newTransactions.length} new transactions");
                } else {
                  allTransactions = fetchedTransactions;
                }
                applyFilters();
                isLoadingTransactions = false;
                transactionError = null;
              });

              print("✅ All transactions fetched successfully from payload object: ${allTransactions.length} transactions");
            } else {
              final errorMessage = payload['message'] ?? 'Failed to fetch transactions';
              print("❌ Transaction fetch failed: $errorMessage");
              setState(() {
                transactionError = errorMessage;
                isLoadingTransactions = false;
              });
            }
          } else {
            print("❌ Invalid payload format: ${payload.runtimeType}");
            setState(() {
              transactionError = 'Invalid response format';
              isLoadingTransactions = false;
            });
          }
        } else {
          // Handle flat response without payload (fallback)
          print("📄 Using flat response structure for transactions");
          if (responseData['status'] == 1) {
            final transactionResponse = TransactionResponse.fromJson(responseData);
            List<TransactionModel> fetchedTransactions = transactionResponse.data.data.data;

            // Transform transfer actions to withdrawal (if needed)
            fetchedTransactions = fetchedTransactions.map((transaction) {
              if (transaction.action.toLowerCase() == 'transfer') {
                return transaction.copyWith(action: 'withdrawal');
              }
              return transaction;
            }).toList();

            // Sort transactions by date (newest first)
            fetchedTransactions.sort((a, b) {
              try {
                DateTime dateA = DateTime.parse(a.createdAt);
                DateTime dateB = DateTime.parse(b.createdAt);
                return dateB.compareTo(dateA); // Most recent first
              } catch (e) {
                print("⚠️ Date parsing error: $e");
                return 0;
              }
            });

            setState(() {
              if (loadMore) {
                // Remove duplicates when loading more
                Set<String> existingKeys = allTransactions.map((t) => '${t.createdAt}_${t.amount}').toSet();
                List<TransactionModel> newTransactions = fetchedTransactions
                    .where((t) => !existingKeys.contains('${t.createdAt}_${t.amount}'))
                    .toList();
                allTransactions.addAll(newTransactions);
                print("📈 Added ${newTransactions.length} new transactions");
              } else {
                allTransactions = fetchedTransactions;
              }
              applyFilters();
              isLoadingTransactions = false;
              transactionError = null;
            });

            print("✅ All transactions fetched successfully from flat response: ${allTransactions.length} transactions");
          } else {
            final errorMessage = responseData['message'] ?? 'Failed to fetch transactions';
            print("❌ Transaction fetch failed: $errorMessage");
            setState(() {
              transactionError = errorMessage;
              isLoadingTransactions = false;
            });
          }
        }
      } else if (response.statusCode == 401) {
        print("❌ Unauthorized: Token may be expired");
        setState(() {
          transactionError = "Session expired. Please login again";
          isLoadingTransactions = false;
        });
        // Optionally redirect to login screen
      } else {
        print("❌ HTTP Error: ${response.statusCode}");
        setState(() {
          transactionError = "Server error: ${response.statusCode}";
          isLoadingTransactions = false;
        });
      }
    } on SocketException catch (e) {
      print("❌ Socket Exception: $e");
      setState(() {
        transactionError = "Connection failed. Check your internet connection";
        isLoadingTransactions = false;
      });
    } on TimeoutException catch (e) {
      print("❌ Timeout Exception: $e");
      setState(() {
        transactionError = "Request timeout. Please try again";
        isLoadingTransactions = false;
      });
    } on FormatException catch (e) {
      print("❌ JSON Format Exception: $e");
      setState(() {
        transactionError = "Invalid response format from server";
        isLoadingTransactions = false;
      });
    } catch (error) {
      print("❌ General Error: $error");
      setState(() {
        transactionError = "Failed to fetch transactions. Please try again";
        isLoadingTransactions = false;
      });
    }
  }
  void applyFilters() {
    List<TransactionModel> filtered = List.from(allTransactions);

    // Apply action filter
    if (selectedFilter != 'All') {
      filtered = filtered.where((transaction) {
        if (selectedFilter == 'Debit') {
          // Include debit, withdrawal, and transfer actions as debit
          return transaction.action.toLowerCase() == 'debit' ||
              transaction.action.toLowerCase() == 'withdrawal' ||
              transaction.action.toLowerCase() == 'transfer';
        } else if (selectedFilter == 'Credit') {
          // Only include actual credit transactions
          return transaction.action.toLowerCase() == 'credit';
        }
        return true;
      }).toList();
    }

    // Apply search query
    if (searchQuery.isNotEmpty) {
      filtered = filtered.where((transaction) {
        return transaction.displayTitle.toLowerCase().contains(searchQuery.toLowerCase()) ||
            transaction.reference.toLowerCase().contains(searchQuery.toLowerCase()) ||
            transaction.status.toLowerCase().contains(searchQuery.toLowerCase()) ||
            transaction.formattedAmount.toLowerCase().contains(searchQuery.toLowerCase());
      }).toList();
    }

    setState(() {
      filteredTransactions = filtered;
    });
  }
  /// Handle search
  void onSearchChanged(String value) {
    setState(() {
      searchQuery = value;
    });
    applyFilters();
  }

  /// Handle filter change
  void onFilterChanged(String filter) {
    setState(() {
      selectedFilter = filter;
    });
    applyFilters();
  }

  /// Format transaction date
  String formatTransactionDate(String dateString) {
    try {
      DateTime date = DateTime.parse(dateString);
      DateTime now = DateTime.now();
      Duration difference = now.difference(date);

      if (difference.inDays == 0) {
        return "Today ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
      } else if (difference.inDays == 1) {
        return "Yesterday";
      } else if (difference.inDays < 7) {
        return "${difference.inDays} days ago";
      } else {
        return "${date.day}/${date.month}/${date.year}";
      }
    } catch (e) {
      return dateString;
    }
  }

  /// Get transaction icon based on action
  IconData getTransactionIcon(String action) {
    switch (action.toLowerCase()) {
      case 'transfer':
        return Icons.swap_horiz;
      case 'credit':
        return Icons.add_circle_outline;
      case 'debit':
        return Icons.remove_circle_outline;
      case 'withdrawal':
        return Icons.account_balance_wallet_outlined;
      default:
        return Icons.receipt_long;
    }
  }

  /// Get transaction color based on action
  Color getTransactionColor(String action) {
    switch (action.toLowerCase()) {
      case 'transfer':
        return Colors.blue;
      case 'credit':
        return Colors.green;
      case 'debit':
      case 'withdrawal':
        return Colors.red;
      default:
        return AppColors.primaryBlue;
    }
  }

  /// Navigate to transaction details
  void navigateToTransactionDetails(TransactionModel transaction) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TransactionDetailsScreen(transaction: transaction),
      ),
    );
  }

  /// Build transaction item
  Widget buildTransactionItem(TransactionModel transaction) {
    return GestureDetector(
      onTap: () => navigateToTransactionDetails(transaction),
      child: Container(
        margin: EdgeInsets.only(bottom: 12.h),
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 40.w,
              height: 40.h,
              decoration: BoxDecoration(
                color: getTransactionColor(transaction.action).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                getTransactionIcon(transaction.action),
                color: getTransactionColor(transaction.action),
                size: 20.sp,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.displayTitle,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14.sp,
                      color: Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    formatTransactionDate(transaction.createdAt),
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Colors.grey[600],
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 6.w,
                          vertical: 2.h,
                        ),
                        decoration: BoxDecoration(
                          color: transaction.isSuccessful
                              ? Colors.green.withOpacity(0.1)
                              : transaction.isPending
                              ? Colors.orange.withOpacity(0.1)
                              : Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                        child: Text(
                          transaction.status.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10.sp,
                            color: transaction.isSuccessful
                                ? Colors.green
                                : transaction.isPending
                                ? Colors.orange
                                : Colors.red,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          transaction.reference,
                          style: TextStyle(
                            fontSize: 10.sp,
                            color: Colors.grey[500],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  "${transaction.action.toLowerCase() == 'credit' ? '+' : '-'}${transaction.formattedAmount}",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14.sp,
                    color: getTransactionColor(transaction.action),
                  ),
                ),
                if (transaction.charges > 0)
                  Text(
                    "Fee: ${transaction.formattedCharges}",
                    style: TextStyle(
                      fontSize: 10.sp,
                      color: Colors.grey[600],
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Build filter chips
  /// Build filter chips
  Widget buildFilterChips() {
    final filters = ['All', 'Debit', 'Credit'];

    // Calculate counts for each filter
    int allCount = allTransactions.length;
    int debitCount = allTransactions.where((t) =>
    t.action.toLowerCase() == 'debit' ||
        t.action.toLowerCase() == 'withdrawal' ||
        t.action.toLowerCase() == 'transfer'
    ).length;
    int creditCount = allTransactions.where((t) =>
    t.action.toLowerCase() == 'credit'
    ).length;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((filter) {
          final isSelected = selectedFilter == filter;
          int count = 0;

          switch (filter) {
            case 'All':
              count = allCount;
              break;
            case 'Debit':
              count = debitCount;
              break;
            case 'Credit':
              count = creditCount;
              break;
          }

          return Padding(
            padding: EdgeInsets.only(right: 8.w),
            child: FilterChip(
              label: Text(
                '$filter ($count)',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: isSelected ? Colors.white : AppColors.primaryBlue,
                ),
              ),
              selected: isSelected,
              onSelected: (selected) => onFilterChanged(filter),
              backgroundColor: Colors.white,
              selectedColor: AppColors.primaryBlue,
              checkmarkColor: Colors.white,
              side: BorderSide(
                color: isSelected ? AppColors.primaryBlue : Colors.grey[300]!,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.transparent,

        foregroundColor: Colors.white,
        leading: GestureDetector(
          child: Icon(Icons.arrow_back, color: AppColors.primaryBlue,),
          onTap: () {
            Navigator.pop(context);
          },
        ),
        centerTitle: true,
        title: Text(
          'All Transactions',
          style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryBlue
          ),
        ),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search and Filter Section
          Container(
            color: Colors.transparent,
            padding: EdgeInsets.all(16.w),
            child: Column(
              children: [

                SizedBox(height: 6.h),

                // Filter Chips
                buildFilterChips(),
              ],
            ),
          ),

          // Transaction Count
          if (!isLoadingTransactions && transactionError == null)
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              child: Text(
                '${filteredTransactions.length} transaction${filteredTransactions.length != 1 ? 's' : ''} found',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12.sp,
                ),
              ),
            ),

          // Transactions List
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => fetchAllTransactions(),
              child: isLoadingTransactions
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      color: AppColors.primaryBlue,
                    ),
                    SizedBox(height: 16.h),
                    Text(
                      "Loading all transactions...",
                      style: TextStyle(
                        color: AppColors.primaryBlue,
                        fontSize: 14.sp,
                      ),
                    ),
                  ],
                ),
              )
                  : transactionError != null
                  ? Center(
                child: Padding(
                  padding: EdgeInsets.all(32.w),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64.sp,
                        color: Colors.red,
                      ),
                      SizedBox(height: 16.h),
                      Text(
                        transactionError!,
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 14.sp,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 24.h),
                      ElevatedButton(
                        onPressed: () => fetchAllTransactions(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryBlue,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(
                            horizontal: 32.w,
                            vertical: 12.h,
                          ),
                        ),
                        child: Text("Retry"),
                      ),
                    ],
                  ),
                ),
              )
                  : filteredTransactions.isEmpty && searchQuery.isEmpty
                  ? Center(
                child: Padding(
                  padding: EdgeInsets.all(32.w),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.receipt_long_outlined,
                        size: 64.sp,
                        color: Colors.grey[400],
                      ),
                      SizedBox(height: 16.h),
                      Text(
                        "No Transactions Available",
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        "Your transaction history will appear here",
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 14.sp,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
                  : filteredTransactions.isEmpty && searchQuery.isNotEmpty
                  ? Center(
                child: Padding(
                  padding: EdgeInsets.all(32.w),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.search_off,
                        size: 64.sp,
                        color: Colors.grey[400],
                      ),
                      SizedBox(height: 16.h),
                      Text(
                        "No Results Found",
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        "Try adjusting your search or filters",
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 14.sp,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
                  : ListView.builder(
                padding: EdgeInsets.all(16.w),
                itemCount: filteredTransactions.length,
                itemBuilder: (context, index) {
                  return buildTransactionItem(filteredTransactions[index]);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}