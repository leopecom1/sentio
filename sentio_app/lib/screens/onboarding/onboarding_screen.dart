import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:sentio_app/config/theme.dart';
import 'package:sentio_app/config/constants.dart';
import 'package:sentio_app/providers/app_provider.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  int _currentPage = 0;

  // Onboarding data
  final List<String> _selectedPressures = [];
  String _selectedMood = '';
  int _energy = 3;
  final List<String> _selectedGoals = [];

  void _nextPage() {
    if (_currentPage < 4) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
    }
  }

  bool _completing = false;

  Future<void> _complete() async {
    if (_completing) return;
    final provider = context.read<AppProvider>();

    // Not authenticated yet: cache selections locally and go to auth
    if (!provider.isAuthenticated) {
      await provider.markWizardSeen(
        pressureTypes: _selectedPressures,
        currentMood: _selectedMood.isEmpty ? 'calm' : _selectedMood,
        energy: _energy,
        goals: _selectedGoals,
      );
      if (!mounted) return;
      context.go('/auth');
      return;
    }

    setState(() => _completing = true);
    try {
      await provider.completeOnboarding(
        pressureTypes: _selectedPressures,
        currentMood: _selectedMood.isEmpty ? 'calm' : _selectedMood,
        energy: _energy,
        goals: _selectedGoals,
      );
      if (!mounted) return;
      context.go('/');
    } catch (e) {
      if (!mounted) return;
      setState(() => _completing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo completar: $e'),
          backgroundColor: SentioColors.error,
        ),
      );
    }
  }

  Future<void> _skipToAuth() async {
    final provider = context.read<AppProvider>();
    await provider.markWizardSeen();
    if (!mounted) return;
    context.go('/auth?mode=login');
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SentioColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Progress indicator
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                children: [
                  if (_currentPage > 0)
                    GestureDetector(
                      onTap: _previousPage,
                      child: const Icon(
                        Icons.arrow_back_rounded,
                        color: SentioColors.textSecondary,
                      ),
                    ),
                  if (_currentPage > 0) const SizedBox(width: 16),
                  Expanded(
                    child: Row(
                      children: List.generate(5, (index) {
                        return Expanded(
                          child: Container(
                            height: 3,
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            decoration: BoxDecoration(
                              color: index <= _currentPage
                                  ? SentioColors.primary
                                  : SentioColors.divider,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ],
              ),
            ),
            // Pages
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (page) => setState(() => _currentPage = page),
                children: [
                  _buildWelcomePage(),
                  _buildPressurePage(),
                  _buildMoodPage(),
                  _buildGoalsPage(),
                  _buildCommitmentPage(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============ PAGE 1: Welcome ============
  Widget _buildWelcomePage() {
    // Si el usuario ya está autenticado (p. ej. recién creó la cuenta), el
    // wizard solo sirve para completar su perfil: los botones de cuenta no
    // aplican y, de hecho, generan un loop ("Ya tengo cuenta" → login →
    // vuelve al wizard porque onboarding_completed sigue en false).
    final isAuthenticated = context.watch<AppProvider>().isAuthenticated;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(flex: 2),
          // Abstract illustration placeholder
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  SentioColors.primary.withValues(alpha: 0.15),
                  SentioColors.accent.withValues(alpha: 0.08),
                  SentioColors.secondary.withValues(alpha: 0.05),
                ],
              ),
            ),
            child: Center(
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: SentioColors.primary.withValues(alpha: 0.1),
                ),
                child: const Icon(
                  Icons.spa_rounded,
                  size: 40,
                  color: SentioColors.primary,
                ),
              ),
            ),
          ),
          const SizedBox(height: 48),
          Text(
            'Emprender es increíble.\nPero a veces pesa.',
            style: GoogleFonts.manrope(
              fontSize: 28,
              height: 1.3,
              color: SentioColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'B2Better es tu espacio para bajar la guardia,\nentenderte y avanzar con más claridad.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: SentioColors.textSecondary,
                  height: 1.5,
                ),
            textAlign: TextAlign.center,
          ),
          const Spacer(flex: 3),
          ElevatedButton(
            onPressed: _nextPage,
            child: const Text('Empezar'),
          ),
          if (!isAuthenticated) ...[
            const SizedBox(height: 16),
            TextButton(
              onPressed: _skipToAuth,
              child: const Text(
                'Ya tengo cuenta',
                style: TextStyle(color: SentioColors.textSecondary),
              ),
            ),
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ============ PAGE 2: Pressure Types ============
  Widget _buildPressurePage() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 32),
          Text(
            '¿Qué es lo que\nmás te pesa hoy?',
            style: GoogleFonts.manrope(
              fontSize: 28,
              height: 1.3,
              color: SentioColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Elegí todas las que apliquen. No hay respuestas incorrectas.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: SentioColors.textSecondary,
                ),
          ),
          const SizedBox(height: 32),
          Expanded(
            child: SingleChildScrollView(
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                children: SentioConstants.pressureTypes.map((pressure) {
                  final isSelected = _selectedPressures.contains(pressure['id']);
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          _selectedPressures.remove(pressure['id']);
                        } else {
                          _selectedPressures.add(pressure['id']!);
                        }
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? SentioColors.primary
                            : SentioColors.card,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: isSelected
                              ? SentioColors.primary
                              : Colors.transparent,
                        ),
                      ),
                      child: Text(
                        pressure['label']!,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: isSelected
                              ? Colors.white
                              : SentioColors.textPrimary,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _selectedPressures.isNotEmpty ? _nextPage : null,
            child: const Text('Continuar'),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ============ PAGE 3: Current Mood ============
  Widget _buildMoodPage() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 32),
          Text(
            'Y en este momento,\n¿cómo estás?',
            style: GoogleFonts.manrope(
              fontSize: 28,
              height: 1.3,
              color: SentioColors.textPrimary,
            ),
          ),
          const SizedBox(height: 32),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Emotion grid
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      childAspectRatio: 1.0,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: SentioConstants.emotions.length,
                    itemBuilder: (context, index) {
                      final emotion = SentioConstants.emotions[index];
                      final isSelected = _selectedMood == emotion['id'];
                      return GestureDetector(
                        onTap: () => setState(() => _selectedMood = emotion['id']),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Color(emotion['color'] as int).withValues(alpha: 0.15)
                                : SentioColors.card,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected
                                  ? Color(emotion['color'] as int)
                                  : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                SentioConstants.getEmotionIcon(emotion['id'] as String),
                                size: 32,
                                color: isSelected
                                    ? Color(emotion['color'] as int)
                                    : SentioColors.textSecondary,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                emotion['label'],
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                  color: isSelected
                                      ? Color(emotion['color'] as int)
                                      : SentioColors.textSecondary,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 32),
                  // Energy slider
                  Text(
                    'Nivel de energía',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Agotado',
                        style: TextStyle(
                          fontSize: 13,
                          color: SentioColors.textTertiary,
                        ),
                      ),
                      Text(
                        'Recargado',
                        style: TextStyle(
                          fontSize: 13,
                          color: SentioColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                  SliderTheme(
                    data: SliderThemeData(
                      activeTrackColor: SentioColors.primary,
                      inactiveTrackColor: SentioColors.divider,
                      thumbColor: SentioColors.primary,
                      overlayColor: SentioColors.primary.withValues(alpha: 0.1),
                      trackHeight: 4,
                    ),
                    child: Slider(
                      value: _energy.toDouble(),
                      min: 1,
                      max: 5,
                      divisions: 4,
                      onChanged: (v) => setState(() => _energy = v.round()),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _selectedMood.isNotEmpty ? _nextPage : null,
            child: const Text('Continuar'),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ============ PAGE 4: Goals ============
  Widget _buildGoalsPage() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 32),
          Text(
            '¿Qué te gustaría\nencontrar acá?',
            style: GoogleFonts.manrope(
              fontSize: 28,
              height: 1.3,
              color: SentioColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Elegí lo que más te resuene.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: SentioColors.textSecondary,
                ),
          ),
          const SizedBox(height: 32),
          Expanded(
            child: ListView.separated(
              itemCount: SentioConstants.goals.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final goal = SentioConstants.goals[index];
                final isSelected = _selectedGoals.contains(goal['id']);
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        _selectedGoals.remove(goal['id']);
                      } else {
                        _selectedGoals.add(goal['id']!);
                      }
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? SentioColors.primary.withValues(alpha: 0.08)
                          : SentioColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? SentioColors.primary
                            : SentioColors.divider,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            goal['label']!,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              color: isSelected
                                  ? SentioColors.primary
                                  : SentioColors.textPrimary,
                            ),
                          ),
                        ),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSelected
                                ? SentioColors.primary
                                : Colors.transparent,
                            border: Border.all(
                              color: isSelected
                                  ? SentioColors.primary
                                  : SentioColors.textTertiary,
                              width: 2,
                            ),
                          ),
                          child: isSelected
                              ? const Icon(
                                  Icons.check_rounded,
                                  size: 16,
                                  color: Colors.white,
                                )
                              : null,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _selectedGoals.isNotEmpty ? _nextPage : null,
            child: const Text('Continuar'),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ============ PAGE 5: Commitment ============
  Widget _buildCommitmentPage() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(flex: 2),
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: SentioColors.accent.withValues(alpha: 0.15),
            ),
            child: const Icon(
              Icons.favorite_rounded,
              size: 48,
              color: SentioColors.accent,
            ),
          ),
          const SizedBox(height: 40),
          Text(
            'No tenés que estar bien\ntodo el tiempo.',
            style: GoogleFonts.manrope(
              fontSize: 28,
              height: 1.3,
              color: SentioColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'Solo tenés que empezar.',
            style: GoogleFonts.manrope(
              fontSize: 24,
              color: SentioColors.secondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Text(
            'Vamos a construir este espacio juntos,\na tu ritmo.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: SentioColors.textSecondary,
                  height: 1.5,
                ),
            textAlign: TextAlign.center,
          ),
          const Spacer(flex: 3),
          ElevatedButton(
            onPressed: _completing ? null : _complete,
            child: _completing
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Empezar'),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
