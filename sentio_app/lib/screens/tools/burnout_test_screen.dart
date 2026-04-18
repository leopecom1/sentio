import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:sentio_app/config/theme.dart';
import 'package:sentio_app/providers/app_provider.dart';

class BurnoutTestScreen extends StatefulWidget {
  const BurnoutTestScreen({super.key});

  @override
  State<BurnoutTestScreen> createState() => _BurnoutTestScreenState();
}

class _BurnoutTestScreenState extends State<BurnoutTestScreen>
    with TickerProviderStateMixin {
  bool _started = false;
  bool _completed = false;
  int _currentQuestion = 0;
  final Map<int, int> _answers = {}; // question index -> score 0-4

  late AnimationController _bgController;
  late AnimationController _entryController;
  late Animation<double> _entryFade;
  late Animation<Offset> _entrySlide;

  // Questions (adapted from Maslach Burnout Inventory + scientific literature)
  static const List<Map<String, dynamic>> _questions = [
    {
      'text': 'Me siento emocionalmente agotado/a por mi trabajo',
      'dimension': 'exhaustion',
    },
    {
      'text': 'Me siento cansado/a cuando me levanto y tengo que enfrentar otro día',
      'dimension': 'exhaustion',
    },
    {
      'text': 'Trabajar todo el día con personas o problemas es realmente agotador',
      'dimension': 'exhaustion',
    },
    {
      'text': 'Me siento frustrado/a en mi trabajo',
      'dimension': 'exhaustion',
    },
    {
      'text': 'Siento que estoy trabajando demasiado',
      'dimension': 'exhaustion',
    },
    {
      'text': 'Me he vuelto más insensible con la gente desde que ejerzo este trabajo',
      'dimension': 'cynicism',
    },
    {
      'text': 'Me preocupa que este trabajo me esté endureciendo emocionalmente',
      'dimension': 'cynicism',
    },
    {
      'text': 'Realmente no me importa lo que les ocurra a las personas con las que trabajo',
      'dimension': 'cynicism',
    },
    {
      'text': 'Siento que las personas me culpan por sus problemas',
      'dimension': 'cynicism',
    },
    {
      'text': 'Puedo entender fácilmente lo que las personas a mi alrededor sienten',
      'dimension': 'efficacy',
      'reverse': true,
    },
    {
      'text': 'Trato muy eficazmente los problemas de las personas con las que trabajo',
      'dimension': 'efficacy',
      'reverse': true,
    },
    {
      'text': 'Siento que estoy influyendo positivamente en la vida de otras personas a través de mi trabajo',
      'dimension': 'efficacy',
      'reverse': true,
    },
    {
      'text': 'Me siento con mucha vitalidad',
      'dimension': 'efficacy',
      'reverse': true,
    },
    {
      'text': 'Me siento estimulado/a después de trabajar con la gente',
      'dimension': 'efficacy',
      'reverse': true,
    },
    {
      'text': 'En mi trabajo trato los problemas emocionales con mucha calma',
      'dimension': 'efficacy',
      'reverse': true,
    },
  ];

  static const List<Map<String, dynamic>> _options = [
    {'label': 'Nunca', 'value': 0, 'color': 0xFF4CAF50},
    {'label': 'Pocas veces al año', 'value': 1, 'color': 0xFF8BC34A},
    {'label': 'Una vez al mes', 'value': 2, 'color': 0xFFFFC107},
    {'label': 'Varias veces al mes', 'value': 3, 'color': 0xFFFF9800},
    {'label': 'Una vez por semana', 'value': 4, 'color': 0xFFFF5722},
    {'label': 'Varias veces por semana', 'value': 5, 'color': 0xFFE53935},
    {'label': 'Todos los días', 'value': 6, 'color': 0xFFB71C1C},
  ];

  static const Color _accentColor = Color(0xFFFF6B9D);

  @override
  void initState() {
    super.initState();
    _bgController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    )..repeat(reverse: true);
    _entryController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _entryFade = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _entryController, curve: Curves.easeOut),
    );
    _entrySlide = Tween(begin: const Offset(0, 0.1), end: Offset.zero).animate(
      CurvedAnimation(parent: _entryController, curve: Curves.easeOutCubic),
    );
    _entryController.forward();
  }

  @override
  void dispose() {
    _bgController.dispose();
    _entryController.dispose();
    super.dispose();
  }

  void _start() {
    HapticFeedback.lightImpact();
    setState(() => _started = true);
    _entryController.reset();
    _entryController.forward();
  }

  void _selectAnswer(int score) {
    HapticFeedback.selectionClick();
    setState(() => _answers[_currentQuestion] = score);
    Future.delayed(const Duration(milliseconds: 250), () {
      if (!mounted) return;
      if (_currentQuestion < _questions.length - 1) {
        setState(() => _currentQuestion++);
        _entryController.reset();
        _entryController.forward();
      } else {
        _complete();
      }
    });
  }

  void _previousQuestion() {
    if (_currentQuestion > 0) {
      HapticFeedback.lightImpact();
      setState(() => _currentQuestion--);
      _entryController.reset();
      _entryController.forward();
    }
  }

  void _complete() {
    HapticFeedback.heavyImpact();
    setState(() => _completed = true);
    _entryController.reset();
    _entryController.forward();

    final provider = context.read<AppProvider>();

    // Save tool usage (XP, stats)
    provider.saveToolUsage(
      toolId: 'burnout_test',
      toolCategory: 'assessment',
      durationSeconds: 300,
      completed: true,
    );

    // Save test result for admin tracking
    final severityLabels = ['none', 'low', 'moderate', 'high'];
    provider.saveTestResult(
      testType: 'burnout',
      severity: severityLabels[_severity],
      severityScore: _severity,
      scores: _scores,
      answers: List.generate(_questions.length, (i) => {
        'question': _questions[i]['text'],
        'dimension': _questions[i]['dimension'],
        'answer_value': _answers[i],
      }),
    );
  }

  // ── Scoring ──

  Map<String, int> get _scores {
    int exhaustion = 0;
    int cynicism = 0;
    int efficacy = 0;
    for (int i = 0; i < _questions.length; i++) {
      final q = _questions[i];
      final raw = _answers[i] ?? 0;
      // Reverse: high efficacy answers reduce burnout, so we don't reverse here
      // We just sum: efficacy is positive (high = good), exhaustion/cynicism are negative (high = bad)
      if (q['dimension'] == 'exhaustion') exhaustion += raw;
      if (q['dimension'] == 'cynicism') cynicism += raw;
      if (q['dimension'] == 'efficacy') efficacy += raw;
    }
    return {'exhaustion': exhaustion, 'cynicism': cynicism, 'efficacy': efficacy};
  }

  /// Burnout severity: 0 (none) to 3 (high)
  int get _severity {
    final s = _scores;
    // Exhaustion: 0-30, Cynicism: 0-24, Efficacy: 0-36 (lower = worse)
    final exhaustionHigh = s['exhaustion']! >= 18;
    final cynicismHigh = s['cynicism']! >= 12;
    final efficacyLow = s['efficacy']! < 18;
    final flags = [exhaustionHigh, cynicismHigh, efficacyLow].where((f) => f).length;
    if (flags == 0) return 0;
    if (flags == 1) return 1;
    if (flags == 2) return 2;
    return 3;
  }

  Map<String, dynamic> get _severityData {
    switch (_severity) {
      case 0:
        return {
          'label': 'Sin signos de burnout',
          'description': 'Tu bienestar laboral está en buen estado. Seguí cuidándote.',
          'color': const Color(0xFF4CAF50),
          'icon': Icons.check_circle_rounded,
        };
      case 1:
        return {
          'label': 'Riesgo bajo',
          'description': 'Hay señales tempranas. Es buen momento para reforzar pausas y autocuidado.',
          'color': const Color(0xFFFFD93D),
          'icon': Icons.info_rounded,
        };
      case 2:
        return {
          'label': 'Riesgo moderado',
          'description': 'Estás mostrando signos claros de agotamiento. Necesitás priorizar tu salud mental.',
          'color': const Color(0xFFFF9800),
          'icon': Icons.warning_amber_rounded,
        };
      default:
        return {
          'label': 'Riesgo alto',
          'description': 'Tu nivel de agotamiento es significativo. Considerá buscar apoyo profesional.',
          'color': const Color(0xFFE53935),
          'icon': Icons.warning_rounded,
        };
    }
  }

  // ── Build ──

  @override
  Widget build(BuildContext context) {
    if (_completed) return _buildResultsView();
    if (_started) return _buildQuestionView();
    return _buildIntroView();
  }

  Widget _animatedBackground() {
    return AnimatedBuilder(
      animation: _bgController,
      builder: (context, _) {
        final t = _bgController.value;
        return Stack(
          children: [
            Positioned(
              right: -100 + t * 60,
              top: -50 + t * 40,
              child: Container(
                width: 320, height: 320,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [
                    _accentColor.withValues(alpha: 0.12 + t * 0.06),
                    _accentColor.withValues(alpha: 0.0),
                  ]),
                ),
              ),
            ),
            Positioned(
              left: -80 + t * 30,
              bottom: 100 + t * 50,
              child: Container(
                width: 250, height: 250,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [
                    SentioColors.primary.withValues(alpha: 0.08 + t * 0.04),
                    SentioColors.primary.withValues(alpha: 0.0),
                  ]),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ══════════════════════════════════════
  // INTRO VIEW
  // ══════════════════════════════════════

  Widget _buildIntroView() {
    return Scaffold(
      backgroundColor: SentioColors.background,
      body: Stack(
        children: [
          _animatedBackground(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => context.pop(),
                        child: Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: SentioColors.border),
                          ),
                          child: const Icon(Icons.arrow_back_rounded, color: SentioColors.textPrimary, size: 20),
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _accentColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: _accentColor.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.timer_outlined, size: 13, color: _accentColor),
                            const SizedBox(width: 5),
                            Text('5 min',
                              style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w700, color: _accentColor)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Expanded(
                    child: SlideTransition(
                      position: _entrySlide,
                      child: FadeTransition(
                        opacity: _entryFade,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 140, height: 140,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(colors: [
                                  _accentColor.withValues(alpha: 0.25),
                                  _accentColor.withValues(alpha: 0.08),
                                  Colors.transparent,
                                ]),
                                boxShadow: [BoxShadow(color: _accentColor.withValues(alpha: 0.3), blurRadius: 40, spreadRadius: 6)],
                              ),
                              child: Center(
                                child: Container(
                                  width: 80, height: 80,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: LinearGradient(colors: [
                                      _accentColor.withValues(alpha: 0.3),
                                      _accentColor.withValues(alpha: 0.1),
                                    ], begin: Alignment.topLeft, end: Alignment.bottomRight),
                                    border: Border.all(color: _accentColor.withValues(alpha: 0.4), width: 1.5),
                                  ),
                                  child: const Icon(Icons.psychology_rounded, color: _accentColor, size: 38),
                                ),
                              ),
                            ),
                            const SizedBox(height: 32),
                            Text('Test de Burnout',
                              style: GoogleFonts.manrope(
                                fontSize: 30, fontWeight: FontWeight.w800,
                                color: SentioColors.textPrimary, letterSpacing: -1, height: 1.1,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 12),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                'Una evaluación rápida basada en el inventario MBI para identificar señales de agotamiento profesional.',
                                style: GoogleFonts.manrope(
                                  fontSize: 14, color: SentioColors.textSecondary, height: 1.5,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: SentioColors.surface,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: SentioColors.border),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.lock_outline_rounded, size: 18, color: SentioColors.textSecondary),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      'Tus respuestas son privadas. Solo se guarda el resultado para tu seguimiento.',
                                      style: GoogleFonts.manrope(fontSize: 12, color: SentioColors.textSecondary, height: 1.4),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  _SpringTap(
                    onTap: _start,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [
                          _accentColor, _accentColor.withValues(alpha: 0.7),
                        ], begin: Alignment.topLeft, end: Alignment.bottomRight),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [BoxShadow(color: _accentColor.withValues(alpha: 0.3), blurRadius: 20, spreadRadius: -2, offset: const Offset(0, 6))],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 24),
                          const SizedBox(width: 6),
                          Text('Empezar test',
                            style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════
  // QUESTION VIEW
  // ══════════════════════════════════════

  Widget _buildQuestionView() {
    final q = _questions[_currentQuestion];
    final progress = (_currentQuestion + 1) / _questions.length;

    return Scaffold(
      backgroundColor: SentioColors.background,
      body: Stack(
        children: [
          _animatedBackground(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: _currentQuestion > 0
                            ? _previousQuestion
                            : () => context.pop(),
                        child: Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: SentioColors.border),
                          ),
                          child: Icon(
                            _currentQuestion > 0 ? Icons.arrow_back_rounded : Icons.close_rounded,
                            color: SentioColors.textPrimary, size: 20,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${_currentQuestion + 1} / ${_questions.length}',
                        style: GoogleFonts.manrope(
                          fontSize: 13, fontWeight: FontWeight.w700, color: SentioColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Progress bar
                  Container(
                    height: 6,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.0, end: progress),
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeOut,
                        builder: (_, value, __) => LinearProgressIndicator(
                          value: value,
                          backgroundColor: Colors.transparent,
                          valueColor: const AlwaysStoppedAnimation(_accentColor),
                          minHeight: 6,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Expanded(
                    child: SlideTransition(
                      position: _entrySlide,
                      child: FadeTransition(
                        opacity: _entryFade,
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text('¿Con qué frecuencia?',
                                style: GoogleFonts.manrope(
                                  fontSize: 13, fontWeight: FontWeight.w600,
                                  color: SentioColors.textTertiary, letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                q['text'],
                                style: GoogleFonts.manrope(
                                  fontSize: 22, fontWeight: FontWeight.w700,
                                  color: SentioColors.textPrimary, height: 1.4, letterSpacing: -0.3,
                                ),
                              ),
                              const SizedBox(height: 28),
                              // Options
                              ..._options.map((opt) {
                                final isSelected = _answers[_currentQuestion] == opt['value'];
                                final color = Color(opt['color'] as int);
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: _SpringTap(
                                    onTap: () => _selectAnswer(opt['value'] as int),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? color.withValues(alpha: 0.12)
                                            : SentioColors.surface,
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(
                                          color: isSelected ? color : SentioColors.border,
                                          width: isSelected ? 1.5 : 1,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 28, height: 28,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: isSelected ? color : Colors.white.withValues(alpha: 0.05),
                                              border: Border.all(
                                                color: isSelected ? color : SentioColors.border,
                                              ),
                                            ),
                                            child: isSelected
                                                ? const Icon(Icons.check_rounded, color: Colors.white, size: 16)
                                                : null,
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              opt['label'] as String,
                                              style: GoogleFonts.manrope(
                                                fontSize: 14,
                                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                                color: isSelected ? color : SentioColors.textPrimary,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════
  // RESULTS VIEW
  // ══════════════════════════════════════

  Widget _buildResultsView() {
    final data = _severityData;
    final color = data['color'] as Color;
    final scores = _scores;

    return Scaffold(
      backgroundColor: SentioColors.background,
      body: Stack(
        children: [
          _animatedBackground(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: SlideTransition(
                position: _entrySlide,
                child: FadeTransition(
                  opacity: _entryFade,
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () => context.pop(),
                              child: Container(
                                width: 40, height: 40,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.05),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: SentioColors.border),
                                ),
                                child: const Icon(Icons.close_rounded, color: SentioColors.textPrimary, size: 20),
                              ),
                            ),
                            const Spacer(),
                          ],
                        ),
                        const SizedBox(height: 32),
                        Center(
                          child: Container(
                            width: 130, height: 130,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(colors: [
                                color.withValues(alpha: 0.3),
                                color.withValues(alpha: 0.08),
                                Colors.transparent,
                              ]),
                              boxShadow: [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 40, spreadRadius: 8)],
                            ),
                            child: Center(
                              child: Container(
                                width: 76, height: 76,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(colors: [
                                    color, color.withValues(alpha: 0.7),
                                  ], begin: Alignment.topLeft, end: Alignment.bottomRight),
                                ),
                                child: Icon(data['icon'] as IconData, color: Colors.white, size: 38),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),
                        Text(
                          data['label'] as String,
                          style: GoogleFonts.manrope(
                            fontSize: 28, fontWeight: FontWeight.w800,
                            color: SentioColors.textPrimary, letterSpacing: -0.8,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            data['description'] as String,
                            style: GoogleFonts.manrope(
                              fontSize: 14, color: SentioColors.textSecondary, height: 1.6,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 32),
                        // Dimension scores
                        _buildDimension(
                          'Agotamiento emocional',
                          scores['exhaustion']!,
                          30,
                          'Cómo te sentís emocionalmente con tu trabajo',
                          const Color(0xFFE53935),
                          inverse: false,
                        ),
                        const SizedBox(height: 12),
                        _buildDimension(
                          'Despersonalización',
                          scores['cynicism']!,
                          24,
                          'Tu actitud hacia las personas con las que trabajás',
                          const Color(0xFFFF9800),
                          inverse: false,
                        ),
                        const SizedBox(height: 12),
                        _buildDimension(
                          'Realización personal',
                          scores['efficacy']!,
                          36,
                          'Tu sentido de logro y eficacia profesional',
                          const Color(0xFF4CAF50),
                          inverse: true,
                        ),
                        const SizedBox(height: 24),
                        // Recommendations
                        if (_severity > 0) ...[
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [SentioColors.surface, color.withValues(alpha: 0.04)],
                                begin: Alignment.topLeft, end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: color.withValues(alpha: 0.2)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.lightbulb_rounded, size: 18, color: color),
                                    const SizedBox(width: 8),
                                    Text('Recomendaciones',
                                      style: GoogleFonts.manrope(
                                        fontSize: 14, fontWeight: FontWeight.w700, color: color,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                ..._recommendations.map((r) => Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        margin: const EdgeInsets.only(top: 6),
                                        width: 5, height: 5,
                                        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(r,
                                          style: GoogleFonts.manrope(
                                            fontSize: 13, color: SentioColors.textPrimary, height: 1.5,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                )),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                        _SpringTap(
                          onTap: () => context.pop(),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(colors: [
                                _accentColor, _accentColor.withValues(alpha: 0.7),
                              ], begin: Alignment.topLeft, end: Alignment.bottomRight),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [BoxShadow(color: _accentColor.withValues(alpha: 0.3), blurRadius: 16, spreadRadius: -2, offset: const Offset(0, 4))],
                            ),
                            child: Center(
                              child: Text('Volver',
                                style: GoogleFonts.manrope(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDimension(String name, int score, int max, String hint, Color color, {required bool inverse}) {
    final fraction = score / max;
    // For "efficacy" (inverse), high is good; for others, low is good
    final isHealthy = inverse ? fraction >= 0.5 : fraction < 0.5;
    final displayColor = isHealthy ? const Color(0xFF4CAF50) : color;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: SentioColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: SentioColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(name,
                  style: GoogleFonts.manrope(
                    fontSize: 13, fontWeight: FontWeight.w700, color: SentioColors.textPrimary,
                  ),
                ),
              ),
              Text('$score / $max',
                style: GoogleFonts.manrope(
                  fontSize: 12, fontWeight: FontWeight.w800, color: displayColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: fraction),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOutCubic,
              builder: (_, value, __) => LinearProgressIndicator(
                value: value,
                backgroundColor: Colors.white.withValues(alpha: 0.05),
                valueColor: AlwaysStoppedAnimation(displayColor),
                minHeight: 6,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(hint,
            style: GoogleFonts.manrope(fontSize: 11, color: SentioColors.textTertiary, height: 1.3),
          ),
        ],
      ),
    );
  }

  List<String> get _recommendations {
    final s = _scores;
    final list = <String>[];
    if (s['exhaustion']! >= 18) {
      list.add('Programá pausas regulares durante el día — usá la herramienta de respiración 4-7-8');
      list.add('Establecé un horario fijo para desconectarte del trabajo');
    }
    if (s['cynicism']! >= 12) {
      list.add('Reconectá con el "por qué" de lo que hacés — escribí en el diario sobre tus motivaciones');
      list.add('Buscá una conversación significativa con alguien de tu equipo');
    }
    if (s['efficacy']! < 18) {
      list.add('Anotá 3 cosas que lograste esta semana, por más pequeñas que sean');
      list.add('Considerá hablar con un profesional de salud mental');
    }
    if (_severity >= 3) {
      list.add('Si estás en crisis, usá el botón rojo (corazón) para acceder a líneas de ayuda');
    }
    return list;
  }
}

// ══════════════════════════════════════
// SPRING TAP
// ══════════════════════════════════════

class _SpringTap extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  const _SpringTap({required this.child, required this.onTap});

  @override
  State<_SpringTap> createState() => _SpringTapState();
}

class _SpringTapState extends State<_SpringTap> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 150));
    _scale = Tween(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) { _ctrl.reverse(); widget.onTap(); },
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(scale: _scale, child: widget.child),
    );
  }
}
