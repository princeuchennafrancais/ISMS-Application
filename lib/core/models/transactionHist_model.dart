String _capitalizeWords(String text) {
  if (text.isEmpty) return 'Transaction';

  // Split by spaces and capitalize each word
  return text.split(' ').map((word) {
    if (word.isEmpty) return word;
    return word[0].toUpperCase() + word.substring(1).toLowerCase();
  }).join(' ');
}

class TransactionModel {
  final String? payoutId;
  final String? splitPaymentId;
  final String? clientReference;
  final String? externalReference;
  final String reference;
  final String? narration;
  final String? description;
  final double amount;
  final double charges;
  final double settledAmount;
  final String currency;
  final bool settled;
  final String? settlementDate;
  final String? settlementCycle;
  final String channel;
  final String source;
  final String type;
  final String action;
  final String status;
  final bool balanceTransfer;
  final Map<String, dynamic>? clientMetadata;
  final Map<String, dynamic>? metadata;
  final String createdAt;
  final String updatedAt;
  final WalletInfo? wallet;
  final SettingInfo? setting;

  TransactionModel({
    this.payoutId,
    this.splitPaymentId,
    this.clientReference,
    this.externalReference,
    required this.reference,
    this.narration,
    this.description,
    required this.amount,
    required this.charges,
    required this.settledAmount,
    required this.currency,
    required this.settled,
    this.settlementDate,
    this.settlementCycle,
    required this.channel,
    required this.source,
    required this.type,
    required this.action,
    required this.status,
    required this.balanceTransfer,
    this.clientMetadata,
    this.metadata,
    required this.createdAt,
    required this.updatedAt,
    this.wallet,
    this.setting,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      payoutId: json['PayoutId'],
      splitPaymentId: json['SplitPaymentId'],
      clientReference: json['client_reference'],
      externalReference: json['external_reference'],
      reference: json['reference'] ?? '',
      narration: json['narration'],
      description: json['description'],
      amount: (json['amount'] ?? 0).toDouble(),
      charges: (json['charges'] ?? 0).toDouble(),
      settledAmount: (json['settled_amount'] ?? 0).toDouble(),
      currency: json['currency'] ?? 'NGN',
      settled: json['settled'] ?? false,
      settlementDate: json['settlement_date'],
      settlementCycle: json['settlement_cycle'],
      channel: json['channel'] ?? '',
      source: json['source'] ?? '',
      type: json['type'] ?? '',
      action: json['action'] ?? '',
      status: json['status'] ?? '',
      balanceTransfer: json['balance_transfer'] ?? false,
      clientMetadata: json['client_metadata'],
      metadata: json['metadata'],
      createdAt: json['createdAt'] ?? '',
      updatedAt: json['updatedAt'] ?? '',
      wallet: json['Wallet'] != null ? WalletInfo.fromJson(json['Wallet']) : null,
      setting: json['Setting'] != null ? SettingInfo.fromJson(json['Setting']) : null,
    );
  }

  // Added copyWith method
  TransactionModel copyWith({
    String? payoutId,
    String? splitPaymentId,
    String? clientReference,
    String? externalReference,
    String? reference,
    String? narration,
    String? description,
    double? amount,
    double? charges,
    double? settledAmount,
    String? currency,
    bool? settled,
    String? settlementDate,
    String? settlementCycle,
    String? channel,
    String? source,
    String? type,
    String? action,
    String? status,
    bool? balanceTransfer,
    Map<String, dynamic>? clientMetadata,
    Map<String, dynamic>? metadata,
    String? createdAt,
    String? updatedAt,
    WalletInfo? wallet,
    SettingInfo? setting,
  }) {
    return TransactionModel(
      payoutId: payoutId ?? this.payoutId,
      splitPaymentId: splitPaymentId ?? this.splitPaymentId,
      clientReference: clientReference ?? this.clientReference,
      externalReference: externalReference ?? this.externalReference,
      reference: reference ?? this.reference,
      narration: narration ?? this.narration,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      charges: charges ?? this.charges,
      settledAmount: settledAmount ?? this.settledAmount,
      currency: currency ?? this.currency,
      settled: settled ?? this.settled,
      settlementDate: settlementDate ?? this.settlementDate,
      settlementCycle: settlementCycle ?? this.settlementCycle,
      channel: channel ?? this.channel,
      source: source ?? this.source,
      type: type ?? this.type,
      action: action ?? this.action,
      status: status ?? this.status,
      balanceTransfer: balanceTransfer ?? this.balanceTransfer,
      clientMetadata: clientMetadata ?? this.clientMetadata,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      wallet: wallet ?? this.wallet,
      setting: setting ?? this.setting,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'PayoutId': payoutId,
      'SplitPaymentId': splitPaymentId,
      'client_reference': clientReference,
      'external_reference': externalReference,
      'reference': reference,
      'narration': narration,
      'description': description,
      'amount': amount,
      'charges': charges,
      'settled_amount': settledAmount,
      'currency': currency,
      'settled': settled,
      'settlement_date': settlementDate,
      'settlement_cycle': settlementCycle,
      'channel': channel,
      'source': source,
      'type': type,
      'action': action,
      'status': status,
      'balance_transfer': balanceTransfer,
      'client_metadata': clientMetadata,
      'metadata': metadata,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'Wallet': wallet?.toJson(),
      'Setting': setting?.toJson(),
    };
  }

