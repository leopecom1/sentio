import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class YoutubeVideo {
  final String id;
  final String title;
  final String description;
  final String thumbnailUrl;
  final String? duration;
  final String? publishedTimeText;

  const YoutubeVideo({
    required this.id,
    required this.title,
    required this.description,
    required this.thumbnailUrl,
    this.duration,
    this.publishedTimeText,
  });

  String get watchUrl => 'https://www.youtube.com/watch?v=$id';
}

class YoutubeService {
  YoutubeService._();
  static final YoutubeService instance = YoutubeService._();

  static const String _channelHandle = 'mateosilveramentor';
  List<YoutubeVideo>? _cache;
  DateTime? _cacheTime;

  /// Fetch videos from channel search, filtering by keyword.
  /// Uses YouTube's internal search endpoint (no API key needed).
  Future<List<YoutubeVideo>> fetchEntrevistas() async {
    // Cache for 15 minutes
    if (_cache != null &&
        _cacheTime != null &&
        DateTime.now().difference(_cacheTime!).inMinutes < 15) {
      return _cache!;
    }

    try {
      final url = Uri.parse(
        'https://www.youtube.com/@$_channelHandle/search?query=entrevista',
      );
      final response = await http.get(
        url,
        headers: {
          'User-Agent': 'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15',
          'Accept-Language': 'es-AR,es;q=0.9,en;q=0.8',
        },
      );

      if (response.statusCode != 200) {
        debugPrint('YouTube fetch failed: ${response.statusCode}');
        return _cache ?? [];
      }

      final videos = _parseVideosFromHtml(response.body);
      // Filter titles that contain "entrevista" (case-insensitive)
      final filtered = videos.where((v) => v.title.toLowerCase().contains('entrevista')).toList();

      _cache = filtered;
      _cacheTime = DateTime.now();
      return filtered;
    } catch (e) {
      debugPrint('YouTube fetch error: $e');
      return _cache ?? [];
    }
  }

  /// Extract video data from the YouTube channel page HTML.
  /// YouTube embeds a big JSON blob in `var ytInitialData = {...};`
  List<YoutubeVideo> _parseVideosFromHtml(String html) {
    final videos = <YoutubeVideo>[];

    // Find the ytInitialData JSON blob
    final match = RegExp(r'var ytInitialData = ({.+?});</script>').firstMatch(html);
    if (match == null) return videos;

    try {
      final data = jsonDecode(match.group(1)!) as Map<String, dynamic>;

      // Recursively walk the tree to find videoRenderer objects
      _walkForVideos(data, videos);
    } catch (e) {
      debugPrint('YouTube JSON parse error: $e');
    }

    // Dedupe by ID
    final seen = <String>{};
    return videos.where((v) => seen.add(v.id)).toList();
  }

  void _walkForVideos(dynamic node, List<YoutubeVideo> out) {
    if (node is Map) {
      if (node['videoRenderer'] != null) {
        final vr = node['videoRenderer'] as Map<String, dynamic>;
        final video = _parseVideoRenderer(vr);
        if (video != null) out.add(video);
      }
      for (final v in node.values) {
        _walkForVideos(v, out);
      }
    } else if (node is List) {
      for (final item in node) {
        _walkForVideos(item, out);
      }
    }
  }

  YoutubeVideo? _parseVideoRenderer(Map<String, dynamic> vr) {
    try {
      final id = vr['videoId'] as String?;
      if (id == null) return null;

      final title = _extractRunsText(vr['title']);
      final description = _extractRunsText(vr['descriptionSnippet']) ?? '';
      final thumbnails = vr['thumbnail']?['thumbnails'] as List?;
      final thumbnail = thumbnails != null && thumbnails.isNotEmpty
          ? thumbnails.last['url'] as String? ?? 'https://i.ytimg.com/vi/$id/hqdefault.jpg'
          : 'https://i.ytimg.com/vi/$id/hqdefault.jpg';
      final duration = _extractRunsText(vr['lengthText']);
      final published = _extractRunsText(vr['publishedTimeText']);

      return YoutubeVideo(
        id: id,
        title: title ?? '',
        description: description,
        thumbnailUrl: thumbnail,
        duration: duration,
        publishedTimeText: published,
      );
    } catch (e) {
      return null;
    }
  }

  String? _extractRunsText(dynamic field) {
    if (field == null) return null;
    if (field is Map) {
      if (field['simpleText'] != null) return field['simpleText'].toString();
      if (field['runs'] is List) {
        final runs = field['runs'] as List;
        return runs.map((r) => r['text'] ?? '').join('');
      }
    }
    return null;
  }
}
