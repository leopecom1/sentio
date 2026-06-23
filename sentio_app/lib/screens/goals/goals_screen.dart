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
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppProvider>().loadGoals();
    });
  }

  void _addGoal(bool isDaily) {
    HapticFeedback.lightImpact();
    final controller = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: SentioColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
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
            Text(
              isDaily ? 'Nueva meta diaria' : 'Nueva meta',
              style: GoogleFonts.manrope(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: SentioColors.textPrimary),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              style: GoogleFonts.manrope(color: SentioColors.textPrimary),
              decoration: InputDecoration(
                hintText: isDaily
                    ? 'Ej. Meditar 5 minutos'
                    : 'Ej. Ordenar mi espacio de trabajo',
              ),
              onSubmitted: (v) {
                if (v.trim().isNotEmpty) {
                  context.read<AppProvider>().addGoal(v, isDaily: isDaily);
                  Navigator.pop(ctx);
                }
              },
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                if (controller.text.trim().isNotEmpty) {
                  context
                      .read<AppProvider>()
                      .addGoal(controller.text, isDaily: isDaily);
                  Navigator.pop(ctx);
                }
              },
              child: const Text('Agregar'),
            ),
          ],
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
            final daily = provider.dailyGoals;
            final regular = provider.regularGoals;
            final allCount = provider.goals.length;
            final doneCount =
                provider.goals.where((g) => g.isCompleted).length;
            final pct = allCount == 0 ? 0.0 : doneCount / allCount;

            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _header(context)),
                SliverToBoxAdapter(
                    child: _progressCard(doneCount, allCount, pct)),
                _section('Hoy', Icons.wb_sunny_rounded, daily, true,
                    'Sumá metas diarias para hoy.'),
                _section('Mis metas', Icons.flag_rounded, regular, false,
                    'Todavía no tenés metas. Creá una o pedile ideas al asistente.'),
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addGoal(false),
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
            ? '¡Completaste todas! 🎉'
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
      bool isDaily, String emptyMsg) {
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
                if (isDaily)
                  GestureDetector(
                    onTap: () => _addGoal(true),
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
        child: const Icon(Icons.delete_outline_rounded,
            color: SentioColors.error),
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
                child: Text(
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
