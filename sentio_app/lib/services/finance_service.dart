import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sentio_app/config/constants.dart';
import 'package:sentio_app/config/finance_constants.dart';
import 'package:sentio_app/models/financial_account.dart';
import 'package:sentio_app/models/financial_transaction.dart';
import 'package:sentio_app/models/custom_category.dart';

class FinanceService {
  FinanceService._();
  static final FinanceService instance = FinanceService._();

  final _supabase = Supabase.instance.client;
  String? get _userId => _supabase.auth.currentUser?.id;

  // ── Accounts ──

  Future<List<FinancialAccount>> loadAccounts() async {
    if (_userId == null) return [];
    try {
      final data = await _supabase
          .from('financial_accounts')
          .select()
          .eq('user_id', _userId!)
          .eq('is_active', true)
          .order('sort_order');
      return (data as List).map((a) => FinancialAccount.fromJson(a)).toList();
    } catch (e) {
      debugPrint('Error loading accounts: $e');
      return [];
    }
  }

  Future<FinancialAccount?> createAccount({
    required String name,
    required String accountType,
    String currency = 'ARS',
    double initialBalance = 0,
    String? color,
  }) async {
    if (_userId == null) return null;
    try {
      final typeData = FinanceConstants.getAccountTypeById(accountType);
      final data = await _supabase.from('financial_accounts').insert({
        'user_id': _userId,
        'name': name,
        'account_type': accountType,
        'currency': currency,
        'balance': initialBalance,
        'icon': accountType,
        'color': color ?? '#${(typeData?['color'] as int? ?? 0xFF3D5A80).toRadixString(16).substring(2)}',
      }).select().single();
      return FinancialAccount.fromJson(data);
    } catch (e) {
      debugPrint('Error creating account: $e');
      return null;
    }
  }

  Future<bool> updateAccount(String accountId, Map<String, dynamic> updates) async {
    try {
      await _supabase
          .from('financial_accounts')
          .update({...updates, 'updated_at': DateTime.now().toIso8601String()})
          .eq('id', accountId);
      return true;
    } catch (e) {
      debugPrint('Error updating account: $e');
      return false;
    }
  }

  Future<bool> deleteAccount(String accountId) async {
    try {
      await _supabase
          .from('financial_accounts')
          .update({'is_active': false, 'updated_at': DateTime.now().toIso8601String()})
          .eq('id', accountId);
      return true;
    } catch (e) {
      debugPrint('Error deleting account: $e');
      return false;
    }
  }

  // ── Transactions ──

  Future<List<FinancialTransaction>> loadTransactions({
    int limit = 50,
    int offset = 0,
    String? accountId,
    DateTime? from,
    DateTime? to,
  }) async {
    if (_userId == null) return [];
    try {
      var query = _supabase
          .from('financial_transactions')
          .select()
          .eq('user_id', _userId!);

      if (accountId != null) {
        query = query.eq('account_id', accountId);
      }
      if (from != null) {
        query = query.gte('transaction_date', from.toIso8601String().split('T').first);
      }
      if (to != null) {
        query = query.lte('transaction_date', to.toIso8601String().split('T').first);
      }

      final data = await query
          .order('transaction_date', ascending: false)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return (data as List).map((t) => FinancialTransaction.fromJson(t)).toList();
    } catch (e) {
      debugPrint('Error loading transactions: $e');
      return [];
    }
  }

  Future<FinancialTransaction?> createTransaction({
    required String accountId,
    required String type,
    required double amount,
    required String category,
    String? description,
    String? receiptImageUrl,
    bool isFromScan = false,
    String? emotionalContext,
    DateTime? transactionDate,
    String currency = 'ARS',
  }) async {
    if (_userId == null) return null;
    try {
      final data = await _supabase.from('financial_transactions').insert({
        'user_id': _userId,
        'account_id': accountId,
        'type': type,
        'amount': amount,
        'currency': currency,
        'category': category,
        'description': description,
        'receipt_image_url': receiptImageUrl,
        'is_from_scan': isFromScan,
        'emotional_context': emotionalContext,
        'transaction_date': (transactionDate ?? DateTime.now()).toIso8601String().split('T').first,
      }).select().single();
      return FinancialTransaction.fromJson(data);
    } catch (e) {
      debugPrint('Error creating transaction: $e');
      return null;
    }
  }

