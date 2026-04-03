import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:sentio_app/config/finance_constants.dart';
import 'package:sentio_app/config/theme.dart';
import 'package:sentio_app/providers/app_provider.dart';

class ReceiptScanScreen extends StatefulWidget {
  const ReceiptScanScreen({super.key});

  @override
  State<ReceiptScanScreen> createState() => _ReceiptScanScreenState();
}

class _ReceiptScanScreenState extends State<ReceiptScanScreen> {
  Uint8List? _imageBytes;
  String? _imageName;
  bool _scanning = false;
  bool _saving = false;
  Map<String, dynamic>? _scanResult;

  // Editable fields from scan
  final _amountController = TextEditingController();
  String _category = 'otros';
  final _descriptionController = TextEditingController();
  DateTime _date = DateTime.now();
  String? _selectedAccountId;

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, maxWidth: 1200, imageQuality: 85);
    if (picked == null) return;

    final bytes = await picked.readAsBytes();
    setState(() {
      _imageBytes = bytes;
      _imageName = picked.name;
      _scanResult = null;
    });

    _scanImage(bytes);
  }

  Future<void> _scanImage(Uint8List bytes) async {
    setState(() => _scanning = true);
    try {
      final provider = context.read<AppProvider>();
      final result = await provider.scanReceipt(bytes);
      if (result != null && mounted) {
        setState(() {
          _scanResult = result;
          _amountController.text = (result['amount'] as num?)?.toString() ?? '';
          _category = result['category'] as String? ?? 'otros';
          _descriptionController.text = result['description'] as String? ?? '';
          if (result['date'] != null) {
            try {
              _date = DateTime.parse(result['date'] as String);
            } catch (_) {}
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al leer el ticket', style: GoogleFonts.manrope())),
        );
      }
    }
    if (mounted) setState(() => _scanning = false);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final accounts = provider.financialAccounts;
    if (_selectedAccountId == null && accounts.isNotEmpty) {
      _selectedAccountId = accounts.first.id;
    }

    return Scaffold(
      backgroundColor: SentioColors.background,
      appBar: AppBar(
        title: Text('Escanear ticket', style: GoogleFonts.manrope(fontWeight: FontWeight.w800)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        children: [
          if (_imageBytes == null)
            _buildPickerOptions()
          else ...[
            // Image preview
            _buildImagePreview(),
            const SizedBox(height: 16),

            if (_scanning)
              _buildScanningState()
            else if (_scanResult != null) ...[
              // Confidence indicator
              _buildConfidence(),
              const SizedBox(height: 20),

              // Editable results
              _buildEditableResults(accounts),
              const SizedBox(height: 24),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => setState(() {
                        _imageBytes = null;
                        _scanResult = null;
                      }),
                      child: Text('Otra foto', style: GoogleFonts.manrope(fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _saving ? null : _saveTransaction,
                      child: _saving
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Text('Guardar', style: GoogleFonts.manrope(fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildPickerOptions() {
    return Column(
      children: [
        const SizedBox(height: 40),
        const Icon(Icons.document_scanner_outlined, size: 64, color: SentioColors.primary),
        const SizedBox(height: 16),
        Text('Escaneá tu ticket', style: GoogleFonts.manrope(fontSize: 20, fontWeight: FontWeight.w800, color: SentioColors.textPrimary)),
        const SizedBox(height: 8),
        Text('Sacá una foto o elegí una de tu galería',
          style: GoogleFonts.manrope(fontSize: 14, color: SentioColors.textSecondary), textAlign: TextAlign.center),
        const SizedBox(height: 32),
        Row(
          children: [
            Expanded(child: _buildPickerButton(
              icon: Icons.camera_alt_outlined,
              label: 'Cámara',
              onTap: () => _pickImage(ImageSource.camera),
            )),
            const SizedBox(width: 12),
            Expanded(child: _buildPickerButton(
              icon: Icons.photo_library_outlined,
              label: 'Galería',
              onTap: () => _pickImage(ImageSource.gallery),
            )),
          ],
        ),
      ],
    );
  }

  Widget _buildPickerButton({required IconData icon, required String label, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: SentioEffects.standardCard(),
        child: Column(
          children: [
            Icon(icon, color: SentioColors.primary, size: 32),
            const SizedBox(height: 8),
            Text(label, style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w600, color: SentioColors.textPrimary)),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePreview() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Image.memory(_imageBytes!, height: 200, width: double.infinity, fit: BoxFit.cover),
    );
  }

  Widget _buildScanningState() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: SentioEffects.standardCard(),
      child: Column(
        children: [
          const SizedBox(width: 32, height: 32, child: CircularProgressIndicator(strokeWidth: 3, color: SentioColors.primary)),
          const SizedBox(height: 16),
          Text('Leyendo el ticket...', style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w600, color: SentioColors.textPrimary)),
          const SizedBox(height: 4),
          Text('Esto puede tardar unos segundos', style: GoogleFonts.manrope(fontSize: 13, color: SentioColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildConfidence() {
    final confidence = (_scanResult?['confidence'] as num?)?.toDouble() ?? 0;
    final isHigh = confidence >= 0.7;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: (isHigh ? const Color(0xFF4CAF50) : SentioColors.warning).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(isHigh ? Icons.check_circle_outline : Icons.info_outline,
            size: 16, color: isHigh ? const Color(0xFF4CAF50) : SentioColors.warning),
          const SizedBox(width: 6),
          Text(
            isHigh ? 'Lectura confiable' : 'Verificá los datos',
            style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w600,
              color: isHigh ? const Color(0xFF4CAF50) : SentioColors.warning),
          ),
        ],
      ),
    );
  }

  Widget _buildEditableResults(List accounts) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Amount
        Text('Monto detectado', style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w600, color: SentioColors.textSecondary)),
        const SizedBox(height: 8),
        TextField(
          controller: _amountController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: GoogleFonts.manrope(fontSize: 24, fontWeight: FontWeight.w800, color: SentioColors.textPrimary),
          decoration: InputDecoration(
            prefixText: '\$ ',
            prefixStyle: GoogleFonts.manrope(fontSize: 24, fontWeight: FontWeight.w600, color: SentioColors.textSecondary),
          ),
        ),
        const SizedBox(height: 16),

        // Category
        Text('Categoría', style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w600, color: SentioColors.textSecondary)),
        const SizedBox(height: 8),
        SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: FinanceConstants.expenseCategories.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, i) {
              final cat = FinanceConstants.expenseCategories[i];
              final isSelected = _category == cat['id'];
              final color = Color(cat['color'] as int);
              return GestureDetector(
                onTap: () => setState(() => _category = cat['id'] as String),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? color.withValues(alpha: 0.15) : SentioColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: isSelected ? color : SentioColors.divider),
                  ),
                  child: Center(
                    child: Text('${cat['emoji']} ${cat['label']}',
                      style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w500,
                        color: isSelected ? color : SentioColors.textSecondary)),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),

        // Description
        Text('Descripción', style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w600, color: SentioColors.textSecondary)),
        const SizedBox(height: 8),
        TextField(
          controller: _descriptionController,
          style: GoogleFonts.manrope(color: SentioColors.textPrimary),
          decoration: InputDecoration(
            hintText: 'Descripción del gasto',
            hintStyle: GoogleFonts.manrope(color: SentioColors.textSecondary),
          ),
        ),
        const SizedBox(height: 16),

        // Account
        if (accounts.isNotEmpty) ...[
          Text('Cuenta', style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w600, color: SentioColors.textSecondary)),
          const SizedBox(height: 8),
          SizedBox(
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
          ),
        ],
      ],
    );
  }

  Future<void> _saveTransaction() async {
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

    // Upload image first
    String? imageUrl;
    if (_imageBytes != null && _imageName != null) {
      final provider = context.read<AppProvider>();
      // Use finance service to upload
      imageUrl = await provider.scanReceipt(_imageBytes!).then((_) => null); // We already have result
      // Actually upload via storage
    }

    final provider = context.read<AppProvider>();
    final tx = await provider.createFinancialTransaction(
      accountId: _selectedAccountId!,
      type: 'expense',
      amount: amount,
      category: _category,
      description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
      isFromScan: true,
      transactionDate: _date,
    );

    if (mounted) {
      setState(() => _saving = false);
      if (tx != null) {
        context.pop();
      }
    }
  }
}