  // UPDATED: Always shows Credit/Debit regardless of narration
  String get displayTitle {
    return _getActionDisplayName();
  }

  // UPDATED: Narration is now available separately for description purposes
  String get displayNarration {
    if (narration != null && narration!.isNotEmpty) {
      return _capitalizeWords(narration!);
    }
    return displayDescription;
  }

  String _getActionDisplayName() {
    switch (action.toLowerCase()) {
      case 'transfer':
      // For transfers, determine if it's credit or debit based on context
        if (source == 'wallet_transfer' && metadata != null && metadata!['destination'] != null) {
          // Outgoing transfer = Debit
          return 'Debit';
        } else {
          // Incoming transfer = Credit
          return 'Credit';
        }
      case 'credit':
        return 'Credit';
      case 'debit':
        return 'Debit';
      case 'deposit':
        return 'Credit';
      case 'withdrawal':
        return 'Debit';
      case 'payment':
        return 'Debit';
      default:
        return _capitalizeWords(action);
    }
  }

  String get displayDescription {
    if (description != null && description!.isNotEmpty) return description!;

    // Enhanced description based on transaction type and metadata
    switch (action.toLowerCase()) {
      case 'transfer':
        if (source == 'wallet_transfer' && metadata != null) {
          final destination = metadata!['destination'];
          if (destination != null) {
            final recipientName = destination['account_name'] ?? 'Unknown';
            return 'Transfer to $recipientName';
          }
        }
        return 'Transfer transaction';
      case 'credit':
        return 'Account credited';
      case 'debit':
        return 'Account debited';
      case 'withdrawal':
        return 'Withdrawal transaction';
      case 'deposit':
        return 'Deposit transaction';
      default:
        return 'Transaction processed';
    }
  }

  // Simple getter to determine transaction type
  String get transactionType {
    return _getActionDisplayName();
  }

  // UPDATED: More accurate transaction direction detection
  bool get isDebitTransaction {
    switch (action.toLowerCase()) {
      case 'debit':
      case 'withdrawal':
      case 'payment':
        return true;
      case 'transfer':
      // Check if it's an outgoing transfer
        return source == 'wallet_transfer' && metadata != null && metadata!['destination'] != null;
      default:
        return false;
    }
  }

  bool get isCreditTransaction {
    switch (action.toLowerCase()) {
      case 'credit':
      case 'deposit':
        return true;
      case 'transfer':
      // If it's not an outgoing transfer, it's incoming (credit)
        return !(source == 'wallet_transfer' && metadata != null && metadata!['destination'] != null);
      default:
        return false;
    }
  }

  // UPDATED: Amount display with proper +/- signs
  String get displayAmount {
    final prefix = isCreditTransaction ? '+' : '-';
    return "$prefix₦${amount.toStringAsFixed(2)}";
  }

  String get formattedAmount => "₦${amount.toStringAsFixed(2)}";
  String get formattedCharges => "₦${charges.toStringAsFixed(2)}";
  String get formattedSettledAmount => "₦${settledAmount.toStringAsFixed(2)}";

