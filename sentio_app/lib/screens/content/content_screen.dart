import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sentio_app/config/theme.dart';

class ContentScreen extends StatelessWidget {
  const ContentScreen({super.key});

  static const _articles = [
    {
      'id': '1',
      'title': 'La presión financiera no te define',
      'subtitle': 'Cómo separar tu valor personal de tus números',
      'category': 'Presión financiera',
      'time': '3 min',
      'color': 0xFFC9A96E,
    },
    {
      'id': '2',
      'title': 'El agotamiento no es un premio',
      'subtitle': 'Por qué trabajar hasta caer no es productividad',
      'category': 'Burnout',
      'time': '3 min',
      'color': 0xFFD4856A,
    },
    {
      'id': '3',
      'title': 'La soledad de emprender',
      'subtitle': 'Por qué te sentís solo aunque estés rodeado de gente',
      'category': 'Soledad',
      'time': '3 min',
      'color': 0xFF8B9DC3,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SentioColors.background,
      appBar: AppBar(
        title: Text(
          'Biblioteca',
          style: GoogleFonts.manrope(fontSize: 24),
        ),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(24),
        itemCount: _articles.length,
        separatorBuilder: (_, __) => const SizedBox(height: 14),
        itemBuilder: (context, index) {
          final article = _articles[index];
          final color = Color(article['color'] as int);

          return GestureDetector(
            onTap: () => context.push('/article/${article['id']}'),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: SentioColors.surface,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.article_outlined,
                      color: color,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          article['category'] as String,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: color,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          article['title'] as String,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          article['subtitle'] as String,
                          style: TextStyle(
                            fontSize: 13,
                            color: SentioColors.textTertiary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${article['time']} de lectura',
                          style: TextStyle(
                            fontSize: 11,
                            color: SentioColors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: SentioColors.textTertiary,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
