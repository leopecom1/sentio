import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AppNotification {
  final String id;
  final String userId;
  final String type;
  final String title;
  final String? body;
  final String icon;
  final String color;
  final Map<String, dynamic> data;
  final bool isRead;
  final DateTime createdAt;

  const AppNotification({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    this.body,
    this.icon = 'notifications',
    this.color = '#0404FB',
    this.data = const {},
    this.isRead = false,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'],
      userId: json['user_id'],
      type: json['type'] ?? 'info',
      title: json['title'] ?? '',
      body: json['body'],
      icon: json['icon'] ?? 'notifications',
      color: json['color'] ?? '#0404FB',
      data: (json['data'] as Map?)?.cast<String, dynamic>() ?? {},
      isRead: json['is_read'] ?? false,
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  AppNotification copyWith({bool? isRead}) => AppNotification(
    id: id, userId: userId, type: type, title: title, body: body,
    icon: icon, color: color, data: data,
    isRead: isRead ?? this.isRead, createdAt: createdAt,
  );
}

class NotificationsService {
  NotificationsService._();
  static final NotificationsService instance = NotificationsService._();

  final _supabase = Supabase.instance.client;
  String? get _userId => _supabase.auth.currentUser?.id;

  Future<List<AppNotification>> loadAll({int limit = 50}) async {
    if (_userId == null) return [];
    try {
      final data = await _supabase
          .from('notifications')
          .select()
          .eq('user_id', _userId!)
          .order('created_at', ascending: false)
          .limit(limit);
      return (data as List).map((n) => AppNotification.fromJson(n)).toList();
    } catch (e) {
      debugPrint('Error loading notifications: $e');
      return [];
    }
  }

  Future<int> unreadCount() async {
    if (_userId == null) return 0;
    try {
      final data = await _supabase
          .from('notifications')
          .select('id')
          .eq('user_id', _userId!)
          .eq('is_read', false);
      return (data as List).length;
    } catch (_) {
      return 0;
    }
  }

  Future<void> markAsRead(String id) async {
    try {
      await _supabase.from('notifications').update({'is_read': true}).eq('id', id);
    } catch (e) {
      debugPrint('Error markAsRead: $e');
    }
  }

  Future<void> markAllAsRead() async {
    if (_userId == null) return;
    try {
      await _supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('user_id', _userId!)
          .eq('is_read', false);
    } catch (e) {
      debugPrint('Error markAllAsRead: $e');
    }
  }

  Future<void> delete(String id) async {
    try {
      await _supabase.from('notifications').delete().eq('id', id);
    } catch (_) {}
  }

  /// Create a notification for current user (e.g. streak milestones from client)
  Future<void> create({
    required String type,
    required String title,
    String? body,
    String icon = 'notifications',
    String color = '#0404FB',
    Map<String, dynamic>? data,
  }) async {
    if (_userId == null) return;
    try {
      await _supabase.from('notifications').insert({
        'user_id': _userId,
        'type': type,
        'title': title,
        'body': body,
        'icon': icon,
        'color': color,
        'data': data ?? {},
      });
    } catch (e) {
      debugPrint('Error creating notification: $e');
    }
  }
}
