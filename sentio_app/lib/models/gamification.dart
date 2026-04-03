class ResilienceLevel {
  final int level;
  final String title;
  final int currentXp;
  final int xpForNextLevel;
  final int xpFromPreviousLevel;

  ResilienceLevel({
    required this.level,
    required this.title,
    required this.currentXp,
    required this.xpForNextLevel,
    required this.xpFromPreviousLevel,
  });

  double get progress {
    final range = xpForNextLevel - xpFromPreviousLevel;
    if (range <= 0) return 1.0;
    return ((currentXp - xpFromPreviousLevel) / range).clamp(0.0, 1.0);
  }

  int get xpInLevel => currentXp - xpFromPreviousLevel;
  int get xpNeeded => xpForNextLevel - xpFromPreviousLevel;

  static const List<Map<String, dynamic>> levels = [
    {'level': 1, 'title': 'Iniciado', 'xp': 0},
    {'level': 2, 'title': 'Explorador Interior', 'xp': 250},
    {'level': 3, 'title': 'Observador Consciente', 'xp': 600},
    {'level': 4, 'title': 'Guerrero Resiliente', 'xp': 1000},
    {'level': 5, 'title': 'Maestro del Equilibrio', 'xp': 1500},
    {'level': 6, 'title': 'Guardián de la Calma', 'xp': 2200},
    {'level': 7, 'title': 'Voluntad de Hierro', 'xp': 3000},
    {'level': 8, 'title': 'Líder Interior', 'xp': 4000},
  ];

  static ResilienceLevel fromXp(int totalXp) {
    int currentLevel = 1;
    String title = 'Iniciado';
    int xpFrom = 0;
    int xpTo = 250;

    for (int i = levels.length - 1; i >= 0; i--) {
      if (totalXp >= (levels[i]['xp'] as int)) {
        currentLevel = levels[i]['level'] as int;
        title = levels[i]['title'] as String;
        xpFrom = levels[i]['xp'] as int;
        xpTo = i < levels.length - 1
            ? levels[i + 1]['xp'] as int
            : (levels[i]['xp'] as int) + 1000;
        break;
      }
    }

    return ResilienceLevel(
      level: currentLevel,
      title: title,
      currentXp: totalXp,
      xpForNextLevel: xpTo,
      xpFromPreviousLevel: xpFrom,
    );
  }

  String get nextLevelTitle {
    for (int i = 0; i < levels.length; i++) {
      if (levels[i]['level'] == level && i < levels.length - 1) {
        return levels[i + 1]['title'] as String;
      }
    }
    return 'Máximo';
  }
}

class Achievement {
  final String id;
  final String name;
  final String description;
  final String iconName;
  final String category;
  final bool isUnlocked;
  final DateTime? unlockedAt;

  Achievement({
    required this.id,
    required this.name,
    required this.description,
    required this.iconName,
    required this.category,
    this.isUnlocked = false,
    this.unlockedAt,
  });

  Achievement copyWith({bool? isUnlocked, DateTime? unlockedAt}) {
    return Achievement(
      id: id,
      name: name,
      description: description,
      iconName: iconName,
      category: category,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      unlockedAt: unlockedAt ?? this.unlockedAt,
    );
  }

  static const List<Map<String, String>> definitions = [
    {'id': 'first_checkin', 'name': 'Primer Paso', 'description': 'Primer check-in', 'icon': 'emoji_events', 'category': 'checkin'},
    {'id': 'writer_5', 'name': 'Escritor Nocturno', 'description': '5 entradas de diario', 'icon': 'edit_note', 'category': 'journal'},
    {'id': 'streak_7', 'name': 'Racha de 7', 'description': '7 días consecutivos', 'icon': 'local_fire_department', 'category': 'checkin'},
    {'id': 'breather_10', 'name': 'Respirador', 'description': '10 herramientas de respiración', 'icon': 'air', 'category': 'tools'},
    {'id': 'talker_10', 'name': 'Voz Interior', 'description': '10 conversaciones con Coach', 'icon': 'chat', 'category': 'chat'},
    {'id': 'connected', 'name': 'Conectado', 'description': 'Primer post en comunidad', 'icon': 'group', 'category': 'community'},
    {'id': 'deep_5', 'name': 'Profundo', 'description': '5 check-ins profundos', 'icon': 'psychology', 'category': 'checkin'},
    {'id': 'streak_30', 'name': 'Constante', 'description': '30 días de racha', 'icon': 'whatshot', 'category': 'checkin'},
    {'id': 'explorer', 'name': 'Explorador', 'description': 'Usaste las 12 herramientas', 'icon': 'explore', 'category': 'tools'},
    {'id': 'routine_10', 'name': 'Rutinario', 'description': '10 rutinas completadas', 'icon': 'repeat', 'category': 'routines'},
    {'id': 'mentor', 'name': 'Mentor', 'description': '50 likes en tus posts', 'icon': 'volunteer_activism', 'category': 'community'},
    {'id': 'resilient', 'name': 'Resiliente', 'description': 'Alcanzaste nivel 5', 'icon': 'shield', 'category': 'milestone'},
    {'id': 'finance_first', 'name': 'Primer Registro', 'description': 'Primera transacción financiera', 'icon': 'account_balance_wallet', 'category': 'finance'},
    {'id': 'finance_10', 'name': 'Control Financiero', 'description': '10 transacciones registradas', 'icon': 'trending_up', 'category': 'finance'},
    {'id': 'receipt_scanner', 'name': 'Scanner Pro', 'description': '5 tickets escaneados', 'icon': 'document_scanner', 'category': 'finance'},
    {'id': 'finance_advisor', 'name': 'Consejo Sabio', 'description': 'Pediste consejo financiero IA', 'icon': 'lightbulb', 'category': 'finance'},
  ];
}

class XpRewards {
  static const int checkin = 20;
  static const int deepCheckin = 35;
  static const int journalEntry = 25;
  static const int chatSession = 15;
  static const int toolCompleted = 30;
  static const int routineCompleted = 40;
  static const int communityPost = 10;
  static const int streakBonus7 = 100;
  static const int transaction = 10;
  static const int accountCreated = 15;
  static const int receiptScan = 20;
}
