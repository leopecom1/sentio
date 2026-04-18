import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:sentio_app/config/theme.dart';
import 'package:sentio_app/providers/app_provider.dart';
import 'package:sentio_app/services/notifications_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppProvider>().loadNotifications();
    });
  }

  IconData _iconFor(String name) {
    switch (name) {
      case 'verified': return Icons.verified_rounded;
      case 'info': return Icons.info_rounded;
      case 'campaign': return Icons.campaign_rounded;
      case 'emoji_events': return Icons.emoji_events_rounded;
      case 'local_fire_department': return Icons.local_fire_department_rounded;
      case 'star': return Icons.star_rounded;
      case 'favorite': return Icons.favorite_rounded;
      case 'chat': return Icons.chat_rounded;
      case 'warning': return Icons.warning_amber_rounded;
      default: return Icons.notifications_rounded;
    }
  }

  Color _parseColor(String hex) {
    final clean = hex.replaceFirst('#', '');
    final value = int.parse(clean.length == 6 ? 'FF$clean' : clean, radix: 16);
    return Color(value);
  }

  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'ahora';
    if (diff.inMinutes < 60) return 'hace ${diff.inMinutes}m';
    if (diff.inHours < 24) return 'hace ${diff.inHours}h';
    if (diff.inDays < 7) return 'hace ${diff.inDays}d';
    return '${(diff.inDays / 7).floor()}sem';
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final notifications = provider.notifications;

    return Scaffold(
      backgroundColor: SentioColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Row(
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
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      'Notificaciones',
                      style: GoogleFonts.manrope(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: SentioColors.textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  if (notifications.any((n) => !n.isRead))
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        provider.markAllNotificationsRead();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: SentioColors.accent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: SentioColors.accent.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          'Marcar leídas',
                          style: GoogleFonts.manrope(
                            fontSize: 12, fontWeight: FontWeight.w700, color: SentioColors.accent,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => provider.loadNotifications(),
                color: SentioColors.accent,
                child: notifications.isEmpty
                    ? _buildEmpty()
                    : ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                        itemCount: notifications.length,
                        itemBuilder: (_, i) {
                          final n = notifications[i];
                          final color = _parseColor(n.color);
                          return Dismissible(
                            key: ValueKey(n.id),
                            direction: DismissDirection.endToStart,
                            onDismissed: (_) => provider.deleteNotification(n.id),
                            background: Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 24),
                              decoration: BoxDecoration(
                                color: SentioColors.error.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(Icons.delete_rounded, color: SentioColors.error),
                            ),
                            child: GestureDetector(
                              onTap: () {
                                if (!n.isRead) {
                                  HapticFeedback.selectionClick();
                                  provider.markNotificationRead(n.id);
                                }
                              },
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: n.isRead
                                      ? SentioColors.surface
                                      : SentioColors.surface,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: n.isRead
                                        ? SentioColors.border
                                        : color.withValues(alpha: 0.3),
                                  ),
                                  boxShadow: n.isRead ? null : [
                                    BoxShadow(
                                      color: color.withValues(alpha: 0.1),
                                      blurRadius: 14,
                                      spreadRadius: -2,
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 44, height: 44,
                                      decoration: BoxDecoration(
                                        color: color.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(_iconFor(n.icon), color: color, size: 22),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  n.title,
                                                  style: GoogleFonts.manrope(
                                                    fontSize: 14,
                                                    fontWeight: n.isRead ? FontWeight.w600 : FontWeight.w800,
                                                    color: SentioColors.textPrimary,
                                                  ),
                                                  maxLines: 2,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                              if (!n.isRead)
                                                Container(
                                                  width: 8, height: 8,
                                                  decoration: BoxDecoration(
                                                    shape: BoxShape.circle,
                                                    color: color,
                                                    boxShadow: [
                                                      BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 4),
                                                    ],
                                                  ),
                                                ),
                                            ],
                                          ),
                                          if (n.body != null) ...[
                                            const SizedBox(height: 3),
                                            Text(
                                              n.body!,
                                              style: GoogleFonts.manrope(
                                                fontSize: 12,
                                                color: SentioColors.textSecondary,
                                                height: 1.4,
                                              ),
                                              maxLines: 3,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                          const SizedBox(height: 5),
                                          Text(
                                            _timeAgo(n.createdAt),
                                            style: GoogleFonts.manrope(
                                              fontSize: 11,
                                              color: SentioColors.textTertiary,
                                            ),
                                          ),
                                        ],
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 120),
          child: Column(
            children: [
              Container(
                width: 80, height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: SentioColors.surface,
                  border: Border.all(color: SentioColors.border),
                ),
                child: Icon(
                  Icons.notifications_off_outlined,
                  color: SentioColors.textTertiary,
                  size: 36,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Sin notificaciones',
                style: GoogleFonts.manrope(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: SentioColors.textSecondary,
                ),
              ),
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  'Acá vas a ver tus logros, avisos y actualizaciones.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.manrope(
                    fontSize: 13,
                    color: SentioColors.textTertiary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
