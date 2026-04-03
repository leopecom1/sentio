import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sentio_app/config/theme.dart';

class ArticleScreen extends StatelessWidget {
  final String articleId;

  const ArticleScreen({super.key, required this.articleId});

  static const _articles = {
    '1': {
      'title': 'La presión financiera no te define',
      'category': 'Presión financiera',
      'content': '''Cuando emprendés, es fácil confundir tu cuenta bancaria con tu valor como persona. Un mal mes no significa que seas un mal emprendedor. La presión financiera es real, pero no es permanente ni es tu identidad.

Lo que podés hacer:

• Separá el problema financiero del problema emocional. Son dos cosas distintas.

• Escribí los números. Verlos en papel los hace más manejables que tenerlos dando vueltas en la cabeza.

• Recordá que la mayoría de los negocios exitosos pasaron por momentos de escasez.

• Pedí ayuda. Un contador, un mentor, un colega. No tenés que resolverlo solo.''',
      'reflection': '¿Cuándo fue la última vez que separaste tu valor personal de los números de tu negocio?',
    },
    '2': {
      'title': 'El agotamiento no es un premio',
      'category': 'Burnout',
      'content': '''En la cultura emprendedora hay un mito peligroso: que el agotamiento es señal de compromiso. No lo es. El burnout destruye creatividad, relaciones y salud.

Señales de que necesitás parar:

• Te cuesta concentrarte en tareas simples
• Todo te irrita más de lo normal
• Sentís que trabajás mucho pero avanzás poco
• Te desconectás de las cosas que antes disfrutabas
• Tu cuerpo te manda señales: dolor de cabeza, tensión, insomnio

Qué hacer:

• Reconocé que estás agotado. Sin culpa.
• Tomá un descanso real, aunque sea breve.
• Delegá algo esta semana.
• Dormí una hora más hoy.''',
      'reflection': '¿Qué te está costando delegar o soltar esta semana?',
    },
    '3': {
      'title': 'La soledad de emprender',
      'category': 'Soledad',
      'content': '''Emprender puede ser una de las experiencias más solitarias. No porque estés solo físicamente, sino porque pocas personas entienden realmente lo que vivís: la incertidumbre, la presión, las decisiones que solo vos podés tomar.

Esto no significa que algo esté mal con vos. Significa que necesitás encontrar tu tribu: otros emprendedores que entienden.

Mientras tanto:

• Hablar de lo que sentís no es debilidad. Es inteligencia emocional.
• Un mentor o coach puede ser ese espacio de escucha que necesitás.
• Esta app puede ser un refugio diario. Usala.
• Escribir lo que sentís es una forma de acompañarte a vos mismo.''',
      'reflection': '¿Con quién compartiste por última vez cómo te sentís de verdad?',
    },
  };

  @override
  Widget build(BuildContext context) {
    final article = _articles[articleId] ?? _articles['1']!;

    return Scaffold(
      backgroundColor: SentioColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: const Icon(Icons.arrow_back_rounded),
                  ),
                  const Spacer(),
                  Text(
                    article['category']!,
                    style: TextStyle(
                      fontSize: 14,
                      color: SentioColors.secondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    Text(
                      article['title']!,
                      style: GoogleFonts.manrope(
                        fontSize: 28,
                        height: 1.3,
                        color: SentioColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      article['content']!,
                      style: GoogleFonts.manrope(
                        fontSize: 17,
                        height: 1.8,
                        color: SentioColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Reflection question
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: SentioColors.secondary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Para reflexionar',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: SentioColors.secondary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            article['reflection']!,
                            style: GoogleFonts.manrope(
                              fontSize: 18,
                              height: 1.4,
                              color: SentioColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // CTA
                    OutlinedButton.icon(
                      onPressed: () {
                        context.pop();
                        context.push('/journal/new');
                      },
                      icon: const Icon(Icons.edit_rounded, size: 18),
                      label: const Text('¿Querés escribir sobre esto?'),
                    ),
                    const SizedBox(height: 40),
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
