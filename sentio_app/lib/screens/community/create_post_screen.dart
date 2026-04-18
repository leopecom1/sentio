import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:sentio_app/config/theme.dart';
import 'package:sentio_app/config/constants.dart';
import 'package:sentio_app/providers/app_provider.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _controller = TextEditingController();
  String? _selectedEmotion;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _publish() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final provider = context.read<AppProvider>();
    await provider.createCommunityPost(text, emotion: _selectedEmotion);
    // Reload so the feed shows the new post
    provider.loadCommunityData();
    if (mounted) context.go('/community');
  }

  @override
  Widget build(BuildContext context) {
    final canPublish = _controller.text.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: SentioColors.background,
      appBar: AppBar(
        backgroundColor: SentioColors.background,
        leading: TextButton(
          onPressed: () => context.pop(),
          child: const Text('Cancelar', style: TextStyle(color: SentioColors.textSecondary, fontSize: 14)),
        ),
        leadingWidth: 90,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: GestureDetector(
              onTap: canPublish ? _publish : null,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                decoration: BoxDecoration(
                  color: canPublish ? SentioColors.primary : SentioColors.primary.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text('Publicar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Text input
            Expanded(
              child: TextField(
                controller: _controller,
                maxLines: null,
                autofocus: true,
                textCapitalization: TextCapitalization.sentences,
                style: const TextStyle(fontSize: 18, height: 1.5, color: SentioColors.textPrimary),
                decoration: InputDecoration(
                  hintText: '¿Qué estás pensando?',
                  border: InputBorder.none,
                  filled: false,
                  hintStyle: TextStyle(fontSize: 18, color: SentioColors.textTertiary),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
            // Emotion selector
            const Text('¿Cómo te sentís?', style: TextStyle(fontSize: 13, color: SentioColors.textSecondary)),
            const SizedBox(height: 8),
            SizedBox(
              height: 40,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: SentioConstants.emotions.length,
                itemBuilder: (context, index) {
                  final emotion = SentioConstants.emotions[index];
                  final isSelected = _selectedEmotion == emotion['id'];
                  return GestureDetector(
                    onTap: () => setState(() {
                      _selectedEmotion = isSelected ? null : emotion['id'];
                    }),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? Color(emotion['color']).withValues(alpha: 0.2) : SentioColors.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? Color(emotion['color']) : SentioColors.divider,
                        ),
                      ),
                      child: Text(
                        '${emotion['emoji']} ${emotion['label']}',
                        style: TextStyle(
                          fontSize: 12,
                          color: isSelected ? Color(emotion['color']) : SentioColors.textSecondary,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
