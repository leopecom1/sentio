import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
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

enum _LayerType { image, text, sticker }

class _StickerDef {
  final IconData icon;
  final Color color;
  const _StickerDef(this.icon, this.color);
}

class _Layer {
  final String id;
  final _LayerType type;
  Offset pos; // Top-left position
  double scale;
  double rotation;
  // Type-specific
  File? file;
  IconData? stickerIcon;
  Color? stickerColor;
  TextEditingController? textCtrl;
  FocusNode? focus;
  Color textColor;
  TextAlign align;

  _Layer({
    required this.id,
    required this.type,
    required this.pos,
    this.scale = 1.0,
    this.rotation = 0.0,
    this.file,
    this.stickerIcon,
    this.stickerColor,
    this.textCtrl,
    this.focus,
    this.textColor = Colors.white,
    this.align = TextAlign.center,
  });
}

class _CreateStoryScreenState extends State<CreateStoryScreen> {
  final _boundaryKey = GlobalKey();
  final List<_Layer> _layers = [];
  int? _activeIndex;
  bool _editingText = false;
  bool _publishing = false;
  int _selectedGradient = 0;
  int _layerIdCounter = 0;

  // Gesture base (captured at scale start)
  double _baseLayerScale = 1.0;
  double _baseLayerRotation = 0.0;

  // Canvas size (measured in build)
  Size _canvasSize = Size.zero;

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

  static const List<Color> _textColors = [
    Colors.white,
    Color(0xFF00FFBD),
    Color(0xFF3030FF),
    Color(0xFFFFB800),
    Color(0xFFFF6B9D),
    Color(0xFF000000),
  ];

  static const List<_StickerDef> _stickers = [
    _StickerDef(Icons.favorite_rounded, Color(0xFFFF3B5C)),
    _StickerDef(Icons.local_fire_department_rounded, Color(0xFFFF6B35)),
    _StickerDef(Icons.auto_awesome_rounded, Color(0xFFFFD700)),
    _StickerDef(Icons.bolt_rounded, Color(0xFFFFC400)),
    _StickerDef(Icons.star_rounded, Color(0xFFFFC107)),
    _StickerDef(Icons.rocket_launch_rounded, Color(0xFF3030FF)),
    _StickerDef(Icons.celebration_rounded, Color(0xFFFF6B9D)),
    _StickerDef(Icons.emoji_events_rounded, Color(0xFFFFD700)),
    _StickerDef(Icons.thumb_up_rounded, Color(0xFF00FFBD)),
    _StickerDef(Icons.mood_rounded, Color(0xFFFFB800)),
    _StickerDef(Icons.psychology_rounded, Color(0xFFC084FC)),
    _StickerDef(Icons.lightbulb_rounded, Color(0xFFFBBF24)),
    _StickerDef(Icons.check_circle_rounded, Color(0xFF00FFBD)),
    _StickerDef(Icons.verified_rounded, Color(0xFF3030FF)),
    _StickerDef(Icons.coffee_rounded, Color(0xFF8B4513)),
    _StickerDef(Icons.wb_sunny_rounded, Color(0xFFFFC400)),
    _StickerDef(Icons.nightlight_rounded, Color(0xFFA5B4FC)),
    _StickerDef(Icons.water_drop_rounded, Color(0xFF38BDF8)),
    _StickerDef(Icons.self_improvement_rounded, Color(0xFFC084FC)),
    _StickerDef(Icons.spa_rounded, Color(0xFF34D399)),
    _StickerDef(Icons.flag_rounded, Color(0xFFFF3B5C)),
    _StickerDef(Icons.emoji_objects_rounded, Color(0xFFFBBF24)),
    _StickerDef(Icons.visibility_rounded, Color(0xFF38BDF8)),
    _StickerDef(Icons.front_hand_rounded, Color(0xFFFFB088)),
  ];

  @override
  void dispose() {
    for (final l in _layers) {
      l.textCtrl?.dispose();
      l.focus?.dispose();
    }
    super.dispose();
  }

  String _newId() => 'l${_layerIdCounter++}';

  Offset _centerOf(Size layerSize) {
    // Fallback to a visible area if canvas hasn't been measured yet
    final w = _canvasSize.width > 0 ? _canvasSize.width : 360;
    final h = _canvasSize.height > 0 ? _canvasSize.height : 640;
    return Offset(w / 2 - layerSize.width / 2, h / 2 - layerSize.height / 2);
  }

