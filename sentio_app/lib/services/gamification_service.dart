import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PointRule {
  final String actionKey;
  final String label;
  final String? description;
  final int xpAmount;
  final String icon;
  final String category;
  final bool isActive;

  PointRule({
    required this.actionKey,
    required this.label,
    this.description,
    required this.xpAmount,
    required this.icon,
    required this.category,
    required this.isActive,
  });

  factory PointRule.fromJson(Map<String, dynamic> json) => PointRule(
    actionKey: json['action_key'],
    label: json['label'],
    description: json['description'],
    xpAmount: json['xp_amount'] ?? 0,
    icon: json['icon'] ?? 'star',
    category: json['category'] ?? 'general',
    isActive: json['is_active'] ?? true,
  );
}

class GamificationLevel {
  final int level;
  final String title;
  final int xpRequired;
  final String icon;

  GamificationLevel({
    required this.level,
    required this.title,
    required this.xpRequired,
    required this.icon,
  });

  factory GamificationLevel.fromJson(Map<String, dynamic> json) => GamificationLevel(
    level: json['level'],
    title: json['title'],
    xpRequired: json['xp_required'] ?? 0,
    icon: json['icon'] ?? 'shield',
  );
}

class ServerAchievement {
  final String achievementKey;
  final String name;
  final String description;
  final String icon;
  final String category;
  final String conditionType;
  final String? conditionField;
  final int conditionValue;
  final int xpReward;
  final bool isActive;

  ServerAchievement({
    required this.achievementKey,
    required this.name,
    required this.description,
    required this.icon,
    required this.category,
    required this.conditionType,
    this.conditionField,
    required this.conditionValue,
    required this.xpReward,
    required this.isActive,
  });

  factory ServerAchievement.fromJson(Map<String, dynamic> json) => ServerAchievement(
    achievementKey: json['achievement_key'],
    name: json['name'],
    description: json['description'] ?? '',
    icon: json['icon'] ?? 'emoji_events',
    category: json['category'] ?? 'general',
    conditionType: json['condition_type'] ?? 'count',
    conditionField: json['condition_field'],
    conditionValue: json['condition_value'] ?? 1,
    xpReward: json['xp_reward'] ?? 0,
    isActive: json['is_active'] ?? true,
  );
}

class GamificationService {
  GamificationService._();
  static final GamificationService instance = GamificationService._();

  final _supabase = Supabase.instance.client;
  String? get _userId => _supabase.auth.currentUser?.id;

  List<PointRule> _pointRules = [];
  List<GamificationLevel> _levels = [];
  List<ServerAchievement> _achievements = [];

  List<PointRule> get pointRules => _pointRules;
  List<GamificationLevel> get levels => _levels;
  List<ServerAchievement> get achievements => _achievements;

  /// Load all gamification config from server
  Future<void> loadConfig() async {
    try {
      final results = await Future.wait([
        _supabase.from('point_rules').select().eq('is_active', true).order('category'),
        _supabase.from('gamification_levels').select().order('level'),
        _supabase.from('gamification_achievements').select().eq('is_active', true).order('sort_order'),
      ]);

      _pointRules = (results[0] as List).map((r) => PointRule.fromJson(r)).toList();
      _levels = (results[1] as List).map((l) => GamificationLevel.fromJson(l)).toList();
      _achievements = (results[2] as List).map((a) => ServerAchievement.fromJson(a)).toList();
    } catch (e) {
      debugPrint('Error loading gamification config: $e');
    }
  }

  /// Get XP amount for an action
  int getXpForAction(String actionKey) {
    final rule = _pointRules.where((r) => r.actionKey == actionKey).firstOrNull;
    return rule?.xpAmount ?? 0;
  }

  /// Log XP earned by user
  Future<void> logPoints(String actionKey, {String? description}) async {
    if (_userId == null) return;
    final xp = getXpForAction(actionKey);
    if (xp <= 0) return;

    try {
      await _supabase.from('user_points_log').insert({
        'user_id': _userId,
        'action_key': actionKey,
        'xp_amount': xp,
        'description': description,
      });

      // Update total_xp on profile
      await _supabase.rpc('increment_user_xp', params: {
        'p_user_id': _userId,
        'p_amount': xp,
      });
    } catch (e) {
      debugPrint('Error logging points: $e');
    }
  }

  /// Get user's unlocked achievement keys
  Future<Set<String>> getUserAchievementKeys() async {
    if (_userId == null) return {};
    try {
      final data = await _supabase
          .from('user_achievements')
          .select('achievement_key')
          .eq('user_id', _userId!);
      return (data as List).map((d) => d['achievement_key'] as String).toSet();
    } catch (e) {
      debugPrint('Error loading user achievements: $e');
      return {};
    }
  }

  /// Unlock an achievement for the user
  Future<void> unlockAchievement(String achievementKey) async {
    if (_userId == null) return;
    try {
      await _supabase.from('user_achievements').upsert({
        'user_id': _userId,
        'achievement_key': achievementKey,
      }, onConflict: 'user_id,achievement_key');
    } catch (e) {
      debugPrint('Error unlocking achievement: $e');
    }
  }

  /// Calculate level from XP using server levels
  GamificationLevel getLevelForXp(int totalXp) {
    if (_levels.isEmpty) {
      return GamificationLevel(level: 1, title: 'Iniciado', xpRequired: 0, icon: 'egg');
    }
    GamificationLevel current = _levels.first;
    for (final lvl in _levels) {
      if (totalXp >= lvl.xpRequired) {
        current = lvl;
      } else {
        break;
      }
    }
    return current;
  }

  /// Get next level threshold
  int getNextLevelXp(int totalXp) {
    for (final lvl in _levels) {
      if (totalXp < lvl.xpRequired) return lvl.xpRequired;
    }
    return _levels.isNotEmpty ? _levels.last.xpRequired + 1000 : 1000;
  }
}
