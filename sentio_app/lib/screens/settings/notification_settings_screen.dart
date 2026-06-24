import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:sentio_app/config/theme.dart';
import 'package:sentio_app/providers/app_provider.dart';
import 'package:sentio_app/services/notification_service.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  bool _morningEnabled = true;
  bool _eveningEnabled = true;
  bool _streakAlert = true;
  bool _weeklySummary = true;
  TimeOfDay _morningTime = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _eveningTime = const TimeOfDay(hour: 21, minute: 0);

  // Preferencias por categoría (servidor): app / push / email
  static const _categories = [
    ('habitos', 'Hábitos', 'Recordatorios de check-in, racha, metas y diario', Icons.self_improvement_rounded),
    ('comunidad', 'Comunidad', 'Cuando comentan o reaccionan a tus publicaciones', Icons.groups_rounded),
    ('reactivacion', 'Reactivación', 'Si pasás unos días sin entrar', Icons.waving_hand_rounded),
  ];
  Map<String, Map<String, bool>> _prefs = {};
  bool _loadingPrefs = true;

  @override
  void initState() {
    super.initState();
    final provider = context.read<AppProvider>();
    _morningEnabled = provider.profile?.morningReminder ?? true;
    _eveningEnabled = provider.profile?.eveningReminder ?? true;
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await context.read<AppProvider>().loadNotificationPreferences();
    if (mounted) setState(() { _prefs = prefs; _loadingPrefs = false; });
  }

  bool _ch(String category, String channel) => _prefs[category]?[channel] ?? true;

  Future<void> _setChannel(String category, String channel, bool value) async {
    final current = {
      'in_app': _ch(category, 'in_app'),
      'push': _ch(category, 'push'),
      'email': _ch(category, 'email'),
    };
    current[channel] = value;
    setState(() => _prefs[category] = current);
    await context.read<AppProvider>().setNotificationPreference(
      category,
      inApp: current['in_app']!,
      push: current['push']!,
      email: current['email']!,
    );
  }

  Future<void> _pickTime(bool isMorning) async {
    final current = isMorning ? _morningTime : _eveningTime;
    final picked = await showTimePicker(
      context: context,
      initialTime: current,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: SentioColors.accent,
              surface: SentioColors.surface,
              onSurface: SentioColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isMorning) {
          _morningTime = picked;
        } else {
          _eveningTime = picked;
        }
      });
      _updateNotification(isMorning ? 'morning' : 'evening');
    }
  }

  Future<void> _updateNotification(String type) async {
    final notif = NotificationService.instance;
    final provider = context.read<AppProvider>();
    final name = provider.userName;

    switch (type) {
      case 'morning':
        if (_morningEnabled) {
          await notif.scheduleMorningReminder(_morningTime, name);
        } else {
          await notif.cancelMorning();
        }
        await provider.updateProfile(morningReminder: _morningEnabled);
        break;
      case 'evening':
        if (_eveningEnabled) {
          await notif.scheduleEveningReminder(_eveningTime, name);
        } else {
          await notif.cancelEvening();
        }
        await provider.updateProfile(eveningReminder: _eveningEnabled);
        break;
      case 'streak':
        if (_streakAlert) {
          final streak = provider.profile?.checkinStreak ?? 0;
          await notif.scheduleStreakDangerAlert(streak);
        } else {
          await notif.cancelStreakDanger();
        }
        break;
      case 'weekly':
        if (_weeklySummary) {
          await notif.scheduleWeeklySummary();
        } else {
          await notif.cancelWeeklySummary();
        }
        break;
    }
  }

  String _formatTime(TimeOfDay time) {
    final h = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final m = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$h:$m $period';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SentioColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: SentioColors.surface,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.arrow_back_rounded,
                        color: SentioColors.textPrimary,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'Notificaciones',
                    style: GoogleFonts.manrope(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: SentioColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                children: [
                  // Morning reminder
                  _buildNotificationTile(
                    icon: Icons.wb_sunny_rounded,
                    title: 'Recordatorio matutino',
                    subtitle: _morningEnabled ? _formatTime(_morningTime) : 'Desactivado',
                    enabled: _morningEnabled,
                    onToggle: (val) {
                      setState(() => _morningEnabled = val);
                      _updateNotification('morning');
                    },
                    onTapTime: _morningEnabled ? () => _pickTime(true) : null,
                  ),
                  const SizedBox(height: 12),

                  // Evening reminder
                  _buildNotificationTile(
                    icon: Icons.nightlight_round,
                    title: 'Recordatorio nocturno',
                    subtitle: _eveningEnabled ? _formatTime(_eveningTime) : 'Desactivado',
                    enabled: _eveningEnabled,
                    onToggle: (val) {
                      setState(() => _eveningEnabled = val);
                      _updateNotification('evening');
                    },
                    onTapTime: _eveningEnabled ? () => _pickTime(false) : null,
                  ),
                  const SizedBox(height: 12),

                  // Streak danger
                  _buildNotificationTile(
                    icon: Icons.local_fire_department_rounded,
                    title: 'Alerta de racha',
                    subtitle: 'Avisarte si tu racha está en peligro',
                    enabled: _streakAlert,
                    onToggle: (val) {
                      setState(() => _streakAlert = val);
                      _updateNotification('streak');
                    },
                  ),
                  const SizedBox(height: 12),

                  // Weekly summary
                  _buildNotificationTile(
                    icon: Icons.analytics_rounded,
                    title: 'Resumen semanal',
                    subtitle: 'Domingos a las 21:00',
                    enabled: _weeklySummary,
                    onToggle: (val) {
                      setState(() => _weeklySummary = val);
                      _updateNotification('weekly');
                    },
                  ),

                  const SizedBox(height: 32),
                  Text(
                    'Tipos de notificación',
                    style: GoogleFonts.manrope(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: SentioColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Elegí por dónde querés recibir cada tipo.',
                    style: GoogleFonts.manrope(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: SentioColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_loadingPrefs)
                    const Center(child: Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(color: SentioColors.accent, strokeWidth: 2),
                    ))
                  else
                    ..._categories.map((c) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildCategoryCard(c.$1, c.$2, c.$3, c.$4),
                    )),

                  const SizedBox(height: 20),
                  // Info text
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: SentioColors.accent.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: SentioColors.accent.withValues(alpha: 0.12)),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          color: SentioColors.accent.withValues(alpha: 0.6),
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Las notificaciones te ayudan a mantener tu racha y crear un hábito de bienestar.',
                            style: GoogleFonts.manrope(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: SentioColors.textSecondary,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool enabled,
    required ValueChanged<bool> onToggle,
    VoidCallback? onTapTime,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SentioColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: enabled
              ? SentioColors.accent.withValues(alpha: 0.15)
              : SentioColors.border,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: enabled
                  ? SentioColors.accent.withValues(alpha: 0.1)
                  : SentioColors.textTertiary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: enabled ? SentioColors.accent : SentioColors.textTertiary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: onTapTime,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.manrope(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: SentioColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        subtitle,
                        style: GoogleFonts.manrope(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: SentioColors.textSecondary,
                        ),
                      ),
                      if (onTapTime != null) ...[
                        const SizedBox(width: 4),
                        Icon(
                          Icons.edit_rounded,
                          size: 14,
                          color: SentioColors.accent.withValues(alpha: 0.6),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          Switch.adaptive(
            value: enabled,
            onChanged: onToggle,
            activeColor: SentioColors.accent,
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(String category, String title, String subtitle, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SentioColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SentioColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: SentioColors.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: SentioColors.accent, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: GoogleFonts.manrope(
                      fontSize: 15, fontWeight: FontWeight.w600, color: SentioColors.textPrimary)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: GoogleFonts.manrope(
                      fontSize: 12, fontWeight: FontWeight.w500, color: SentioColors.textSecondary, height: 1.3)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _channelChip(category, 'in_app', 'App', Icons.notifications_rounded),
              const SizedBox(width: 8),
              _channelChip(category, 'push', 'Push', Icons.phone_iphone_rounded),
              const SizedBox(width: 8),
              _channelChip(category, 'email', 'Email', Icons.mail_outline_rounded),
            ],
          ),
        ],
      ),
    );
  }

  Widget _channelChip(String category, String channel, String label, IconData icon) {
    final on = _ch(category, channel);
    return Expanded(
      child: GestureDetector(
        onTap: () => _setChannel(category, channel, !on),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: on ? SentioColors.accent.withValues(alpha: 0.1) : SentioColors.background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: on ? SentioColors.accent.withValues(alpha: 0.4) : SentioColors.border,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, size: 18, color: on ? SentioColors.accent : SentioColors.textTertiary),
              const SizedBox(height: 4),
              Text(label, style: GoogleFonts.manrope(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: on ? SentioColors.accent : SentioColors.textTertiary,
              )),
            ],
          ),
        ),
      ),
    );
  }
}
