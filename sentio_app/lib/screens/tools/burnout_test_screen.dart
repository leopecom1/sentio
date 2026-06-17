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
  final Map<int, int> _answers = {}; // question index -> score 0-6

  late AnimationController _bgController;
  late AnimationController _entryController;
  late Animation<double> _entryFade;
  late Animation<Offset> _entrySlide;

  // Test de Burnout MBI (Maslach Burnout Inventory) adaptado a founders.
  // 22 ítems en 3 dimensiones: Agotamiento Emocional (ae, 9), Despersonalización
  // (dp, 5) y Realización Personal (rp, 8, dimensión positiva = invertida).
  static const List<Map<String, dynamic>> _questions = [
    // ── AGOTAMIENTO EMOCIONAL (ae) ──
    {'text': 'Me siento emocionalmente agotado/a por gestionar mi negocio.', 'dimension': 'ae'},
    {'text': 'Me siento vacío/a al final de la jornada de trabajo.', 'dimension': 'ae'},
    {'text': 'Me levanto cansado/a y con desgana de enfrentarme a otro día de emprendedor/a.', 'dimension': 'ae'},
    {'text': 'Trabajar en mi negocio durante todo el día me exige un esfuerzo enorme.', 'dimension': 'ae'},
    {'text': 'Siento que me estoy quemando en este proceso.', 'dimension': 'ae'},
    {'text': 'Me siento frustrado/a con mi trabajo o negocio.', 'dimension': 'ae'},
    {'text': 'Creo que estoy trabajando demasiado para lo que recibo a cambio.', 'dimension': 'ae'},
    {'text': 'Lidiar con clientes, equipo o socios me genera un estrés agotador.', 'dimension': 'ae'},
    {'text': 'Siento que ya llegué al límite de mis fuerzas.', 'dimension': 'ae'},

    // ── DESPERSONALIZACIÓN (dp) ──
    {'text': 'Trato a algunos clientes o colaboradores de forma fría o distante, como si no me importaran.', 'dimension': 'dp'},
    {'text': 'Me volví más insensible con las personas que me rodean desde que empecé a emprender.', 'dimension': 'dp'},
    {'text': 'Me preocupa que este trabajo me esté endureciendo emocionalmente.', 'dimension': 'dp'},
    {'text': 'Realmente no me importa demasiado lo que le pase a ciertos clientes o miembros de mi equipo.', 'dimension': 'dp'},
    {'text': 'Siento que mi entorno (clientes, equipo, familia) me responsabiliza de sus problemas.', 'dimension': 'dp'},

    // ── REALIZACIÓN PERSONAL (rp) — dimensión positiva ──
    {'text': 'Entiendo con facilidad cómo se sienten mis clientes o equipo.', 'dimension': 'rp'},
    {'text': 'Resuelvo los problemas de mi negocio de forma efectiva.', 'dimension': 'rp'},
    {'text': 'Siento que mi trabajo tiene un impacto positivo en la vida de otras personas.', 'dimension': 'rp'},
    {'text': 'Me siento con energía y vitalidad en mi rol de emprendedor/a.', 'dimension': 'rp'},
    {'text': 'Me siento motivado/a después de interactuar con mis clientes.', 'dimension': 'rp'},
    {'text': 'Creo que estoy logrando cosas valiosas con este trabajo.', 'dimension': 'rp'},
    {'text': 'Manejo los desafíos emocionales de emprender con calma y claridad.', 'dimension': 'rp'},
    {'text': 'Al terminar mi jornada, me siento satisfecho/a con lo que hice.', 'dimension': 'rp'},
  ];

  // Escala de frecuencia MBI (0–6).
  static const List<Map<String, dynamic>> _options = [
    {'label': 'Nunca', 'value': 0, 'color': 0xFF4CAF50},
    {'label': 'Pocas veces al año', 'value': 1, 'color': 0xFF8BC34A},
    {'label': 'Una vez al mes', 'value': 2, 'color': 0xFFFFC107},
    {'label': 'Algunas veces al mes', 'value': 3, 'color': 0xFFFF9800},
    {'label': 'Una vez a la semana', 'value': 4, 'color': 0xFFFF5722},
    {'label': 'Varias veces a la semana', 'value': 5, 'color': 0xFFE53935},
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

  // ── Scoring (cutoffs MBI estándar) ──
  // Máximos: AE 54 (9×6), DP 30 (5×6), RP 48 (8×6, dimensión positiva).

  Map<String, int> get _scores {
    int ae = 0, dp = 0, rp = 0;
    for (int i = 0; i < _questions.length; i++) {
      final dim = _questions[i]['dimension'];
      final raw = _answers[i] ?? 0;
      if (dim == 'ae') {
        ae += raw;
      } else if (dim == 'dp') {
        dp += raw;
      } else if (dim == 'rp') {
        rp += raw;
      }
    }
    return {'ae': ae, 'dp': dp, 'rp': rp};
  }

  /// Nivel por dimensión: 'low' | 'medium' | 'high'.
  String get _aeLevel {
    final v = _scores['ae']!;
    return v >= 27 ? 'high' : (v >= 19 ? 'medium' : 'low');
  }

  String get _dpLevel {
    final v = _scores['dp']!;
    return v >= 10 ? 'high' : (v >= 6 ? 'medium' : 'low');
  }

  /// RP es positiva: alto = bueno. Por eso bajo = peor (invertida).
  String get _rpLevel {
    final v = _scores['rp']!;
    return v <= 33 ? 'low' : (v <= 39 ? 'medium' : 'high');
  }

  /// Nº de indicadores de burnout activos (0–3): AE alto + DP alto + RP bajo.
  int get _severity {
    int flags = 0;
    if (_aeLevel == 'high') flags++;
    if (_dpLevel == 'high') flags++;
    if (_rpLevel == 'low') flags++;
    return flags;
  }

  /// Riesgo global a mostrar: 'low' (0) · 'medium' (1–2) · 'high' (3).
  String get _risk => _severity == 3 ? 'high' : (_severity >= 1 ? 'medium' : 'low');

  Map<String, dynamic> get _severityData {
    switch (_risk) {
      case 'high':
        return {
          'label': 'Riesgo alto de burnout',
          'description': 'Tus niveles indican un agotamiento significativo. Esto no es normal ni necesario: tu bienestar es parte de la estrategia. Te recomendamos buscar apoyo de un profesional de salud mental.',
          'color': const Color(0xFFE53935),
          'icon': Icons.warning_rounded,
        };
      case 'medium':
        return {
          'label': 'Señales de alerta',
          'description': 'Hay señales que merecen atención. Estás en una zona de alerta donde el autocuidado puede marcar la diferencia antes de que escale.',
          'color': const Color(0xFFFF9800),
          'icon': Icons.warning_amber_rounded,
        };
      default:
        return {
          'label': 'Sin burnout significativo',
          'description': 'Tus niveles son saludables. Eso no es casualidad: es el resultado de cómo estás manejando tu energía. Seguí cuidándote.',
          'color': const Color(0xFF4CAF50),
          'icon': Icons.check_circle_rounded,
        };
    }
  }

  /// Datos de cada dimensión para la vista de resultados (3 niveles MBI).
  List<Map<String, dynamic>> get _dimensionResults {
    final s = _scores;
    return [
      {
        'name': 'Agotamiento emocional',
        'score': s['ae']!,
        'max': 54,
        'level': _aeLevel,
        'inverse': false,
        'descs': {
          'high': 'Nivel alto. Te sentís emocionalmente drenado/a. Es la señal más importante del burnout.',
          'medium': 'Nivel moderado. El cansancio está presente pero todavía manejable.',
          'low': 'Nivel bajo. Tu energía emocional está bien sostenida.',
        },
      },
      {
        'name': 'Despersonalización',
        'score': s['dp']!,
        'max': 30,
        'level': _dpLevel,
        'inverse': false,
        'descs': {
          'high': 'Nivel alto. Estás desarrollando una distancia emocional con tu entorno. Es señal de agotamiento profundo.',
          'medium': 'Nivel moderado. Hay cierta distancia emocional que vale la pena trabajar.',
          'low': 'Nivel bajo. Mantenés conexión genuina con clientes y equipo.',
        },
      },
      {
        'name': 'Realización personal',
        'score': s['rp']!,
        'max': 48,
        'level': _rpLevel,
        'inverse': true,
        'descs': {
          'high': 'Nivel alto. Sentís que tu trabajo tiene sentido e impacto. Es un factor protector clave.',
          'medium': 'Nivel moderado. Tu sentido de logro existe pero podría ser más sólido.',
          'low': 'Nivel bajo. Sentís que tu trabajo no tiene el impacto o el sentido que esperabas.',
        },
      },
    ];
  }

  /// Texto interpretativo dinámico ("¿Qué significa esto para vos?").
  List<String> get _interpretation {
    if (_risk == 'high') {
      return [
        'Tus resultados muestran los tres indicadores del burnout en niveles críticos: agotamiento emocional alto, despersonalización alta y realización personal baja. No es un estado permanente, pero sí una señal que no podés ignorar.',
        'El burnout en emprendedores no aparece de golpe: es la acumulación de meses operando al máximo sin reponer energía. Tu cuerpo y tu mente te están diciendo que el ritmo actual no es sostenible.',
        'Lo más importante ahora: priorizá una conversación con un profesional de salud mental. No es debilidad, es estrategia. Un founder quemado toma peores decisiones.',
      ];
    }
    if (_risk == 'medium') {
      final msgs = <String>[];
      if (_aeLevel == 'high') {
        msgs.add('Tu agotamiento emocional está en zona alta: revisá tus límites y tu ritmo de trabajo.');
      }
      if (_dpLevel == 'high') {
        msgs.add('Estás desarrollando cierta distancia con tu entorno: reconectá con el propósito de lo que hacés.');
      }
      if (_rpLevel == 'low') {
        msgs.add('Tu sentido de realización necesita atención: celebrá los logros pequeños, no solo los grandes.');
      }
      return [
        'Estás en zona de alerta. No es burnout severo, pero hay señales concretas que requieren acción antes de que escalen.',
        if (msgs.isNotEmpty) msgs.join(' '),
        'Esta es exactamente la zona donde muchos founders se quedan meses sin hacer nada hasta que el sistema colapsa. El momento de actuar es ahora, cuando todavía tenés margen.',
      ];
    }
    return [
      'Tus niveles son saludables en este momento: el agotamiento está bajo control, mantenés conexión genuina con tu trabajo y sentís que lo que hacés tiene sentido.',
      'Esto no es permanente ni garantizado. El burnout en founders suele aparecer tras períodos de crecimiento acelerado, crisis o cambios importantes. Seguí monitoreando tu estado.',
      'Volvé a hacer este test en 3 meses o cuando notes un cambio en tu energía.',
    ];
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
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: _accentColor.withValues(alpha: 0.06),
                                borderRadius: BorderRadius.circular(14),
                                border: Border(
                                  left: BorderSide(color: _accentColor, width: 3),
                                ),
                              ),
                              child: Text(
                                'Este test es una autoevaluación basada en el MBI y no reemplaza un diagnóstico profesional. Si obtenés niveles altos, te recomendamos buscar apoyo de un profesional de salud mental.',
                                style: GoogleFonts.manrope(fontSize: 12, color: SentioColors.textSecondary, height: 1.5),
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
                                // En realización personal (positiva) "más frecuente" es bueno:
                                // invertimos el color para no marcar en rojo una respuesta positiva.
                                final isPositive = q['dimension'] == 'rp';
                                final value = opt['value'] as int;
                                final colorIndex = isPositive ? (_options.length - 1 - value) : value;
                                final color = Color(_options[colorIndex]['color'] as int);
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
                        // Dimension scores (3 niveles MBI)
                        ..._dimensionResults.expand((d) => [
                              _buildDimensionCard(d),
                              const SizedBox(height: 12),
                            ]),
                        const SizedBox(height: 4),
                        // Interpretación dinámica
                        _buildInterpretationBox(),
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

  // Color según nivel y si la dimensión es positiva (RP, inverse) o negativa.
  Color _levelColor(String level, bool inverse) {
    final bad = inverse ? 'low' : 'high';
    final good = inverse ? 'high' : 'low';
    if (level == bad) return const Color(0xFFE53935);
    if (level == good) return const Color(0xFF4CAF50);
    return const Color(0xFFFF9800);
  }

  String _levelName(String level) =>
      level == 'high' ? 'Alto' : (level == 'medium' ? 'Moderado' : 'Bajo');

  Widget _buildDimensionCard(Map<String, dynamic> d) {
    final score = d['score'] as int;
    final max = d['max'] as int;
    final level = d['level'] as String;
    final inverse = d['inverse'] as bool;
    final fraction = (score / max).clamp(0.0, 1.0);
    final color = _levelColor(level, inverse);
    final desc = (d['descs'] as Map)[level] as String;

    return Container(
      padding: const EdgeInsets.all(16),
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
                child: Text(d['name'] as String,
                  style: GoogleFonts.manrope(
                    fontSize: 14, fontWeight: FontWeight.w700, color: SentioColors.textPrimary,
                  ),
                ),
              ),
              Text('$score / $max',
                style: GoogleFonts.manrope(
                  fontSize: 13, fontWeight: FontWeight.w800, color: color,
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
                valueColor: AlwaysStoppedAnimation(color),
                minHeight: 6,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(_levelName(level),
              style: GoogleFonts.manrope(
                fontSize: 11, fontWeight: FontWeight.w800, color: color, letterSpacing: 0.3,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(desc,
            style: GoogleFonts.manrope(fontSize: 12, color: SentioColors.textSecondary, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildInterpretationBox() {
    final color = _severityData['color'] as Color;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: SentioColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.insights_rounded, size: 18, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text('¿Qué significa esto para vos?',
                  style: GoogleFonts.manrope(
                    fontSize: 14, fontWeight: FontWeight.w700, color: SentioColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ..._interpretation.map((p) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(p,
              style: GoogleFonts.manrope(fontSize: 13, color: SentioColors.textSecondary, height: 1.55),
            ),
          )),
        ],
      ),
    );
  }

  List<String> get _recommendations {
    final list = <String>[];
    if (_aeLevel != 'low') {
      list.add('Programá pausas reales durante el día — probá la respiración 4-7-8.');
      list.add('Fijá un horario para desconectarte del trabajo y respetalo.');
    }
    if (_dpLevel != 'low') {
      list.add('Reconectá con el "por qué" de lo que hacés — escribilo en el diario.');
      list.add('Buscá una conversación genuina con alguien de tu equipo o entorno.');
    }
    if (_rpLevel != 'high') {
      list.add('Anotá 3 cosas que lograste esta semana, por más chicas que sean.');
    }
    if (_risk == 'high') {
      list.add('Considerá hablar con un profesional de salud mental.');
      list.add('Si estás en crisis, usá el botón de ayuda (corazón) para líneas de apoyo.');
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
