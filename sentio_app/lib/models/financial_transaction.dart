class FinancialTransaction {
  final String id;
  final String userId;
  final String accountId;
  final String type; // income, expense
  final double amount;
  final String currency;
  final String category;
  final String? description;
  final String? receiptImageUrl;
  final bool isFromScan;
  final String? emotionalContext;
  final DateTime transactionDate;
  final DateTime createdAt;

  FinancialTransaction({
    required this.id,
    required this.userId,
    required this.accountId,
    this.type = 'expense',
    required this.amount,
    this.currency = 'ARS',
    this.category = 'otros',
    this.description,
    this.receiptImageUrl,
    this.isFromScan = false,
    this.emotionalContext,
    DateTime? transactionDate,
    DateTime? createdAt,
  })  : transactionDate = transactionDate ?? DateTime.now(),
        createdAt = createdAt ?? DateTime.now();

  factory FinancialTransaction.fromJson(Map<String, dynamic> json) {
    return FinancialTransaction(
      id: json['id'],
      userId: json['user_id'],
      accountId: json['account_id'],
      type: json['type'] ?? 'expense',
      amount: (json['amount'] as num).toDouble(),
      currency: json['currency'] ?? 'ARS',
      category: json['category'] ?? 'otros',
      description: json['description'],
      receiptImageUrl: json['receipt_image_url'],
      isFromScan: json['is_from_scan'] ?? false,
      emotionalContext: json['emotional_context'],
      transactionDate: DateTime.parse(json['transaction_date']),
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toInsertJson() => {
    'user_id': userId,
    'account_id': accountId,
    'type': type,
    'amount': amount,
    'currency': currency,
    'category': category,
    'description': description,
    'receipt_image_url': receiptImageUrl,
    'is_from_scan': isFromScan,
    'emotional_context': emotionalContext,
    'transaction_date': transactionDate.toIso8601String().split('T').first,
  };

  bool get isExpense => type == 'expense';
  bool get isIncome => type == 'income';
}
