import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:sentio_app/config/finance_constants.dart';
import 'package:sentio_app/config/theme.dart';
import 'package:sentio_app/models/financial_transaction.dart';
import 'package:sentio_app/providers/app_provider.dart';

class FinanceDashboardScreen extends StatefulWidget {
  const FinanceDashboardScreen({super.key});

  @override
  State<FinanceDashboardScreen> createState() => _FinanceDashboardScreenState();
}

class _FinanceDashboardScreenState extends State<FinanceDashboardScreen> {
  String? _aiAdvice;
  bool _loadingAdvice = false;

  Future<void> _loadAdvice() async {
    setState(() => _loadingAdvice = true);
    try {
      final provider = context.read<AppProvider>();
      final advice = await provider.getFinancialAdvice();
      if (mounted) setState(() => _aiAdvice = advice);
    } catch (_) {}
    if (mounted) setState(() => _loadingAdvice = false);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final accounts = provider.financialAccounts;
    final transactions = provider.financialTransactions;
    final totalBalance = provider.totalBalance;
    final monthlyIncome = provider.monthlyIncome;
    final monthlyExpenses = provider.monthlyExpenses;

    return Scaffold(
      backgroundColor: SentioColors.background,
      appBar: AppBar(
        title: Text('Finanzas', style: GoogleFonts.manrope(fontWeight: FontWeight.w800)),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_balance_outlined, size: 22),
            onPressed: () => context.push('/finance/accounts'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => provider.refreshFinancialData(),
        color: SentioColors.accent,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
          children: [
            // Total Balance Card (per currency)
            _buildBalanceCard(provider),
            const SizedBox(height: 20),

            // Quick Actions
            _buildQuickActions(),
            const SizedBox(height: 24),

            // Monthly Chart
            if (transactions.isNotEmpty) ...[
              _buildSectionTitle('Resumen del mes'),
              const SizedBox(height: 12),
              _buildMonthlyChart(monthlyIncome, monthlyExpenses),
              const SizedBox(height: 24),
            ],

            // Category Distribution
            if (transactions.where((t) => t.isExpense).isNotEmpty) ...[
              _buildSectionTitle('Distribución de gastos'),
              const SizedBox(height: 12),
              _buildCategoryPieChart(transactions),
              const SizedBox(height: 24),
            ],

            // AI Advice Card
            _buildAdviceCard(),
            const SizedBox(height: 24),

            // Recent Transactions
            _buildSectionTitle('Últimos movimientos'),
            const SizedBox(height: 12),
            if (transactions.isEmpty)
              _buildEmptyState()
            else
              ...transactions.take(10).map((t) => _buildTransactionTile(t)),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceCard(AppProvider provider) {
    final balances = provider.balanceByCurrency;
    final incomes = provider.monthlyIncomeByCurrency;
    final expenses = provider.monthlyExpensesByCurrency;

    // Aggregate all currencies present (balance + income + expenses)
    final allCurrencies = <String>{
      ...balances.keys,
      ...incomes.keys,
      ...expenses.keys,
    }.toList();

    if (allCurrencies.isEmpty) {
      // No accounts yet — show placeholder
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: SentioEffects.glowCard(glowColor: SentioColors.accent),
        child: Column(
          children: [
            Text('Balance total',
              style: GoogleFonts.manrope(fontSize: 13, color: SentioColors.textSecondary, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Text(
              'Sin cuentas',
              style: GoogleFonts.manrope(
                fontSize: 24, fontWeight: FontWeight.w700, color: SentioColors.textTertiary,
              ),
            ),
            const SizedBox(height: 12),
            Text('Creá una cuenta para empezar',
              style: GoogleFonts.manrope(fontSize: 13, color: SentioColors.textSecondary)),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: SentioEffects.glowCard(glowColor: SentioColors.accent),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Balance total',
            textAlign: TextAlign.center,
            style: GoogleFonts.manrope(fontSize: 13, color: SentioColors.textSecondary, fontWeight: FontWeight.w500)),
          const SizedBox(height: 14),
          // Per-currency rows
          ...allCurrencies.map((currency) {
            final bal = balances[currency] ?? 0;
            final inc = incomes[currency] ?? 0;
            final exp = expenses[currency] ?? 0;
            return _buildCurrencyBlock(currency, bal, inc, exp);
          }),
        ],
      ),
    );
  }

  Widget _buildCurrencyBlock(String currency, double balance, double income, double expenses) {
    final symbol = FinanceConstants.currencySymbol(currency);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: SentioColors.border),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: SentioColors.accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  currency,
                  style: GoogleFonts.manrope(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: SentioColors.accent,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              Text(
                FinanceConstants.formatAmount(balance, currency),
                style: GoogleFonts.manrope(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: SentioColors.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          if (income > 0 || expenses > 0) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: _buildMiniStat('Ingresos (mes)', income, currency, const Color(0xFF4CAF50))),
                Container(width: 1, height: 28, color: SentioColors.divider),
                Expanded(child: _buildMiniStat('Gastos (mes)', expenses, currency, SentioColors.error)),
              ],
            ),
          ],
          // hide unused symbol var warning in builds
          if (symbol.isEmpty) const SizedBox.shrink(),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, double amount, String currency, Color color) {
    return Column(
      children: [
        Text(label, style: GoogleFonts.manrope(fontSize: 11, color: SentioColors.textSecondary)),
        const SizedBox(height: 2),
        Text(
          FinanceConstants.formatAmount(amount, currency),
          style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w700, color: color),
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Row(
      children: [
        Expanded(child: _buildActionButton(
          icon: Icons.remove_circle_outline,
          label: 'Gasto',
          color: SentioColors.error,
          onTap: () => context.push('/finance/add?type=expense'),
        )),
        const SizedBox(width: 12),
        Expanded(child: _buildActionButton(
          icon: Icons.add_circle_outline,
          label: 'Ingreso',
          color: const Color(0xFF4CAF50),
          onTap: () => context.push('/finance/add?type=income'),
        )),
        const SizedBox(width: 12),
        Expanded(child: _buildActionButton(
          icon: Icons.document_scanner_outlined,
          label: 'Escanear',
          color: SentioColors.primary,
          onTap: () => context.push('/finance/scan'),
        )),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: SentioEffects.standardCard(),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 6),
            Text(label, style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w600, color: SentioColors.textPrimary)),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, style: GoogleFonts.manrope(fontSize: 18, fontWeight: FontWeight.w700, color: SentioColors.textPrimary));
  }

  Widget _buildMonthlyChart(double income, double expenses) {
    final maxY = (income > expenses ? income : expenses) * 1.3;
    if (maxY == 0) return const SizedBox.shrink();

    return Container(
      height: 180,
      padding: const EdgeInsets.all(16),
      decoration: SentioEffects.standardCard(),
      child: BarChart(
        BarChartData(
          maxY: maxY,
          barTouchData: BarTouchData(enabled: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final labels = ['Ingresos', 'Gastos'];
                  if (value.toInt() >= labels.length) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(labels[value.toInt()],
                      style: GoogleFonts.manrope(fontSize: 11, color: SentioColors.textSecondary)),
                  );
                },
              ),
            ),
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          barGroups: [
            BarChartGroupData(x: 0, barRods: [
              BarChartRodData(
                toY: income, color: const Color(0xFF4CAF50), width: 32,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
              ),
            ]),
            BarChartGroupData(x: 1, barRods: [
              BarChartRodData(
                toY: expenses, color: SentioColors.error, width: 32,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
              ),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryPieChart(List<FinancialTransaction> transactions) {
    final expenseTx = transactions.where((t) => t.isExpense).toList();
    final categoryTotals = <String, double>{};
    for (final t in expenseTx) {
      categoryTotals[t.category] = (categoryTotals[t.category] ?? 0) + t.amount;
    }

    final sorted = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = sorted.take(5).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: SentioEffects.standardCard(),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            height: 120,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 24,
                sections: top.map((entry) {
                  final cat = FinanceConstants.getCategoryById(entry.key);
                  return PieChartSectionData(
                    value: entry.value,
                    color: Color(cat?['color'] as int? ?? 0xFF9E9E9E),
                    radius: 28,
                    showTitle: false,
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: top.map((entry) {
                final cat = FinanceConstants.getCategoryById(entry.key);
                final total = categoryTotals.values.fold(0.0, (s, v) => s + v);
                final pct = total > 0 ? (entry.value / total * 100).toStringAsFixed(0) : '0';
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Container(
                        width: 10, height: 10,
                        decoration: BoxDecoration(
                          color: Color(cat?['color'] as int? ?? 0xFF9E9E9E),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        FinanceConstants.getCategoryIcon(entry.key),
                        size: 14,
                        color: Color(cat?['color'] as int? ?? 0xFF9E9E9E),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(cat?['label'] ?? entry.key,
                          style: GoogleFonts.manrope(fontSize: 12, color: SentioColors.textPrimary),
                          overflow: TextOverflow.ellipsis),
                      ),
                      Text('$pct%',
                        style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w600, color: SentioColors.textSecondary)),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdviceCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: SentioEffects.glowCard(glowColor: SentioColors.primary),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.lightbulb_outline, color: SentioColors.accent, size: 20),
              const SizedBox(width: 8),
              Text('Consejo IA', style: GoogleFonts.manrope(fontSize: 15, fontWeight: FontWeight.w700, color: SentioColors.accent)),
              const Spacer(),
              if (_aiAdvice != null && !_loadingAdvice)
                GestureDetector(
                  onTap: _loadAdvice,
                  child: const Icon(Icons.refresh, color: SentioColors.textSecondary, size: 18),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (_loadingAdvice)
            const Center(child: Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: SentioColors.accent)),
            ))
          else if (_aiAdvice != null)
            Text(
              _aiAdvice!,
              style: GoogleFonts.manrope(fontSize: 14, color: SentioColors.textPrimary, height: 1.5),
            )
          else
            Center(
              child: TextButton.icon(
                onPressed: _loadAdvice,
                icon: const Icon(Icons.auto_awesome, size: 18),
                label: Text('Pedir consejo personalizado', style: GoogleFonts.manrope(fontWeight: FontWeight.w600)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTransactionTile(FinancialTransaction tx) {
    final isIncome = tx.isIncome;
    final provider = context.read<AppProvider>();
    // Use the account's currency (fallback to tx.currency)
    final account = provider.financialAccounts
        .where((a) => a.id == tx.accountId)
        .firstOrNull;
    final displayCurrency = account?.currency ?? tx.currency;

    // Look up category in defaults first, then in user's custom categories
    final defaultCat = FinanceConstants.getCategoryById(tx.category);
    final customCat = defaultCat == null
        ? provider.customCategories.where((c) => c.id == tx.category).firstOrNull
        : null;
    final catLabel = defaultCat?['label'] ?? customCat?.label ?? tx.category;
    final catColor = defaultCat != null
        ? Color(defaultCat['color'] as int)
        : (customCat != null ? Color(customCat.color) : const Color(0xFF9E9E9E));
    final catIcon = defaultCat != null
        ? FinanceConstants.getCategoryIcon(tx.category)
        : (customCat?.iconData ?? Icons.more_horiz_rounded);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Dismissible(
        key: ValueKey(tx.id),
        background: _swipeBackground(
          color: SentioColors.primary,
          icon: Icons.edit_rounded,
          label: 'Editar',
          alignment: Alignment.centerLeft,
        ),
        secondaryBackground: _swipeBackground(
          color: SentioColors.error,
          icon: Icons.delete_rounded,
          label: 'Eliminar',
          alignment: Alignment.centerRight,
        ),
        confirmDismiss: (direction) async {
          if (direction == DismissDirection.startToEnd) {
            // Swipe right: edit (don't actually dismiss)
            HapticFeedback.lightImpact();
            context.push('/finance/add?id=${tx.id}');
            return false;
          } else {
            // Swipe left: confirm delete
            HapticFeedback.mediumImpact();
            return await _confirmDelete(tx);
          }
        },
        onDismissed: (_) async {
          final provider = context.read<AppProvider>();
          final ok = await provider.deleteFinancialTransaction(tx.id);
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                ok ? 'Movimiento eliminado' : 'No se pudo eliminar',
                style: GoogleFonts.manrope(),
              ),
              backgroundColor: ok ? SentioColors.surface : SentioColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: SentioEffects.standardCard(),
          child: Row(
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: catColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(catIcon, size: 20, color: catColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tx.description ?? catLabel,
                      style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w600, color: SentioColors.textPrimary),
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${tx.transactionDate.day}/${tx.transactionDate.month}',
                      style: GoogleFonts.manrope(fontSize: 12, color: SentioColors.textSecondary),
                    ),
                  ],
                ),
              ),
              Text(
                '${isIncome ? '+' : '-'} ${FinanceConstants.formatAmount(tx.amount, displayCurrency)}',
                style: GoogleFonts.manrope(
                  fontSize: 14, fontWeight: FontWeight.w700,
                  color: isIncome ? const Color(0xFF4CAF50) : SentioColors.error,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _swipeBackground({
    required Color color,
    required IconData icon,
    required String label,
    required Alignment alignment,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      alignment: alignment,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.manrope(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Future<bool> _confirmDelete(FinancialTransaction tx) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: SentioColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          '¿Eliminar movimiento?',
          style: GoogleFonts.manrope(
            fontWeight: FontWeight.w800,
            color: SentioColors.textPrimary,
          ),
        ),
        content: Text(
          'Esta acción no se puede deshacer.',
          style: GoogleFonts.manrope(
            fontSize: 14,
            color: SentioColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancelar',
              style: GoogleFonts.manrope(color: SentioColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Eliminar',
              style: GoogleFonts.manrope(
                color: SentioColors.error,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: SentioEffects.standardCard(),
      child: Column(
        children: [
          const Icon(Icons.account_balance_wallet_outlined, color: SentioColors.textSecondary, size: 40),
          const SizedBox(height: 12),
          Text('Sin movimientos aún', style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w600, color: SentioColors.textPrimary)),
          const SizedBox(height: 4),
          Text('Registrá tu primer ingreso o gasto',
            style: GoogleFonts.manrope(fontSize: 13, color: SentioColors.textSecondary)),
        ],
      ),
    );
  }
}
