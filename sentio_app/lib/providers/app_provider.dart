import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sentio_app/config/constants.dart';
import 'package:sentio_app/models/profile.dart';
import 'package:sentio_app/models/checkin.dart';
import 'package:sentio_app/models/journal_entry.dart';
import 'package:sentio_app/models/chat_message.dart';
import 'package:sentio_app/models/community_post.dart';
import 'package:sentio_app/models/community_comment.dart';
import 'package:sentio_app/models/community_story.dart';
import 'package:sentio_app/models/community_user.dart';
import 'package:sentio_app/models/gamification.dart';
import 'package:sentio_app/services/notification_service.dart';
import 'package:sentio_app/services/community_service.dart';
import 'package:sentio_app/services/finance_service.dart';
import 'package:sentio_app/services/gamification_service.dart';
import 'package:sentio_app/models/financial_account.dart';
import 'package:sentio_app/models/financial_transaction.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum CelebrationEvent { xpGained, streakMilestone, levelUp, achievementUnlocked }

class CelebrationData {
  final CelebrationEvent event;
  final int? xpAmount;
  final int? streakCount;
  final ResilienceLevel? newLevel;
  final Achievement? achievement;

  const CelebrationData({
    required this.event,
    this.xpAmount,
    this.streakCount,
    this.newLevel,
    this.achievement,
  });
}

class AppProvider extends ChangeNotifier {
  final _supabase = Supabase.instance.client;

  Profile? _profile;
  List<Checkin> _checkins = [];
  List<JournalEntry> _journalEntries = [];
  List<ChatConversation> _conversations = [];
  List<ChatMessage> _currentMessages = [];
  String? _currentConversationId;
  bool _isLoading = false;
  bool _isAuthenticated = false;
  Checkin? _todayCheckin;
  String _dailyPhrase = '';
  List<Map<String, dynamic>> _articles = [];
  List<Map<String, dynamic>> _routines = [];

  // Community
  List<CommunityPost> _communityPosts = [];
  List<CommunityStory> _communityStories = [];
  List<CommunityUser> _communityUsers = [];
  List<CommunityComment> _postComments = [];
  final Set<String> _likedPostIds = {};
  final Set<String> _followedUserIds = {};

  // Finance
  List<FinancialAccount> _financialAccounts = [];
  List<FinancialTransaction> _financialTransactions = [];

  // Gamification
  int _totalXp = 0;
  String _selectedCommunityCategory = 'Todo';
  List<Achievement> _achievements = [];

  // Celebrations queue
  final List<CelebrationData> _pendingCelebrations = [];
  Set<String> _celebratedAchievementIds = {};

  // Getters
  Profile? get profile => _profile;
  List<Checkin> get checkins => _checkins;
  List<JournalEntry> get journalEntries => _journalEntries;
  List<ChatConversation> get conversations => _conversations;
  List<ChatMessage> get currentMessages => _currentMessages;
  String? get currentConversationId => _currentConversationId;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _isAuthenticated;
  Checkin? get todayCheckin => _todayCheckin;
  String get dailyPhrase => _dailyPhrase;
  bool get hasCompletedOnboarding => _profile?.onboardingCompleted ?? false;
  String get userName => _profile?.firstName ?? 'amigo';
  List<Map<String, dynamic>> get articles => _articles;
  List<Map<String, dynamic>> get routines => _routines;
  List<CommunityPost> get communityPosts => _communityPosts;
  List<CommunityStory> get communityStories => _communityStories;
  List<CommunityUser> get communityUsers => _communityUsers;
  List<CommunityComment> get postComments => _postComments;

  // Finance getters
  List<FinancialAccount> get financialAccounts => _financialAccounts;
  List<FinancialTransaction> get financialTransactions => _financialTransactions;

  double get totalBalance {
    return _financialAccounts.fold(0.0, (sum, a) => sum + a.balance);
  }

