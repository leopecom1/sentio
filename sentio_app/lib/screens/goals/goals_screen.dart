import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:sentio_app/config/theme.dart';
import 'package:sentio_app/models/user_goal.dart';
import 'package:sentio_app/providers/app_provider.dart';

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  static const _freqs = [
    {'key': 'none', 'label': 'Una vez', 'icon': Icons.check_circle_outline_rounded},
    {'key': 'daily', 'label': 'Diaria', 'icon': Icons.wb_sunny_outlined},
    {'key': 'weekly', 'label': 'Semanal', 'icon': Icons.view_week_outlined},
    {'key': 'monthly', 'label': 'Mensual', 'icon': Icons.calendar_month_outlined},
    {'key': 'custom', 'label': 'Cada X días', 'icon': Icons.repeat_rounded},
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppProvider>().loadGoals();
    });
  }

  void _addGoal({String initialFreq = 'none'}) {
    HapticFeedback.lightImpact();
    final controller = TextEditingController();
    final intervalController = TextEditingController(text: '3');
    String freq = initialFreq;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: SentioColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Nueva meta',
                  style: GoogleFonts.manrope(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: SentioColors.textPrimary)),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                autofocus: true,
                textCapitalization: TextCapitalization.sentences,
                style: GoogleFonts.manrope(color: SentioColors.textPrimary),
                decoration: const InputDecoration(
                    hintText: 'Ej. Ordenar mi espacio de trabajo'),
              ),
              const SizedBox(height: 18),
              Text('Frecuencia',
                  style: GoogleFonts.manrope(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: SentioColors.textSecondary)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _freqs.map((f) {
                  final selected = freq == f['key'];
                  return GestureDetector(
                    onTap: () => setSheet(() => freq = f['key'] as String),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 9),
                      decoration: BoxDecoration(
                        color: selected
                            ? SentioColors.primary
                            : SentioColors.card,
                        borderRadius: BorderRadius.circular(100),
                        border: Border.all(
                            color: selected
                                ? SentioColors.primary
                                : SentioColors.border),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(f['icon'] as IconData,
                              size: 15,
                              color: selected
                                  ? Colors.white
                                  : SentioColors.textSecondary),
                          const SizedBox(width: 6),
                          Text(f['label'] as String,
                              style: GoogleFonts.manrope(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: selected
                                      ? Colors.white
                                      : SentioColors.textPrimary)),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              if (freq == 'custom') ...[
                const SizedBox(height: 14),
                Row(
                  children: [
                    Text('Cada',
                        style: GoogleFonts.manrope(
                            color: SentioColors.textSecondary)),
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 64,
                      child: TextField(
                        controller: intervalController,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ],
                        style:
                            GoogleFonts.manrope(color: SentioColors.textPrimary),
                        decoration: const InputDecoration(hintText: '3'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text('días',
                        style: GoogleFonts.manrope(
                            color: SentioColors.textSecondary)),
                  ],
                ),
              ],
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  final t = controller.text.trim();
                  if (t.isEmpty) return;
                  final interval = freq == 'custom'
                      ? (int.tryParse(intervalController.text) ?? 1)
                          .clamp(1, 365)
                      : null;
                  context
                      .read<AppProvider>()
                      .addGoal(t, recurrence: freq, intervalDays: interval);
                  Navigator.pop(ctx);
                },
                child: const Text('Agregar'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SentioColors.background,
      body: SafeArea(
        child: Consumer<AppProvider>(
          builder: (context, provider, _) {
            final recurring = provider.recurringGoals;
            final oneTime = provider.oneTimeGoals;
            final allCount = provider.goals.length;
            final doneCount =
                provider.goals.where((g) => g.isCompleted).length;
            final pct = allCount == 0 ? 0.0 : doneCount / allCount;

            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _header(context)),
                SliverToBoxAdapter(
                    child: _progressCard(doneCount, allCount, pct)),
                _section('Recurrentes', Icons.repeat_rounded, recurring,
                    'custom', 'Sumá metas que se repitan (diarias, semanales…).'),
                _section('Mis metas', Icons.flag_rounded, oneTime, 'none',
                    'Todavía no tenés metas. Creá una o pedile ideas al asistente.'),
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addGoal(),
        backgroundColor: SentioColors.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text('Nueva meta',
            style: GoogleFonts.manrope(
                fontWeight: FontWeight.w700, color: Colors.white)),
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.pop(),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: SentioColors.border),
              ),
              child: const Icon(Icons.arrow_back_rounded,
                  color: SentioColors.textPrimary, size: 20),
            ),
          ),
          const SizedBox(width: 14),
          Text('Metas',
              style: GoogleFonts.manrope(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: SentioColors.textPrimary,
                  letterSpacing: -0.5)),
        ],
      ),
    );
  }

  Widget _progressCard(int done, int total, double pct) {
    final msg = total == 0
        ? 'Empezá creando tu primera meta'
        : pct == 1
            ? '¡Completaste todas!'
            : 'Vas $done de $total. Seguí así.';
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            SentioColors.primary.withValues(alpha: 0.18),
            SentioColors.accent.withValues(alpha: 0.10),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: SentioColors.primary.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 56,
            height: 56,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 56,
                  height: 56,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: pct),
                    duration: const Duration(milliseconds: 700),
                    curve: Curves.easeOutCubic,
                    builder: (_, v, __) => CircularProgressIndicator(
                      value: v,
                      strokeWidth: 6,
                      backgroundColor: Colors.white.withValues(alpha: 0.10),
                      valueColor:
                          const AlwaysStoppedAnimation(SentioColors.accent),
                    ),
                  ),
                ),
                Text('${(pct * 100).round()}%',
                    style: GoogleFonts.manrope(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: SentioColors.textPrimary)),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Tu progreso',
                    style: GoogleFonts.manrope(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: SentioColors.textSecondary)),
                const SizedBox(height: 4),
                Text(msg,
                    style: GoogleFonts.manrope(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: SentioColors.textPrimary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _section(String title, IconData icon, List<UserGoal> goals,
      String addFreq, String emptyMsg) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: SentioColors.accent),
                const SizedBox(width: 8),
                Text(title,
                    style: GoogleFonts.manrope(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: SentioColors.textPrimary)),
                const Spacer(),
                GestureDetector(
                  onTap: () => _addGoal(
                      initialFreq: addFreq == 'custom' ? 'daily' : 'none'),
                  child: Row(
                    children: [
                      const Icon(Icons.add_rounded,
                          size: 16, color: SentioColors.primary),
                      Text('Agregar',
                          style: GoogleFonts.manrope(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: SentioColors.primary)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (goals.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Text(emptyMsg,
                    style: GoogleFonts.manrope(
                        fontSize: 13, color: SentioColors.textTertiary)),
              )
            else
              ...goals.map((g) => _goalTile(g)),
          ],
        ),
      ),
    );
  }

  Widget _goalTile(UserGoal g) {
    return Dismissible(
      key: ValueKey(g.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: SentioColors.error.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(14),
        ),
        child:
            const Icon(Icons.delete_outline_rounded, color: SentioColors.error),
      ),
      onDismissed: (_) {
        HapticFeedback.mediumImpact();
        context.read<AppProvider>().deleteGoal(g.id);
      },
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          context.read<AppProvider>().toggleGoal(g);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: SentioColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: g.isCompleted
                  ? SentioColors.accent.withValues(alpha: 0.4)
                  : SentioColors.border,
            ),
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color:
                      g.isCompleted ? SentioColors.accent : Colors.transparent,
                  border: Border.all(
                    color: g.isCompleted
                        ? SentioColors.accent
                        : SentioColors.textTertiary,
                    width: 2,
                  ),
                ),
                child: g.isCompleted
                    ? const Icon(Icons.check_rounded,
                        size: 16, color: Colors.black)
                    : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      g.title,
                      style: GoogleFonts.manrope(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: g.isCompleted
                            ? SentioColors.textTertiary
                            : SentioColors.textPrimary,
                        decoration:
                            g.isCompleted ? TextDecoration.lineThrough : null,
                        decorationColor: SentioColors.textTertiary,
                      ),
                    ),
                    if (g.isRecurring) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.repeat_rounded,
                              size: 12, color: SentioColors.accent),
                          const SizedBox(width: 4),
                          Text(g.recurrenceLabel,
                              style: GoogleFonts.manrope(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: SentioColors.accent)),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              if (g.source == 'chat')
                Icon(Icons.auto_awesome_rounded,
                    size: 14,
                    color: SentioColors.primary.withValues(alpha: 0.7)),
            ],
          ),
        ),
      ),
    );
  }
}
