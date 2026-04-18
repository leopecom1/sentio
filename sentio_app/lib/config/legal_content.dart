/// Legal content for B2Better app
/// Last updated: 2026-04-18
class LegalContent {
  static const String version = '1.0';
  static const String lastUpdated = '18 de abril de 2026';
  static const String contactEmail = 'hola@b2better.app';

  // ══════════════════════════════════════
  // TERMS & CONDITIONS
  // ══════════════════════════════════════

  static const List<LegalSection> terms = [
    LegalSection(
      title: '1. Aceptación',
      body:
          'Al usar B2Better aceptás estos Términos y Condiciones y nuestra Política de Privacidad. Si no estás de acuerdo, por favor no uses la aplicación.',
    ),
    LegalSection(
      title: '2. Qué es B2Better',
      body:
          'B2Better es una aplicación de bienestar emocional diseñada para emprendedores. Ofrece check-ins emocionales, diario personal, herramientas de bienestar (respiración, meditación), test de burnout, gestión financiera personal, comunidad y un asistente conversacional con inteligencia artificial.\n\nB2Better NO es un servicio médico, psicológico ni psiquiátrico. La app no reemplaza el consejo, diagnóstico o tratamiento de profesionales de la salud mental.',
    ),
    LegalSection(
      title: '3. Edad mínima',
      body:
          'Para usar B2Better debés tener al menos 16 años. Si sos menor de edad en tu jurisdicción, necesitás autorización de tus padres o tutores.',
    ),
    LegalSection(
      title: '4. Tu cuenta',
      body:
          'Sos responsable de mantener segura tu contraseña y de toda actividad que ocurra bajo tu cuenta. Notificanos inmediatamente si sospechás un acceso no autorizado.',
    ),
    LegalSection(
      title: '5. Uso aceptable',
      body:
          'No podés usar B2Better para:\n\n• Publicar contenido ilegal, ofensivo, discriminatorio o que viole derechos de terceros.\n• Acosar, intimidar o dañar a otros usuarios.\n• Suplantar la identidad de otra persona.\n• Intentar vulnerar la seguridad de la plataforma.\n• Usar la app con fines comerciales sin autorización.',
    ),
    LegalSection(
      title: '6. Contenido del usuario',
      body:
          'Vos sos el dueño del contenido que creás (entradas de diario, posts en comunidad, fotos, etc.). Al publicar en la comunidad, nos otorgás una licencia limitada para mostrar ese contenido a otros usuarios dentro de la app.\n\nNos reservamos el derecho de eliminar contenido que viole estos términos.',
    ),
    LegalSection(
      title: '7. Asistente con IA',
      body:
          'El asistente conversacional usa modelos de inteligencia artificial (OpenAI). Las respuestas son generadas automáticamente y pueden contener errores. NO uses al asistente para:\n\n• Diagnóstico médico o psicológico.\n• Decisiones financieras críticas sin consultar a un profesional.\n• Situaciones de crisis o emergencia.\n\nSi estás en crisis, usá el botón de corazón para acceder a líneas de ayuda profesionales reales en tu país.',
    ),
    LegalSection(
      title: '8. Datos financieros',
      body:
          'B2Better incluye herramientas para registrar tus movimientos financieros. Estos datos son ingresados manualmente por vos y se almacenan de forma cifrada. NO conectamos con tus cuentas bancarias reales ni movemos dinero.\n\nLos consejos financieros generados por IA son orientativos y NO reemplazan asesoramiento profesional.',
    ),
    LegalSection(
      title: '9. Suscripciones y pagos',
      body:
          'B2Better puede ofrecer planes premium con funciones adicionales. Las suscripciones se gestionan a través de Apple App Store o Google Play Store según tu plataforma. La cancelación se hace desde tu cuenta de la tienda correspondiente.',
    ),
    LegalSection(
      title: '10. Propiedad intelectual',
      body:
          'B2Better, su código, diseño, marca, logos y contenido son propiedad de B2Better. No podés copiar, modificar, distribuir ni crear obras derivadas sin autorización escrita.',
    ),
    LegalSection(
      title: '11. Limitación de responsabilidad',
      body:
          'B2Better se ofrece "tal como está". No garantizamos que la app esté libre de errores o interrupciones. En la medida permitida por la ley, no somos responsables por daños indirectos, lucro cesante, pérdida de datos o decisiones que tomes basándote en la información de la app.\n\nB2Better NO es responsable por crisis, emergencias o decisiones de salud mental. Para esos casos, buscá ayuda profesional.',
    ),
    LegalSection(
      title: '12. Modificaciones',
      body:
          'Podemos actualizar estos Términos en cualquier momento. Te notificaremos los cambios importantes dentro de la app. El uso continuado luego de los cambios implica aceptación de los nuevos términos.',
    ),
    LegalSection(
      title: '13. Cancelación',
      body:
          'Podés eliminar tu cuenta en cualquier momento desde la sección de Perfil. Al hacerlo, eliminamos tus datos personales según lo descripto en la Política de Privacidad.\n\nPodemos suspender o cerrar tu cuenta si violás estos términos.',
    ),
    LegalSection(
      title: '14. Ley aplicable',
      body:
          'Estos términos se rigen por las leyes de la República Argentina. Cualquier disputa será resuelta en los tribunales ordinarios de la Ciudad Autónoma de Buenos Aires.',
    ),
    LegalSection(
      title: '15. Contacto',
      body:
          'Para consultas sobre estos Términos, escribinos a $contactEmail',
    ),
  ];