  Future<bool> deleteTransaction(String transactionId) async {
    try {
      await _supabase
          .from('financial_transactions')
          .delete()
          .eq('id', transactionId);
      return true;
    } catch (e) {
      debugPrint('Error deleting transaction: $e');
      return false;
    }
  }

  // ── Custom Categories ──

  Future<List<CustomCategory>> loadCustomCategories() async {
    if (_userId == null) return [];
    try {
      final data = await _supabase
          .from('custom_categories')
          .select()
          .eq('user_id', _userId!)
          .order('created_at');
      return (data as List).map((c) => CustomCategory.fromJson(c)).toList();
    } catch (e) {
      debugPrint('Error loading custom categories: $e');
      return [];
    }
  }

  Future<CustomCategory?> createCustomCategory({
    required String type,
    required String label,
    required int iconCode,
    required int color,
  }) async {
    if (_userId == null) return null;
    try {
      final data = await _supabase
          .from('custom_categories')
          .insert({
            'user_id': _userId,
            'type': type,
            'label': label,
            'icon_code': iconCode,
            'color': color,
          })
          .select()
          .single();
      return CustomCategory.fromJson(data);
    } catch (e) {
      debugPrint('Error creating custom category: $e');
      return null;
    }
  }

  Future<bool> deleteCustomCategory(String id) async {
    try {
      await _supabase.from('custom_categories').delete().eq('id', id);
      return true;
    } catch (e) {
      debugPrint('Error deleting custom category: $e');
      return false;
    }
  }

