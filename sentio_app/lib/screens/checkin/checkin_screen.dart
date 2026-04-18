import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:sentio_app/config/theme.dart';
import 'package:sentio_app/config/constants.dart';
import 'package:sentio_app/providers/app_provider.dart';
import 'package:sentio_app/widgets/sentio_button.dart';
import 'package:sentio_app/widgets/sentio_card.dart';

class CheckinScreen extends StatefulWidget {
  const CheckinScreen({super.key});

  @override
  State<CheckinScreen> createState() => _CheckinScreenState();
}

class _CheckinScreenState extends State<CheckinScreen> {
  // Data
  String _emotion = '';
  int _energy = 3;
  int _stress = 3;
  int _mentalClarity = 3;
  int _motivation = 3;
  int _financialPressure = 3;
  int _control = 3;
  int _dayQuality = 3;
  String _note = '';
  final Set<String> _selectedTriggers = {};
  bool _isDeep = false;
  bool _isSaving = false;
  late String _currentPrompt;
  final _noteController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _currentPrompt = SentioConstants.checkinPrompts[
        Random().nextInt(SentioConstants.checkinPrompts.length)];
  }

  @override
  void dispose() {
    _noteController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_emotion.isEmpty) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
      return;
    }

    HapticFeedback.mediumImpact();
    setState(() => _isSaving = true);

    try {
      final provider = context.read<AppProvider>();
      await provider.saveCheckin(
        emotion: _emotion,
        energy: _energy,
        stress: _stress,
        mentalClarity: _isDeep ? _mentalClarity : null,
        motivation: _isDeep ? _motivation : null,
        financialPressure: _isDeep ? _financialPressure : null,
        control: _isDeep ? _control : null,
        dayQuality: _isDeep ? _dayQuality : null,
        note: _note.isNotEmpty ? _note : null,
        notePrompt: _note.isNotEmpty ? _currentPrompt : null,
      );

      if (!mounted) return;
      _showSummary();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al guardar: $e'),
          backgroundColor: SentioColors.error,
        ),
      );
    }
  }

  void _showSummary() {
    final emotion = SentioConstants.emotions.firstWhere(
      (e) => e['id'] == _emotion,
      orElse: () => SentioConstants.emotions.first,
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: SentioColors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(
            top: BorderSide(color: SentioColors.border),
            left: BorderSide(color: SentioColors.border),
            right: BorderSide(color: SentioColors.border),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Color(emotion['color'] as int).withOpacity(0.15),
                boxShadow: SentioEffects.glow(
                  Color(emotion['color'] as int),
                  blur: 20,
                  opacity: 0.3,
                ),
              ),
              child: Center(
                child: Icon(
                  SentioConstants.getEmotionIcon(emotion['id']),
                  color: Color(emotion['color'] as int),
                  size: 36,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Check-in registrado',
              style: GoogleFonts.manrope(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: SentioColors.textPrimary,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _getClosingMessage(),
              style: GoogleFonts.manrope(
                fontSize: 14,
                color: SentioColors.textSecondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            // Mini stats
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _MiniStat(label: 'Energia', value: '$_energy/5'),
                const SizedBox(width: 24),
                _MiniStat(label: 'Estres', value: '$_stress/5'),
              ],
            ),
            const SizedBox(height: 24),
            SentioGradientButton(
              label: 'Listo',
              onPressed: () {
                Navigator.of(ctx).pop();
                context.pop();
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  String _getClosingMessage() {
    if (_stress >= 4) {
      return 'Hoy fue pesado, y esta bien reconocerlo.\nGracias por ser honesto con vos mismo.';
    }
    if (_energy <= 2) {
      return 'Tu cuerpo te esta pidiendo un respiro.\nCuidarte es estrategia, no debilidad.';
    }
    if (_emotion == 'motivated' || _emotion == 'focused') {
      return 'Que bueno sentir esa energia.\nAprovecha este momento.';
    }
    return 'Gracias por registrar como te sentis.\nCada check-in es un acto de cuidado.';
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();

    return Scaffold(
      backgroundColor: SentioColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(),
            // Scrollable content
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    // Title section
                    _buildTitleSection(),
                    const SizedBox(height: 24),
                    // Emotion selector
                    _buildEmotionSelector(),
                    const SizedBox(height: 28),
                    // Stress slider
                    _buildStressSlider(),
                    const SizedBox(height: 28),
                    // Energy slider
                    _buildEnergySlider(),
                    const SizedBox(height: 28),
                    // Note textarea
                    _buildNoteSection(),
                    const SizedBox(height: 28),
                    // Trigger tags
                    _buildTriggerTags(),
                    const SizedBox(height: 28),
                    // Deep check-in expandable
                    _buildDeepCheckin(),
                    const SizedBox(height: 28),
                    // Weekly overview
                    _buildWeeklyOverview(provider),
                    const SizedBox(height: 28),
                    // Save button
                    SentioGradientButton(
                      label: 'Registrar check-in',
                      icon: Icons.check_rounded,
                      isLoading: _isSaving,
                      onPressed: _save,
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============ Header ============
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.pop(),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: SentioColors.surface,
                border: Border.all(color: SentioColors.border),
              ),
              child: const Icon(
                Icons.arrow_back_rounded,
                color: SentioColors.textPrimary,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Text(
            'Seguimiento de Bienestar',
            style: GoogleFonts.manrope(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: SentioColors.textPrimary,
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
    );
  }

  // ============ Title Section ============
  Widget _buildTitleSection() {
    final now = DateTime.now();
    String formattedDate;
    try {
      formattedDate = DateFormat('EEEE d MMMM', 'es').format(now);
      // Capitalize first letter
      formattedDate = formattedDate[0].toUpperCase() + formattedDate.substring(1);
    } catch (_) {
      final months = ['enero','febrero','marzo','abril','mayo','junio','julio','agosto','septiembre','octubre','noviembre','diciembre'];
      final days = ['lunes','martes','miercoles','jueves','viernes','sabado','domingo'];
      formattedDate = '${days[now.weekday - 1]} ${now.day} de ${months[now.month - 1]}';
      formattedDate = formattedDate[0].toUpperCase() + formattedDate.substring(1);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Como te sentis?',
          style: GoogleFonts.manrope(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: SentioColors.textPrimary,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          formattedDate,
          style: GoogleFonts.manrope(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: SentioColors.textSecondary,
          ),
        ),
      ],
    );
  }

  // ============ Emotion Selector ============
  Widget _buildEmotionSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Emocion',
          style: GoogleFonts.manrope(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: SentioColors.textSecondary,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 100,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: SentioConstants.emotions.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final emotion = SentioConstants.emotions[index];
              final isSelected = _emotion == emotion['id'];
              final color = Color(emotion['color'] as int);

              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _emotion = emotion['id']);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 72,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? color.withOpacity(0.15)
                              : SentioColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected ? color : SentioColors.border,
                            width: isSelected ? 2 : 1,
                          ),
                          boxShadow: isSelected
                              ? SentioEffects.glow(color, blur: 12, opacity: 0.4)
                              : null,
                        ),
                        child: Center(
                          child: Icon(
                            SentioConstants.getEmotionIcon(emotion['id']),
                            color: isSelected ? color : SentioColors.textSecondary,
                            size: 28,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        emotion['label'],
                        style: GoogleFonts.manrope(
                          fontSize: 11,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                          color: isSelected ? color : SentioColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ============ Stress Slider ============
  Widget _buildStressSlider() {
    return SentioCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Nivel de estres',
                style: GoogleFonts.manrope(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: SentioColors.textPrimary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStressColor(_stress).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$_stress/5',
                  style: GoogleFonts.manrope(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _getStressColor(_stress),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Gradient track slider
          _GradientSlider(
            value: _stress,
            gradientColors: const [
              Color(0xFF00FFBD), // green (Zen)
              Color(0xFFFFD700), // yellow (Equilibrado)
              Color(0xFFE05252), // red (Agotado)
            ],
            onChanged: (v) => setState(() => _stress = v),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Zen', style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w500, color: SentioColors.textTertiary)),
              Text('Equilibrado', style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w500, color: SentioColors.textTertiary)),
              Text('Agotado', style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w500, color: SentioColors.textTertiary)),
            ],
          ),
        ],
      ),
    );
  }

  Color _getStressColor(int value) {
    if (value <= 2) return const Color(0xFF00FFBD);
    if (value <= 3) return const Color(0xFFFFD700);
    return const Color(0xFFE05252);
  }

  // ============ Energy Slider ============
  Widget _buildEnergySlider() {
    return SentioCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Nivel de energia',
                style: GoogleFonts.manrope(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: SentioColors.textPrimary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _getEnergyColor(_energy).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$_energy/5',
                  style: GoogleFonts.manrope(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _getEnergyColor(_energy),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _GradientSlider(
            value: _energy,
            gradientColors: const [
              Color(0xFFE05252), // red (Baja)
              Color(0xFFFFD700), // yellow (Media)
              Color(0xFF00FFBD), // green (Alta)
            ],
            onChanged: (v) => setState(() => _energy = v),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Baja', style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w500, color: SentioColors.textTertiary)),
              Text('Media', style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w500, color: SentioColors.textTertiary)),
              Text('Alta', style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w500, color: SentioColors.textTertiary)),
            ],
          ),
        ],
      ),
    );
  }

  Color _getEnergyColor(int value) {
    if (value <= 2) return const Color(0xFFE05252);
    if (value <= 3) return const Color(0xFFFFD700);
    return const Color(0xFF00FFBD);
  }

  // ============ Note Section ============
  Widget _buildNoteSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Notas',
          style: GoogleFonts.manrope(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: SentioColors.textSecondary,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: SentioColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: SentioColors.border),
          ),
          child: TextField(
            controller: _noteController,
            onChanged: (v) => _note = v,
            maxLines: 4,
            style: GoogleFonts.manrope(
              fontSize: 14,
              color: SentioColors.textPrimary,
            ),
            decoration: InputDecoration(
              hintText: 'Que tenes en mente?',
              hintStyle: GoogleFonts.manrope(
                fontSize: 14,
                color: SentioColors.textTertiary,
              ),
              filled: true,
              fillColor: Colors.transparent,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
        ),
      ],
    );
  }

  // ============ Trigger Tags ============
  Widget _buildTriggerTags() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Que provoco esto?',
          style: GoogleFonts.manrope(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: SentioColors.textSecondary,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: SentioConstants.triggerTags.map((tag) {
            final isSelected = _selectedTriggers.contains(tag);
            return GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() {
                  if (isSelected) {
                    _selectedTriggers.remove(tag);
                  } else {
                    _selectedTriggers.add(tag);
                  }
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? SentioColors.primary
                      : SentioColors.surface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isSelected
                        ? SentioColors.primary
                        : SentioColors.border,
                  ),
                  boxShadow: isSelected
                      ? SentioEffects.glow(SentioColors.primary, blur: 10, opacity: 0.3)
                      : null,
                ),
                child: Text(
                  tag,
                  style: GoogleFonts.manrope(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected
                        ? Colors.white
                        : SentioColors.textSecondary,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ============ Deep Check-in (Expandable) ============
  Widget _buildDeepCheckin() {
    return SentioCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          // Toggle header
          GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _isDeep = !_isDeep);
            },
            child: Container(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _isDeep
                          ? SentioColors.primary.withOpacity(0.15)
                          : Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.psychology_rounded,
                      color: _isDeep ? SentioColors.primary : SentioColors.textTertiary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Check-in profundo',
                          style: GoogleFonts.manrope(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: _isDeep
                                ? SentioColors.primary
                                : SentioColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Motivacion, presion financiera, control, calidad del dia',
                          style: GoogleFonts.manrope(
                            fontSize: 12,
                            color: SentioColors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: _isDeep ? 0.5 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: _isDeep ? SentioColors.primary : SentioColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Expandable content
          AnimatedCrossFade(
            firstChild: const SizedBox(width: double.infinity),
            secondChild: _buildDeepFields(),
            crossFadeState: _isDeep ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 300),
            sizeCurve: Curves.easeOutCubic,
          ),
        ],
      ),
    );
  }

  Widget _buildDeepFields() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        children: [
          Divider(color: SentioColors.border, height: 1),
          const SizedBox(height: 20),
          _DeepSlider(
            title: 'Motivacion',
            leftLabel: 'Sin ganas',
            rightLabel: 'Encendido',
            value: _motivation,
            color: SentioColors.accent,
            onChanged: (v) => setState(() => _motivation = v),
          ),
          const SizedBox(height: 20),
          _DeepSlider(
            title: 'Presion financiera',
            leftLabel: 'Estable',
            rightLabel: 'Preocupado',
            value: _financialPressure,
            color: SentioColors.warning,
            onChanged: (v) => setState(() => _financialPressure = v),
          ),
          const SizedBox(height: 20),
          _DeepSlider(
            title: 'Sensacion de control',
            leftLabel: 'Desbordado',
            rightLabel: 'En control',
            value: _control,
            color: SentioColors.primary,
            onChanged: (v) => setState(() => _control = v),
          ),
          const SizedBox(height: 20),
          _DeepSlider(
            title: 'Calidad del dia',
            leftLabel: 'Mal dia',
            rightLabel: 'Buen dia',
            value: _dayQuality,
            color: const Color(0xFF9B8EC4),
            onChanged: (v) => setState(() => _dayQuality = v),
          ),
        ],
      ),
    );
  }

  // ============ Weekly Overview ============
  Widget _buildWeeklyOverview(AppProvider provider) {
    final weeklyData = provider.weeklyEvolutionEmotional;
    final weekCheckins = provider.thisWeekCheckins;
    final dayNames = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];
    final now = DateTime.now();

    return SentioCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tu semana',
            style: GoogleFonts.manrope(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: SentioColors.textPrimary,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 120,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(7, (index) {
                final value = weeklyData[index];
                final hasData = value > 0;
                final barHeight = hasData ? (value * 80).clamp(12.0, 80.0) : 8.0;

                final dayDate = now.subtract(Duration(days: 6 - index));
                final dayCheckin = weekCheckins.where((c) =>
                  c.createdAt.year == dayDate.year &&
                  c.createdAt.month == dayDate.month &&
                  c.createdAt.day == dayDate.day
                ).firstOrNull;

                Color barColor;
                if (dayCheckin != null) {
                  final emotion = SentioConstants.emotions.firstWhere(
                    (e) => e['id'] == dayCheckin.primaryEmotion,
                    orElse: () => SentioConstants.emotions.first,
                  );
                  barColor = Color(emotion['color'] as int);
                } else {
                  barColor = SentioColors.textTertiary;
                }

                final isToday = dayDate.year == now.year &&
                    dayDate.month == now.month &&
                    dayDate.day == now.day;

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeOutCubic,
                          height: barHeight,
                          decoration: BoxDecoration(
                            gradient: hasData
                                ? LinearGradient(
                                    colors: [
                                      barColor.withOpacity(0.9),
                                      barColor.withOpacity(0.4),
                                    ],
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                  )
                                : null,
                            color: hasData ? null : Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: hasData
                                ? [
                                    BoxShadow(
                                      color: barColor.withOpacity(0.25),
                                      blurRadius: 8,
                                      spreadRadius: -2,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            color: isToday
                                ? SentioColors.primary.withOpacity(0.15)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              dayNames[index],
                              style: GoogleFonts.manrope(
                                fontSize: 11,
                                fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
                                color: isToday
                                    ? SentioColors.primary
                                    : SentioColors.textTertiary,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

// ============ Gradient Slider ============
class _GradientSlider extends StatelessWidget {
  final int value;
  final List<Color> gradientColors;
  final ValueChanged<int> onChanged;

  const _GradientSlider({
    required this.value,
    required this.gradientColors,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final trackWidth = constraints.maxWidth;
        final thumbRadius = 14.0;
        final usableWidth = trackWidth - (thumbRadius * 2);
        final thumbPosition = thumbRadius + ((value - 1) / 4.0) * usableWidth;

        return GestureDetector(
          onHorizontalDragUpdate: (details) {
            final dx = details.localPosition.dx;
            final ratio = ((dx - thumbRadius) / usableWidth).clamp(0.0, 1.0);
            final newValue = (ratio * 4).round() + 1;
            if (newValue != value) {
              HapticFeedback.selectionClick();
              onChanged(newValue);
            }
          },
          onTapDown: (details) {
            final dx = details.localPosition.dx;
            final ratio = ((dx - thumbRadius) / usableWidth).clamp(0.0, 1.0);
            final newValue = (ratio * 4).round() + 1;
            if (newValue != value) {
              HapticFeedback.selectionClick();
              onChanged(newValue);
            }
          },
          child: SizedBox(
            height: 40,
            child: Stack(
              alignment: Alignment.centerLeft,
              children: [
                // Track background
                Container(
                  height: 8,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: gradientColors),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                // Thumb
                Positioned(
                  left: thumbPosition - thumbRadius,
                  child: Container(
                    width: thumbRadius * 2,
                    height: thumbRadius * 2,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 6,
                          spreadRadius: 0,
                        ),
                        BoxShadow(
                          color: _interpolateColor(gradientColors, (value - 1) / 4.0).withOpacity(0.4),
                          blurRadius: 10,
                          spreadRadius: -1,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _interpolateColor(gradientColors, (value - 1) / 4.0),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Color _interpolateColor(List<Color> colors, double t) {
    if (colors.length == 1) return colors.first;
    if (t <= 0) return colors.first;
    if (t >= 1) return colors.last;

    final segment = t * (colors.length - 1);
    final index = segment.floor();
    final localT = segment - index;

    return Color.lerp(colors[index], colors[index + 1], localT) ?? colors.first;
  }
}

// ============ Deep Slider (compact) ============
class _DeepSlider extends StatelessWidget {
  final String title;
  final String leftLabel;
  final String rightLabel;
  final int value;
  final Color color;
  final ValueChanged<int> onChanged;

  const _DeepSlider({
    required this.title,
    required this.leftLabel,
    required this.rightLabel,
    required this.value,
    required this.color,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: GoogleFonts.manrope(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: SentioColors.textPrimary,
              ),
            ),
            Text(
              '$value/5',
              style: GoogleFonts.manrope(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(leftLabel, style: GoogleFonts.manrope(fontSize: 11, color: SentioColors.textTertiary)),
            Text(rightLabel, style: GoogleFonts.manrope(fontSize: 11, color: SentioColors.textTertiary)),
          ],
        ),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: color,
            inactiveTrackColor: color.withOpacity(0.12),
            thumbColor: color,
            overlayColor: color.withOpacity(0.1),
            trackHeight: 6,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
          ),
          child: Slider(
            value: value.toDouble(),
            min: 1,
            max: 5,
            divisions: 4,
            onChanged: (v) {
              HapticFeedback.selectionClick();
              onChanged(v.round());
            },
          ),
        ),
      ],
    );
  }
}

// ============ Mini Stat ============
class _MiniStat extends StatelessWidget {
  final String label;
  final String value;

  const _MiniStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.manrope(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: SentioColors.primary,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.manrope(
            fontSize: 12,
            color: SentioColors.textTertiary,
          ),
        ),
      ],
    );
  }
}