  // ══════════════════════════════════════
  // PRIVACY POLICY
  // ══════════════════════════════════════

  static const List<LegalSection> privacy = [
    LegalSection(
      title: '1. Información que recopilamos',
      body:
          'Para que B2Better funcione, recopilamos los siguientes datos:\n\n'
          '• Datos de cuenta: email, nombre, contraseña (cifrada).\n'
          '• Datos de perfil: foto, biografía, presiones, objetivos seleccionados.\n'
          '• Check-ins emocionales: emoción, energía, estrés, notas.\n'
          '• Diario personal: entradas que escribís y emoción asociada.\n'
          '• Conversaciones con el coach IA: texto de tus mensajes y las respuestas generadas.\n'
          '• Datos financieros: cuentas, transacciones, categorías que vos creás manualmente.\n'
          '• Contenido en comunidad: posts, comentarios, historias, likes.\n'
          '• Datos de uso: estadísticas anónimas de uso (cuándo abrís la app, qué herramientas usás).\n'
          '• Resultados de tests (ej. burnout): respuestas y puntajes.',
    ),
    LegalSection(
      title: '2. Dónde se almacenan tus datos',
      body:
          'Tus datos se almacenan en servidores seguros de Supabase, que cuenta con cifrado en reposo (AES-256) y en tránsito (TLS 1.3). Los servidores están ubicados en infraestructura de AWS.\n\n'
          'IMPORTANTE: Aunque tus conversaciones, diario y datos financieros son privados (solo vos podés verlos), están almacenados en servidores cloud, NO solo en tu dispositivo. Esto nos permite:\n\n'
          '• Sincronizar tu información entre dispositivos.\n'
          '• Recuperar tus datos si perdés el teléfono.\n'
          '• Procesar las consultas del coach IA.\n'
          '• Generar estadísticas y gráficos.',
    ),
    LegalSection(
      title: '3. Quién puede ver tus datos',
      body:
          'Datos PRIVADOS (solo vos podés acceder):\n\n'
          '• Tu diario personal\n'
          '• Tus check-ins emocionales\n'
          '• Tus conversaciones con el coach IA\n'
          '• Tus datos financieros\n'
          '• Tus resultados de tests\n\n'
          'Datos PÚBLICOS (visibles para otros usuarios de la app):\n\n'
          '• Tu nombre y foto de perfil\n'
          '• Posts e historias que publiques en comunidad\n'
          '• Comentarios y likes\n\n'
          'Datos que ve el equipo de B2Better (con fines administrativos):\n\n'
          '• Estadísticas agregadas y anónimas de uso\n'
          '• Resultados de tests para mejorar la app (sin contenido personal identificable)\n'
          '• Datos de onboarding (presiones, objetivos)\n\n'
          'Nuestro equipo NO lee tu diario, conversaciones con el coach ni datos financieros, salvo orden judicial expresa.',
    ),
    LegalSection(
      title: '4. Terceros con los que compartimos datos',
      body:
          'Para que la app funcione, compartimos algunos datos con proveedores externos:\n\n'
          '• Supabase (almacenamiento de base de datos y archivos)\n'
          '• OpenAI (procesamiento de mensajes del coach IA)\n'
          '• Apple Push Notification Service / Firebase Cloud Messaging (notificaciones)\n\n'
          'No vendemos tus datos a terceros. No usamos tus datos para publicidad.',
    ),
    LegalSection(
      title: '5. Tus derechos',
      body:
          'Vos tenés los siguientes derechos sobre tus datos:\n\n'
          '• ACCESO: Solicitar una copia de toda tu información.\n'
          '• RECTIFICACIÓN: Corregir datos incorrectos.\n'
          '• ELIMINACIÓN: Borrar tu cuenta y todos tus datos.\n'
          '• PORTABILIDAD: Exportar tus datos en formato legible.\n'
          '• OPOSICIÓN: Limitar el procesamiento de tus datos.\n\n'
          'Para ejercer estos derechos, escribinos a $contactEmail. Respondemos en un plazo máximo de 30 días.',
    ),
    LegalSection(
      title: '6. Retención de datos',
      body:
          'Mantenemos tus datos mientras tu cuenta esté activa. Si eliminás tu cuenta, borramos tus datos personales en un plazo de 30 días, excepto:\n\n'
          '• Información que debamos conservar por obligación legal.\n'
          '• Logs anónimos de uso (sin información identificable).\n'
          '• Posts e historias en comunidad (que pueden permanecer si otros usuarios interactuaron con ellos).',
    ),
    LegalSection(
      title: '7. Seguridad',
      body:
          'Implementamos medidas técnicas y organizativas para proteger tus datos:\n\n'
          '• Cifrado en reposo (AES-256) y en tránsito (HTTPS/TLS).\n'
          '• Autenticación segura con tokens.\n'
          '• Acceso restringido a la base de datos por roles.\n'
          '• Row Level Security (RLS) que garantiza que solo vos accedas a tus datos privados.\n'
          '• Backups encriptados.\n\n'
          'Aun así, ningún sistema es 100% seguro. En caso de una brecha de datos, te notificaremos en un plazo máximo de 72 horas según las normativas aplicables.',
    ),
    LegalSection(
      title: '8. Menores de edad',
      body:
          'B2Better está pensada para personas mayores de 16 años. No recopilamos datos de menores de esta edad de forma intencional. Si descubrimos que tenemos datos de un menor sin autorización, los eliminamos.',
    ),
    LegalSection(
      title: '9. Transferencias internacionales',
      body:
          'Tus datos pueden ser transferidos y procesados en países fuera de tu jurisdicción (principalmente EE.UU., donde están los servidores de Supabase y OpenAI). Estas transferencias se realizan con garantías adecuadas conforme a las leyes aplicables (GDPR, Ley 25.326).',
    ),
    LegalSection(
      title: '10. Cookies y tecnologías similares',
      body:
          'La app móvil no usa cookies. Usamos almacenamiento local del dispositivo (SharedPreferences) para mantener tu sesión iniciada y guardar preferencias como tema, idioma y notificaciones.',
    ),
    LegalSection(
      title: '11. Cambios en esta política',
      body:
          'Podemos actualizar esta Política de Privacidad. Si hay cambios materiales, te notificaremos dentro de la app o por email. La fecha de "última actualización" siempre estará al inicio del documento.',
    ),
    LegalSection(
      title: '12. Marco legal',
      body:
          'Cumplimos con las siguientes regulaciones aplicables:\n\n'
          '• Ley 25.326 (Argentina) — Protección de Datos Personales\n'
          '• GDPR (Unión Europea) — Reglamento General de Protección de Datos\n'
          '• LGPD (Brasil) — Lei Geral de Proteção de Dados\n'
          '• CCPA (California, EE.UU.)',
    ),
    LegalSection(
      title: '13. Autoridad de control',
      body:
          'Si considerás que el tratamiento de tus datos no se ajusta a la normativa, podés presentar un reclamo ante la Agencia de Acceso a la Información Pública (Argentina) o la autoridad equivalente en tu país.',
    ),
    LegalSection(
      title: '14. Contacto',
      body:
          'Para consultas sobre esta Política de Privacidad o ejercer tus derechos, escribinos a $contactEmail',
    ),
  ];
}

class LegalSection {
  final String title;
  final String body;
  const LegalSection({required this.title, required this.body});
}
