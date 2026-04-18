import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sentio_app/config/theme.dart';
import 'package:sentio_app/services/youtube_service.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class MaterialsScreen extends StatefulWidget {
  const MaterialsScreen({super.key});

  @override
  State<MaterialsScreen> createState() => _MaterialsScreenState();
}

class _MaterialsScreenState extends State<MaterialsScreen> {
  List<YoutubeVideo>? _videos;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final videos = await YoutubeService.instance.fetchEntrevistas();
      if (!mounted) return;
      setState(() {
        _videos = videos;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'No se pudieron cargar los videos. Reintentá.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SentioColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: SentioColors.border),
                      ),
                      child: const Icon(
                        Icons.arrow_back_rounded,
                        color: SentioColors.textPrimary,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Materiales y Entrevistas',
                          style: GoogleFonts.manrope(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: SentioColors.textPrimary,
                            letterSpacing: -0.5,
                          ),
                        ),
                        Text(
                          '@mateosilveramentor',
                          style: GoogleFonts.manrope(
                            fontSize: 12,
                            color: SentioColors.textTertiary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _loading
                  ? _buildLoading()
                  : _error != null
                      ? _buildError()
                      : (_videos == null || _videos!.isEmpty)
                          ? _buildEmpty()
                          : RefreshIndicator(
                              onRefresh: _load,
                              color: SentioColors.accent,
                              child: ListView.builder(
                                physics: const BouncingScrollPhysics(),
                                padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
                                itemCount: _videos!.length,
                                itemBuilder: (context, i) => _VideoCard(video: _videos![i]),
                              ),
                            ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: SentioColors.accent),
          SizedBox(height: 16),
          Text(
            'Cargando entrevistas...',
            style: TextStyle(color: SentioColors.textSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off_rounded, size: 48, color: SentioColors.textTertiary),
            const SizedBox(height: 12),
            Text(
              _error ?? '',
              style: GoogleFonts.manrope(
                fontSize: 14,
                color: SentioColors.textSecondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _load,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.videocam_off_rounded, size: 48, color: SentioColors.textTertiary),
            const SizedBox(height: 12),
            Text(
              'Aún no hay entrevistas disponibles.',
              style: GoogleFonts.manrope(
                fontSize: 14,
                color: SentioColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════
// VIDEO CARD (thumbnail + title + description)
// ══════════════════════════════════════

class _VideoCard extends StatelessWidget {
  final YoutubeVideo video;
  const _VideoCard({required this.video});

  void _open(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => _VideoPlayerScreen(video: video),
      fullscreenDialog: true,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: GestureDetector(
        onTap: () => _open(context),
        child: Container(
          decoration: BoxDecoration(
            color: SentioColors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: SentioColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thumbnail with play overlay
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CachedNetworkImage(
                        imageUrl: video.thumbnailUrl,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(color: SentioColors.card),
                        errorWidget: (_, __, ___) => Container(
                          color: SentioColors.card,
                          child: const Icon(Icons.broken_image_rounded, color: SentioColors.textTertiary),
                        ),
                      ),
                      // Gradient overlay for play button contrast
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withValues(alpha: 0.3),
                              ],
                            ),
                          ),
                        ),
                      ),
                      // Play button
                      Center(
                        child: Container(
                          width: 54,
                          height: 54,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.black.withValues(alpha: 0.5),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.9), width: 2),
                          ),
                          child: const Icon(
                            Icons.play_arrow_rounded,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                      ),
                      // Duration badge
                      if (video.duration != null)
                        Positioned(
                          bottom: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.8),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              video.duration!,
                              style: GoogleFonts.manrope(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              // Info
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      video.title,
                      style: GoogleFonts.manrope(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: SentioColors.textPrimary,
                        height: 1.35,
                        letterSpacing: -0.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (video.description.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        video.description,
                        style: GoogleFonts.manrope(
                          fontSize: 13,
                          color: SentioColors.textSecondary,
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (video.publishedTimeText != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.calendar_today_rounded, size: 11, color: SentioColors.textTertiary),
                          const SizedBox(width: 5),
                          Text(
                            video.publishedTimeText!,
                            style: GoogleFonts.manrope(
                              fontSize: 11,
                              color: SentioColors.textTertiary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════
// VIDEO PLAYER SCREEN (embedded YouTube)
// ══════════════════════════════════════

class _VideoPlayerScreen extends StatefulWidget {
  final YoutubeVideo video;
  const _VideoPlayerScreen({required this.video});

  @override
  State<_VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<_VideoPlayerScreen> {
  late YoutubePlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = YoutubePlayerController(
      initialVideoId: widget.video.id,
      flags: const YoutubePlayerFlags(
        autoPlay: true,
        mute: false,
        enableCaption: true,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return YoutubePlayerBuilder(
      player: YoutubePlayer(
        controller: _controller,
        showVideoProgressIndicator: true,
        progressIndicatorColor: SentioColors.accent,
        progressColors: const ProgressBarColors(
          playedColor: SentioColors.accent,
          handleColor: SentioColors.accent,
        ),
      ),
      builder: (context, player) => Scaffold(
        backgroundColor: SentioColors.background,
        appBar: AppBar(
          backgroundColor: SentioColors.background,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close_rounded, color: SentioColors.textPrimary),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(
            widget.video.title,
            style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w700, color: SentioColors.textPrimary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        body: Column(
          children: [
            player,
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.video.title,
                      style: GoogleFonts.manrope(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: SentioColors.textPrimary,
                        letterSpacing: -0.3,
                        height: 1.3,
                      ),
                    ),
                    if (widget.video.publishedTimeText != null) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.calendar_today_rounded, size: 12, color: SentioColors.textTertiary),
                          const SizedBox(width: 5),
                          Text(
                            widget.video.publishedTimeText!,
                            style: GoogleFonts.manrope(fontSize: 12, color: SentioColors.textTertiary),
                          ),
                        ],
                      ),
                    ],
                    if (widget.video.description.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const Divider(color: SentioColors.divider),
                      const SizedBox(height: 16),
                      Text(
                        widget.video.description,
                        style: GoogleFonts.manrope(
                          fontSize: 13,
                          color: SentioColors.textSecondary,
                          height: 1.6,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
