import 'package:flutter/material.dart';

class SentioConstants {
  static const String appName = 'B2Better';
  static const String tagline = 'Tu espacio para sentir, entender y avanzar.';

  // Supabase — se inyectan en build via --dart-define-from-file=env.json
  // (ya no se commitean secretos en el código fuente).
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://b2better.api.kodevant.space',
  );
  static const String supabaseAnonKey =
      String.fromEnvironment('SUPABASE_ANON_KEY');

  // OpenAI — la clave ya NO vive en la app. Las llamadas pasan por la función
  // `ai_proxy` en Supabase (la clave está en Vault, del lado del servidor).

  // Emotions
  static const List<Map<String, dynamic>> emotions = [
    {'id': 'calm', 'label': 'Tranquilo', 'emoji': '😌', 'color': 0xFF7B9E87},
    {'id': 'focused', 'label': 'Enfocado', 'emoji': '🎯', 'color': 0xFF3D5A80},
    {'id': 'motivated', 'label': 'Motivado', 'emoji': '🔥', 'color': 0xFFC9A96E},
    {'id': 'grateful', 'label': 'Agradecido', 'emoji': '🙏', 'color': 0xFF9B8EC4},
    {'id': 'hopeful', 'label': 'Esperanzado', 'emoji': '✨', 'color': 0xFF6DB3C4},
    {'id': 'tired', 'label': 'Cansado', 'emoji': '💤', 'color': 0xFF8E8E93},
    {'id': 'overwhelmed', 'label': 'Abrumado', 'emoji': '😰', 'color': 0xFFD4A574},
    {'id': 'anxious', 'label': 'Ansioso', 'emoji': '😟', 'color': 0xFFD4856A},
    {'id': 'frustrated', 'label': 'Frustrado', 'emoji': '😤', 'color': 0xFFC75B5B},
    {'id': 'sad', 'label': 'Triste', 'emoji': '😔', 'color': 0xFF7A8BA8},
    {'id': 'insecure', 'label': 'Inseguro', 'emoji': '😣', 'color': 0xFFB8A9C9},
    {'id': 'lonely', 'label': 'Solo', 'emoji': '🫂', 'color': 0xFF8B9DC3},
    {'id': 'pressured', 'label': 'Presionado', 'emoji': '⚡', 'color': 0xFFCC8B6E},
    {'id': 'angry', 'label': 'Enojado', 'emoji': '😠', 'color': 0xFFBF4E4E},
    {'id': 'blocked', 'label': 'Bloqueado', 'emoji': '🚫', 'color': 0xFF6B7280},
  ];

  /// Get Material Icon for an emotion (guaranteed to render)
  static IconData getEmotionIcon(String emotionId) {
    switch (emotionId) {
      case 'calm': return Icons.self_improvement_rounded;
      case 'focused': return Icons.center_focus_strong_rounded;
      case 'motivated': return Icons.local_fire_department_rounded;
      case 'grateful': return Icons.favorite_rounded;
      case 'hopeful': return Icons.auto_awesome_rounded;
      case 'tired': return Icons.bedtime_rounded;
      case 'overwhelmed': return Icons.waves_rounded;
      case 'anxious': return Icons.speed_rounded;
      case 'frustrated': return Icons.mood_bad_rounded;
      case 'sad': return Icons.sentiment_dissatisfied_rounded;
      case 'insecure': return Icons.shield_outlined;
      case 'lonely': return Icons.person_outline_rounded;
      case 'pressured': return Icons.bolt_rounded;
      case 'angry': return Icons.whatshot_rounded;
      case 'blocked': return Icons.block_rounded;
      default: return Icons.circle_outlined;
    }
  }

  // Community categories
  static const List<String> communityCategories = [
    'Todo', 'Mentalidad', 'Ventas', 'Finanzas', 'Hábitos', 'Tech',
  ];

  // Trigger tags for check-in
  static const List<String> triggerTags = [
    'Trabajo', 'Finanzas', 'Equipo', 'Clientes',
    'Salud', 'Familia', 'Soledad', 'Decisiones',
  ];

  // Pressure types for onboarding
  static const List<Map<String, String>> pressureTypes = [
    {'id': 'financial', 'label': 'Presión financiera'},
    {'id': 'burnout', 'label': 'Agotamiento mental'},
    {'id': 'loneliness', 'label': 'Soledad de emprender'},
    {'id': 'fear', 'label': 'Miedo al fracaso'},
    {'id': 'decisions', 'label': 'Sobrecarga de decisiones'},
    {'id': 'disconnect', 'label': 'Dificultad para desconectar'},
    {'id': 'frustration', 'label': 'Frustración por resultados'},
    {'id': 'team', 'label': 'Manejo de equipo'},
  ];

  // Goals for onboarding
  static const List<Map<String, String>> goals = [
    {'id': 'discharge', 'label': 'Un espacio para descargar'},
    {'id': 'tools', 'label': 'Herramientas para calmarme'},
    {'id': 'patterns', 'label': 'Entender mis patrones'},
    {'id': 'companion', 'label': 'Acompañamiento diario'},
    {'id': 'organize', 'label': 'Ordenar mi cabeza'},
    {'id': 'all', 'label': 'Todo un poco'},
  ];

  // Check-in prompts
  static const List<String> checkinPrompts = [
    '¿Qué te tiene la cabeza ocupada hoy?',
    '¿Hubo algo que te dio paz?',
    '¿Qué necesitás en este momento?',
    '¿Qué te gustaría soltar?',
    '¿Cómo te trató el día?',
    '¿Qué decisión te está costando?',
  ];

  // Journal prompts
  static const List<String> journalPrompts = [
    'Escribí lo primero que venga a tu mente',
    '¿Qué decisión te está costando?',
    '¿Qué te dirías si fueras tu mejor amigo?',
    '¿Qué fue lo mejor del día?',
    '¿Qué te está pesando?',
    'Hoy necesito decir que...',
    'Si pudiera soltar algo, sería...',
    'Lo que nadie sabe es que...',
  ];

  // Tools
  // ── Set curado: 10 ejercicios claros y sin repeticiones.
  //    Cada paso es una instrucción completa y autoexplicativa.
  static const List<Map<String, dynamic>> tools = [
    {
      'id': 'burnout_test',
      'title': 'Test de Burnout',
      'description': 'Medí tu nivel de agotamiento en 5 minutos',
      'category': 'assessment',
      'duration': '5 min',
      'durationSeconds': 300,
      'featured': true,
      'icon': Icons.psychology_rounded,
      'intro': 'Respondé 12 preguntas rápidas sobre tu energía, tu ánimo y tu motivación de las últimas dos semanas. Al terminar vas a ver tu nivel de agotamiento y qué hacer con él.',
      'steps': [
        {'text': 'Respondé pensando en cómo estuviste realmente, no en cómo creés que deberías estar.', 'seconds': 0},
        {'text': 'Tomá como referencia las últimas dos semanas, no solo el día de hoy.', 'seconds': 0},
        {'text': 'Al final recibís un puntaje y pasos concretos según tu resultado.', 'seconds': 0},
      ],
    },
    {
      'id': 'breathing_calm',
      'title': 'Respiración para calmar',
      'description': 'Técnica 4-7-8 para bajar la ansiedad',
      'category': 'breathing',
      'duration': '3 min',
      'durationSeconds': 180,
      'breathingPattern': {'inhale': 4, 'holdIn': 7, 'exhale': 8, 'holdOut': 0},
      'totalCycles': 9,
      'icon': Icons.spa_rounded,
      'intro': 'Inhalás 4 segundos, retenés 7 y exhalás 8. La exhalación larga calma el sistema nervioso y baja la ansiedad en pocos minutos. Ideal antes de dormir o en un pico de estrés.',
      'steps': [
        {'text': 'Sentate con la espalda recta y los hombros sueltos.', 'seconds': 0},
        {'text': 'Apoyá la punta de la lengua detrás de los dientes de arriba y dejala ahí.', 'seconds': 0},
        {'text': 'Seguí el círculo de la pantalla: cuando crece inhalás, cuando se mantiene retenés y cuando se achica exhalás por la boca.', 'seconds': 0},
      ],
    },
    {
      'id': 'breathing_focus',
      'title': 'Respiración para enfocar',
      'description': 'Box breathing para recuperar claridad',
      'category': 'breathing',
      'duration': '4 min',
      'durationSeconds': 240,
      'breathingPattern': {'inhale': 4, 'holdIn': 4, 'exhale': 4, 'holdOut': 4},
      'totalCycles': 15,
      'icon': Icons.crop_square_rounded,
      'intro': 'Cuatro tiempos iguales de 4 segundos: inhalar, retener, exhalar y retener. Usala antes de una tarea importante o cuando tu cabeza está dispersa y necesitás volver al foco.',
      'steps': [
        {'text': 'Dejá las manos quietas y los pies apoyados en el piso.', 'seconds': 0},
        {'text': 'Seguí el ritmo de 4 tiempos: inhalá 4, retené 4, exhalá 4 y retené 4.', 'seconds': 0},
        {'text': 'Imaginá que dibujás los cuatro lados de un cuadrado, uno por cada tiempo.', 'seconds': 0},
      ],
    },
    {
      'id': 'pause_2min',
      'title': 'Reinicio mental',
      'description': 'Un corte de 2 minutos para resetear entre tareas',
      'category': 'pause',
      'duration': '2 min',
      'durationSeconds': 120,
      'icon': Icons.refresh_rounded,
      'intro': 'Un micro-descanso para cortar el piloto automático entre reuniones o tareas. En dos minutos bajás revoluciones y volvés con la cabeza más despejada.',
      'steps': [
        {'text': 'Apoyá el teléfono, cerrá los ojos y dejá caer los hombros.', 'seconds': 25},
        {'text': 'Hacé tres respiraciones lentas: inhalá por la nariz y exhalá largo por la boca.', 'seconds': 35},
        {'text': 'Mové el cuello y los hombros en círculos suaves para soltar la tensión.', 'seconds': 30},
        {'text': 'Abrí los ojos y mirá un punto lejano durante diez segundos antes de seguir.', 'seconds': 30},
      ],
    },
    {
      'id': 'anxiety_grounding',
      'title': 'Anclaje 5-4-3-2-1',
      'description': 'Volvé al presente usando los cinco sentidos',
      'category': 'anxiety',
      'duration': '3 min',
      'durationSeconds': 180,
      'icon': Icons.anchor_rounded,
      'intro': 'Te saca del bucle de pensamientos y te trae al presente recorriendo los cinco sentidos. Usala cuando sientas la ansiedad acelerada o la cabeza en otro lado.',
      'steps': [
        {'text': 'Mirá a tu alrededor y nombrá en voz baja 5 cosas que podés ver.', 'seconds': 36},
        {'text': 'Prestá atención y nombrá 4 cosas que podés tocar o sentir en tu cuerpo.', 'seconds': 36},
        {'text': 'Escuchá y nombrá 3 sonidos distintos a tu alrededor.', 'seconds': 36},
        {'text': 'Nombrá 2 olores que percibís ahora o que recordás del día.', 'seconds': 36},
        {'text': 'Nombrá 1 sabor en tu boca o algo que te guste saborear.', 'seconds': 36},
      ],
    },
    {
      'id': 'anxiety_bodyscan',
      'title': 'Escaneo corporal',
      'description': 'Recorré tu cuerpo y soltá la tensión zona por zona',
      'category': 'anxiety',
      'duration': '4 min',
      'durationSeconds': 240,
      'icon': Icons.accessibility_new_rounded,
      'intro': 'Un recorrido guiado por tu cuerpo para detectar y soltar la tensión que acumulás sin darte cuenta. Sirve para frenar la ansiedad física y reconectar con el cuerpo.',
      'steps': [
        {'text': 'Buscá una posición cómoda, cerrá los ojos y respirá hondo tres veces.', 'seconds': 30},
        {'text': 'Llevá la atención a tu cara y tu mandíbula, y aflojalas.', 'seconds': 40},
        {'text': 'Bajá al cuello y los hombros, y dejalos caer con su propio peso.', 'seconds': 40},
        {'text': 'Recorré los brazos y las manos, notá su peso y soltalos.', 'seconds': 40},
        {'text': 'Llevá el aire al pecho y al abdomen, sintiendo cómo suben y bajan.', 'seconds': 50},
        {'text': 'Terminá en las piernas y los pies, sintiéndolos firmes contra el piso.', 'seconds': 40},
      ],
    },
    {
      'id': 'discharge_writing',
      'title': 'Descarga por escrito',
      'description': 'Vaciá la cabeza en papel en 1 minuto',
      'category': 'anxiety',
      'duration': '1 min',
      'durationSeconds': 60,
      'icon': Icons.edit_note_rounded,
      'intro': 'Cuando tenés demasiadas vueltas en la cabeza, escribir las ordena más rápido que pensarlas. No busques que quede bien: solo soltá todo lo que aparezca.',
      'steps': [
        {'text': 'Agarrá papel y lápiz o abrí una nota en el teléfono.', 'seconds': 15},
        {'text': 'Escribí sin parar todo lo que tengas en la cabeza, sin corregir ni juzgar.', 'seconds': 30},
        {'text': 'Cuando termines, cerrá la nota sin releerla. Ya está afuera.', 'seconds': 15},
      ],
    },
    {
      'id': 'entrepreneur_overload',
      'title': 'Cuando todo abruma',
      'description': 'Ordená el caos y elegí por dónde empezar',
      'category': 'entrepreneur',
      'duration': '5 min',
      'durationSeconds': 300,
      'icon': Icons.calendar_month_rounded,
      'intro': 'Cuando tenés mil cosas y no sabés por dónde arrancar, el error es empezar a hacer sin parar. Primero frenás, después elegís lo que de verdad importa.',
      'steps': [
        {'text': 'Frená lo que estás haciendo y hacé un par de respiraciones largas.', 'seconds': 30},
        {'text': 'Anotá o repasá mentalmente todo lo que tenés pendiente, sin filtrar nada.', 'seconds': 60},
        {'text': 'Marcá las 3 tareas que de verdad mueven la aguja hoy.', 'seconds': 60},
        {'text': 'El resto: posponelo o delegalo, sin sentir culpa por eso.', 'seconds': 60},
        {'text': 'Empezá solo por la primera de las tres. Lo demás puede esperar.', 'seconds': 90},
      ],
    },
    {
      'id': 'entrepreneur_bad_sale',
      'title': 'Después de un "no"',
      'description': 'Reseteá cuando un cliente o un deal se cae',
      'category': 'entrepreneur',
      'duration': '3 min',
      'durationSeconds': 180,
      'icon': Icons.trending_down_rounded,
      'intro': 'Un "no" duele, pero no dice nada sobre tu valor. Este mini-ritual separa el resultado de quién sos y te deja listo para lo que viene.',
      'steps': [
        {'text': 'Date un segundo y reconocé que esto duele, sin minimizarlo.', 'seconds': 30},
        {'text': 'Tomá aire profundo y soltá la tensión de los hombros.', 'seconds': 30},
        {'text': 'Recordate: el "no" fue sobre esta venta, no sobre vos.', 'seconds': 30},
        {'text': 'Preguntate qué podés aprender de esta conversación.', 'seconds': 45},
        {'text': 'Elegí una sola cosa que vas a hacer distinto la próxima vez.', 'seconds': 45},
      ],
    },
    {
      'id': 'entrepreneur_cantmore',
      'title': 'Cuando no das más',
      'description': 'Contención para los días que te superan',
      'category': 'entrepreneur',
      'duration': '5 min',
      'durationSeconds': 300,
      'icon': Icons.favorite_rounded,
      'intro': 'Hay días en que el cuerpo y la cabeza dicen basta, y eso no significa que estés fallando. Date permiso para parar: descansar también es parte del trabajo.',
      'steps': [
        {'text': 'Reconocé sin juzgarte que hoy estás al límite, y que está bien estarlo.', 'seconds': 60},
        {'text': 'Respirá lento cuatro veces, llevando el aire bien abajo, hacia la panza.', 'seconds': 60},
        {'text': 'Acordate de 3 personas que te quieren y que te bancan.', 'seconds': 60},
        {'text': 'Traé a la memoria una cosa buena, por chica que sea, de esta semana.', 'seconds': 60},
        {'text': 'Por hoy no decidas nada importante. Dale a tu cuerpo el descanso que pide.', 'seconds': 60},
      ],
    },
  ];

  // Greeting messages by time of day
  static String getGreeting(String name) {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Buenos días, $name';
    } else if (hour < 19) {
      return 'Hola, $name';
    } else {
      return 'Buenas noches, $name';
    }
  }

  static String getGreetingSubtitle() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return '¿Cómo arrancás hoy?';
    } else if (hour < 19) {
      return '¿Cómo viene el día?';
    } else {
      return '¿Cómo estuvo hoy?';
    }
  }

  // ============ COMMUNITY DEMO DATA ============

  static const List<Map<String, dynamic>> demoUsers = [
    {
      'id': 'demo-ana',
      'full_name': 'Ana Martínez',
      'avatar_url': 'https://picsum.photos/seed/ana-sentio/200',
      'bio': 'CEO @ TechFlow · Obsesionada con el product-market fit',
      'followers_count': 284,
      'following_count': 143,
      'posts_count': 47,
    },
    {
      'id': 'demo-diego',
      'full_name': 'Diego Ruiz',
      'avatar_url': 'https://picsum.photos/seed/diego-sentio/200',
      'bio': 'Founder de una fintech en Buenos Aires 🚀',
      'followers_count': 512,
      'following_count': 231,
      'posts_count': 89,
    },
    {
      'id': 'demo-vale',
      'full_name': 'Valentina Torres',
      'avatar_url': 'https://picsum.photos/seed/vale-sentio/200',
      'bio': 'Diseñadora UX que dejó su empleo para emprender',
      'followers_count': 198,
      'following_count': 167,
      'posts_count': 34,
    },
    {
      'id': 'demo-nico',
      'full_name': 'Nicolás Herrera',
      'avatar_url': 'https://picsum.photos/seed/nico-sentio/200',
      'bio': 'CTO & co-founder · 3 startups, 2 fracasos, 1 éxito',
      'followers_count': 743,
      'following_count': 89,
      'posts_count': 156,
    },
    {
      'id': 'demo-cami',
      'full_name': 'Camila Reyes',
      'avatar_url': 'https://picsum.photos/seed/cami-sentio/200',
      'bio': 'Marketing digital · Creando mi agencia desde cero',
      'followers_count': 321,
      'following_count': 245,
      'posts_count': 62,
    },
    {
      'id': 'demo-mateo',
      'full_name': 'Mateo Vargas',
      'avatar_url': 'https://picsum.photos/seed/mateo-sentio/200',
      'bio': 'Emprendedor serial · Mentor en Endeavor',
      'followers_count': 1247,
      'following_count': 312,
      'posts_count': 203,
    },
    {
      'id': 'demo-isa',
      'full_name': 'Isabella Méndez',
      'avatar_url': 'https://picsum.photos/seed/isa-sentio/200',
      'bio': 'Fundadora de una marca de skincare natural 🌿',
      'followers_count': 456,
      'following_count': 178,
      'posts_count': 71,
    },
    {
      'id': 'demo-santi',
      'full_name': 'Santiago López',
      'avatar_url': 'https://picsum.photos/seed/santi-sentio/200',
      'bio': 'Dev freelancer transitando a producto propio',
      'followers_count': 167,
      'following_count': 203,
      'posts_count': 28,
    },
  ];

  static List<Map<String, dynamic>> get demoPosts {
    final now = DateTime.now();
    return [
      {
        'id': 'post-1',
        'user_id': 'demo-ana',
        'content': 'Hoy cerramos nuestra primera ronda de inversión. 18 meses de "no" hasta llegar al "sí". No se rindan, el timing es todo. 🎉',
        'image_urls': ['https://picsum.photos/seed/office-cele/600/400'],
        'likes_count': 47,
        'comments_count': 12,
        'emotion': 'motivated',
        'created_at': now.subtract(const Duration(hours: 2)).toIso8601String(),
      },
      {
        'id': 'post-2',
        'user_id': 'demo-diego',
        'content': '¿Alguien más siente que los domingos a la noche ya está pensando en todo lo que tiene que hacer el lunes? Necesito aprender a desconectar de verdad.',
        'image_urls': <String>[],
        'likes_count': 89,
        'comments_count': 23,
        'emotion': 'overwhelmed',
        'created_at': now.subtract(const Duration(hours: 5)).toIso8601String(),
      },
      {
        'id': 'post-3',
        'user_id': 'demo-vale',
        'content': 'Mi espacio de trabajo hoy. A veces la creatividad necesita silencio y una buena taza de café. ☕',
        'image_urls': ['https://picsum.photos/seed/workspace-val/600/400'],
        'likes_count': 34,
        'comments_count': 5,
        'emotion': 'calm',
        'created_at': now.subtract(const Duration(hours: 8)).toIso8601String(),
      },
      {
        'id': 'post-4',
        'user_id': 'demo-nico',
        'content': 'Después de 2 startups fallidas aprendí algo: el fracaso no es lo opuesto al éxito, es parte del camino. Hoy mi tercera empresa cumple 3 años rentable.',
        'image_urls': <String>[],
        'likes_count': 156,
        'comments_count': 31,
        'emotion': 'grateful',
        'created_at': now.subtract(const Duration(hours: 12)).toIso8601String(),
      },
      {
        'id': 'post-5',
        'user_id': 'demo-cami',
        'content': 'Primer cliente grande para la agencia!! No puedo creerlo todavía. Gracias a todos los que creyeron cuando yo dudaba. 💜',
        'image_urls': ['https://picsum.photos/seed/celebrate/600/400'],
        'likes_count': 72,
        'comments_count': 18,
        'emotion': 'motivated',
        'created_at': now.subtract(const Duration(hours: 16)).toIso8601String(),
      },
      {
        'id': 'post-6',
        'user_id': 'demo-mateo',
        'content': 'Hoy no fue un buen día. Perdimos un deal importante y el equipo está desanimado. Pero mañana es otro día. A veces la fortaleza está en aceptar que hoy no se pudo.',
        'image_urls': <String>[],
        'likes_count': 203,
        'comments_count': 42,
        'emotion': 'sad',
        'created_at': now.subtract(const Duration(hours: 20)).toIso8601String(),
      },
      {
        'id': 'post-7',
        'user_id': 'demo-isa',
        'content': 'Nuestra primera producción en el nuevo laboratorio. De cocinar fórmulas en mi cocina a esto... el viaje vale la pena. 🧴✨',
        'image_urls': ['https://picsum.photos/seed/lab-isa/600/400'],
        'likes_count': 91,
        'comments_count': 14,
        'emotion': 'hopeful',
        'created_at': now.subtract(const Duration(days: 1, hours: 3)).toIso8601String(),
      },
      {
        'id': 'post-8',
        'user_id': 'demo-santi',
        'content': 'Transición de freelancer a producto propio: Día 47. Todavía no tengo ni un usuario de pago pero nunca me sentí tan vivo. El miedo y la emoción conviven.',
        'image_urls': <String>[],
        'likes_count': 45,
        'comments_count': 8,
        'emotion': 'anxious',
        'created_at': now.subtract(const Duration(days: 1, hours: 7)).toIso8601String(),
      },
      {
        'id': 'post-9',
        'user_id': 'demo-ana',
        'content': 'Tip para founders: no esperen a tener todo perfecto para lanzar. Nuestro MVP era horrible y aún así nos dió las mejores lecciones.',
        'image_urls': <String>[],
        'likes_count': 128,
        'comments_count': 19,
        'created_at': now.subtract(const Duration(days: 1, hours: 14)).toIso8601String(),
      },
      {
        'id': 'post-10',
        'user_id': 'demo-diego',
        'content': 'Hoy almorcé sin mirar el celular. 45 minutos de paz. Suena ridículo pero para mí fue un logro enorme.',
        'image_urls': <String>[],
        'likes_count': 167,
        'comments_count': 27,
        'emotion': 'calm',
        'created_at': now.subtract(const Duration(days: 2)).toIso8601String(),
      },
      {
        'id': 'post-11',
        'user_id': 'demo-vale',
        'content': 'Rediseñé mi portfolio completo este finde. Cuando la creatividad fluye, no hay que frenarla.',
        'image_urls': ['https://picsum.photos/seed/portfolio-v/600/400'],
        'likes_count': 56,
        'comments_count': 7,
        'emotion': 'focused',
        'created_at': now.subtract(const Duration(days: 2, hours: 5)).toIso8601String(),
      },
      {
        'id': 'post-12',
        'user_id': 'demo-mateo',
        'content': 'A los que recién arrancan: el síndrome del impostor no se va, aprendés a convivir con él. Después de 15 años emprendiendo, sigo dudando. Y está bien.',
        'image_urls': <String>[],
        'likes_count': 312,
        'comments_count': 56,
        'emotion': 'insecure',
        'created_at': now.subtract(const Duration(days: 2, hours: 10)).toIso8601String(),
      },
      {
        'id': 'post-13',
        'user_id': 'demo-cami',
        'content': 'Necesito recomendaciones: ¿qué herramienta usan para organizar su semana? Probé de todo y sigo con post-its pegados en la pantalla 😅',
        'image_urls': <String>[],
        'likes_count': 34,
        'comments_count': 41,
        'created_at': now.subtract(const Duration(days: 3)).toIso8601String(),
      },
      {
        'id': 'post-14',
        'user_id': 'demo-nico',
        'content': 'El equipo después del sprint más intenso del año. Orgulloso de esta gente. 🫶',
        'image_urls': ['https://picsum.photos/seed/team-nico/600/400'],
        'likes_count': 89,
        'comments_count': 11,
        'emotion': 'grateful',
        'created_at': now.subtract(const Duration(days: 3, hours: 8)).toIso8601String(),
      },
      {
        'id': 'post-15',
        'user_id': 'demo-isa',
        'content': 'Hoy una clienta me escribió que nuestro sérum la ayudó con su autoestima. No hay métrica que mida eso. Este es mi "por qué".',
        'image_urls': <String>[],
        'likes_count': 234,
        'comments_count': 29,
        'emotion': 'grateful',
        'created_at': now.subtract(const Duration(days: 4)).toIso8601String(),
      },
    ];
  }

  static List<Map<String, dynamic>> get demoStories {
    final now = DateTime.now();
    return [
      {
        'id': 'story-1',
        'user_id': 'demo-ana',
        'image_url': 'https://picsum.photos/seed/story-ana/400/700',
        'text_overlay': 'Día de cierre 🎯',
        'created_at': now.subtract(const Duration(hours: 3)).toIso8601String(),
        'expires_at': now.add(const Duration(hours: 21)).toIso8601String(),
      },
      {
        'id': 'story-2',
        'user_id': 'demo-diego',
        'image_url': 'https://picsum.photos/seed/story-diego/400/700',
        'text_overlay': 'Primer mes rentable!! 📈',
        'created_at': now.subtract(const Duration(hours: 6)).toIso8601String(),
        'expires_at': now.add(const Duration(hours: 18)).toIso8601String(),
      },
      {
        'id': 'story-3',
        'user_id': 'demo-vale',
        'image_url': 'https://picsum.photos/seed/story-vale/400/700',
        'text_overlay': null,
        'created_at': now.subtract(const Duration(hours: 10)).toIso8601String(),
        'expires_at': now.add(const Duration(hours: 14)).toIso8601String(),
      },
      {
        'id': 'story-4',
        'user_id': 'demo-mateo',
        'image_url': 'https://picsum.photos/seed/story-mateo/400/700',
        'text_overlay': 'La paciencia es la ventaja competitiva que nadie quiere tener',
        'created_at': now.subtract(const Duration(hours: 14)).toIso8601String(),
        'expires_at': now.add(const Duration(hours: 10)).toIso8601String(),
      },
    ];
  }

  static List<Map<String, dynamic>> get demoComments {
    final now = DateTime.now();
    return [
      // Comments on post-1 (Ana's investment round)
      {'id': 'c1', 'post_id': 'post-1', 'user_id': 'demo-diego', 'content': 'Felicitaciones Ana! Merecidísimo 🙌', 'created_at': now.subtract(const Duration(hours: 1, minutes: 45)).toIso8601String()},
      {'id': 'c2', 'post_id': 'post-1', 'user_id': 'demo-mateo', 'content': 'La perseverancia siempre gana. Orgulloso!', 'created_at': now.subtract(const Duration(hours: 1, minutes: 30)).toIso8601String()},
      {'id': 'c3', 'post_id': 'post-1', 'user_id': 'demo-vale', 'content': 'Inspirás mucho! A seguir así 💪', 'created_at': now.subtract(const Duration(hours: 1)).toIso8601String()},
      // Comments on post-2 (Diego's Sunday anxiety)
      {'id': 'c4', 'post_id': 'post-2', 'user_id': 'demo-ana', 'content': 'Totalmente. Yo empecé a apagar notificaciones los domingos y cambió todo.', 'created_at': now.subtract(const Duration(hours: 4)).toIso8601String()},
      {'id': 'c5', 'post_id': 'post-2', 'user_id': 'demo-santi', 'content': 'Me pasa igual. Probé la técnica de "brain dump" antes de dormir y ayuda bastante.', 'created_at': now.subtract(const Duration(hours: 3, minutes: 30)).toIso8601String()},
      {'id': 'c6', 'post_id': 'post-2', 'user_id': 'demo-isa', 'content': 'No estás solo en esto 🫂', 'created_at': now.subtract(const Duration(hours: 3)).toIso8601String()},
      // Comments on post-6 (Mateo's bad day)
      {'id': 'c7', 'post_id': 'post-6', 'user_id': 'demo-nico', 'content': 'Fuerza Mateo. Los mejores líderes son los que se permiten sentir.', 'created_at': now.subtract(const Duration(hours: 19)).toIso8601String()},
      {'id': 'c8', 'post_id': 'post-6', 'user_id': 'demo-cami', 'content': 'Gracias por compartir esto. Normalizamos hablar de los días difíciles.', 'created_at': now.subtract(const Duration(hours: 18)).toIso8601String()},
      {'id': 'c9', 'post_id': 'post-6', 'user_id': 'demo-ana', 'content': 'Mañana va a ser mejor. Siempre lo es. 💙', 'created_at': now.subtract(const Duration(hours: 17)).toIso8601String()},
      // Comments on post-12 (Mateo's impostor syndrome)
      {'id': 'c10', 'post_id': 'post-12', 'user_id': 'demo-santi', 'content': 'Esto es exactamente lo que necesitaba leer hoy.', 'created_at': now.subtract(const Duration(days: 2, hours: 8)).toIso8601String()},
      {'id': 'c11', 'post_id': 'post-12', 'user_id': 'demo-vale', 'content': 'El síndrome del impostor es el tax de hacer algo que importa.', 'created_at': now.subtract(const Duration(days: 2, hours: 7)).toIso8601String()},
      {'id': 'c12', 'post_id': 'post-12', 'user_id': 'demo-diego', 'content': 'Guardé este post. Gracias Mateo.', 'created_at': now.subtract(const Duration(days: 2, hours: 6)).toIso8601String()},
    ];
  }
}
