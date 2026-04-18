import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:sentio_app/config/finance_constants.dart';
import 'package:sentio_app/config/theme.dart';
import 'package:sentio_app/providers/app_provider.dart';

class FinanceAdvisorScreen extends StatefulWidget {
  const FinanceAdvisorScreen({super.key});

  @override
  State<FinanceAdvisorScreen> createState() => _FinanceAdvisorScreenState();
}

class _FinanceAdvisorScreenState extends State<FinanceAdvisorScreen> with SingleTickerProviderStateMixin {
  String? _advice;
  bool _loading = true;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _loadAdvice();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _loadAdvice() async {
    setState(() => _loading = true);
    try {
      final provider = context.read<AppProvider>();
      final advice = await provider.getFinancialAdvice();
      if (mounted) {
        setState(() {
          _advice = advice;
          _loading = false;
        });
        _fadeController.forward(from: 0);
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final transactions = provider.financialTransactions;
    final monthlyIncome = provider.monthlyIncome;
    final monthlyExpenses = provider.monthlyExpenses;
    final balance = monthlyIncome - monthlyExpenses;

    // Category breakdown
    final now = DateTime.now();
    final firstOfMonth = DateTime(now.year, now.month, 1);
    final monthlyTx = transactions.where((t) =>
      t.isExpense && !t.transactionDate.isBefore(firstOfMonth)).toList();
    final categoryTotals = <String, double>{};
    for (final t in monthlyTx) {
      categoryTotals[t.category] = (categoryTotals[t.category] ?? 0) + t.amount;
    }
    final sortedCategories = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Scaffold(
      backgroundColor: SentioColors.background,
      appBar: AppBar(
        title: Text('Asesor Financiero', style: GoogleFonts.manrope(fontWeight: FontWeight.w800)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        children: [
          // Summary cards
          _buildSummaryRow(monthlyIncome, monthlyExpenses, balance),
          const SizedBox(height: 24),

          // Top expenses
          if (sortedCategories.isNotEmpty) ...[
            Text('Top gastos del mes',
              style: GoogleFonts.manrope(fontSize: 18, fontWeight: FontWeight.w700, color: SentioColors.textPrimary)),
            const SizedBox(height: 12),
            ...sortedCategories.take(5).map((entry) => _buildCategoryRow(entry, monthlyExpenses)),
            const SizedBox(height: 24),
          ],

          // AI Advice
          Text('Consejo personalizado',
            style: GoogleFonts.manrope(fontSize: 18, fontWeight: FontWeight.w700, color: SentioColors.textPrimary)),
          const SizedBox(height: 12),
          _buildAdviceCard(),
          const SizedBox(height: 16),

          // Refresh button
          Center(
            child: TextButton.icon(
              onPressed: _loading ? null : _loadAdvice,
              icon: const Icon(Icons.refresh, size: 18),
              label: Text('Pedir nuevo consejo', style: GoogleFonts.manrope(fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(double income, double expenses, double balance) {
    return Row(
      children: [
        Expanded(child: _buildSummaryCard('Ingresos', income, const Color(0xFF4CAF50))),
        const SizedBox(width: 8),
        Expanded(child: _buildSummaryCard('Gastos', expenses, SentioColors.error)),
        const SizedBox(width: 8),
        Expanded(child: _buildSummaryCard('Balance', balance,
          balance >= 0 ? SentioColors.accent : SentioColors.error)),
      ],
    );
  }

  Widget _buildSummaryCard(String label, double amount, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: SentioEffects.standardCard(),
      child: Column(
        children: [
          Text(label, style: GoogleFonts.manrope(fontSize: 11, color: SentioColors.textSecondary)),
          const SizedBox(height: 4),
          Text(
            FinanceConstants.formatAmount(amount.abs(), 'ARS'),
            style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w700, color: color),
            maxLines: 1, overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryRow(MapEntry<String, double> entry, double totalExpenses) {
    final cat = FinanceConstants.getCategoryById(entry.key);
    final color = Color(cat?['color'] as int? ?? 0xFF9E9E9E);
    final pct = totalExpenses > 0 ? entry.value / totalExpenses : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: SentioEffects.standardCard(),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                FinanceConstants.getCategoryIcon(entry.key),
                size: 18,
                color: Color(cat?['color'] as int? ?? 0xFF9E9E9E),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(cat?['label'] as String? ?? entry.key,
                  style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w600, color: SentioColors.textPrimary)),
              ),
              Text(FinanceConstants.formatAmount(entry.value, 'ARS'),
                style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w700, color: SentioColors.textPrimary)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              backgroundColor: SentioColors.divider,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdviceCard() {
    return FadeTransition(
      opacity: _loading ? const AlwaysStoppedAnimation(1.0) : _fadeAnimation,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: SentioEffects.glowCard(glowColor: SentioColors.primary),
        child: _loading
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: SizedBox(width: 24, height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2, color: SentioColors.accent)),
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.auto_awesome, color: SentioColors.accent, size: 20),
                    const SizedBox(width: 8),
                    Text('IA Financiera', style: GoogleFonts.manrope(
                      fontSize: 14, fontWeight: FontWeight.w700, color: SentioColors.accent)),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  _advice ?? 'No hay suficientes datos para generar un consejo. Registrá algunos movimientos primero.',
                  style: GoogleFonts.manrope(fontSize: 14, color: SentioColors.textPrimary, height: 1.6),
                ),
              ],
            ),
      ),
    );
  }
}
