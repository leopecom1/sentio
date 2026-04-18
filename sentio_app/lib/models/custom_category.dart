import 'package:flutter/material.dart';

class CustomCategory {
  final String id;
  final String userId;
  final String type; // income or expense
  final String label;
  final int iconCode;
  final int color;
  final DateTime createdAt;

  CustomCategory({
    required this.id,
    required this.userId,
    required this.type,
    required this.label,
    required this.iconCode,
    required this.color,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory CustomCategory.fromJson(Map<String, dynamic> json) {
    return CustomCategory(
      id: json['id'],
      userId: json['user_id'],
      type: json['type'],
      label: json['label'],
      iconCode: json['icon_code'] ?? 0xe5d3,
      color: json['color'] ?? 0xFF9E9E9E,
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  IconData get iconData => IconData(iconCode, fontFamily: 'MaterialIcons');

  Map<String, dynamic> toMap() => {
    'id': id,
    'label': label,
    'icon': iconData,
    'color': color,
    'isCustom': true,
  };
}
