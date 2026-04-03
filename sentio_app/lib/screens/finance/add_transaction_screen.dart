import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:sentio_app/config/finance_constants.dart';
import 'package:sentio_app/config/theme.dart';
import 'package:sentio_app/providers/app_provider.dart';

class AddTransactionScreen extends StatefulWidget {
  final String initialType;

  const AddTransactionScreen({super.key, this.initialType = 'expense'});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  late String _type;
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  String? _selectedCategory;
  String? _selectedAccountId;
  DateTime _selectedDate = DateTime.now();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _type = widget.initialType;
    final categories = FinanceConstants.categoriesForType(_type);
    if (categories.isNotEmpty) _selectedCategory = categories.first['id'] as String;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _categories => FinanceConstants.categoriesForType(_type);

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final accounts = provider.financialAccounts;

    // Auto-select first account
    if (_selectedAccountId == null && accounts.isNotEmpty) {
      _selectedAccountId = accounts.first.id;
    }

    return Scaffold(
      backgroundColor: SentioColors.background,
      appBar: AppBar(
        title: Text(_type == 'income' ? 'Nuevo ingreso' : 'Nuevo gasto',
          style: GoogleFonts.manrope(fontWeight: FontWeight.w800)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        children: [
          // Type toggle
          _buildTypeToggle(),
          const SizedBox(height: 24),

          // Amount input
          _buildAmountInput(),
          const SizedBox(height: 24),

          // Category selector
          _buildLabel('Categoría'),
          const SizedBox(height: 8),
          _buildCategorySelector(),
          const SizedBox(height: 20),

          // Account selector
          if (accounts.isNotEmpty) ...[
            _buildLabel('Cuenta'),
            const SizedBox(height: 8),
            _buildAccountSelector(accounts),
            const SizedBox(height: 20),
          ],

          // Date picker
          _buildLabel('Fecha'),
          const SizedBox(height: 8),
          _buildDatePicker(),
          const SizedBox(height: 20),

          // Description
          _buildLabel('Descripción (opcional)'),
          const SizedBox(height: 8),
          TextField(
            controller: _descriptionController,
            style: GoogleFonts.manrope(color: SentioColors.textPrimary),
            maxLines: 2,
            decoration: InputDecoration(
              hintText: '¿Qué fue?',
              hintStyle: GoogleFonts.manrope(color: SentioColors.textSecondary),
            ),
          ),
          const SizedBox(height: 32),

          // Save button
          ElevatedButton(
            onPressed: _saving ? null : _save,
            child: _saving
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : Text('Guardar', style: GoogleFonts.manrope(fontWeight: FontWeight.w700)),
          ),

          // No accounts warning
          if (accounts.isEmpty) ...[
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () => context.push('/finance/accounts'),
              child: Text(
                'Primero creá una cuenta para registrar movimientos',
                style: GoogleFonts.manrope(fontSize: 13, color: SentioColors.primary, decoration: TextDecoration.underline),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTypeToggle() {
    return Container(
      decoration: BoxDecoration(
        color: SentioColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SentioColors.divider),
      ),
      child: Row(
        children: [
          Expanded(child: _buildToggleOption('Gasto', 'expense', SentioColors.error)),
          Expanded(child: _buildToggleOption('Ingreso', 'income', const Color(0xFF4CAF50))),
        ],
      ),
    );
  }

  Widget _buildToggleOption(String label, String type, Color color) {
    final isSelected = _type == type;
    return GestureDetector(
      onTap: () {
        setState(() {
          _type = type;
          final cats = FinanceConstants.categoriesForType(_type);
          _selectedCategory = cats.isNotEmpty ? cats.first['id'] as String : null;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Center(
          child: Text(label, style: GoogleFonts.manrope(
            fontSize: 15, fontWeight: FontWeight.w700,
            color: isSelected ? color : SentioColors.textSecondary)),
        ),
      ),
    );
  }

  Widget _buildAmountInput() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: SentioEffects.standardCard(),
      child: Column(
        children: [
          Text('Monto', style: GoogleFonts.manrope(fontSize: 13, color: SentioColors.textSecondary)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text('\$', style: GoogleFonts.manrope(fontSize: 24, fontWeight: FontWeight.w600, color: SentioColors.textSecondary)),
              ),
              const SizedBox(width: 4),
              IntrinsicWidth(
                child: TextField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  autofocus: true,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.manrope(fontSize: 40, fontWeight: FontWeight.w800, color: SentioColors.textPrimary),
                  decoration: InputDecoration(
                    hintText: '0',
                    hintStyle: GoogleFonts.manrope(fontSize: 40, fontWeight: FontWeight.w800, color: SentioColors.textTertiary),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                    isDense: true,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String label) {
    return Text(label, style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w600, color: SentioColors.textSecondary));
  }

  Widget _buildCategorySelector() {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final cat = _categories[i];
          final isSelected = _selectedCategory == cat['id'];
          final color = Color(cat['color'] as int);
          return GestureDetector(
            onTap: () => setState(() => _selectedCategory = cat['id'] as String),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: isSelected ? color.withValues(alpha: 0.15) : SentioColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isSelected ? color : SentioColors.divider),
              ),
              child: Row(
                children: [
                  Text(cat['emoji'] as String, style: const TextStyle(fontSize: 14)),
                  const SizedBox(width: 6),
                  Text(cat['label'] as String,
                    style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w500,
                      color: isSelected ? color : SentioColors.textSecondary)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAccountSelector(List accounts) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: accounts.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final acc = accounts[i];
          final isSelected = _selectedAccountId == acc.id;
          return GestureDetector(
            onTap: () => setState(() => _selectedAccountId = acc.id),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: isSelected ? SentioColors.primary.withValues(alpha: 0.15) : SentioColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isSelected ? SentioColors.primary : SentioColors.divider),
              ),
              child: Center(
                child: Text(acc.name,
                  style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w500,
                    color: isSelected ? SentioColors.primary : SentioColors.textSecondary)),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDatePicker() {
    return GestureDetector(
      onTap: _pickDate,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: SentioEffects.standardCard(),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_outlined, size: 18, color: SentioColors.textSecondary),
            const SizedBox(width: 12),
            Text(
              '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
              style: GoogleFonts.manrope(fontSize: 14, color: SentioColors.textPrimary),
            ),
            const Spacer(),
            if (_selectedDate.day == DateTime.now().day &&
                _selectedDate.month == DateTime.now().month &&
                _selectedDate.year == DateTime.now().year)
              Text('Hoy', style: GoogleFonts.manrope(fontSize: 12, color: SentioColors.accent, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: SentioColors.primary,
            surface: SentioColors.surface,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _save() async {
    final amount = double.tryParse(_amountController.text.replaceAll(',', '.'));
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ingresá un monto válido', style: GoogleFonts.manrope())),
      );
      return;
    }
    if (_selectedAccountId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Seleccioná una cuenta', style: GoogleFonts.manrope())),
      );
      return;
    }

    setState(() => _saving = true);
    final provider = context.read<AppProvider>();
    final tx = await provider.createFinancialTransaction(
      accountId: _selectedAccountId!,
      type: _type,
      amount: amount,
      category: _selectedCategory ?? 'otros',
      description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
      transactionDate: _selectedDate,
    );

    if (mounted) {
      setState(() => _saving = false);
      if (tx != null) {
        context.pop();
      }
    }
  }
}
