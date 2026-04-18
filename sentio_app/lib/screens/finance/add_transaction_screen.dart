import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:sentio_app/config/finance_constants.dart';
import 'package:sentio_app/config/theme.dart';
import 'package:sentio_app/providers/app_provider.dart';

class AddTransactionScreen extends StatefulWidget {
  final String initialType;
  final String? transactionId;

  const AddTransactionScreen({
    super.key,
    this.initialType = 'expense',
    this.transactionId,
  });

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

  bool get _isEditing => widget.transactionId != null;

  @override
  void initState() {
    super.initState();
    _type = widget.initialType;
    final categories = FinanceConstants.categoriesForType(_type);
    if (categories.isNotEmpty) _selectedCategory = categories.first['id'] as String;

    // Pre-fill if editing
    if (_isEditing) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final provider = context.read<AppProvider>();
        final tx = provider.financialTransactions
            .where((t) => t.id == widget.transactionId)
            .firstOrNull;
        if (tx != null) {
          setState(() {
            _type = tx.type;
            _amountController.text = tx.amount.toString();
            _descriptionController.text = tx.description ?? '';
            _selectedCategory = tx.category;
            _selectedAccountId = tx.accountId;
            _selectedDate = tx.transactionDate;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _allCategories(AppProvider provider) {
    final defaults = FinanceConstants.categoriesForType(_type);
    final custom = provider.customCategoriesForType(_type).map((c) => {
      'id': c.id,
      'label': c.label,
      'icon': c.iconData,
      'color': c.color,
      'isCustom': true,
    }).toList();
    return [...defaults, ...custom];
  }

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
        title: Text(
          _isEditing
              ? 'Editar movimiento'
              : (_type == 'income' ? 'Nuevo ingreso' : 'Nuevo gasto'),
          style: GoogleFonts.manrope(fontWeight: FontWeight.w800),
        ),
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
    final provider = context.watch<AppProvider>();
    final account = provider.financialAccounts
        .where((a) => a.id == _selectedAccountId)
        .firstOrNull;
    final currency = account?.currency ?? 'USD';
    final symbol = FinanceConstants.currencySymbol(currency);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: SentioEffects.standardCard(),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Monto en ', style: GoogleFonts.manrope(fontSize: 13, color: SentioColors.textSecondary)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: SentioColors.accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(currency, style: GoogleFonts.manrope(
                  fontSize: 11, fontWeight: FontWeight.w800, color: SentioColors.accent, letterSpacing: 0.5,
                )),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(symbol, style: GoogleFonts.manrope(fontSize: 22, fontWeight: FontWeight.w600, color: SentioColors.textSecondary)),
              ),
              const SizedBox(width: 6),
              IntrinsicWidth(
                child: TextField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  autofocus: !_isEditing,
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
    final provider = context.watch<AppProvider>();
    final cats = _allCategories(provider);

    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: cats.length + 1, // +1 for "Add" button
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          // Last item: add new category button
          if (i == cats.length) {
            return GestureDetector(
              onTap: _showCreateCategorySheet,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: SentioColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: SentioColors.primary.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.add_rounded, size: 16, color: SentioColors.primary),
                    const SizedBox(width: 4),
                    Text('Nueva',
                      style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w700,
                        color: SentioColors.primary)),
                  ],
                ),
              ),
            );
          }

          final cat = cats[i];
          final isSelected = _selectedCategory == cat['id'];
          final color = Color(cat['color'] as int);
          final isCustom = cat['isCustom'] == true;
          return GestureDetector(
            onTap: () => setState(() => _selectedCategory = cat['id'] as String),
            onLongPress: isCustom
                ? () => _confirmDeleteCategory(cat['id'] as String, cat['label'] as String)
                : null,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: isSelected ? color.withValues(alpha: 0.15) : SentioColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isSelected ? color : SentioColors.divider),
              ),
              child: Row(
                children: [
                  Icon(
                    cat['icon'] as IconData,
                    size: 16,
                    color: isSelected ? color : SentioColors.textSecondary,
                  ),
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

  Future<void> _confirmDeleteCategory(String id, String label) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: SentioColors.surface,
        title: Text('Eliminar categoría', style: GoogleFonts.manrope(color: SentioColors.textPrimary, fontWeight: FontWeight.w800)),
        content: Text('¿Eliminar "$label"? Esto no afectará movimientos existentes.',
          style: GoogleFonts.manrope(color: SentioColors.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Cancelar', style: GoogleFonts.manrope(color: SentioColors.textSecondary))),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text('Eliminar', style: GoogleFonts.manrope(color: SentioColors.error, fontWeight: FontWeight.w700))),
        ],
      ),
    );
    if (ok == true && mounted) {
      await context.read<AppProvider>().deleteCustomCategory(id);
      if (_selectedCategory == id) {
        final fallback = FinanceConstants.categoriesForType(_type).first['id'] as String;
        setState(() => _selectedCategory = fallback);
      }
    }
  }

  void _showCreateCategorySheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: SentioColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: _CreateCategorySheet(
          type: _type,
          onCreated: (cat) {
            setState(() => _selectedCategory = cat.id);
          },
        ),
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

    bool success;
    if (_isEditing) {
      success = await provider.updateFinancialTransaction(
        transactionId: widget.transactionId!,
        type: _type,
        amount: amount,
        category: _selectedCategory ?? 'otros',
        description: _descriptionController.text.trim().isEmpty
            ? ''
            : _descriptionController.text.trim(),
        accountId: _selectedAccountId!,
        transactionDate: _selectedDate,
      );
    } else {
      final tx = await provider.createFinancialTransaction(
        accountId: _selectedAccountId!,
        type: _type,
        amount: amount,
        category: _selectedCategory ?? 'otros',
        description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
        transactionDate: _selectedDate,
      );
      success = tx != null;
    }

    if (mounted) {
      setState(() => _saving = false);
      if (success) {
        context.pop();
      }
    }
  }
}

