import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sentio_app/config/theme.dart';

class RoutineScreen extends StatefulWidget {
  final String routineId;

  const RoutineScreen({super.key, required this.routineId});

  @override
  State<RoutineScreen> createState() => _RoutineScreenState();
}

class _RoutineScreenState extends State<RoutineScreen> {
  int _currentStep = 0;
  bool _completed = false;

  // Demo routines
  static const _routines = {
    'morning': {
      'title': 'Inicio con intención',
      'description': 'Empezá tu día con claridad y calma',
      'steps': [
        {'title': 'Respirá profundo', 'description': '3 respiraciones lentas para despertar tu cuerpo', 'duration': '30s', 'type': 'breathing'},
        {'title': 'Intención del día', 'description': '¿Cuál es la única cosa importante de hoy?', 'duration': '60s', 'type': 'reflection'},
        {'title': 'Un motivo', 'description': 'Nombrá una cosa por la que estás agradecido hoy', 'duration': '30s', 'type': 'gratitude'},
        {'title': 'Respirá y arrancá', 'description': 'Una respiración profunda final. Estás listo.', 'duration': '20s', 'type': 'breathing'},
      ],
    },
    'evening': {
      'title': 'Cierre del día',
      'description': 'Soltá el día y preparate para descansar',
      'steps': [
        {'title': '¿Cómo fue tu día?', 'description': 'Sin juzgar, solo observá. ¿Cómo te sentís ahora?', 'duration': '45s', 'type': 'reflection'},
        {'title': 'Algo bueno', 'description': '¿Qué fue lo mejor del día, por más chico que sea?', 'duration': '30s', 'type': 'gratitude'},
        {'title': 'Soltar', 'description': 'Escribí una cosa que querés dejar ir antes de dormir', 'duration': '60s', 'type': 'writing'},
        {'title': 'Respirá y descansá', 'description': '5 respiraciones lentas. El día terminó. Merecés descansar.', 'duration': '45s', 'type': 'breathing'},
      ],
    },
  };

  Map<String, dynamic> get _routine => _routines[widget.routineId] ?? _routines['morning']!;
  List<Map<String, String>> get _steps => List<Map<String, String>>.from(
      (_routine['steps'] as List).map((s) => Map<String, String>.from(s)));

  void _nextStep() {
    if (_currentStep < _steps.length - 1) {
      setState(() => _currentStep++);
    } else {
      setState(() => _completed = true);
    }
  }

  IconData _getStepIcon(String type) {
    switch (type) {
      case 'breathing': return Icons.air_rounded;
      case 'reflection': return Icons.psychology_rounded;
      case 'gratitude': return Icons.favorite_rounded;
      case 'writing': return Icons.edit_rounded;
      case 'body_scan': return Icons.self_improvement_rounded;
      default: return Icons.spa_rounded;
    }
  }

  Color _getStepColor(String type) {
    switch (type) {
      case 'breathing': return SentioColors.accent;
      case 'reflection': return SentioColors.primary;
      case 'gratitude': return SentioColors.secondary;
      case 'writing': return SentioColors.primaryLight;
      case 'body_scan': return SentioColors.warning;
      default: return SentioColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_completed) return _buildCompleted();

    final step = _steps[_currentStep];
    final stepColor = _getStepColor(step['type']!);
    final stepIcon = _getStepIcon(step['type']!);

    return Scaffold(
      backgroundColor: SentioColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Header
              Row(
                children: [
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: const Icon(Icons.close_rounded, color: SentioColors.textTertiary),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Row(
                      children: List.generate(_steps.length, (i) {
                        return Expanded(
                          child: Container(
                            height: 3,
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            decoration: BoxDecoration(
                              color: i <= _currentStep
                                  ? stepColor
                                  : SentioColors.divider,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    '${_currentStep + 1}/${_steps.length}',
                    style: TextStyle(
                      fontSize: 14,
                      color: SentioColors.textTertiary,
                    ),
                  ),
                ],
              ),
              const Spacer(flex: 2),
              // Step content
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: stepColor.withValues(alpha: 0.12),
                ),
                child: Icon(stepIcon, color: stepColor, size: 44),
              ),
              const SizedBox(height: 32),
              Text(
                step['title']!,
                style: GoogleFonts.manrope(
                  fontSize: 28,
                  color: SentioColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                step['description']!,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: SentioColors.textSecondary,
                      height: 1.5,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: stepColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  step['duration']!,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: stepColor,
                  ),
                ),
              ),
              const Spacer(flex: 3),
              ElevatedButton(
                onPressed: _nextStep,
                style: ElevatedButton.styleFrom(backgroundColor: stepColor),
                child: Text(
                  _currentStep < _steps.length - 1 ? 'Siguiente' : 'Completar',
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompleted() {
    return Scaffold(
      backgroundColor: SentioColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: SentioColors.accent.withValues(alpha: 0.15),
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: SentioColors.accent,
                  size: 48,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Rutina completada',
                style: GoogleFonts.manrope(
                  fontSize: 28,
                  color: SentioColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Cada momento que dedicás a cuidarte\nes una inversión, no un gasto.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: SentioColors.textSecondary,
                      height: 1.5,
                    ),
                textAlign: TextAlign.center,
              ),
              const Spacer(flex: 3),
              ElevatedButton(
                onPressed: () => context.pop(),
                child: const Text('Volver'),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