  double get monthlyExpenses {
    final now = DateTime.now();
    final firstOfMonth = DateTime(now.year, now.month, 1);
    return _financialTransactions
        .where((t) => t.isExpense && !t.transactionDate.isBefore(firstOfMonth))
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double get monthlyIncome {
    final now = DateTime.now();
    final firstOfMonth = DateTime(now.year, now.month, 1);
    return _financialTransactions
        .where((t) => t.isIncome && !t.transactionDate.isBefore(firstOfMonth))
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  // Gamification getters
  int get totalXp => _totalXp;
  ResilienceLevel get resilienceLevel => ResilienceLevel.fromXp(_totalXp);
  List<Achievement> get achievements => _achievements;
  String get selectedCommunityCategory => _selectedCommunityCategory;
  List<CelebrationData> get pendingCelebrations => _pendingCelebrations;

  void consumeCelebration() {
    if (_pendingCelebrations.isNotEmpty) {
      _pendingCelebrations.removeAt(0);
      notifyListeners();
    }
  }

  int get focusScore {
    if (_checkins.isEmpty) return 0;
    final recent = _checkins.take(14).toList();
    if (recent.isEmpty) return 0;
    final avgEnergy = recent.map((c) => c.energyLevel).reduce((a, b) => a + b) / recent.length;
    final avgStress = recent.map((c) => c.stressLevel).reduce((a, b) => a + b) / recent.length;
    final consistency = (_profile?.checkinStreak ?? 0).clamp(0, 14) / 14.0;
    return (((avgEnergy / 5.0) * 40 + ((5 - avgStress) / 5.0) * 30 + consistency * 30) * 100 / 100).round().clamp(0, 100);
  }

  List<double> get weeklyEvolutionEmotional {
    final now = DateTime.now();
    return List.generate(7, (i) {
      final day = now.subtract(Duration(days: 6 - i));
      final dayCheckins = _checkins.where((c) =>
        c.createdAt.year == day.year && c.createdAt.month == day.month && c.createdAt.day == day.day
      ).toList();
      if (dayCheckins.isEmpty) return 0.0;
      return dayCheckins.map((c) => c.energyLevel.toDouble()).reduce((a, b) => a + b) / dayCheckins.length / 5.0;
    });
  }

  void setCommunityCategory(String category) {
    _selectedCommunityCategory = category;
    notifyListeners();
  }

  void _calculateXp() {
    final p = _profile;
    if (p == null) return;
    _totalXp = (p.totalCheckins * XpRewards.checkin) +
        (p.totalJournalEntries * XpRewards.journalEntry) +
        (p.totalToolsUsed * XpRewards.toolCompleted) +
        (p.totalChatMessages ~/ 5 * XpRewards.chatSession) +
        ((p.longestStreak ~/ 7) * XpRewards.streakBonus7);
    _updateAchievements();
  }

  void _addXp(int amount) {
    final oldLevel = ResilienceLevel.fromXp(_totalXp);
    _totalXp += amount;
    final newLevel = ResilienceLevel.fromXp(_totalXp);

    // Enqueue XP celebration
    _pendingCelebrations.add(CelebrationData(
      event: CelebrationEvent.xpGained,
      xpAmount: amount,
    ));

    // Detect level-up
    if (newLevel.level > oldLevel.level) {
      _pendingCelebrations.add(CelebrationData(
        event: CelebrationEvent.levelUp,
        newLevel: newLevel,
      ));
    }

    _updateAchievements();
    notifyListeners();
  }

  void _updateAchievements() {
    final p = _profile;
    if (p == null) return;

    final defs = Achievement.definitions;
    _achievements = defs.map((d) {
      bool unlocked = false;
      switch (d['id']) {
        case 'first_checkin': unlocked = p.totalCheckins >= 1; break;
        case 'writer_5': unlocked = p.totalJournalEntries >= 5; break;
        case 'streak_7': unlocked = p.longestStreak >= 7; break;
        case 'breather_10': unlocked = p.totalToolsUsed >= 10; break;
        case 'talker_10': unlocked = p.totalChatMessages >= 50; break;
        case 'connected': unlocked = _communityPosts.any((post) => post.userId == p.id); break;
        case 'deep_5': unlocked = _checkins.where((c) => c.isDeep).length >= 5; break;
        case 'streak_30': unlocked = p.longestStreak >= 30; break;
        case 'routine_10': unlocked = p.totalToolsUsed >= 20; break;
        case 'resilient': unlocked = resilienceLevel.level >= 5; break;
        case 'finance_first': unlocked = p.totalTransactions >= 1; break;
        case 'finance_10': unlocked = p.totalTransactions >= 10; break;
        case 'receipt_scanner': unlocked = _financialTransactions.where((t) => t.isFromScan).length >= 5; break;
        case 'finance_advisor': break; // unlocked manually when advice is requested
        default: unlocked = false;
      }
      return Achievement(
        id: d['id']!,
        name: d['name']!,
        description: d['description']!,
        iconName: d['icon']!,
        category: d['category']!,
        isUnlocked: unlocked,
      );
    }).toList();

    // Enqueue celebrations only for achievements not yet celebrated
    for (final a in _achievements) {
      if (a.isUnlocked && !_celebratedAchievementIds.contains(a.id)) {
        _pendingCelebrations.add(CelebrationData(
          event: CelebrationEvent.achievementUnlocked,
          achievement: a,
        ));
        _celebratedAchievementIds.add(a.id);
      }
    }
    // Persist celebrated achievements
    SharedPreferences.getInstance().then((prefs) {
      prefs.setStringList('celebrated_achievements', _celebratedAchievementIds.toList());
    });
  }

  void setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  // ============ INIT ============
  Future<void> initialize() async {
    // Load celebrated achievements from local storage
    final prefs = await SharedPreferences.getInstance();
    _celebratedAchievementIds = (prefs.getStringList('celebrated_achievements') ?? []).toSet();

    final session = _supabase.auth.currentSession;
    if (session != null) {
      _isAuthenticated = true;
      try {
        await _loadUserData().timeout(const Duration(seconds: 10));
      } catch (e) {
        debugPrint('User data loading timed out or failed: $e');
      }
    }

    // Load gamification config from server
    await GamificationService.instance.loadConfig();

    // Load community data from Supabase
    await loadCommunityData();

    // Listen for auth state changes
    _supabase.auth.onAuthStateChange.listen((data) async {
      final event = data.event;
      if (event == AuthChangeEvent.signedIn) {
        _isAuthenticated = true;
        await _loadUserData();
        notifyListeners();
      } else if (event == AuthChangeEvent.signedOut) {
        _clearData();
        notifyListeners();
      }
    });
  }

  Future<void> _loadUserData() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    await Future.wait([
      _loadProfile(userId),
      _loadCheckins(userId),
      _loadJournalEntries(userId),
      _loadConversations(userId),
      _loadDailyPhrase(),
      _loadArticles(),
      _loadRoutines(),
      _loadFinancialData(),
    ]);

    _findTodayCheckin();
    _calculateXp();
    notifyListeners();
  }

  Future<void> _loadProfile(String userId) async {
    try {
      final data = await _supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();
      _profile = Profile.fromJson(data);
    } catch (e) {
      debugPrint('Error loading profile: $e');
    }
  }

  Future<void> _loadCheckins(String userId) async {
    try {
      final data = await _supabase
          .from('checkins')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(100);
      _checkins = (data as List).map((e) => Checkin.fromJson(e)).toList();
    } catch (e) {
      debugPrint('Error loading checkins: $e');
    }
  }

  Future<void> _loadJournalEntries(String userId) async {
    try {
      final data = await _supabase
          .from('journal_entries')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(100);
      _journalEntries =
          (data as List).map((e) => JournalEntry.fromJson(e)).toList();
    } catch (e) {
      debugPrint('Error loading journal entries: $e');
    }
  }

  Future<void> _loadConversations(String userId) async {
    try {
      final data = await _supabase
          .from('chat_conversations')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(50);
      _conversations =
          (data as List).map((e) => ChatConversation.fromJson(e)).toList();
    } catch (e) {
      debugPrint('Error loading conversations: $e');
    }
  }

  Future<void> _loadDailyPhrase() async {
    try {
      final data = await _supabase
          .from('daily_phrases')
          .select()
          .eq('is_active', true);
      final phrases = data as List;
      if (phrases.isNotEmpty) {
        final random = phrases[Random().nextInt(phrases.length)];
        _dailyPhrase = random['phrase'] ?? '';
      }
    } catch (e) {
      // Fallback phrase
      _dailyPhrase = 'No necesitás tener todas las respuestas. Solo la siguiente.';
    }
  }

  Future<void> _loadArticles() async {
    try {
      final data = await _supabase
          .from('articles')
          .select()
          .eq('is_published', true)
          .order('sort_order');
      _articles = List<Map<String, dynamic>>.from(data);
    } catch (e) {
      debugPrint('Error loading articles: $e');
    }
  }

  Future<void> _loadRoutines() async {
    try {
      final data = await _supabase
          .from('routines')
          .select()
          .eq('is_published', true)
          .order('sort_order');
      _routines = List<Map<String, dynamic>>.from(data);
    } catch (e) {
      debugPrint('Error loading routines: $e');
    }
  }

  void _findTodayCheckin() {
    final now = DateTime.now();
    try {
      _todayCheckin = _checkins.firstWhere((c) =>
          c.createdAt.year == now.year &&
          c.createdAt.month == now.month &&
          c.createdAt.day == now.day);
    } catch (_) {
      _todayCheckin = null;
    }
  }

  void _clearData() {
    _profile = null;
    _checkins = [];
    _journalEntries = [];
    _conversations = [];
    _currentMessages = [];
    _currentConversationId = null;
    _isAuthenticated = false;
    _todayCheckin = null;
    _dailyPhrase = '';
    _articles = [];
    _routines = [];
    _financialAccounts = [];
    _financialTransactions = [];
    _celebratedAchievementIds = {};
    SharedPreferences.getInstance().then((prefs) {
      prefs.remove('celebrated_achievements');
    });
  }

  // ============ AUTH ============
  Future<void> signUp(String email, String password, String name) async {
    setLoading(true);
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': name},
      );

      if (response.user != null) {
        _isAuthenticated = true;
        await _loadUserData();
      }
    } catch (e) {
      rethrow;
    } finally {
      setLoading(false);
    }
  }

  Future<void> signIn(String email, String password) async {
    setLoading(true);
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        _isAuthenticated = true;
        await _loadUserData();
      }
    } catch (e) {
      rethrow;
    } finally {
      setLoading(false);
    }
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
    _clearData();
    notifyListeners();
  }

  // ============ ONBOARDING ============
  Future<void> completeOnboarding({
    required List<String> pressureTypes,
    required String currentMood,
    required int energy,
    required List<String> goals,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      await _supabase.from('profiles').update({
        'onboarding_completed': true,
        'pressure_types': pressureTypes,
        'current_mood': currentMood,
        'initial_energy': energy,
        'goals': goals,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', userId);

      // Reload profile
      await _loadProfile(userId);
      notifyListeners();
    } catch (e) {
      debugPrint('Error completing onboarding: $e');
      rethrow;
    }
  }

  // ============ CHECK-IN ============
  Future<void> saveCheckin({
    required String emotion,
    required int energy,
    required int stress,
    int? mentalClarity,
    int? motivation,
    int? financialPressure,
    int? control,
    int? dayQuality,
    String? note,
    String? notePrompt,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    final isDeep = mentalClarity != null;
    final isCrisis = stress == 5 && energy == 1;

    try {
      final data = await _supabase.from('checkins').insert({
        'user_id': userId,
        'primary_emotion': emotion,
        'energy_level': energy,
        'stress_level': stress,
        'mental_clarity': mentalClarity,
        'motivation_level': motivation,
        'financial_pressure': financialPressure,
        'control_feeling': control,
        'day_quality': dayQuality,
        'note': note,
        'note_prompt': notePrompt,
        'is_deep': isDeep,
        'is_crisis': isCrisis,
      }).select().single();

      final checkin = Checkin.fromJson(data);
      _checkins.insert(0, checkin);
      _todayCheckin = checkin;

      // Reload profile to get updated streak/counts
      await _loadProfile(userId);
      _addXp(isDeep ? XpRewards.deepCheckin : XpRewards.checkin);

      // Cancel today's streak danger notification
      NotificationService.instance.cancelTodayStreakDanger();

      // Detect streak milestones
      final streak = _profile?.checkinStreak ?? 0;
      const milestones = [7, 14, 30, 60, 100];
      if (milestones.contains(streak)) {
        _pendingCelebrations.add(CelebrationData(
          event: CelebrationEvent.streakMilestone,
          streakCount: streak,
        ));
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error saving checkin: $e');
      rethrow;
    }
  }

  bool get hasCheckedInToday {
    if (_checkins.isEmpty) return false;
    final now = DateTime.now();
    return _checkins.any((c) =>
        c.createdAt.year == now.year &&
        c.createdAt.month == now.month &&
        c.createdAt.day == now.day);
  }

  // ============ JOURNAL ============
  Future<bool> saveJournalEntry({
    required String content,
    String? prompt,
    String? emotion,
    List<String>? tags,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      debugPrint('saveJournalEntry: no authenticated user');
      return false;
    }

    try {
      final data = await _supabase.from('journal_entries').insert({
        'user_id': userId,
        'content': content,
        'prompt_used': prompt,
        'dominant_emotion': emotion,
        'tags': tags ?? [],
        'word_count': content.split(' ').length,
      }).select().single();

      final entry = JournalEntry.fromJson(data);
      _journalEntries.insert(0, entry);

      // Reload profile to get updated count
      await _loadProfile(userId);
      _addXp(XpRewards.journalEntry);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error saving journal entry: $e');
      return false;
    }
  }

  // ============ CHAT ============
  Future<void> startNewConversation() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      final data = await _supabase.from('chat_conversations').insert({
        'user_id': userId,
        'initial_emotion': _todayCheckin?.primaryEmotion,
      }).select().single();

      final conv = ChatConversation.fromJson(data);
      _conversations.insert(0, conv);
      _currentConversationId = conv.id;
      _currentMessages = [];

      // Welcome message
      final welcomeContent = _getWelcomeMessage();
      final welcomeData = await _supabase.from('chat_messages').insert({
        'conversation_id': conv.id,
        'user_id': userId,
        'role': 'assistant',
        'content': welcomeContent,
      }).select().single();

      _currentMessages.add(ChatMessage.fromJson(welcomeData));
      notifyListeners();
    } catch (e) {
      debugPrint('Error starting conversation: $e');
      rethrow;
    }
  }

  Future<void> loadConversationMessages(String conversationId) async {
    try {
      final data = await _supabase
          .from('chat_messages')
          .select()
          .eq('conversation_id', conversationId)
          .order('created_at');
      _currentMessages =
          (data as List).map((e) => ChatMessage.fromJson(e)).toList();
      _currentConversationId = conversationId;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading messages: $e');
    }
  }

  Future<void> sendMessage(String content) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    if (_currentConversationId == null) await startNewConversation();

    try {
      // Save user message
      final userMsgData = await _supabase.from('chat_messages').insert({
        'conversation_id': _currentConversationId,
        'user_id': userId,
        'role': 'user',
        'content': content,
      }).select().single();

      _currentMessages.add(ChatMessage.fromJson(userMsgData));
      notifyListeners();

      // Generate AI response via OpenAI
      final responseContent = await _getOpenAIResponse(content);

      final assistantMsgData = await _supabase.from('chat_messages').insert({
        'conversation_id': _currentConversationId,
        'user_id': userId,
        'role': 'assistant',
        'content': responseContent,
      }).select().single();

      _currentMessages.add(ChatMessage.fromJson(assistantMsgData));

      // Update conversation message count
      await _supabase.from('chat_conversations').update({
        'message_count': _currentMessages.length,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', _currentConversationId!);

      notifyListeners();
    } catch (e) {
      debugPrint('Error sending message: $e');
      rethrow;
    }
  }

  String _getWelcomeMessage() {
    final name = userName;
    if (_todayCheckin != null) {
      return 'Hola, $name. Vi que hoy registraste cómo te sentís. ¿Querés contarme más sobre eso?';
    }
    return 'Hola, $name. ¿Cómo estás hoy? Contame lo que necesites, estoy acá para escucharte.';
  }

  Future<String> _getOpenAIResponse(String userMessage) async {
    try {
      // Build conversation history for context
      final messages = <Map<String, String>>[
        {
          'role': 'system',
          'content': 'Sos un terapeuta emocional empático especializado en emprendedores. '
              'Tu nombre es Sentio. Hablás en español rioplatense (vos, querés, sentís). '
              'Sos cálido, genuino y directo. No das consejos genéricos. '
              'Validás emociones antes de sugerir acciones. '
              'Tus respuestas son concisas (2-4 oraciones máximo). '
              'Nunca decís "como IA" ni rompés el personaje.',
        },
      ];

      // Add recent conversation history (last 10 messages)
      final recentMessages = _currentMessages.length > 10
          ? _currentMessages.sublist(_currentMessages.length - 10)
          : _currentMessages;
      for (final msg in recentMessages) {
        messages.add({
          'role': msg.role == 'user' ? 'user' : 'assistant',
          'content': msg.content,
        });
      }

      // Add the current message
      messages.add({'role': 'user', 'content': userMessage});

      final response = await http.post(
        Uri.parse('https://api.openai.com/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${SentioConstants.openaiApiKey}',
        },
        body: jsonEncode({
          'model': 'gpt-4o-mini',
          'messages': messages,
          'max_tokens': 300,
          'temperature': 0.8,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'] as String;
      } else {
        debugPrint('OpenAI error: ${response.statusCode} - ${response.body}');
        return _getFallbackResponse(userMessage);
      }
    } catch (e) {
      debugPrint('OpenAI request failed: $e');
      return _getFallbackResponse(userMessage);
    }
  }

  String _getFallbackResponse(String userMessage) {
    final lower = userMessage.toLowerCase();
    if (lower.contains('estres') || lower.contains('presion') || lower.contains('presión')) {
      return 'Parece que estás cargando bastante presión. ¿Querés que hagamos una pausa juntos? A veces 2 minutos de respiración pueden cambiar cómo te sentís.';
    }
    if (lower.contains('cansado') || lower.contains('agotado')) {
      return 'El agotamiento es una señal importante. No es debilidad, es información. ¿Cuándo fue la última vez que te tomaste un descanso real?';
    }
    if (lower.contains('miedo') || lower.contains('fracaso')) {
      return 'El miedo al fracaso es algo que casi todos los emprendedores sienten. Lo importante es que lo estés reconociendo. ¿Qué te preocupa concretamente?';
    }
    return 'Gracias por compartir eso conmigo. Lo que sentís es válido. ¿Querés que profundicemos un poco más?';
  }

  // ============ TOOL USAGE ============
  Future<void> saveToolUsage({
    required String toolId,
    required String toolCategory,
    int? durationSeconds,
    bool completed = false,
    String? emotionBefore,
    int? stressBefore,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      await _supabase.from('tool_usage').insert({
        'user_id': userId,
        'tool_id': toolId,
        'tool_category': toolCategory,
        'duration_seconds': durationSeconds,
        'completed': completed,
        'emotion_before': emotionBefore,
        'stress_before': stressBefore,
      });

      // Update total tools used
      await _supabase.from('profiles').update({
        'total_tools_used': (_profile?.totalToolsUsed ?? 0) + 1,
        'last_active_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', userId);

      await _loadProfile(userId);
      _addXp(XpRewards.toolCompleted);
    } catch (e) {
      debugPrint('Error saving tool usage: $e');
    }
  }

  // ============ ROUTINE COMPLETIONS ============
  Future<void> saveRoutineCompletion({
    required String routineId,
    required int completedSteps,
    required int totalSteps,
    required bool completed,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      await _supabase.from('routine_completions').insert({
        'user_id': userId,
        'routine_id': routineId,
        'completed_steps': completedSteps,
        'total_steps': totalSteps,
        'completed': completed,
      });
    } catch (e) {
      debugPrint('Error saving routine completion: $e');
    }
  }

  // ============ FAVORITES ============
  Future<void> toggleFavoriteTool(String toolId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      // Check if already favorited
      final existing = await _supabase
          .from('favorite_tools')
          .select()
          .eq('user_id', userId)
          .eq('tool_id', toolId);

      if ((existing as List).isNotEmpty) {
        await _supabase
            .from('favorite_tools')
            .delete()
            .eq('user_id', userId)
            .eq('tool_id', toolId);
      } else {
        await _supabase.from('favorite_tools').insert({
          'user_id': userId,
          'tool_id': toolId,
        });
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error toggling favorite: $e');
    }
  }

  Future<bool> isToolFavorite(String toolId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return false;

    try {
      final data = await _supabase
          .from('favorite_tools')
          .select()
          .eq('user_id', userId)
          .eq('tool_id', toolId);
      return (data as List).isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // ============ PROFILE UPDATE ============
  Future<void> updateProfile({
    String? fullName,
    String? preferredCompanionStyle,
    bool? morningReminder,
    bool? eveningReminder,
    String? theme,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    final updates = <String, dynamic>{
      'updated_at': DateTime.now().toIso8601String(),
    };
    if (fullName != null) updates['full_name'] = fullName;
    if (preferredCompanionStyle != null) {
      updates['preferred_companion_style'] = preferredCompanionStyle;
    }
    if (morningReminder != null) updates['morning_reminder'] = morningReminder;
    if (eveningReminder != null) updates['evening_reminder'] = eveningReminder;
    if (theme != null) updates['theme'] = theme;

    try {
      await _supabase.from('profiles').update(updates).eq('id', userId);
      await _loadProfile(userId);
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating profile: $e');
      rethrow;
    }
  }

  // ============ INSIGHTS ============
  Map<String, int> get emotionCounts {
    final counts = <String, int>{};
    for (final checkin in _checkins) {
      counts[checkin.primaryEmotion] =
          (counts[checkin.primaryEmotion] ?? 0) + 1;
    }
    return counts;
  }

  double get averageStress {
    if (_checkins.isEmpty) return 0;
    return _checkins.map((c) => c.stressLevel).reduce((a, b) => a + b) /
        _checkins.length;
  }

  double get averageEnergy {
    if (_checkins.isEmpty) return 0;
    return _checkins.map((c) => c.energyLevel).reduce((a, b) => a + b) /
        _checkins.length;
  }

  List<Checkin> get thisWeekCheckins {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    return _checkins.where((c) => c.createdAt.isAfter(weekStart)).toList();
  }

  List<Checkin> get lastMonthCheckins {
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
    return _checkins.where((c) => c.createdAt.isAfter(thirtyDaysAgo)).toList();
  }

  // ============ FINANCE ============

  final _financeService = FinanceService.instance;

  Future<void> _loadFinancialData() async {
    try {
      await Future.wait([
        _loadFinancialAccounts(),
        _loadFinancialTransactions(),
      ]);
    } catch (e) {
      debugPrint('Error loading financial data: $e');
    }
  }

  Future<void> _loadFinancialAccounts() async {
    _financialAccounts = await _financeService.loadAccounts();
  }

  Future<void> _loadFinancialTransactions() async {
    _financialTransactions = await _financeService.loadTransactions();
  }

  Future<void> refreshFinancialData() async {
    await _loadFinancialData();
    notifyListeners();
  }

  Future<FinancialAccount?> createFinancialAccount({
    required String name,
    required String accountType,
    String currency = 'ARS',
    double initialBalance = 0,
    String? color,
  }) async {
    final account = await _financeService.createAccount(
      name: name,
      accountType: accountType,
      currency: currency,
      initialBalance: initialBalance,
      color: color,
    );
    if (account != null) {
      _financialAccounts.add(account);
      _addXp(XpRewards.accountCreated);
      notifyListeners();
    }
    return account;
  }

  Future<bool> deleteFinancialAccount(String accountId) async {
    final ok = await _financeService.deleteAccount(accountId);
    if (ok) {
      _financialAccounts.removeWhere((a) => a.id == accountId);
      notifyListeners();
    }
    return ok;
  }

  Future<FinancialTransaction?> createFinancialTransaction({
    required String accountId,
    required String type,
    required double amount,
    required String category,
    String? description,
    String? receiptImageUrl,
    bool isFromScan = false,
    DateTime? transactionDate,
    String currency = 'ARS',
  }) async {
    final tx = await _financeService.createTransaction(
      accountId: accountId,
      type: type,
      amount: amount,
      category: category,
      description: description,
      receiptImageUrl: receiptImageUrl,
      isFromScan: isFromScan,
      emotionalContext: _todayCheckin?.primaryEmotion,
      transactionDate: transactionDate,
      currency: currency,
    );
    if (tx != null) {
      _financialTransactions.insert(0, tx);
      // Refresh accounts to get updated balance from trigger
      await _loadFinancialAccounts();
      _addXp(isFromScan ? XpRewards.receiptScan : XpRewards.transaction);
      notifyListeners();
    }
    return tx;
  }

  Future<bool> deleteFinancialTransaction(String transactionId) async {
    final ok = await _financeService.deleteTransaction(transactionId);
    if (ok) {
      _financialTransactions.removeWhere((t) => t.id == transactionId);
      await _loadFinancialAccounts();
      notifyListeners();
    }
    return ok;
  }

  Future<Map<String, dynamic>?> scanReceipt(dynamic imageBytes) async {
    return _financeService.scanReceipt(imageBytes);
  }

  Future<String> getFinancialAdvice() async {
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
    final recentTx = _financialTransactions
        .where((t) => !t.transactionDate.isBefore(thirtyDaysAgo))
        .toList();

    // Get financial pressure from recent deep check-ins
    int? financialPressure;
    String? emotionalContext;
    if (_checkins.isNotEmpty) {
      emotionalContext = _checkins.first.primaryEmotion;
      final deepCheckins = _checkins.where((c) => c.isDeep).toList();
      if (deepCheckins.isNotEmpty) {
        financialPressure = deepCheckins.first.financialPressure;
      }
    }

    return _financeService.getFinancialAdvice(
      transactions: recentTx,
      emotionalContext: emotionalContext,
      financialPressure: financialPressure,
    );
  }

  // ============ COMMUNITY ============

  final _communityService = CommunityService.instance;

  Future<void> loadCommunityData() async {
    await Future.wait([
      _loadCommunityPosts(),
      _loadCommunityStories(),
    ]);
    notifyListeners();
  }

  Future<void> _loadCommunityPosts({String? category}) async {
    try {
      _communityPosts = await _communityService.loadPosts(
        category: category ?? _selectedCommunityCategory,
      );
    } catch (e) {
      debugPrint('Error loading community posts: $e');
    }
  }

  Future<void> _loadCommunityStories() async {
    try {
      _communityStories = await _communityService.loadStories();
    } catch (e) {
      debugPrint('Error loading stories: $e');
    }
  }

  Future<void> refreshCommunityPosts({String? category, bool append = false}) async {
    if (!append) {
      _communityPosts = await _communityService.loadPosts(
        category: category ?? _selectedCommunityCategory,
      );
    } else {
      final more = await _communityService.loadPosts(
        category: category ?? _selectedCommunityCategory,
        offset: _communityPosts.length,
      );
      _communityPosts.addAll(more);
    }
    notifyListeners();
  }

  Future<void> togglePostLike(String postId) async {
    // Optimistic update
    final index = _communityPosts.indexWhere((p) => p.id == postId);
    if (index == -1) return;

    final post = _communityPosts[index];
    final wasLiked = post.isLikedByMe;

    _communityPosts[index] = post.copyWith(
      isLikedByMe: !wasLiked,
      likesCount: wasLiked ? post.likesCount - 1 : post.likesCount + 1,
    );
    notifyListeners();

    // Server call
    await _communityService.toggleLike(postId);
  }

  Future<void> toggleFollowUser(String userId) async {
    // Optimistic update
    final index = _communityUsers.indexWhere((u) => u.id == userId);
    if (index != -1) {
      final user = _communityUsers[index];
      final wasFollowed = _followedUserIds.contains(userId);

      if (wasFollowed) {
        _followedUserIds.remove(userId);
        _communityUsers[index] = user.copyWith(
          isFollowedByMe: false,
          followersCount: user.followersCount - 1,
        );
      } else {
        _followedUserIds.add(userId);
        _communityUsers[index] = user.copyWith(
          isFollowedByMe: true,
          followersCount: user.followersCount + 1,
        );
      }
      notifyListeners();
    }

    // Server call
    await _communityService.toggleFollow(userId);
  }

  Future<List<CommunityComment>> getCommentsForPost(String postId) async {
    return _communityService.loadComments(postId);
  }

  Future<void> addCommentToPost(String postId, String content) async {
    final comment = await _communityService.addComment(postId, content);
    if (comment != null) {
      // Update post comment count locally
      final index = _communityPosts.indexWhere((p) => p.id == postId);
      if (index != -1) {
        final post = _communityPosts[index];
        _communityPosts[index] = post.copyWith(
          commentsCount: post.commentsCount + 1,
        );
      }
      notifyListeners();
    }
  }

  Future<void> createCommunityPost(String content, {List<String>? imageUrls, String? emotion, String? category}) async {
    final post = await _communityService.createPost(
      content: content,
      imageUrls: imageUrls,
      emotion: emotion,
      category: category,
    );
    if (post != null) {
      _communityPosts.insert(0, post);
      notifyListeners();
    }
  }

  Future<CommunityUser?> getCommunityUser(String userId) async {
    // Check cache first
    try {
      return _communityUsers.firstWhere((u) => u.id == userId);
    } catch (_) {
      // Load from server
      final user = await _communityService.loadUserProfile(userId);
      if (user != null) {
        _communityUsers.add(user);
      }
      return user;
    }
  }

  Future<List<CommunityPost>> getPostsByUser(String userId) async {
    return _communityService.loadPostsByUser(userId);
  }

  Future<void> createCommunityStory(String textOverlay, {String? imageUrl}) async {
    final story = await _communityService.createStory(textOverlay: textOverlay, imageUrl: imageUrl);
    if (story != null) {
      _communityStories.insert(0, story);
      notifyListeners();
    }
  }

  void markStoryViewed(String storyId) {
    final index = _communityStories.indexWhere((s) => s.id == storyId);
    if (index == -1) return;
    _communityStories[index] = _communityStories[index].copyWith(isViewed: true);
    notifyListeners();
  }
}
