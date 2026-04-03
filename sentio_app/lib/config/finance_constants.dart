import 'package:flutter/material.dart';

class FinanceConstants {
  // Account types
  static const List<Map<String, dynamic>> accountTypes = [
    {'id': 'cash', 'label': 'Efectivo', 'icon': Icons.payments_outlined, 'color': 0xFF4CAF50},
    {'id': 'bank', 'label': 'Banco', 'icon': Icons.account_balance_outlined, 'color': 0xFF3D5A80},
    {'id': 'credit_card', 'label': 'Tarjeta de crédito', 'icon': Icons.credit_card_outlined, 'color': 0xFFC75B5B},
    {'id': 'wallet', 'label': 'Billetera digital', 'icon': Icons.account_balance_wallet_outlined, 'color': 0xFF9B8EC4},
    {'id': 'investment', 'label': 'Inversión', 'icon': Icons.trending_up_outlined, 'color': 0xFFC9A96E},
  ];

  // Currencies
  static const List<Map<String, String>> currencies = [
    {'id': 'ARS', 'label': 'Peso Argentino', 'symbol': '\$'},
    {'id': 'USD', 'label': 'Dólar', 'symbol': 'US\$'},
  ];

  // Expense categories
  static const List<Map<String, dynamic>> expenseCategories = [
    {'id': 'comida', 'label': 'Comida', 'emoji': '🍔', 'color': 0xFFFF9800},
    {'id': 'transporte', 'label': 'Transporte', 'emoji': '🚗', 'color': 0xFF2196F3},
    {'id': 'servicios', 'label': 'Servicios', 'emoji': '💡', 'color': 0xFFFFC107},
    {'id': 'alquiler', 'label': 'Alquiler', 'emoji': '🏠', 'color': 0xFF795548},
    {'id': 'salud', 'label': 'Salud', 'emoji': '🏥', 'color': 0xFFE91E63},
    {'id': 'educacion', 'label': 'Educación', 'emoji': '📚', 'color': 0xFF673AB7},
    {'id': 'entretenimiento', 'label': 'Entretenimiento', 'emoji': '🎬', 'color': 0xFF9C27B0},
    {'id': 'compras', 'label': 'Compras', 'emoji': '🛍️', 'color': 0xFFFF5722},
    {'id': 'negocio', 'label': 'Negocio', 'emoji': '💼', 'color': 0xFF3D5A80},
    {'id': 'impuestos', 'label': 'Impuestos', 'emoji': '🏛️', 'color': 0xFF607D8B},
    {'id': 'equipo', 'label': 'Equipo', 'emoji': '💻', 'color': 0xFF00BCD4},
    {'id': 'software', 'label': 'Herramientas/Software', 'emoji': '🛠️', 'color': 0xFF8BC34A},
    {'id': 'otros', 'label': 'Otros', 'emoji': '📌', 'color': 0xFF9E9E9E},
  ];

  // Income categories
  static const List<Map<String, dynamic>> incomeCategories = [
    {'id': 'sueldo', 'label': 'Sueldo', 'emoji': '💰', 'color': 0xFF4CAF50},
    {'id': 'freelance', 'label': 'Freelance', 'emoji': '💻', 'color': 0xFF00BCD4},
    {'id': 'ventas', 'label': 'Ventas', 'emoji': '🛒', 'color': 0xFFFF9800},
    {'id': 'inversiones', 'label': 'Inversiones', 'emoji': '📈', 'color': 0xFFC9A96E},
    {'id': 'reembolso', 'label': 'Reembolso', 'emoji': '🔄', 'color': 0xFF2196F3},
    {'id': 'otros_ingreso', 'label': 'Otros', 'emoji': '📌', 'color': 0xFF9E9E9E},
  ];

  // Get all categories for a transaction type
  static List<Map<String, dynamic>> categoriesForType(String type) {
    return type == 'income' ? incomeCategories : expenseCategories;
  }

  // Get category data by id
  static Map<String, dynamic>? getCategoryById(String categoryId) {
    for (final cat in [...expenseCategories, ...incomeCategories]) {
      if (cat['id'] == categoryId) return cat;
    }
    return null;
  }

  // Get account type data by id
  static Map<String, dynamic>? getAccountTypeById(String typeId) {
    for (final t in accountTypes) {
      if (t['id'] == typeId) return t;
    }
    return null;
  }

  // Get currency symbol
  static String currencySymbol(String currencyId) {
    for (final c in currencies) {
      if (c['id'] == currencyId) return c['symbol']!;
    }
    return '\$';
  }

  // Format amount with currency
  static String formatAmount(double amount, String currency) {
    final symbol = currencySymbol(currency);
    final formatted = amount.toStringAsFixed(2).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    );
    return '$symbol $formatted';
  }

  // Valid categories for OCR matching
  static const List<String> allCategoryIds = [
    'comida', 'transporte', 'servicios', 'alquiler', 'salud',
    'educacion', 'entretenimiento', 'compras', 'negocio', 'impuestos',
    'equipo', 'software', 'otros',
    'sueldo', 'freelance', 'ventas', 'inversiones', 'reembolso', 'otros_ingreso',
  ];
}
