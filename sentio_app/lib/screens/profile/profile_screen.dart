import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:sentio_app/config/theme.dart';
import 'package:sentio_app/providers/app_provider.dart';
import 'package:sentio_app/models/gamification.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int _selectedEvolutionTab = 0;
  bool _uploadingAvatar = false;

  Future<void> _pickAndUploadAvatar(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: source,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );
    if (picked == null) return;

    HapticFeedback.lightImpact();
    setState(() => _uploadingAvatar = true);

    try {
      final bytes = await picked.readAsBytes();
      final url = await context.read<AppProvider>().uploadAvatar(bytes);
      if (!mounted) return;
      if (url != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Foto actualizada'),
            backgroundColor: SentioColors.accent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('No se pudo subir la foto. Reintentá.'),
            backgroundColor: SentioColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: SentioColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _uploadingAvatar = false);
    }
  }

  void _showAvatarSourceSheet() {
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      backgroundColor: SentioColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: SentioColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_rounded, color: SentioColors.textPrimary),
                title: Text('Tomar foto', style: GoogleFonts.manrope(color: SentioColors.textPrimary)),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickAndUploadAvatar(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_rounded, color: SentioColors.textPrimary),
                title: Text('Elegir de galería', style: GoogleFonts.manrope(color: SentioColors.textPrimary)),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickAndUploadAvatar(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _mapIconName(String iconName) {
    switch (iconName) {
      case 'emoji_events':
        return Icons.emoji_events;
      case 'edit_note':
        return Icons.edit_note;
      case 'local_fire_department':
        return Icons.local_fire_department;
      case 'air':
        return Icons.air;
      case 'chat':
        return Icons.chat;
      case 'group':
        return Icons.group;
      case 'psychology':
        return Icons.psychology;
      case 'whatshot':
        return Icons.whatshot;
      case 'explore':
        return Icons.explore;
      case 'repeat':
        return Icons.repeat;
      case 'volunteer_activism':
        return Icons.volunteer_activism;
      case 'shield':
        return Icons.shield;
      default:
        return Icons.star;
    }
  }

  String _getPhaseLabel(int level) {
    if (level <= 2) return 'Fase: Despertar';
    if (level <= 4) return 'Fase: Crecimiento';
    if (level <= 6) return 'Fase: Dominio';
    return 'Fase: Maestría';
  }

  String _getArchetypeLabel(String style) {
    switch (style) {
      case 'direct':
        return 'Arquetipo: Estratega';
      case 'empathetic':
        return 'Arquetipo: Sanador';
      case 'analytical':
        return 'Arquetipo: Analista';
      case 'motivational':
        return 'Arquetipo: Líder';
      default:
        return 'Arquetipo: Explorador';
    }
  }

  String _getMotivationalText(int level) {
    if (level <= 1) return 'Cada check-in te acerca a conocerte mejor.';
    if (level <= 3) return 'Tu constancia está construyendo resiliencia real.';
    if (level <= 5) return 'Estás dominando el arte del autoconocimiento.';
    return 'Tu disciplina emocional es extraordinaria.';
  }

  final List<String> _weekDays = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final profile = provider.profile;
    final resilience = provider.resilienceLevel;
    final achievements = provider.achievements;
    final focusScore = provider.focusScore;
    final weeklyData = provider.weeklyEvolutionEmotional;

    return Scaffold(
      backgroundColor: SentioColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),

              // ─── 1. HEADER ───
              _buildHeader(context),

              const SizedBox(height: 24),

              // ─── 2. AVATAR CARD ───
              _buildAvatarCard(profile, resilience),

              const SizedBox(height: 16),

              // ─── 3. RESILIENCE LEVEL CARD ───
              _buildResilienceCard(resilience),

              const SizedBox(height: 16),

              // ─── 4. STATS GRID ───
              _buildStatsGrid(profile, focusScore),

              const SizedBox(height: 24),

              // ─── 5. EVOLUTION SECTION ───
              _buildEvolutionSection(weeklyData),

              const SizedBox(height: 24),

              // ─── 6. RECENT ACHIEVEMENTS ───
              _buildRecentAchievements(achievements),

              const SizedBox(height: 24),

              // ─── 7. MENU SECTIONS ───
              _buildMenuSection(
                title: 'Tu espacio',
                items: [
                  _MenuItemData(
                    icon: Icons.edit_note_rounded,
                    label: 'Diario',
                    onTap: () => context.push('/journal'),
                  ),
                  _MenuItemData(
                    icon: Icons.air_rounded,
                    label: 'Herramientas',
                    onTap: () => context.push('/tools'),
                  ),
                  _MenuItemData(
                    icon: Icons.insights_rounded,
                    label: 'Progreso',
                    onTap: () => context.push('/progress'),
                  ),
                  _MenuItemData(
                    icon: Icons.favorite_rounded,
                    label: 'Necesito apoyo',
                    color: SentioColors.error,
                    onTap: () => context.push('/crisis'),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              _buildMenuSection(
                title: 'Configuración',
                items: [
                  _MenuItemData(
                    icon: Icons.notifications_outlined,
                    label: 'Notificaciones',
                    onTap: () => context.push('/settings/notifications'),
                  ),
                  _MenuItemData(
                    icon: Icons.dark_mode_outlined,
                    label: 'Tema',
                    trailing: Text(
                      'Oscuro',
                      style: GoogleFonts.manrope(
                        fontSize: 14,
                        color: SentioColors.textSecondary,
                      ),
                    ),
                    onTap: () {},
                  ),
                  _MenuItemData(
                    icon: Icons.shield_outlined,
                    label: 'Política de privacidad',
                    onTap: () => context.push('/legal/privacy'),
                  ),
                  _MenuItemData(
                    icon: Icons.gavel_rounded,
                    label: 'Términos y condiciones',
                    onTap: () => context.push('/legal/terms'),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // ─── B2BETTER BANNER ───
              _B2BetterBanner(),

              const SizedBox(height: 16),

              _buildMenuSection(
                title: 'Acerca de',
                items: [
                  _MenuItemData(
                    icon: Icons.help_outline_rounded,
                    label: 'Ayuda',
                    onTap: () {},
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // ─── 8. SIGN OUT + VERSION ───
              Center(
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: () {
                        provider.signOut();
                        context.go('/auth');
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: SentioColors.error.withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          'Cerrar sesión',
                          style: GoogleFonts.manrope(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: SentioColors.error,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'B2Better v1.0.0',
                      style: GoogleFonts.manrope(
                        fontSize: 12,
                        color: SentioColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              // ─── 9. BOTTOM PADDING FOR NAV ───
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  // 1. HEADER
  // ═══════════════════════════════════════════════════════

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        // Back button
        GestureDetector(
          onTap: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/');
            }
          },
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
        // Title centered
        Expanded(
          child: Center(
            child: Text(
              'Mi Perfil',
              style: GoogleFonts.manrope(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: SentioColors.textPrimary,
                letterSpacing: -0.3,
              ),
            ),
          ),
        ),
        // Settings gear button
        GestureDetector(
          onTap: () {
            // Settings action
          },
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: SentioColors.surface,
              border: Border.all(color: SentioColors.border),
            ),
            child: const Icon(
              Icons.settings_rounded,
              color: SentioColors.textPrimary,
              size: 20,
            ),
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════
  // 2. AVATAR CARD
  // ═══════════════════════════════════════════════════════

  Widget _buildAvatarCard(dynamic profile, ResilienceLevel resilience) {
    final name = profile?.fullName ?? 'Usuario';
    final avatarUrl = profile?.avatarUrl;
    final firstLetter = name.isNotEmpty ? name[0].toUpperCase() : 'U';
    final companionStyle = profile?.preferredCompanionStyle ?? 'balanced';
    final phaseLabel = _getPhaseLabel(resilience.level);
    final archetypeLabel = _getArchetypeLabel(companionStyle);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
      decoration: SentioEffects.standardCard(),
      child: Column(
        children: [
          // Avatar with edit overlay
          Stack(
            children: [
              // Avatar circle
              Container(
                width: 112,
                height: 112,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: avatarUrl != null
                      ? null
                      : SentioColors.primary.withOpacity(0.1),
                  border: Border.all(
                    color: SentioColors.border,
                    width: 2,
                  ),
                  image: avatarUrl != null
                      ? DecorationImage(
                          image: NetworkImage(avatarUrl),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: avatarUrl == null
                    ? Center(
                        child: Text(
                          firstLetter,
                          style: GoogleFonts.manrope(
                            fontSize: 44,
                            fontWeight: FontWeight.w800,
                            color: SentioColors.primary,
                          ),
                        ),
                      )
                    : null,
              ),
              // Edit button overlay
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: _uploadingAvatar ? null : _showAvatarSourceSheet,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: SentioColors.primary,
                      border: Border.all(color: SentioColors.background, width: 2),
                    ),
                    child: _uploadingAvatar
                        ? const Padding(
                            padding: EdgeInsets.all(6),
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(
                            Icons.camera_alt_rounded,
                            color: Colors.white,
                            size: 14,
                          ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Name
          Text(
            name,
            style: GoogleFonts.manrope(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: SentioColors.textPrimary,
              letterSpacing: -0.3,
            ),
          ),

          const SizedBox(height: 4),

          // Subtitle
          Text(
            'Emprendedor • ${resilience.title}',
            style: GoogleFonts.manrope(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: SentioColors.textSecondary,
            ),
          ),

          const SizedBox(height: 12),

          // Tags row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Phase tag
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: SentioColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: SentioColors.primary.withOpacity(0.2),
                  ),
                ),
                child: Text(
                  phaseLabel,
                  style: GoogleFonts.manrope(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: SentioColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Archetype tag
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: SentioColors.accent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: SentioColors.accent.withOpacity(0.2),
                  ),
                ),
                child: Text(
                  archetypeLabel,
                  style: GoogleFonts.manrope(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: SentioColors.accent,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  // 3. RESILIENCE LEVEL CARD
  // ═══════════════════════════════════════════════════════

  Widget _buildResilienceCard(ResilienceLevel resilience) {
    final motivational = _getMotivationalText(resilience.level);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: SentioEffects.gradientCard(glowColor: SentioColors.accent),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: icon + title + level number
          Row(
            children: [
              Icon(
                Icons.shield_rounded,
                color: SentioColors.accent,
                size: 24,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Nivel de Resiliencia',
                  style: GoogleFonts.manrope(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: SentioColors.textPrimary,
                  ),
                ),
              ),
              Text(
                '${resilience.level}',
                style: GoogleFonts.manrope(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: SentioColors.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // XP info row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${resilience.xpInLevel} / ${resilience.xpNeeded} XP',
                style: GoogleFonts.manrope(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: SentioColors.textSecondary,
                ),
              ),
              Text(
                'Siguiente: ${resilience.nextLevelTitle}',
                style: GoogleFonts.manrope(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: SentioColors.accent,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Progress bar
          Container(
            height: 12,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(100),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: resilience.progress.clamp(0.0, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  color: SentioColors.accent,
                  borderRadius: BorderRadius.circular(100),
                  boxShadow: SentioEffects.glow(
                    SentioColors.accent,
                    blur: 8,
                    opacity: 0.5,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Motivational text
          Text(
            motivational,
            style: GoogleFonts.manrope(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: SentioColors.textSecondary,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  // 4. STATS GRID
  // ═══════════════════════════════════════════════════════

  Widget _buildStatsGrid(dynamic profile, int focusScore) {
    final streak = profile?.checkinStreak ?? 0;

    return Row(
      children: [
        // Left: Streak
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: SentioEffects.standardCard(),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: SentioColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.local_fire_department_rounded,
                    color: SentioColors.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$streak',
                        style: GoogleFonts.manrope(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: SentioColors.textPrimary,
                          height: 1,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Racha de\nBienestar',
                        style: GoogleFonts.manrope(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: SentioColors.textSecondary,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(width: 12),

        // Right: Focus Score
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: SentioEffects.standardCard(),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: SentioColors.accent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.psychology_rounded,
                    color: SentioColors.accent,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$focusScore%',
                        style: GoogleFonts.manrope(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: SentioColors.textPrimary,
                          height: 1,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Puntaje de\nEnfoque',
                        style: GoogleFonts.manrope(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: SentioColors.textSecondary,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════
  // 5. EVOLUTION SECTION
  // ═══════════════════════════════════════════════════════

  Widget _buildEvolutionSection(List<double> weeklyData) {
    final today = DateTime.now().weekday; // 1=Mon, 7=Sun

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title
        Text(
          'Evolución',
          style: GoogleFonts.manrope(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: SentioColors.textPrimary,
            letterSpacing: -0.2,
          ),
        ),

        const SizedBox(height: 12),

        // Tab bar
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: SentioColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: SentioColors.border),
          ),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedEvolutionTab = 0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: _selectedEvolutionTab == 0
                          ? SentioColors.primary
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        'Emocional',
                        style: GoogleFonts.manrope(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _selectedEvolutionTab == 0
                              ? Colors.white
                              : SentioColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedEvolutionTab = 1),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: _selectedEvolutionTab == 1
                          ? SentioColors.primary
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        'Financiera',
                        style: GoogleFonts.manrope(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _selectedEvolutionTab == 1
                              ? Colors.white
                              : SentioColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Bar chart
        Container(
          padding: const EdgeInsets.all(20),
          decoration: SentioEffects.standardCard(),
          child: SizedBox(
            height: 140,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(7, (index) {
                // index 0 = 6 days ago (Mon if today is Sun)
                // The data is ordered: [6 days ago, 5 days ago, ... today]
                final value = index < weeklyData.length
                    ? weeklyData[index].clamp(0.0, 1.0)
                    : 0.0;
                // Determine if this bar is "today"
                // weeklyData[6] is today, weeklyData[0] is 6 days ago
                final isToday = index == 6;
                // Map index to day-of-week label
                // index 0 = today - 6 days
                final dayOffset = 6 - index;
                final dayDate = DateTime.now().subtract(Duration(days: dayOffset));
                final dayIndex = dayDate.weekday - 1; // 0=Mon .. 6=Sun
                final dayLabel = _weekDays[dayIndex];

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // Bar
                        Expanded(
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 24),
                              child: FractionallySizedBox(
                                heightFactor: value > 0 ? value : 0.05,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: isToday
                                        ? SentioColors.primary
                                        : SentioColors.primary.withOpacity(0.2),
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(6),
                                      topRight: Radius.circular(6),
                                    ),
                                    boxShadow: isToday
                                        ? SentioEffects.glow(
                                            SentioColors.primary,
                                            blur: 6,
                                            opacity: 0.4,
                                          )
                                        : null,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Day label
                        Text(
                          dayLabel,
                          style: GoogleFonts.manrope(
                            fontSize: 11,
                            fontWeight:
                                isToday ? FontWeight.w700 : FontWeight.w500,
                            color: isToday
                                ? SentioColors.textPrimary
                                : SentioColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════
  // 6. RECENT ACHIEVEMENTS
  // ═══════════════════════════════════════════════════════

  Widget _buildRecentAchievements(List<Achievement> achievements) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Logros Recientes',
              style: GoogleFonts.manrope(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: SentioColors.textPrimary,
                letterSpacing: -0.2,
              ),
            ),
            GestureDetector(
              onTap: () {
                // Navigate to full achievements list
              },
              child: Text(
                'Ver Todo',
                style: GoogleFonts.manrope(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: SentioColors.primary,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Horizontal scroll
        SizedBox(
          height: 160,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: achievements.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final achievement = achievements[index];
              final isUnlocked = achievement.isUnlocked;
              final icon = _mapIconName(achievement.iconName);

              return Opacity(
                opacity: isUnlocked ? 1.0 : 0.6,
                child: ColorFiltered(
                  colorFilter: isUnlocked
                      ? const ColorFilter.mode(
                          Colors.transparent,
                          BlendMode.multiply,
                        )
                      : const ColorFilter.matrix(<double>[
                          0.2126, 0.7152, 0.0722, 0, 0,
                          0.2126, 0.7152, 0.0722, 0, 0,
                          0.2126, 0.7152, 0.0722, 0, 0,
                          0, 0, 0, 1, 0,
                        ]),
                  child: Container(
                    width: 120,
                    padding: const EdgeInsets.all(14),
                    decoration: SentioEffects.standardCard(),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Gradient icon circle
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [
                                SentioColors.primary.withOpacity(0.3),
                                SentioColors.accent.withOpacity(0.3),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: Icon(
                            icon,
                            color: isUnlocked
                                ? SentioColors.accent
                                : SentioColors.textSecondary,
                            size: 22,
                          ),
                        ),
                        const SizedBox(height: 10),
                        // Name
                        Text(
                          achievement.name,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.manrope(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: SentioColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        // Description
                        Text(
                          achievement.description,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.manrope(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: SentioColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════
  // 7. MENU SECTIONS
  // ═══════════════════════════════════════════════════════

  Widget _buildMenuSection({
    required String title,
    required List<_MenuItemData> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.manrope(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: SentioColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: SentioEffects.standardCard(),
          child: Column(
            children: items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final isLast = index == items.length - 1;

              return Column(
                children: [
                  GestureDetector(
                    onTap: item.onTap,
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            item.icon,
                            color: item.color ?? SentioColors.textSecondary,
                            size: 22,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              item.label,
                              style: GoogleFonts.manrope(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color:
                                    item.color ?? SentioColors.textPrimary,
                              ),
                            ),
                          ),
                          item.trailing ??
                              Icon(
                                Icons.arrow_forward_ios_rounded,
                                size: 14,
                                color: SentioColors.textSecondary,
                              ),
                        ],
                      ),
                    ),
                  ),
                  if (!isLast)
                    Padding(
                      padding: const EdgeInsets.only(left: 52),
                      child: Container(
                        height: 1,
                        color: SentioColors.divider,
                      ),
                    ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════
// HELPER DATA CLASS
// ═══════════════════════════════════════════════════════

class _MenuItemData {
  final IconData icon;
  final String label;
  final Color? color;
  final Widget? trailing;
  final VoidCallback onTap;

  const _MenuItemData({
    required this.icon,
    required this.label,
    this.color,
    this.trailing,
    required this.onTap,
  });
}

// ══════════════════════════════════════
// B2BETTER / MATEO SILVERA BANNER
// ══════════════════════════════════════

class _B2BetterBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/about/mateo'),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              SentioColors.primary.withValues(alpha: 0.12),
              SentioColors.accent.withValues(alpha: 0.08),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: SentioColors.primary.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 48,
                height: 48,
                color: Colors.white,
                padding: const EdgeInsets.all(4),
                child: Image.asset(
                  'assets/images/mateo_logo.png',
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.auto_awesome_rounded,
                    color: SentioColors.primary,
                    size: 24,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sobre B2Better',
                    style: GoogleFonts.manrope(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: SentioColors.textPrimary,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'La historia detrás de la app',
                    style: GoogleFonts.manrope(
                      fontSize: 11,
                      color: SentioColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 13,
              color: SentioColors.primary,
            ),
          ],
        ),
      ),
    );
  }
}
