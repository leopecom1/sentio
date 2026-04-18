import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:sentio_app/config/theme.dart';
import 'package:sentio_app/providers/app_provider.dart';
import 'package:sentio_app/services/community_service.dart';

class CreateStoryScreen extends StatefulWidget {
  const CreateStoryScreen({super.key});

  @override
  State<CreateStoryScreen> createState() => _CreateStoryScreenState();
}

class _CreateStoryScreenState extends State<CreateStoryScreen> {
  final _controller = TextEditingController();
  int _selectedGradient = 0;
  bool _publishing = false;
  File? _selectedImage;
  Uint8List? _imageBytes;

  static const List<List<Color>> _gradients = [
    [Color(0xFF1a1a2e), Color(0xFF16213e), Color(0xFF0f3460)],
    [Color(0xFF2d1b69), Color(0xFF11998e), Color(0xFF38ef7d)],
    [Color(0xFF0f0c29), Color(0xFF302b63), Color(0xFF24243e)],
    [Color(0xFF200122), Color(0xFF6f0000), Color(0xFF200122)],
    [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
    [Color(0xFF3D5A80), Color(0xFF7B9E87), Color(0xFFC9A96E)],
    [Color(0xFF833AB4), Color(0xFFFF6B6B), Color(0xFFFCB045)],
    [Color(0xFF0D324D), Color(0xFF7F5A83), Color(0xFFA188A6)],
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: source,
      maxWidth: 1080,
      imageQuality: 85,
    );
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    setState(() {
      _selectedImage = File(picked.path);
      _imageBytes = bytes;
    });
  }

  void _showImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: SentioColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt_rounded, color: Colors.white),
                title: Text('Cámara', style: GoogleFonts.manrope(color: Colors.white)),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_rounded, color: Colors.white),
                title: Text('Galería', style: GoogleFonts.manrope(color: Colors.white)),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _publish() async {
    final text = _controller.text.trim();
    final hasImage = _imageBytes != null;
    if (text.isEmpty && !hasImage) return;
    if (_publishing) return;

    setState(() => _publishing = true);
    final provider = context.read<AppProvider>();

    String? imageUrl;
    if (_imageBytes != null) {
      final fileName = 'story_${DateTime.now().millisecondsSinceEpoch}.jpg';
      imageUrl = await CommunityService.instance.uploadImage(fileName, _imageBytes!);
    }

    await provider.createCommunityStory(
      text.isNotEmpty ? text : '',
      imageUrl: imageUrl,
    );
    provider.loadCommunityData();
    if (mounted) context.go('/community');
  }

  @override
  Widget build(BuildContext context) {
    final hasContent = _controller.text.trim().isNotEmpty || _selectedImage != null;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background: image or gradient
          if (_selectedImage != null)
            Image.file(
              _selectedImage!,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
            )
          else
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: _gradients[_selectedGradient],
                ),
              ),
            ),

          // Dark overlay when image is selected (for text readability)
          if (_selectedImage != null)
            Container(color: Colors.black.withValues(alpha: 0.3)),

          // Text input centered
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: TextField(
                controller: _controller,
                autofocus: _selectedImage == null,
                maxLines: null,
                textAlign: TextAlign.center,
                style: GoogleFonts.manrope(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  height: 1.4,
                  shadows: _selectedImage != null
                      ? [const Shadow(blurRadius: 8, color: Colors.black)]
                      : null,
                ),
                decoration: InputDecoration(
                  hintText: 'Escribí tu historia...',
                  hintStyle: GoogleFonts.manrope(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Colors.white.withValues(alpha: 0.4),
                  ),
                  border: InputBorder.none,
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
          ),

          // Top bar
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 16,
            right: 16,
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => context.pop(),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black.withValues(alpha: 0.3),
                    ),
                    child: const Icon(Icons.close_rounded, color: Colors.white, size: 22),
                  ),
                ),
                const Spacer(),
                Text(
                  'Tu historia',
                  style: GoogleFonts.manrope(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: hasContent ? _publish : null,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                    decoration: BoxDecoration(
                      color: hasContent
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: _publishing
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                          )
                        : Text(
                            'Publicar',
                            style: GoogleFonts.manrope(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: hasContent
                                  ? Colors.black
                                  : Colors.white.withValues(alpha: 0.5),
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),

          // Bottom controls: image button + gradient selector
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 20,
            left: 0,
            right: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Image action row
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: _showImageSourceSheet,
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.black.withValues(alpha: 0.4),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.3),
                              width: 1.5,
                            ),
                          ),
                          child: const Icon(Icons.image_rounded, color: Colors.white, size: 22),
                        ),
                      ),
                      if (_selectedImage != null) ...[
                        const SizedBox(width: 10),
                        GestureDetector(
                          onTap: () => setState(() {
                            _selectedImage = null;
                            _imageBytes = null;
                          }),
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.red.withValues(alpha: 0.4),
                              border: Border.all(
                                color: Colors.red.withValues(alpha: 0.5),
                                width: 1.5,
                              ),
                            ),
                            child: const Icon(Icons.delete_rounded, color: Colors.white, size: 22),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // Gradient selector (hidden when image is selected)
                if (_selectedImage == null)
                  SizedBox(
                    height: 48,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: _gradients.length,
                      itemBuilder: (context, index) {
                        final isSelected = _selectedGradient == index;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedGradient = index),
                          child: Container(
                            width: 40,
                            height: 40,
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: _gradients[index],
                              ),
                              border: Border.all(
                                color: isSelected ? Colors.white : Colors.transparent,
                                width: 2.5,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