  bool get isSuccessful => status.toLowerCase() == 'successful';
  bool get isPending => status.toLowerCase() == 'pending';
  bool get isFailed => status.toLowerCase() == 'failed' || status.toLowerCase() == 'error';
}

class WalletInfo {
  final int id;
  final int merchantId;
  final int aggregatorId;
  final int customerId;
  final String walletId;
  final String reference;
  final String currency;
  final double balance;
  final double balancePendingSettlement;
  final String? subMerchant;
  final Map<String, dynamic>? bank;
  final String accountName;
  final String accountNumber;
  final String bankName;
  final String bankCode;
  final Map<String, dynamic>? meta;
  final bool active;
  final String type;
  final String createdAt;
  final String updatedAt;

  WalletInfo({
    required this.id,
    required this.merchantId,
    required this.aggregatorId,
    required this.customerId,
    required this.walletId,
    required this.reference,
    required this.currency,
    required this.balance,
    required this.balancePendingSettlement,
    this.subMerchant,
    this.bank,
    required this.accountName,
    required this.accountNumber,
    required this.bankName,
    required this.bankCode,
    this.meta,
    required this.active,
    required this.type,
    required this.createdAt,
    required this.updatedAt,
  });

  factory WalletInfo.fromJson(Map<String, dynamic> json) {
    return WalletInfo(
      id: json['id'] ?? 0,
      merchantId: json['MerchantId'] ?? 0,
      aggregatorId: json['AggregatorId'] ?? 0,
      customerId: json['CustomerId'] ?? 0,
      walletId: json['wallet_id'] ?? '',
      reference: json['reference'] ?? '',
      currency: json['currency'] ?? 'NGN',
      balance: (json['balance'] ?? 0).toDouble(),
      balancePendingSettlement: (json['balance_pending_settlement'] ?? 0).toDouble(),
      subMerchant: json['sub_merchant'],
      bank: json['bank'],
      accountName: json['account_name'] ?? '',
      accountNumber: json['account_number'] ?? '',
      bankName: json['bank_name'] ?? '',
      bankCode: json['bank_code'] ?? '',
      meta: json['meta'],
      active: json['active'] ?? true,
      type: json['type'] ?? '',
      createdAt: json['createdAt'] ?? '',
      updatedAt: json['updatedAt'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'MerchantId': merchantId,
      'AggregatorId': aggregatorId,
      'CustomerId': customerId,
      'wallet_id': walletId,
      'reference': reference,
      'currency': currency,
      'balance': balance,
      'balance_pending_settlement': balancePendingSettlement,
      'sub_merchant': subMerchant,
      'bank': bank,
      'account_name': accountName,
      'account_number': accountNumber,
      'bank_name': bankName,
      'bank_code': bankCode,
      'meta': meta,
      'active': active,
      'type': type,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  String get formattedBalance => "₦${balance.toStringAsFixed(2)}";
}

class SettingInfo {
  final String merchantRef;

  SettingInfo({required this.merchantRef});

  factory SettingInfo.fromJson(Map<String, dynamic> json) {
    return SettingInfo(
      merchantRef: json['MerchantRef'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {'MerchantRef': merchantRef};
}

class TransactionResponse {
  final int status;
  final String message;
  final TransactionData data;

  TransactionResponse({required this.status, required this.message, required this.data});

  factory TransactionResponse.fromJson(Map<String, dynamic> json) {
    return TransactionResponse(
      status: json['status'] ?? 0,
      message: json['message'] ?? '',
      data: TransactionData.fromJson(json['data'] ?? {}),
    );
  }
}

class TransactionData {
  final bool success;
  final String message;
  final TransactionDataInfo data;

  TransactionData({required this.success, required this.message, required this.data});

  factory TransactionData.fromJson(Map<String, dynamic> json) {
    return TransactionData(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: TransactionDataInfo.fromJson(json['data'] ?? {}),
    );
  }
}

class TransactionDataInfo {
  final int total;
  final int count;
  final List<TransactionModel> data;

  TransactionDataInfo({required this.total, required this.count, required this.data});

  factory TransactionDataInfo.fromJson(Map<String, dynamic> json) {
    return TransactionDataInfo(
      total: json['total'] ?? 0,
      count: json['count'] ?? 0,
      data: (json['data'] as List<dynamic>?)?.map((item) => TransactionModel.fromJson(item)).toList() ?? [],
    );
  }
}