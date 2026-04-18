import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:sentio_app/config/theme.dart';
import 'package:sentio_app/providers/app_provider.dart';
import 'package:sentio_app/models/community_story.dart';

class StoryViewerScreen extends StatefulWidget {
  final String userId;
  const StoryViewerScreen({super.key, required this.userId});

  @override
  State<StoryViewerScreen> createState() => _StoryViewerScreenState();
}

class _StoryViewerScreenState extends State<StoryViewerScreen> with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  late AnimationController _progressController;
  Timer? _autoAdvanceTimer;
  bool _isNavigating = false;
  late List<CommunityStory> _userStories;

  static const List<List<Color>> _storyGradients = [
    [Color(0xFF1a1a2e), Color(0xFF16213e), Color(0xFF0f3460)],
    [Color(0xFF2d1b69), Color(0xFF11998e), Color(0xFF38ef7d)],
    [Color(0xFF0f0c29), Color(0xFF302b63), Color(0xFF24243e)],
    [Color(0xFF200122), Color(0xFF6f0000), Color(0xFF200122)],
    [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
  ];

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    );
    final provider = context.read<AppProvider>();
    _userStories = provider.communityStories
        .where((s) => s.userId == widget.userId)
        .toList();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startProgress();
    });
  }

  void _startProgress() {
    if (!mounted || _isNavigating) return;
    final provider = context.read<AppProvider>();
    if (_currentIndex < _userStories.length) {
      provider.markStoryViewed(_userStories[_currentIndex].id);
    }

    _progressController.reset();
    _progressController.forward();
    _autoAdvanceTimer?.cancel();
    _autoAdvanceTimer = Timer(const Duration(seconds: 5), _nextStory);
  }

  void _close() {
    if (_isNavigating || !mounted) return;
    _isNavigating = true;
    _autoAdvanceTimer?.cancel();
    _progressController.stop();
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  void _nextStory() {
    if (!mounted || _isNavigating) return;
    if (_currentIndex < _userStories.length - 1) {
      setState(() => _currentIndex++);
      _startProgress();
    } else {
      _close();
    }
  }

  void _prevStory() {
    if (!mounted || _isNavigating) return;
    if (_currentIndex > 0) {
      setState(() => _currentIndex--);
      _startProgress();
    }
  }

  @override
  void dispose() {
    _progressController.dispose();
    _autoAdvanceTimer?.cancel();
    super.dispose();
  }

  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${diff.inDays}d';
  }

  @override
  Widget build(BuildContext context) {
    if (_userStories.isEmpty || _currentIndex >= _userStories.length) {
      return const Scaffold(backgroundColor: Colors.black);
    }

    final story = _userStories[_currentIndex];

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTapDown: (details) {
          final width = MediaQuery.of(context).size.width;
          if (details.globalPosition.dx < width / 3) {
            _prevStory();
          } else {
            _nextStory();
          }
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Gradient background
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: _storyGradients[_currentIndex % _storyGradients.length],
                ),
              ),
            ),
            // Network image on top
            if (story.imageUrl.isNotEmpty)
              CachedNetworkImage(
                imageUrl: story.imageUrl,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                placeholder: (_, __) => const SizedBox.shrink(),
                errorWidget: (_, __, ___) => const SizedBox.shrink(),
              ),
            // Gradient overlay top
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.center,
                  colors: [
                    Colors.black.withValues(alpha: 0.7),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            // Gradient overlay bottom
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.center,
                  colors: [
                    Colors.black.withValues(alpha: 0.5),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            // Progress bars (one per user story)
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              left: 16,
              right: 16,
              child: Row(
                children: List.generate(_userStories.length, (i) {
                  return Expanded(
                    child: Container(
                      height: 3,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      child: i < _currentIndex
                          ? Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            )
                          : i == _currentIndex
                              ? AnimatedBuilder(
                                  animation: _progressController,
                                  builder: (_, __) => ClipRRect(
                                    borderRadius: BorderRadius.circular(2),
                                    child: LinearProgressIndicator(
                                      value: _progressController.value,
                                      backgroundColor: Colors.white.withValues(alpha: 0.3),
                                      valueColor: const AlwaysStoppedAnimation(Colors.white),
                                      minHeight: 3,
                                    ),
                                  ),
                                )
                              : Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.3),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                    ),
                  );
                }),
              ),
            ),
            // Header
            Positioned(
              top: MediaQuery.of(context).padding.top + 20,
              left: 16,
              right: 16,
              child: Row(
                children: [
                  ClipOval(
                    child: Container(
                      width: 36,
                      height: 36,
                      color: Colors.white.withValues(alpha: 0.2),
                      child: story.userAvatar != null
                          ? CachedNetworkImage(imageUrl: story.userAvatar!, fit: BoxFit.cover, errorWidget: (_, __, ___) => Center(child: Text(story.userName[0], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))))
                          : Center(child: Text(story.userName[0], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(story.userName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                  const SizedBox(width: 8),
                  Text(_timeAgo(story.createdAt), style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 13)),
                  const Spacer(),
                  GestureDetector(
                    onTap: _close,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.2)),
                      child: Icon(Icons.close_rounded, color: Colors.white.withValues(alpha: 0.9), size: 18),
                    ),
                  ),
                ],
              ),
            ),
            // Text overlay
            if (story.textOverlay != null && story.textOverlay!.isNotEmpty)
              Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 32),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    story.textOverlay!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
