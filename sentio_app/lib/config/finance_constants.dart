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

  // Currencies (USD, UYU, ARS first, then rest of LATAM + EUR)
  static const List<Map<String, String>> currencies = [
    {'id': 'USD', 'label': 'Dólar Estadounidense', 'symbol': 'US\$'},
    {'id': 'UYU', 'label': 'Peso Uruguayo', 'symbol': '\$U'},
    {'id': 'ARS', 'label': 'Peso Argentino', 'symbol': 'AR\$'},
    {'id': 'EUR', 'label': 'Euro', 'symbol': '€'},
    {'id': 'BRL', 'label': 'Real Brasileño', 'symbol': 'R\$'},
    {'id': 'CLP', 'label': 'Peso Chileno', 'symbol': 'CL\$'},
    {'id': 'COP', 'label': 'Peso Colombiano', 'symbol': 'COL\$'},
    {'id': 'MXN', 'label': 'Peso Mexicano', 'symbol': 'MX\$'},
    {'id': 'PEN', 'label': 'Sol Peruano', 'symbol': 'S/.'},
    {'id': 'BOB', 'label': 'Boliviano', 'symbol': 'Bs.'},
    {'id': 'PYG', 'label': 'Guaraní', 'symbol': '₲'},
    {'id': 'VES', 'label': 'Bolívar', 'symbol': 'Bs.S'},
    {'id': 'CRC', 'label': 'Colón Costarricense', 'symbol': '₡'},
    {'id': 'GTQ', 'label': 'Quetzal', 'symbol': 'Q'},
    {'id': 'HNL', 'label': 'Lempira', 'symbol': 'L'},
    {'id': 'NIO', 'label': 'Córdoba', 'symbol': 'C\$'},
    {'id': 'PAB', 'label': 'Balboa', 'symbol': 'B/.'},
    {'id': 'DOP', 'label': 'Peso Dominicano', 'symbol': 'RD\$'},
    {'id': 'CUP', 'label': 'Peso Cubano', 'symbol': '\$MN'},
  ];

  // Expense categories (using Material Icons)
  static const List<Map<String, dynamic>> expenseCategories = [
    {'id': 'comida', 'label': 'Comida', 'icon': Icons.restaurant_rounded, 'color': 0xFFFF9800},
    {'id': 'transporte', 'label': 'Transporte', 'icon': Icons.directions_car_rounded, 'color': 0xFF2196F3},
    {'id': 'servicios', 'label': 'Servicios', 'icon': Icons.lightbulb_rounded, 'color': 0xFFFFC107},
    {'id': 'alquiler', 'label': 'Alquiler', 'icon': Icons.home_rounded, 'color': 0xFF795548},
    {'id': 'salud', 'label': 'Salud', 'icon': Icons.local_hospital_rounded, 'color': 0xFFE91E63},
    {'id': 'educacion', 'label': 'Educación', 'icon': Icons.school_rounded, 'color': 0xFF673AB7},
    {'id': 'entretenimiento', 'label': 'Entretenimiento', 'icon': Icons.movie_rounded, 'color': 0xFF9C27B0},
    {'id': 'compras', 'label': 'Compras', 'icon': Icons.shopping_bag_rounded, 'color': 0xFFFF5722},
    {'id': 'negocio', 'label': 'Negocio', 'icon': Icons.business_center_rounded, 'color': 0xFF3D5A80},
    {'id': 'impuestos', 'label': 'Impuestos', 'icon': Icons.account_balance_rounded, 'color': 0xFF607D8B},
    {'id': 'equipo', 'label': 'Equipo', 'icon': Icons.computer_rounded, 'color': 0xFF00BCD4},
    {'id': 'software', 'label': 'Herramientas/Software', 'icon': Icons.build_rounded, 'color': 0xFF8BC34A},
    {'id': 'otros', 'label': 'Otros', 'icon': Icons.more_horiz_rounded, 'color': 0xFF9E9E9E},
  ];

  // Income categories (using Material Icons)
  static const List<Map<String, dynamic>> incomeCategories = [
    {'id': 'sueldo', 'label': 'Sueldo', 'icon': Icons.attach_money_rounded, 'color': 0xFF4CAF50},
    {'id': 'freelance', 'label': 'Freelance', 'icon': Icons.laptop_mac_rounded, 'color': 0xFF00BCD4},
    {'id': 'ventas', 'label': 'Ventas', 'icon': Icons.shopping_cart_rounded, 'color': 0xFFFF9800},
    {'id': 'inversiones', 'label': 'Inversiones', 'icon': Icons.trending_up_rounded, 'color': 0xFFC9A96E},
    {'id': 'reembolso', 'label': 'Reembolso', 'icon': Icons.replay_rounded, 'color': 0xFF2196F3},
    {'id': 'otros_ingreso', 'label': 'Otros', 'icon': Icons.more_horiz_rounded, 'color': 0xFF9E9E9E},
  ];

  static List<Map<String, dynamic>> categoriesForType(String type) {
    return type == 'income' ? incomeCategories : expenseCategories;
  }

  static Map<String, dynamic>? getCategoryById(String categoryId) {
    for (final cat in [...expenseCategories, ...incomeCategories]) {
      if (cat['id'] == categoryId) return cat;
    }
    return null;
  }

  static IconData getCategoryIcon(String categoryId) {
    final cat = getCategoryById(categoryId);
    return (cat?['icon'] as IconData?) ?? Icons.more_horiz_rounded;
  }

  static Map<String, dynamic>? getAccountTypeById(String typeId) {
    for (final t in accountTypes) {
      if (t['id'] == typeId) return t;
    }
    return null;
  }

  static String currencySymbol(String currencyId) {
    for (final c in currencies) {
      if (c['id'] == currencyId) return c['symbol']!;
    }
    return '\$';
  }

  static String formatAmount(double amount, String currency) {
    final symbol = currencySymbol(currency);
    final formatted = amount.toStringAsFixed(2).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    );
    return '$symbol $formatted';
  }

  static const List<String> allCategoryIds = [
    'comida', 'transporte', 'servicios', 'alquiler', 'salud',
    'educacion', 'entretenimiento', 'compras', 'negocio', 'impuestos',
    'equipo', 'software', 'otros',
    'sueldo', 'freelance', 'ventas', 'inversiones', 'reembolso', 'otros_ingreso',
  ];
}
