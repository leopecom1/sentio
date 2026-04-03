class FinancialAccount {
  final String id;
  final String userId;
  final String name;
  final String accountType;
  final String currency;
  final double balance;
  final String icon;
  final String color;
  final bool isActive;
  final int sortOrder;
  final DateTime createdAt;

  FinancialAccount({
    required this.id,
    required this.userId,
    required this.name,
    this.accountType = 'cash',
    this.currency = 'ARS',
    this.balance = 0,
    this.icon = 'account_balance_wallet',
    this.color = '#3D5A80',
    this.isActive = true,
    this.sortOrder = 0,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory FinancialAccount.fromJson(Map<String, dynamic> json) {
    return FinancialAccount(
      id: json['id'],
      userId: json['user_id'],
      name: json['name'],
      accountType: json['account_type'] ?? 'cash',
      currency: json['currency'] ?? 'ARS',
      balance: (json['balance'] as num?)?.toDouble() ?? 0,
      icon: json['icon'] ?? 'account_balance_wallet',
      color: json['color'] ?? '#3D5A80',
      isActive: json['is_active'] ?? true,
      sortOrder: json['sort_order'] ?? 0,
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toInsertJson() => {
    'user_id': userId,
    'name': name,
    'account_type': accountType,
    'currency': currency,
    'balance': balance,
    'icon': icon,
    'color': color,
    'is_active': isActive,
    'sort_order': sortOrder,
  };

  FinancialAccount copyWith({
    String? name,
    String? accountType,
    String? currency,
    double? balance,
    String? icon,
    String? color,
    bool? isActive,
    int? sortOrder,
  }) {
    return FinancialAccount(
      id: id,
      userId: userId,
      name: name ?? this.name,
      accountType: accountType ?? this.accountType,
      currency: currency ?? this.currency,
      balance: balance ?? this.balance,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      isActive: isActive ?? this.isActive,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt,
    );
  }
}
