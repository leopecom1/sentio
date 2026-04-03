import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:sentio_app/config/finance_constants.dart';
import 'package:sentio_app/config/theme.dart';
import 'package:sentio_app/models/financial_account.dart';
import 'package:sentio_app/providers/app_provider.dart';

class FinanceAccountsScreen extends StatelessWidget {
  const FinanceAccountsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final accounts = provider.financialAccounts;

    return Scaffold(
      backgroundColor: SentioColors.background,
      appBar: AppBar(
        title: Text('Cuentas', style: GoogleFonts.manrope(fontWeight: FontWeight.w800)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
        children: [
          if (accounts.isEmpty)
            _buildEmptyState()
          else
            ...accounts.map((a) => _buildAccountCard(context, a, provider)),
          const SizedBox(height: 20),
          _buildAddButton(context, provider),
        ],
      ),
    );
  }

  Widget _buildAccountCard(BuildContext context, FinancialAccount account, AppProvider provider) {
    final typeData = FinanceConstants.getAccountTypeById(account.accountType);
    final color = Color(typeData?['color'] as int? ?? 0xFF3D5A80);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: SentioEffects.glowCard(glowColor: color),
      child: Row(
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(typeData?['icon'] as IconData? ?? Icons.account_balance_wallet_outlined, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(account.name,
                  style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w700, color: SentioColors.textPrimary)),
                const SizedBox(height: 2),
                Text(typeData?['label'] as String? ?? account.accountType,
                  style: GoogleFonts.manrope(fontSize: 12, color: SentioColors.textSecondary)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                FinanceConstants.formatAmount(account.balance, account.currency),
                style: GoogleFonts.manrope(
                  fontSize: 16, fontWeight: FontWeight.w700,
                  color: account.balance >= 0 ? SentioColors.textPrimary : SentioColors.error,
                ),
              ),
              Text(account.currency,
                style: GoogleFonts.manrope(fontSize: 11, color: SentioColors.textSecondary)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAddButton(BuildContext context, AppProvider provider) {
    return GestureDetector(
      onTap: () => _showAddAccountSheet(context, provider),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: SentioColors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: SentioColors.primary.withValues(alpha: 0.3), style: BorderStyle.solid),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add_circle_outline, color: SentioColors.primary, size: 22),
            const SizedBox(width: 8),
            Text('Agregar cuenta',
              style: GoogleFonts.manrope(fontSize: 15, fontWeight: FontWeight.w600, color: SentioColors.primary)),
          ],
        ),
      ),
    );
  }

  void _showAddAccountSheet(BuildContext context, AppProvider provider) {
    final nameController = TextEditingController();
    String selectedType = 'cash';
    String selectedCurrency = 'ARS';
    final balanceController = TextEditingController(text: '0');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: SentioColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(20, 24, 20, MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(width: 40, height: 4, decoration: BoxDecoration(
                  color: SentioColors.textSecondary, borderRadius: BorderRadius.circular(2))),
              ),
              const SizedBox(height: 20),
              Text('Nueva cuenta',
                style: GoogleFonts.manrope(fontSize: 20, fontWeight: FontWeight.w800, color: SentioColors.textPrimary)),
              const SizedBox(height: 20),

              // Name
              TextField(
                controller: nameController,
                style: GoogleFonts.manrope(color: SentioColors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Nombre de la cuenta',
                  hintStyle: GoogleFonts.manrope(color: SentioColors.textSecondary),
                ),
              ),
              const SizedBox(height: 16),

              // Account type pills
              Text('Tipo', style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w600, color: SentioColors.textSecondary)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8, runSpacing: 8,
                children: FinanceConstants.accountTypes.map((t) {
                  final isSelected = selectedType == t['id'];
                  final color = Color(t['color'] as int);
                  return GestureDetector(
                    onTap: () => setSheetState(() => selectedType = t['id'] as String),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? color.withValues(alpha: 0.15) : SentioColors.background,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: isSelected ? color : SentioColors.divider),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(t['icon'] as IconData, size: 16, color: isSelected ? color : SentioColors.textSecondary),
                          const SizedBox(width: 6),
                          Text(t['label'] as String,
                            style: GoogleFonts.manrope(
                              fontSize: 13, fontWeight: FontWeight.w500,
                              color: isSelected ? color : SentioColors.textSecondary)),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Currency + Balance row
              Row(
                children: [
                  // Currency toggle
                  ...FinanceConstants.currencies.map((c) {
                    final isSelected = selectedCurrency == c['id'];
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => setSheetState(() => selectedCurrency = c['id']!),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? SentioColors.primary.withValues(alpha: 0.15) : SentioColors.background,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: isSelected ? SentioColors.primary : SentioColors.divider),
                          ),
                          child: Text(c['id']!,
                            style: GoogleFonts.manrope(
                              fontSize: 13, fontWeight: FontWeight.w600,
                              color: isSelected ? SentioColors.primary : SentioColors.textSecondary)),
                        ),
                      ),
                    );
                  }),
                  const SizedBox(width: 8),
                  // Balance input
                  Expanded(
                    child: TextField(
                      controller: balanceController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: GoogleFonts.manrope(color: SentioColors.textPrimary),
                      decoration: InputDecoration(
                        hintText: 'Balance inicial',
                        hintStyle: GoogleFonts.manrope(color: SentioColors.textSecondary),
                        prefixText: '${FinanceConstants.currencySymbol(selectedCurrency)} ',
                        prefixStyle: GoogleFonts.manrope(color: SentioColors.textSecondary),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Create button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    if (nameController.text.trim().isEmpty) return;
                    await provider.createFinancialAccount(
                      name: nameController.text.trim(),
                      accountType: selectedType,
                      currency: selectedCurrency,
                      initialBalance: double.tryParse(balanceController.text) ?? 0,
                    );
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  child: Text('Crear cuenta', style: GoogleFonts.manrope(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: SentioEffects.standardCard(),
      child: Column(
        children: [
          const Icon(Icons.account_balance_outlined, color: SentioColors.textSecondary, size: 40),
          const SizedBox(height: 12),
          Text('Sin cuentas aún', style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w600, color: SentioColors.textPrimary)),
          const SizedBox(height: 4),
          Text('Creá tu primera cuenta para empezar',
            style: GoogleFonts.manrope(fontSize: 13, color: SentioColors.textSecondary)),
        ],
      ),
    );
  }
}
