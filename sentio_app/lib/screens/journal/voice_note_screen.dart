import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:record/record.dart';
import 'package:sentio_app/config/theme.dart';
import 'package:sentio_app/providers/app_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Grabar una nota de voz para el Diario. Graba (AAC mono, liviano),
/// permite escuchar la prueba, y guarda. Duración máxima configurable
/// desde el admin (app_config.voice_note_max_seconds).
class VoiceNoteScreen extends StatefulWidget {
  const VoiceNoteScreen({super.key});

  @override
  State<VoiceNoteScreen> createState() => _VoiceNoteScreenState();
}

enum _Phase { idle, recording, recorded, saving }

class _VoiceNoteScreenState extends State<VoiceNoteScreen> {
  final _rec = AudioRecorder();
  final _player = AudioPlayer();
  Timer? _timer;

  _Phase _phase = _Phase.idle;
  int _elapsed = 0; // segundos grabados
  int _maxSeconds = 180;
  String? _filePath;
  bool _playing = false;

  @override
  void initState() {
    super.initState();
    _loadMax();
    _player.onPlayerComplete.listen((_) {
      if (mounted) setState(() => _playing = false);
    });
  }

  Future<void> _loadMax() async {
    try {
      final row = await Supabase.instance.client
          .from('app_config')
          .select('value')
          .eq('key', 'voice_note_max_seconds')
          .maybeSingle();
      final v = int.tryParse((row?['value'] as String?)?.trim() ?? '');
      if (v != null && v > 0 && mounted) setState(() => _maxSeconds = v);
    } catch (_) {/* default 180 */}
  }

  @override
  void dispose() {
    _timer?.cancel();
    _rec.dispose();
    _player.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    if (!await _rec.hasPermission()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Necesitamos permiso al micrófono para grabar.')));
      }
      return;
    }
    final dir = await getTemporaryDirectory();
    final path =
        '${dir.path}/vn_${DateTime.now().millisecondsSinceEpoch}.m4a';
    await _rec.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        numChannels: 1,
        bitRate: 32000,
        sampleRate: 44100,
      ),
      path: path,
    );
    setState(() {
      _phase = _Phase.recording;
      _elapsed = 0;
      _filePath = path;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _elapsed++);
      if (_elapsed >= _maxSeconds) _stop();
    });
  }

  Future<void> _stop() async {
    _timer?.cancel();
    final path = await _rec.stop();
    setState(() {
      _phase = _Phase.recorded;
      if (path != null) _filePath = path;
    });
  }

  Future<void> _togglePlay() async {
    if (_filePath == null) return;
    if (_playing) {
      await _player.pause();
      setState(() => _playing = false);
    } else {
      await _player.play(DeviceFileSource(_filePath!));
      setState(() => _playing = true);
    }
  }

  Future<void> _discard() async {
    await _player.stop();
    setState(() {
      _phase = _Phase.idle;
      _elapsed = 0;
      _filePath = null;
      _playing = false;
    });
  }

  Future<void> _save() async {
    if (_filePath == null) return;
    setState(() => _phase = _Phase.saving);
    final ok = await context
        .read<AppProvider>()
        .saveVoiceNote(localFilePath: _filePath!, durationSeconds: _elapsed);
    if (!mounted) return;
    if (ok) {
      context.pop();
    } else {
      setState(() => _phase = _Phase.recorded);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('No se pudo guardar la nota. Probá de nuevo.')));
    }
  }

  String _fmt(int s) =>
      '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SentioColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: SentioColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text('Nota de voz',
            style: GoogleFonts.manrope(
                fontSize: 18, fontWeight: FontWeight.w700, color: SentioColors.textPrimary)),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              // Contador
              Text(_fmt(_elapsed),
                  style: GoogleFonts.manrope(
                      fontSize: 56, fontWeight: FontWeight.w800, color: SentioColors.textPrimary)),
              const SizedBox(height: 4),
              Text(
                  _phase == _Phase.recording
                      ? 'Grabando… (máx ${_fmt(_maxSeconds)})'
                      : _phase == _Phase.recorded
                          ? 'Escuchá tu nota antes de guardar'
                          : 'Tocá para grabar (máx ${_fmt(_maxSeconds)})',
                  style: GoogleFonts.manrope(fontSize: 14, color: SentioColors.textSecondary)),
              const Spacer(),

              if (_phase == _Phase.recorded) ...[
                // Reproducir prueba
                _CircleButton(
                  icon: _playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  color: SentioColors.primary,
                  size: 72,
                  onTap: _togglePlay,
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _TextAction(icon: Icons.replay_rounded, label: 'Rehacer', onTap: _discard),
                    _TextAction(
                      icon: Icons.check_rounded,
                      label: 'Guardar',
                      primary: true,
                      onTap: _save,
                    ),
                  ],
                ),
              ] else
                // Botón grabar / detener
                _CircleButton(
                  icon: _phase == _Phase.recording ? Icons.stop_rounded : Icons.mic_rounded,
                  color: _phase == _Phase.recording ? SentioColors.error : SentioColors.primary,
                  size: 92,
                  pulsing: _phase == _Phase.recording,
                  onTap: _phase == _Phase.recording ? _stop : _start,
                ),

              const Spacer(),
              if (_phase == _Phase.saving)
                const Padding(
                  padding: EdgeInsets.only(bottom: 16),
                  child: CircularProgressIndicator(),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;
  final bool pulsing;
  final VoidCallback onTap;
  const _CircleButton({
    required this.icon,
    required this.color,
    required this.size,
    this.pulsing = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          boxShadow: [
            BoxShadow(
                color: color.withValues(alpha: pulsing ? 0.5 : 0.3),
                blurRadius: pulsing ? 28 : 16,
                spreadRadius: pulsing ? 4 : 0),
          ],
        ),
        child: Icon(icon, color: Colors.white, size: size * 0.44),
      ),
    );
  }
}

class _TextAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool primary;
  final VoidCallback onTap;
  const _TextAction({
    required this.icon,
    required this.label,
    this.primary = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = primary ? SentioColors.accent : SentioColors.textSecondary;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.12),
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(height: 8),
          Text(label,
              style: GoogleFonts.manrope(
                  fontSize: 13, fontWeight: FontWeight.w600, color: SentioColors.textPrimary)),
        ],
      ),
    );
  }
}