// ══════════════════════════════════════
// CREATE CATEGORY SHEET
// ══════════════════════════════════════

class _CreateCategorySheet extends StatefulWidget {
  final String type;
  final void Function(dynamic category) onCreated;

  const _CreateCategorySheet({required this.type, required this.onCreated});

  @override
  State<_CreateCategorySheet> createState() => _CreateCategorySheetState();
}

class _CreateCategorySheetState extends State<_CreateCategorySheet> {
  final _labelController = TextEditingController();
  IconData _selectedIcon = Icons.star_rounded;
  Color _selectedColor = const Color(0xFF7B61FF);
  bool _saving = false;

  static final List<IconData> _iconOptions = [
    Icons.star_rounded,
    Icons.favorite_rounded,
    Icons.local_cafe_rounded,
    Icons.fitness_center_rounded,
    Icons.pets_rounded,
    Icons.local_gas_station_rounded,
    Icons.flight_rounded,
    Icons.directions_bus_rounded,
    Icons.directions_bike_rounded,
    Icons.local_taxi_rounded,
    Icons.local_grocery_store_rounded,
    Icons.local_pharmacy_rounded,
    Icons.local_florist_rounded,
    Icons.cake_rounded,
    Icons.icecream_rounded,
    Icons.sports_soccer_rounded,
    Icons.music_note_rounded,
    Icons.book_rounded,
    Icons.brush_rounded,
    Icons.camera_alt_rounded,
    Icons.headphones_rounded,
    Icons.tv_rounded,
    Icons.phone_iphone_rounded,
    Icons.watch_rounded,
    Icons.diamond_rounded,
    Icons.savings_rounded,
    Icons.card_giftcard_rounded,
    Icons.celebration_rounded,
    Icons.work_rounded,
    Icons.beach_access_rounded,
    Icons.umbrella_rounded,
    Icons.spa_rounded,
    Icons.psychology_rounded,
    Icons.lightbulb_rounded,
    Icons.eco_rounded,
    Icons.child_care_rounded,
  ];

  static const List<int> _colorOptions = [
    0xFF7B61FF, 0xFF00D4AA, 0xFFFF6B9D, 0xFFFFD93D,
    0xFFFF9800, 0xFF2196F3, 0xFF4CAF50, 0xFFE91E63,
    0xFF9C27B0, 0xFF00BCD4, 0xFFC9A96E, 0xFF795548,
  ];

  @override
  void dispose() {
    _labelController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final label = _labelController.text.trim();
    if (label.isEmpty) return;
    setState(() => _saving = true);
    final cat = await context.read<AppProvider>().createCustomCategory(
      type: widget.type,
      label: label,
      iconCode: _selectedIcon.codePoint,
      color: _selectedColor.toARGB32(),
    );
    if (mounted) {
      if (cat != null) {
        widget.onCreated(cat);
        Navigator.pop(context);
      } else {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al crear categoría', style: GoogleFonts.manrope())),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36, height: 4,
              decoration: BoxDecoration(color: SentioColors.divider, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 16),
          Text('Nueva categoría', style: GoogleFonts.manrope(
            fontSize: 20, fontWeight: FontWeight.w800, color: SentioColors.textPrimary,
          )),
          const SizedBox(height: 16),
          // Preview
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: _selectedColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _selectedColor),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(_selectedIcon, size: 20, color: _selectedColor),
                  const SizedBox(width: 8),
                  Text(
                    _labelController.text.isEmpty ? 'Vista previa' : _labelController.text,
                    style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w600, color: _selectedColor),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Name input
          TextField(
            controller: _labelController,
            autofocus: true,
            onChanged: (_) => setState(() {}),
            style: GoogleFonts.manrope(color: SentioColors.textPrimary),
            decoration: InputDecoration(
              hintText: 'Nombre de la categoría',
              hintStyle: GoogleFonts.manrope(color: SentioColors.textTertiary),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.04),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: _selectedColor)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
          const SizedBox(height: 16),
          // Icons
          Text('Icono', style: GoogleFonts.manrope(fontSize: 12, color: SentioColors.textSecondary, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          SizedBox(
            height: 200,
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 6, mainAxisSpacing: 8, crossAxisSpacing: 8,
              ),
              itemCount: _iconOptions.length,
              itemBuilder: (_, i) {
                final icon = _iconOptions[i];
                final isSelected = _selectedIcon.codePoint == icon.codePoint;
                return GestureDetector(
                  onTap: () => setState(() => _selectedIcon = icon),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected ? _selectedColor.withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: isSelected ? _selectedColor : Colors.transparent),
                    ),
                    child: Icon(icon, color: isSelected ? _selectedColor : SentioColors.textSecondary, size: 22),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          // Colors
          Text('Color', style: GoogleFonts.manrope(fontSize: 12, color: SentioColors.textSecondary, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: _colorOptions.map((c) {
              final color = Color(c);
              final isSelected = _selectedColor.toARGB32() == c;
              return GestureDetector(
                onTap: () => setState(() => _selectedColor = color),
                child: Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(color: isSelected ? Colors.white : Colors.transparent, width: 2),
                  ),
                  child: isSelected ? const Icon(Icons.check_rounded, color: Colors.white, size: 18) : null,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _saving || _labelController.text.trim().isEmpty ? null : _save,
            style: ElevatedButton.styleFrom(backgroundColor: _selectedColor),
            child: _saving
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Text('Crear categoría', style: GoogleFonts.manrope(fontWeight: FontWeight.w800)),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