  Future<void> _addImageLayer(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: source,
      maxWidth: 1600,
      imageQuality: 88,
    );
    if (picked == null) return;
    const defaultSize = Size(240, 240);
    setState(() {
      _layers.add(_Layer(
        id: _newId(),
        type: _LayerType.image,
        pos: _centerOf(defaultSize),
        file: File(picked.path),
      ));
      _activeIndex = _layers.length - 1;
    });
  }

  void _addTextLayer() {
    const defaultSize = Size(280, 80);
    final layer = _Layer(
      id: _newId(),
      type: _LayerType.text,
      pos: _centerOf(defaultSize),
      textCtrl: TextEditingController(),
      focus: FocusNode(),
    );
    setState(() {
      _layers.add(layer);
      _activeIndex = _layers.length - 1;
      _editingText = true;
    });
    Future.delayed(const Duration(milliseconds: 80), () {
      if (mounted) layer.focus?.requestFocus();
    });
  }

  void _addStickerLayer(_StickerDef def) {
    const defaultSize = Size(96, 96);
    setState(() {
      _layers.add(_Layer(
        id: _newId(),
        type: _LayerType.sticker,
        pos: _centerOf(defaultSize),
        stickerIcon: def.icon,
        stickerColor: def.color,
      ));
      _activeIndex = _layers.length - 1;
    });
  }

  void _deleteActive() {
    if (_activeIndex == null) return;
    final i = _activeIndex!;
    final layer = _layers[i];
    layer.textCtrl?.dispose();
    layer.focus?.dispose();
    HapticFeedback.mediumImpact();
    setState(() {
      _layers.removeAt(i);
      _activeIndex = null;
      _editingText = false;
    });
  }

  void _bringToFront(int index) {
    if (index == _layers.length - 1) return;
    final l = _layers.removeAt(index);
    _layers.add(l);
    _activeIndex = _layers.length - 1;
  }

  void _showImageSourceSheet() {
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: SentioColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded, color: SentioColors.textPrimary),
              title: Text('Tomar foto', style: GoogleFonts.manrope(color: SentioColors.textPrimary)),
              onTap: () {
                Navigator.pop(ctx);
                _addImageLayer(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded, color: SentioColors.textPrimary),
              title: Text('Elegir de galería', style: GoogleFonts.manrope(color: SentioColors.textPrimary)),
              onTap: () {
                Navigator.pop(ctx);
                _addImageLayer(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showEmojiPicker() {
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: SentioColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Agregá un sticker',
                style: GoogleFonts.manrope(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: SentioColors.textPrimary,
                ),
              ),
              const SizedBox(height: 14),
              GridView.builder(
                shrinkWrap: true,
                itemCount: _stickers.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                ),
                itemBuilder: (_, i) {
                  final s = _stickers[i];
                  return InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () {
                      Navigator.pop(ctx);
                      _addStickerLayer(s);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: s.color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: s.color.withValues(alpha: 0.3)),
                      ),
                      child: Center(
                        child: Icon(s.icon, color: s.color, size: 32),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<Uint8List?> _capturePng() async {
    try {
      final boundary = _boundaryKey.currentContext!.findRenderObject()
          as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 2.5);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      return data?.buffer.asUint8List();
    } catch (_) {
      return null;
    }
  }

  Future<void> _publish() async {
    if (_publishing) return;
    final provider = context.read<AppProvider>();
    final userId = provider.profile?.id;
    if (userId == null) return;

    setState(() {
      _publishing = true;
      _activeIndex = null;
      _editingText = false;
    });
    for (final l in _layers) {
      l.focus?.unfocus();
    }

    final allText = _layers
        .where((l) => l.type == _LayerType.text)
        .map((l) => l.textCtrl?.text.trim() ?? '')
        .where((t) => t.isNotEmpty)
        .join('\n');

    try {
      String? imageUrl;
      if (_layers.isNotEmpty) {
        // Wait 2 frames for selection border etc to hide before capturing
        await WidgetsBinding.instance.endOfFrame;
        await Future.delayed(const Duration(milliseconds: 80));
        final bytes = await _capturePng();
        debugPrint('story capture: ${bytes?.lengthInBytes ?? 0} bytes');
        if (bytes != null) {
          final fileName = 'story_${DateTime.now().millisecondsSinceEpoch}.png';
          imageUrl = await CommunityService.instance.uploadImage(fileName, bytes);
          debugPrint('story upload url: $imageUrl');
        }
      }
      final story = await CommunityService.instance.createStory(
        textOverlay: allText,
        imageUrl: imageUrl,
      );
      debugPrint('story created: ${story?.id}');

      if (story == null) {
        throw Exception('No se pudo crear la historia');
      }

      await provider.loadCommunityData();
      if (!mounted) return;

      // Always navigate explicitly back to community feed
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/community');
      }
    } catch (e) {
      debugPrint('story publish error: $e');
      if (!mounted) return;
      setState(() => _publishing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo publicar: $e'),
          backgroundColor: SentioColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final active = _activeIndex != null ? _layers[_activeIndex!] : null;

    return Scaffold(
      backgroundColor: Colors.black,
      resizeToAvoidBottomInset: false,
      body: LayoutBuilder(
        builder: (context, constraints) {
          _canvasSize = Size(constraints.maxWidth, constraints.maxHeight);
          return Stack(
            fit: StackFit.expand,
            children: [
              // Capture-able canvas
              RepaintBoundary(
                key: _boundaryKey,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Gradient background (catches taps to deselect)
                    Positioned.fill(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          setState(() {
                            _activeIndex = null;
                            _editingText = false;
                          });
                          for (final l in _layers) {
                            l.focus?.unfocus();
                          }
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: _gradients[_selectedGradient],
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Layers
                    for (int i = 0; i < _layers.length; i++) _buildLayer(i),
                  ],
                ),
              ),

              // Top bar
              Positioned(
                top: media.padding.top + 8,
                left: 16,
                right: 16,
                child: Row(
                  children: [
                    _roundBtn(icon: Icons.close_rounded, onTap: () => context.pop()),
                    const Spacer(),
                    if (_activeIndex != null) ...[
                      _roundBtn(
                        icon: Icons.delete_outline_rounded,
                        onTap: _deleteActive,
                        color: Colors.red.withValues(alpha: 0.45),
                      ),
                      const SizedBox(width: 10),
                    ],
                    GestureDetector(
                      onTap: _layers.isNotEmpty && !_publishing ? _publish : null,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 10),
                        decoration: BoxDecoration(
                          color: _layers.isNotEmpty
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: _publishing
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.black),
                              )
                            : Text(
                                'Publicar',
                                style: GoogleFonts.manrope(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: _layers.isNotEmpty
                                      ? Colors.black
                                      : Colors.white.withValues(alpha: 0.5),
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),

              // Side tool rail (hidden while editing text)
              if (!_editingText)
                Positioned(
                  right: 14,
                  top: media.padding.top + 72,
                  child: Column(
                    children: [
                      _toolBtn(icon: Icons.image_rounded, onTap: _showImageSourceSheet),
                      const SizedBox(height: 10),
                      _toolBtn(
                          icon: Icons.text_fields_rounded, onTap: _addTextLayer),
                      const SizedBox(height: 10),
                      _toolBtn(
                          icon: Icons.emoji_emotions_rounded,
                          onTap: _showEmojiPicker),
                      if (active != null && active.type == _LayerType.text) ...[
                        const SizedBox(height: 10),
                        _toolBtn(
                          icon: Icons.format_align_center_rounded,
                          onTap: () {
                            setState(() {
                              active.align = active.align == TextAlign.center
                                  ? TextAlign.left
                                  : active.align == TextAlign.left
                                      ? TextAlign.right
                                      : TextAlign.center;
                            });
                          },
                        ),
                      ],
                      if (active != null) ...[
                        const SizedBox(height: 10),
                        _toolBtn(
                          icon: Icons.flip_to_front_rounded,
                          onTap: () => setState(() => _bringToFront(_activeIndex!)),
                        ),
                      ],
                    ],
                  ),
                ),

              // Bottom controls
              if (!_editingText)
                Positioned(
                  bottom: media.padding.bottom + 16,
                  left: 0,
                  right: 0,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (active != null && active.type == _LayerType.text)
                        _buildColorPicker(active)
                      else
                        _buildGradientPicker(),
                    ],
                  ),
                ),

              // Done button when editing text
              if (_editingText)
                Positioned(
                  bottom: media.viewInsets.bottom + 12,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    color: Colors.black.withValues(alpha: 0.4),
                    child: Center(
                      child: TextButton(
                        onPressed: () {
                          setState(() => _editingText = false);
                          active?.focus?.unfocus();
                        },
                        child: Text(
                          'Listo',
                          style: GoogleFonts.manrope(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLayer(int index) {
    final layer = _layers[index];
    final isActive = _activeIndex == index;
    final content = _buildLayerContent(layer, isActive);

    return Positioned(
      left: layer.pos.dx,
      top: layer.pos.dy,
      child: GestureDetector(
        behavior: HitTestBehavior.deferToChild,
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() {
            _activeIndex = index;
            if (layer.type == _LayerType.text && !_editingText) {
              _editingText = true;
              Future.delayed(const Duration(milliseconds: 40), () {
                if (mounted) layer.focus?.requestFocus();
              });
            }
          });
        },
        onScaleStart: (d) {
          _baseLayerScale = layer.scale;
          _baseLayerRotation = layer.rotation;
          setState(() => _activeIndex = index);
        },
        onScaleUpdate: (d) {
          setState(() {
            // Accumulate movement frame by frame
            layer.pos = layer.pos + d.focalPointDelta;
            if (d.scale != 1.0) {
              layer.scale = (_baseLayerScale * d.scale).clamp(0.3, 6.0);
            }
            if (d.pointerCount >= 2) {
              layer.rotation = _baseLayerRotation + d.rotation;
            }
          });
        },
        child: Transform.rotate(
          angle: layer.rotation,
          child: Transform.scale(
            scale: layer.scale,
            alignment: Alignment.center,
            child: Container(
              decoration: isActive
                  ? BoxDecoration(
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.6),
                        width: 1.2,
                      ),
                      borderRadius: BorderRadius.circular(6),
                    )
                  : null,
              padding: const EdgeInsets.all(4),
              child: content,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLayerContent(_Layer layer, bool isActive) {
    switch (layer.type) {
      case _LayerType.image:
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.file(
            layer.file!,
            width: 240,
            fit: BoxFit.contain,
          ),
        );
      case _LayerType.sticker:
        final icon = layer.stickerIcon ?? Icons.star_rounded;
        final color = layer.stickerColor ?? Colors.white;
        return SizedBox(
          width: 96,
          height: 96,
          child: Center(
            child: Icon(
              icon,
              size: 84,
              color: color,
              shadows: [
                Shadow(
                  blurRadius: 18,
                  color: color.withValues(alpha: 0.55),
                ),
                const Shadow(
                  blurRadius: 8,
                  color: Colors.black26,
                ),
              ],
            ),
          ),
        );
      case _LayerType.text:
        final style = GoogleFonts.manrope(
          fontSize: 28,
          fontWeight: FontWeight.w800,
          color: layer.textColor,
          height: 1.2,
          shadows: layer.textColor == Colors.black
              ? null
              : const [Shadow(blurRadius: 12, color: Colors.black38)],
        );
        final showEditor = isActive && _editingText;
        return ConstrainedBox(
          constraints: BoxConstraints(maxWidth: _canvasSize.width - 48),
          child: IntrinsicWidth(
            child: showEditor
                ? TextField(
                    controller: layer.textCtrl,
                    focusNode: layer.focus,
                    autofocus: true,
                    maxLines: null,
                    textAlign: layer.align,
                    style: style,
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: 'Escribí algo...',
                      hintStyle: style.copyWith(
                        color: Colors.white.withValues(alpha: 0.4),
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                    onChanged: (_) => setState(() {}),
                  )
                : Text(
                    layer.textCtrl?.text.isEmpty ?? true
                        ? 'Tocá para editar'
                        : layer.textCtrl!.text,
                    style: (layer.textCtrl?.text.isEmpty ?? true)
                        ? style.copyWith(
                            color: Colors.white.withValues(alpha: 0.5))
                        : style,
                    textAlign: layer.align,
                  ),
          ),
        );
    }
  }

  Widget _roundBtn({
    required IconData icon,
    required VoidCallback onTap,
    Color? color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color ?? Colors.black.withValues(alpha: 0.3),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }

  Widget _toolBtn({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.black.withValues(alpha: 0.45),
          border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
        ),
        child: Icon(icon, color: Colors.white, size: 22),
      ),
    );
  }

  Widget _buildGradientPicker() {
    return SizedBox(
      height: 44,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _gradients.length,
        itemBuilder: (context, index) {
          final isSelected = _selectedGradient == index;
          return GestureDetector(
            onTap: () => setState(() => _selectedGradient = index),
            child: Container(
              width: 36,
              height: 36,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(colors: _gradients[index]),
                border: Border.all(
                  color: isSelected ? Colors.white : Colors.transparent,
                  width: 2.5,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildColorPicker(_Layer layer) {
    return SizedBox(
      height: 40,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: _textColors.map((c) {
          final isSelected = layer.textColor == c;
          return GestureDetector(
            onTap: () => setState(() => layer.textColor = c),
            child: Container(
              width: 32,
              height: 32,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: c,
                border: Border.all(
                  color: isSelected
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.15),
                  width: isSelected ? 2.5 : 1.5,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