  Future<bool> updateTransaction({
    required String transactionId,
    String? type,
    double? amount,
    String? category,
    String? description,
    String? accountId,
    DateTime? transactionDate,
  }) async {
    try {
      final updates = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };
      if (type != null) updates['type'] = type;
      if (amount != null) updates['amount'] = amount;
      if (category != null) updates['category'] = category;
      if (description != null) updates['description'] = description;
      if (accountId != null) updates['account_id'] = accountId;
      if (transactionDate != null) {
        updates['transaction_date'] = transactionDate.toIso8601String();
      }

      await _supabase
          .from('financial_transactions')
          .update(updates)
          .eq('id', transactionId);
      return true;
    } catch (e) {
      debugPrint('Error updating transaction: $e');
      return false;
    }
  }

  // ── Image upload ──

  Future<String?> uploadReceiptImage(String fileName, Uint8List bytes) async {
    try {
      final path = '${_userId}/$fileName';
      await _supabase.storage
          .from('receipt-images')
          .uploadBinary(path, bytes);
      return _supabase.storage
          .from('receipt-images')
          .getPublicUrl(path);
    } catch (e) {
      debugPrint('Error uploading receipt image: $e');
      return null;
    }
  }

  // ── Receipt OCR (OpenAI Vision) ──

  Future<Map<String, dynamic>?> scanReceipt(Uint8List imageBytes) async {
    try {
      final base64Image = base64Encode(imageBytes);

      final validCategories = FinanceConstants.expenseCategories
          .map((c) => c['id'] as String)
          .join(', ');

      final response = await http.post(
        Uri.parse('https://api.openai.com/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${SentioConstants.openaiApiKey}',
        },
        body: jsonEncode({
          'model': 'gpt-4o-mini',
          'messages': [
            {
              'role': 'system',
              'content': '''Sos un sistema de OCR para tickets y recibos de compra.
Analizá la imagen y extraé la información del gasto.
Respondé SOLO con un JSON válido con estos campos:
- "amount": número decimal (monto total del ticket)
- "category": una de estas categorías: $validCategories
- "description": descripción breve del gasto (máx 50 caracteres)
- "date": fecha del ticket en formato YYYY-MM-DD (si no se ve, usá null)
- "currency": "ARS" o "USD" según lo que veas
- "confidence": número entre 0.0 y 1.0 indicando tu confianza en la lectura

Si no podés leer el ticket claramente, respondé con confidence < 0.5.
Si es un ticket argentino, la moneda es ARS por defecto.''',
            },
            {
              'role': 'user',
              'content': [
                {'type': 'text', 'text': 'Leé este ticket y extraé los datos del gasto:'},
                {
                  'type': 'image_url',
                  'image_url': {
                    'url': 'data:image/jpeg;base64,$base64Image',
                    'detail': 'high',
                  },
                },
              ],
            },
          ],
          'max_tokens': 200,
          'temperature': 0.1,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'] as String;

        // Parse JSON from response (handle markdown code blocks)
        String jsonStr = content;
        if (content.contains('```')) {
          jsonStr = content
              .replaceAll(RegExp(r'```json\s*'), '')
              .replaceAll(RegExp(r'```\s*'), '')
              .trim();
        }

        return jsonDecode(jsonStr) as Map<String, dynamic>;
      } else {
        debugPrint('OCR error: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('OCR request failed: $e');
      return null;
    }
  }

  // ── AI Financial Advisor ──

  Future<String> getFinancialAdvice({
    required List<FinancialTransaction> transactions,
    String? emotionalContext,
    int? financialPressure,
  }) async {
    try {
      // Build spending summary
      double totalIncome = 0;
      double totalExpenses = 0;
      final categoryTotals = <String, double>{};

      for (final t in transactions) {
        if (t.isIncome) {
          totalIncome += t.amount;
        } else {
          totalExpenses += t.amount;
          categoryTotals[t.category] = (categoryTotals[t.category] ?? 0) + t.amount;
        }
      }

      // Sort categories by amount
      final sortedCategories = categoryTotals.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      final top5 = sortedCategories.take(5).map((e) {
        final cat = FinanceConstants.getCategoryById(e.key);
        return '${cat?['label'] ?? e.key}: \$${e.value.toStringAsFixed(0)}';
      }).join(', ');

      final balance = totalIncome - totalExpenses;
      final savingsRate = totalIncome > 0
          ? ((balance / totalIncome) * 100).toStringAsFixed(1)
          : '0';

      String emotionalNote = '';
      if (financialPressure != null && financialPressure >= 4) {
        emotionalNote = '''
IMPORTANTE: El usuario reportó un nivel de presión financiera de $financialPressure/5.
Priorizá la contención emocional sobre los números. Sé empático y evitá ser alarmista.''';
      } else if (emotionalContext != null) {
        emotionalNote = 'Estado emocional reciente del usuario: $emotionalContext.';
      }

      final response = await http.post(
        Uri.parse('https://api.openai.com/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${SentioConstants.openaiApiKey}',
        },
        body: jsonEncode({
          'model': 'gpt-4o-mini',
          'messages': [
            {
              'role': 'system',
              'content': '''Sos un asesor financiero empático para emprendedores argentinos.
Hablás en español rioplatense (vos, tuteás).
Tu objetivo es dar consejos prácticos y contención emocional sobre finanzas personales.
Sé breve (máx 150 palabras), directo y alentador. Usá un tono cálido y cercano.
No uses emojis excesivos (máximo 2-3 relevantes).
$emotionalNote''',
            },
            {
              'role': 'user',
              'content': '''Resumen financiero últimos 30 días:
- Ingresos totales: \$${totalIncome.toStringAsFixed(0)}
- Gastos totales: \$${totalExpenses.toStringAsFixed(0)}
- Balance: \$${balance.toStringAsFixed(0)}
- Tasa de ahorro: $savingsRate%
- Top gastos: $top5
- Total transacciones: ${transactions.length}

Dame un consejo financiero personalizado basado en estos datos.''',
            },
          ],
          'max_tokens': 250,
          'temperature': 0.7,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'] as String;
      } else {
        debugPrint('Advisor error: ${response.statusCode}');
        return _getFallbackAdvice(totalIncome, totalExpenses);
      }
    } catch (e) {
      debugPrint('Advisor request failed: $e');
      return _getFallbackAdvice(0, 0);
    }
  }

  String _getFallbackAdvice(double income, double expenses) {
    if (income == 0 && expenses == 0) {
      return 'Empezá a registrar tus movimientos para que pueda darte consejos personalizados. Cada registro cuenta.';
    }
    final balance = income - expenses;
    if (balance >= 0) {
      return 'Buen trabajo manteniendo un balance positivo. Intentá destinar al menos un 20% de tus ingresos al ahorro o inversión.';
    }
    return 'Tus gastos superan tus ingresos este mes. Revisá las categorías donde más gastás y buscá oportunidades para reducir sin afectar tu calidad de vida.';
  }
}
