class PaymentResponseModel {
  final int status;
  final String message;
  final PaymentData data;

  PaymentResponseModel({
    required this.status,
    required this.message,
    required this.data,
  });

  factory PaymentResponseModel.fromJson(Map<String, dynamic> json) {
    return PaymentResponseModel(
      status: json['status'] ?? 0,
      message: json['message'] ?? '',
      data: PaymentData.fromJson(json['data'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'message': message,
      'data': data.toJson(),
    };
  }
}

class PaymentData {
  final bool settled;
  final String settlementCycle;
  final String channel;
  final String reference;
  final String status;
  final String action;
  final String? narration;
  final int amount;
  final int charges;
  final int settledAmount;
  final String currency;
  final PaymentMetadata metadata;
  final String? customerId;
  final String source;
  final String type;
  final bool balanceTransfer;
  final String? clientReference;
  final int aggregatorId;
  final String updatedAt;
  final String createdAt;
  final String? payoutId;
  final String? splitPaymentId;
  final String? externalReference;
  final String? providerSlug;
  final String? settlementDate;
  final String? clientMetadata;

  PaymentData({
    required this.settled,
    required this.settlementCycle,
    required this.channel,
    required this.reference,
    required this.status,
    required this.action,
    this.narration,
    required this.amount,
    required this.charges,
    required this.settledAmount,
    required this.currency,
    required this.metadata,
    this.customerId,
    required this.source,
    required this.type,
    required this.balanceTransfer,
    this.clientReference,
    required this.aggregatorId,
    required this.updatedAt,
    required this.createdAt,
    this.payoutId,
    this.splitPaymentId,
    this.externalReference,
    this.providerSlug,
    this.settlementDate,
    this.clientMetadata,
  });

  factory PaymentData.fromJson(Map<String, dynamic> json) {
    return PaymentData(
      settled: json['settled'] ?? false,
      settlementCycle: json['settlement_cycle'] ?? '',
      channel: json['channel'] ?? '',
      reference: json['reference'] ?? '',
      status: json['status'] ?? '',
      action: json['action'] ?? '',
      narration: json['narration'],
      amount: json['amount'] ?? 0,
      charges: json['charges'] ?? 0,
      settledAmount: json['settled_amount'] ?? 0,
      currency: json['currency'] ?? '',
      metadata: PaymentMetadata.fromJson(json['metadata'] ?? {}),
      customerId: json['CustomerId'],
      source: json['source'] ?? '',
      type: json['type'] ?? '',
      balanceTransfer: json['balance_transfer'] ?? false,
      clientReference: json['client_reference'],
      aggregatorId: json['AggregatorId'] ?? 0,
      updatedAt: json['updatedAt'] ?? '',
      createdAt: json['createdAt'] ?? '',
      payoutId: json['PayoutId'],
      splitPaymentId: json['SplitPaymentId'],
      externalReference: json['external_reference'],
      providerSlug: json['provider_slug'],
      settlementDate: json['settlement_date'],
      clientMetadata: json['client_metadata'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'settled': settled,
      'settlement_cycle': settlementCycle,
      'channel': channel,
      'reference': reference,
      'status': status,
      'action': action,
      'narration': narration,
      'amount': amount,
      'charges': charges,
      'settled_amount': settledAmount,
      'currency': currency,
      'metadata': metadata.toJson(),
      'CustomerId': customerId,
      'source': source,
      'type': type,
      'balance_transfer': balanceTransfer,
      'client_reference': clientReference,
      'AggregatorId': aggregatorId,
      'updatedAt': updatedAt,
      'createdAt': createdAt,
      'PayoutId': payoutId,
      'SplitPaymentId': splitPaymentId,
      'external_reference': externalReference,
      'provider_slug': providerSlug,
      'settlement_date': settlementDate,
      'client_metadata': clientMetadata,
    };
  }
}

class PaymentMetadata {
  final PaymentDestination destination;

  PaymentMetadata({
    required this.destination,
  });

  factory PaymentMetadata.fromJson(Map<String, dynamic> json) {
    return PaymentMetadata(
      destination: PaymentDestination.fromJson(json['destination'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'destination': destination.toJson(),
    };
  }
}

class PaymentDestination {
  final String recipient;
  final String type;
  final PaymentBank bank;
  final String accountName;
  final String accountNumber;
  final String bankName;
  final String bankCode;
  final String currency;

  PaymentDestination({
    required this.recipient,
    required this.type,
    required this.bank,
    required this.accountName,
    required this.accountNumber,
    required this.bankName,
    required this.bankCode,
    required this.currency,
  });

  factory PaymentDestination.fromJson(Map<String, dynamic> json) {
    return PaymentDestination(
      recipient: json['recipient'] ?? '',
      type: json['type'] ?? '',
      bank: PaymentBank.fromJson(json['bank'] ?? {}),
      accountName: json['account_name'] ?? '',
      accountNumber: json['account_number'] ?? '',
      bankName: json['bank_name'] ?? '',
      bankCode: json['bank_code'] ?? '',
      currency: json['currency'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'recipient': recipient,
      'type': type,
      'bank': bank.toJson(),
      'account_name': accountName,
      'account_number': accountNumber,
      'bank_name': bankName,
      'bank_code': bankCode,
      'currency': currency,
    };
  }
}

class PaymentBank {
  final String accountName;
  final String accountNumber;
  final String bankName;
  final String bankCode;

  PaymentBank({
    required this.accountName,
    required this.accountNumber,
    required this.bankName,
    required this.bankCode,
  });

  factory PaymentBank.fromJson(Map<String, dynamic> json) {
    return PaymentBank(
      accountName: json['account_name'] ?? '',
      accountNumber: json['account_number'] ?? '',
      bankName: json['bank_name'] ?? '',
      bankCode: json['bank_code'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'account_name': accountName,
      'account_number': accountNumber,
      'bank_name': bankName,
      'bank_code': bankCode,
    };
  }
}
