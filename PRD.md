# SENTIO — Product Requirements Document
## App de Soporte Emocional para Emprendedores

---

## 1. Vision General del Producto

**Sentio** es una app movil premium de bienestar emocional disenada exclusivamente para emprendedores, empresarios, freelancers y personas que cargan alta presion economica, mental y emocional por su actividad profesional.

Sentio no es una app de meditacion generica ni una red social. Es un **refugio emocional inteligente**: un espacio privado donde el emprendedor puede registrar como se siente, entender sus patrones, recibir acompanamiento emocional personalizado y acceder a herramientas de regulacion disenadas para la realidad de quien emprende.

**Mantra del producto:** *"Tu espacio para sentir, entender y avanzar."*

---

## 2. Propuesta de Valor

| Para quien | Problema | Solucion Sentio |
|---|---|---|
| Emprendedor solo | Soledad, sobrecarga de decisiones | Acompanamiento IA empatico + journaling |
| Dueno de negocio | Presion por equipo + finanzas | Check-in diario + insights de patrones |
| Freelancer saturado | Agotamiento, culpa por descansar | Herramientas de regulacion rapidas |
| Empresario con alta carga | Ansiedad, dificultad para desconectar | Rutinas de bienestar + progreso emocional |
| Emprendedor nuevo | Miedo al fracaso, inseguridad | Contenido guiado + asistente que acompana |

**Diferenciadores clave:**
- Disenado para emprendedores, no para el publico general
- Asistente IA emocionalmente inteligente (no robotico, no clinico)
- Check-in emocional rapido pero profundo
- Insights que conectan emociones con presion laboral/financiera
- Estetica premium, calida, no hospitalaria
- Herramientas para momentos reales: antes de una reunion, despues de una mala venta, dias de saturacion

---

## 3. Pilares Funcionales

1. **Registro** — Check-in emocional diario (rapido o profundo)
2. **Expresion** — Diario/descarga mental privado
3. **Acompanamiento** — Asistente IA empatico y presente
4. **Regulacion** — Herramientas concretas para momentos dificiles
5. **Comprension** — Insights y patrones emocionales
6. **Crecimiento** — Progreso emocional visible y rutinas personalizadas
7. **Contencion** — Soporte en momentos de crisis

---

## 4. Modulos de la App

### 4.1 Check-in Emocional Diario

**Proposito:** Registrar el estado emocional de forma rapida pero significativa.

**Mecanica:**
- **Check-in rapido (< 60 seg):** Seleccion de estado emocional principal (rueda de emociones visual), nivel de energia (1-5 con iconos), nivel de estres (1-5)
- **Check-in profundo (2-3 min):** Agrega claridad mental, motivacion, presion financiera/laboral, sensacion de control, calidad del dia + campo de texto opcional
- El check-in se activa con un prompt empatico: "Como estas hoy, de verdad?"
- Cada metrica usa sliders visuales suaves con microanimaciones
- Al finalizar, la app muestra un resumen visual del dia con un mensaje personalizado

**Emociones disponibles (rueda):**
- Tranquilo, Enfocado, Motivado, Agradecido, Esperanzado
- Cansado, Abrumado, Ansioso, Frustrado, Triste
- Inseguro, Solo, Presionado, Enojado, Bloqueado

**Escalas adicionales (check-in profundo):**
- Energia: Agotado → Recargado
- Estres: En calma → Desbordado
- Claridad mental: Confuso → Lucido
- Motivacion: Sin ganas → Encendido
- Presion financiera: Estable → Preocupado
- Control: Desbordado → En control

**Texto opcional con prompts rotativos:**
- "Que te tiene la cabeza ocupada hoy?"
- "Hubo algo que te dio paz?"
- "Que necesitas en este momento?"
- "Que te gustaria soltar?"

### 4.2 Diario / Descarga Mental

**Proposito:** Espacio intimo para escribir, reflexionar y vaciar la mente.

**Caracteristicas:**
- Editor limpio, pantalla completa, sin distracciones
- Prompts opcionales para inspirar la escritura:
  - "Escribe lo primero que venga a tu mente"
  - "Que decision te esta costando?"
  - "Que te dirias si fueras tu mejor amigo?"
  - "Que fue lo mejor del dia?"
  - "Que te esta pesando?"
- Tags emocionales y tematicos (automaticos + manuales)
- Organizacion por fecha, emocion dominante, tema
- Busqueda en entradas pasadas
- Vista calendario del historial
- Indicador de racha de escritura (sutil, no competitivo)

**Estados vacios:**
- Primera vez: "Este es tu espacio. Nada de lo que escribas aqui sera juzgado. Empieza cuando quieras."
- Sin entradas recientes: "A veces las palabras ayudan a ordenar lo que sentimos. No tiene que ser perfecto."

### 4.3 Asistente Emocional IA

**Proposito:** Acompanamiento conversacional calido, inteligente y presente.

**Personalidad del asistente:**
- Nombre: No tiene nombre propio (es "tu espacio", no un personaje)
- Tono: Calido, maduro, respetuoso, directo sin ser frio
- No diagnostica, no prescribe, no juzga
- Hace preguntas suaves que invitan a reflexionar
- Detecta saturacion y sugiere pausas
- Reconoce logros y esfuerzo del emprendedor

**Capacidades:**
- Poner en palabras lo que el usuario siente
- Ordenar pensamientos desordenados
- Diferenciar problemas urgentes de pensamientos ciclicos
- Sugerir herramientas de regulacion en contexto
- Acompanar despues de un mal dia
- Guiar reflexiones breves (3-5 minutos)
- Recordar contexto de conversaciones anteriores

**Interacciones tipo:**
- "Parece que hoy viniste con mucho encima. Queres que te ayude a ordenar un poco lo que estas sintiendo?"
- "Lo que describis suena como presion acumulada. Es normal sentirse asi cuando cargas tanto. Que te parece si hacemos una pausa juntos?"
- "Llevamos varias conversaciones donde mencionas la presion financiera. Queres que exploremos eso un poco?"

**Limites responsables:**
- Si detecta ideacion suicida o crisis severa: redirige a lineas de ayuda con tono humano
- No reemplaza terapia: "Lo que compartis conmigo es valioso, pero si sentis que necesitas hablar con un profesional, eso tambien es un paso de fuerza."

### 4.4 Herramientas de Regulacion Emocional

**Proposito:** Acciones concretas para momentos dificiles, disenadas para emprendedores.

**Categorias:**

**Respiraciones Guiadas:**
- Respira para calmar (4-7-8)
- Respira para enfocar (box breathing)
- Respira antes de una reunion
- Respira para soltar el dia

**Pausas Rapidas (2-5 min):**
- Reinicio mental de 2 minutos
- Pausa de descompresion
- Micro-descanso entre tareas
- Reset despues de una llamada dificil

**Ejercicios de Ansiedad:**
- Grounding 5-4-3-2-1
- Escaneo corporal rapido
- Tecnica de la mano (tocar cada dedo, nombrar algo)
- Escritura de descarga (1 minuto)

**Para Emprendedores (unicas):**
- "Antes de la reunion" — 3 min para centrarse
- "Despues de la mala venta" — reset emocional
- "Dia de facturar" — manejo de presion financiera
- "Lunes de sobrecarga" — ordenar la semana
- "No puedo mas" — contención inmediata
- "Culpa por descansar" — permiso para parar

**UI de herramientas:**
- Animacion visual suave (circulos de respiracion, ondas)
- Audio opcional (sonidos ambient, no musica)
- Timer visual elegante
- Feedback al completar: "Bien hecho. Cada pausa cuenta."

### 4.5 Insights y Patrones

**Proposito:** Mostrar al usuario patrones emocionales utiles, visuales y humanos.

**Metricas rastreadas:**
- Tendencia emocional semanal/mensual
- Dias de mayor estres vs mayor calma
- Correlacion descanso ↔ claridad mental
- Patrones de presion financiera
- Frecuencia de emociones especificas
- Momentos de saturacion recurrente
- Horarios de check-in (cuando se siente peor/mejor)

**Visualizaciones:**
- Grafico de ondas emocionales (no barras frias — curvas suaves)
- Mapa de calor semanal (tonos suaves)
- Circulo de emociones mas frecuentes
- Timeline de progreso con hitos

**Tono de insights:**
- "Esta semana tu estres bajo un 15%. Algo estas haciendo bien."
- "Los lunes suelen ser tus dias de mayor presion. Queres preparar una rutina para empezar la semana?"
- "Cuando escribis en el diario, tu claridad mental del dia siguiente suele mejorar."
- "Llevamos 3 semanas donde la presion financiera esta alta. Queres hablar de esto?"

**Estado vacio:**
- "Todavia estamos conociendonos. Despues de algunos check-ins, vamos a empezar a mostrarte patrones que te van a servir."

### 4.6 Centro de Contenido / Biblioteca Emocional

**Proposito:** Articulos, guias y reflexiones breves para temas especificos.

**Temas:**
- Presion financiera del emprendedor
- Miedo al fracaso
- Agotamiento y burnout
- Soledad de emprender
- Culpa por descansar
- Exceso de responsabilidad
- Comparacion con otros emprendedores
- Frustracion por resultados lentos
- Tomar decisiones bajo estres
- Manejar equipos cuando vos mismo estas agotado
- Imposter syndrome
- Separar identidad personal de identidad de negocio

**Formato:**
- Lecturas de 2-4 minutos
- Tono conversacional, no academico
- Con preguntas de reflexion al final
- Ilustraciones minimalistas

### 4.7 Rutinas de Bienestar Personalizadas

**Proposito:** Micro-rutinas sugeridas segun estado emocional.

**Tipos:**
- **Rutina de manana** (3 min): Intencion del dia + respiracion + frase
- **Cierre del dia** (3 min): Reflexion + gratitud + soltar
- **Pre-reunion** (2 min): Centrarse + intencion
- **Post-conflicto** (3 min): Regular + escribir + soltar
- **Descarga nocturna** (5 min): Vaciar la mente + respirar + desconectar

**Personalizacion:**
- Basada en check-ins recientes
- Adaptada a horarios de uso
- Ajustada a preferencias (mas escritura vs mas respiracion vs mas reflexion)

### 4.8 Progreso Emocional

**Proposito:** Mostrar evolucion sin competitividad ni gamificacion superficial.

**Metricas de progreso:**
- Dias de check-in consecutivos (racha suave)
- Tendencia de bienestar general
- Momentos de mayor claridad
- Herramientas mas usadas y su impacto
- Crecimiento en conciencia emocional

**Tono:**
- "No se trata de estar bien siempre. Se trata de conocerte mejor."
- "Llevas 14 dias registrando como te sentis. Eso ya es un acto de cuidado."
- "Tu promedio de estres bajo esta semana. Cada pequeno paso cuenta."

### 4.9 Soporte en Momentos Dificiles

**Proposito:** Flujo especial para dias de crisis o saturacion extrema.

**Triggers:**
- Check-in con estres 5/5 + energia 1/5
- Seleccion de emocion "No puedo mas"
- Acceso manual: boton "Necesito apoyo ahora"

**Flujo:**
1. Mensaje de contencion: "Estas aca y eso importa. Vamos despacio."
2. Opcion de respiracion guiada inmediata
3. Opcion de escribir lo que siente
4. Opcion de hablar con el asistente
5. Recurso: lineas de ayuda profesional (con tono humano, no clinico)
6. Mensaje de cierre: "No tenes que resolver todo hoy. A veces alcanza con hacer una pausa."

---

## 5. Mapa de Pantallas

```
Splash → Onboarding (5 pasos) → Auth (Login/Register)
                                        ↓
                                    Main App
                                        ↓
                    ┌───────────────────┼───────────────────┐
                    │                   │                   │
                  Home            Herramientas          Perfil
                    │                   │                   │
            ┌───────┼───────┐     ┌─────┼─────┐      ┌─────┼─────┐
            │       │       │     │     │     │      │     │     │
        Check-in  Diario  Chat  Resp  Pausas Ejer  Config  Prog  Hist
            │       │       │
        Resumen  Entrada  Conv
                    │
                Historial

Tab Bar: Home | Diario | Chat | Herramientas | Perfil
```

---

## 6. Descripcion de Cada Pantalla

### 6.1 Splash Screen
- Logo Sentio centrado con animacion suave de fade-in
- Fondo color primario profundo (#1A1A2E)
- Duracion: 2 segundos
- Transicion: dissolve al onboarding o home

### 6.2 Onboarding (5 pasos)

**Paso 1 — Bienvenida emocional:**
- Titulo: "Emprender es increible. Pero a veces pesa."
- Subtitulo: "Sentio es tu espacio para bajar la guardia, entenderte y avanzar con mas claridad."
- Visual: Ilustracion abstracta de calma (formas organicas suaves)

**Paso 2 — Que tipo de presion vivis:**
- Titulo: "Que es lo que mas te pesa hoy?"
- Opciones multiples (chips seleccionables):
  - Presion financiera
  - Agotamiento mental
  - Soledad de emprender
  - Miedo al fracaso
  - Sobrecarga de decisiones
  - Dificultad para desconectar
  - Frustracion por resultados
  - Manejo de equipo

**Paso 3 — Como te sentis ahora:**
- Titulo: "Y en este momento, como estas?"
- Selector de emocion visual (iconos expresivos pero adultos)
- Slider de energia

**Paso 4 — Que buscas en Sentio:**
- Titulo: "Que te gustaria encontrar aca?"
- Opciones:
  - Un espacio para descargar
  - Herramientas para calmarme
  - Entender mis patrones
  - Acompanamiento diario
  - Ordenar mi cabeza
  - Todo un poco

**Paso 5 — Compromiso suave:**
- Titulo: "No tenes que estar bien todo el tiempo. Solo tenes que empezar."
- Subtitulo: "Vamos a construir este espacio juntos, a tu ritmo."
- CTA: "Empezar"

### 6.3 Home Principal

**Objetivo:** Centro emocional del dia. Calido, util, personalizado.

**Estructura (scroll vertical):**

1. **Header:** Saludo personalizado + fecha
   - Manana: "Buenos dias, [nombre]. Como arrancas hoy?"
   - Tarde: "Hola, [nombre]. Como viene el dia?"
   - Noche: "Buenas noches, [nombre]. Como estuvo hoy?"

2. **Card de Check-in:**
   - Si no hizo check-in: Card destacada invitando a registrar
   - Si ya hizo: Resumen visual del estado del dia

3. **Sugerencia contextual:**
   - Basada en estado actual o patrones
   - Ej: "Tus ultimos dias fueron intensos. Que tal una pausa de 2 minutos?"
   - Link a herramienta o rutina sugerida

4. **Accesos rapidos:**
   - Escribir en el diario
   - Hablar con el asistente
   - Herramienta rapida

5. **Insight del dia:**
   - Dato breve sobre patrones recientes
   - Ej: "Los miercoles suelen ser tus dias de mayor claridad."

6. **Frase del dia:**
   - Frase breve, no cliche, relevante para emprendedores
   - Ej: "No necesitas tener todas las respuestas. Solo la siguiente."

### 6.4 Check-in Emocional (Pantalla completa)

**Flujo rapido:**
1. Seleccion de emocion (grilla visual, 1 tap)
2. Slider de energia
3. Slider de estres
4. [Opcional] Campo de texto
5. Resumen + mensaje personalizado

**Flujo profundo:**
- Mismo + claridad, motivacion, presion financiera, control, calidad del dia
- Cada slider con labels empaticas en los extremos
- Transiciones suaves entre pasos

### 6.5 Diario Personal

**Vista principal:** Lista cronologica de entradas con:
- Fecha
- Emocion dominante (badge de color)
- Preview del texto (2 lineas)
- Tags

**Vista escritura:**
- Pantalla completa, fondo limpio
- Prompt rotativo arriba (opcional, dismissable)
- Editor de texto simple
- Selector de emocion + tags al guardar
- Boton guardar sutil

### 6.6 Chat con Asistente

**Vista:** Interfaz conversacional limpia
- Burbujas de chat elegantes (no estilo WhatsApp — mas tipo editorial)
- El asistente usa texto, no emojis excesivos
- Input de texto con placeholder rotativo: "Contame como estas..."
- Sin avatar robotico — icono abstracto suave
- Historial de conversaciones previas accesible

### 6.7 Herramientas de Regulacion

**Vista principal:** Grid de herramientas organizadas por categoria
- Cards con icono, titulo, duracion, descripcion breve
- Filtros: Todas | Ansiedad | Enfoque | Descanso | Emprendedor
- Herramientas favoritas arriba

**Vista de herramienta:**
- Pantalla completa inmersiva
- Animacion visual (ej: circulo de respiracion)
- Instrucciones paso a paso
- Timer elegante
- Boton de salir discreto
- Feedback al completar

### 6.8 Insights / Tendencias

**Secciones:**
- Resumen semanal (ondas emocionales)
- Emociones mas frecuentes (circulo)
- Tendencia de estres (curva suave)
- Correlaciones descubiertas
- Comparacion con semanas anteriores (sutil)

### 6.9 Contenido / Biblioteca

**Vista:** Cards verticales con:
- Titulo del articulo
- Tiempo de lectura
- Tag de tema
- Ilustracion minimalista

**Vista de lectura:**
- Tipografia editorial elegante
- Fondo calido
- Progreso de lectura sutil
- Pregunta de reflexion al final
- CTA: "Queres escribir sobre esto?" → abre diario

### 6.10 Perfil / Ajustes

- Foto + nombre
- Racha de check-ins
- Estadisticas generales (discretas)
- Configuracion de notificaciones
- Recordatorio de check-in
- Tema (claro/oscuro)
- Privacidad y seguridad
- Sobre Sentio
- Cerrar sesion

### 6.11 Pantalla de Crisis / Apoyo Inmediato

- Fondo oscuro calido
- Mensaje de contencion grande y claro
- 3 opciones visuales:
  1. Respirar ahora (va a respiracion guiada)
  2. Escribir lo que siento (va a diario)
  3. Hablar con alguien (muestra lineas de ayuda)
- "No tenes que resolver nada ahora. Solo respira."

### 6.12 Historial Personal

- Timeline visual de check-ins
- Filtros por fecha, emocion, nivel de estres
- Acceso a entradas de diario por dia
- Vista calendario con indicadores de color

---

## 7. Flujos Clave

### Primer dia de uso:
Splash → Onboarding (5 pasos) → Registro → Home con card de bienvenida → Primer check-in guiado → Mensaje de bienvenida del asistente → Sugerencia de primera herramienta

### Check-in rapido (< 60 seg):
Home → Tap "Como estas?" → Seleccionar emocion → Energia → Estres → Guardar → Resumen del dia

### Check-in profundo:
Home → Tap "Check-in" → Emocion → Energia → Estres → Claridad → Motivacion → Presion → Control → Texto opcional → Resumen detallado

### Dia de saturacion:
Check-in con estres 5/5 → App detecta → Mensaje de contencion → Ofrece: respiracion / escribir / hablar con asistente → Cierra con mensaje calido

### Conversacion con asistente:
Tab Chat → Escribe o elige prompt sugerido → Conversacion fluida → Asistente puede sugerir herramienta o journaling → Cierre empatico

### Escritura en diario:
Tab Diario → "Nueva entrada" → Prompt opcional → Escribe → Elige emocion + tags → Guarda → Feedback suave

### Revision de patrones:
Home (insight del dia) → Tap para ver mas → Insights completos → Tendencias + correlaciones + sugerencias

### Rutina antes de dormir:
Notificacion suave → Abre app → Rutina nocturna: reflexion del dia (1 min) + gratitud (30 seg) + respiracion (1 min) → "Descansa bien"

### Apoyo inmediato:
Boton "Necesito apoyo" (accesible desde cualquier pantalla) → Pantalla de crisis → Respiracion / Escribir / Contacto profesional

---

## 8. Lineamientos Esteticos

### Paleta de Colores

**Modo Claro (principal):**
- Background: #FAFAF8 (blanco calido)
- Surface: #FFFFFF
- Card: #F5F3EF (crema suave)
- Primary: #3D5A80 (azul profundo calmo — confianza)
- Primary Light: #5B7BA5
- Secondary: #C9A96E (dorado calido — premium, calidez)
- Accent: #7B9E87 (sage/verde salvia — crecimiento)
- Success: #7B9E87
- Warning: #D4A574 (ambar suave)
- Error: #C75B5B (rojo suave)
- Text Primary: #1A1A2E (navy profundo)
- Text Secondary: #6B7280 (gris calido)
- Text Tertiary: #9CA3AF

**Modo Oscuro:**
- Background: #0F0F14 (negro calido)
- Surface: #1A1A24
- Card: #22222E
- Los demas colores se mantienen con ajustes de luminosidad

### Tipografia

- **Display/Headlines:** DM Serif Display (elegante, editorial, calido)
- **Body/UI:** DM Sans (limpio, moderno, legible)
- **Jerarquia:**
  - H1: 28px, DM Serif Display, semibold
  - H2: 24px, DM Serif Display, medium
  - H3: 20px, DM Sans, semibold
  - Body: 16px, DM Sans, regular
  - Caption: 14px, DM Sans, regular
  - Small: 12px, DM Sans, regular

### Iconografia
- Estilo: Outlined, suave, con esquinas redondeadas
- Grosor: 1.5px
- Sin relleno (solo trazo)
- Feeling: Minimal, calido, no tech

### Tarjetas / Cards
- Border radius: 16px
- Padding interno: 20px
- Sombra: muy sutil (0, 2, 8, rgba(0,0,0,0.04))
- Sin bordes visibles (se definen por sombra y fondo)

### Botones
- Primario: Fondo primary (#3D5A80), texto blanco, border radius 12px, height 52px
- Secundario: Fondo transparente, borde primary, texto primary
- Texto: Sin fondo ni borde, texto primary
- Todos con transicion suave al tap

### Espaciado
- Padding de pantalla: 24px horizontal
- Separacion entre secciones: 24px
- Separacion entre cards: 16px
- Mucho aire visual — no saturar

### Animaciones / Micro-interacciones
- Transiciones entre pantallas: slide horizontal suave (300ms)
- Aparicion de cards: fade-in + slide-up sutil
- Check-in completado: animacion de circulo que se completa
- Respiracion: circulo que expande/contrae con curva bezier
- Haptic feedback en acciones clave (iOS)
- Todo suave, nada brusco

### Ilustraciones
- Estilo: Abstracto organico — formas fluidas, no figurativas
- Colores: Dentro de la paleta, tonos pastel
- Uso: Onboarding, estados vacios, contenido, herramientas
- No: personas, caras, caricaturas, clipart

---

## 9. Direccion Emocional del Producto

Cada pantalla debe evocar una sensacion especifica:

| Pantalla | Sensacion |
|---|---|
| Home | Calma, claridad, bienvenida |
| Check-in | Intimidad, honestidad, cuidado |
| Diario | Refugio, libertad, desahogo |
| Chat | Acompanamiento, comprension, calidez |
| Herramientas | Accion, alivio, practica |
| Insights | Comprension, descubrimiento, esperanza |
| Contenido | Aprendizaje, empatia, relevancia |
| Crisis | Contencion, calma, seguridad |
| Progreso | Orgullo suave, reconocimiento, motivacion |

---

## 10. Tono y Microcopys

### Principios de tono:
- Hablar como un amigo sabio, no como un terapeuta
- Validar sin dramatizar
- Acompanar sin invadir
- Sugerir sin imponer
- Ser directo pero calido
- Nada cursi, nada infantil, nada clinico

### Ejemplos de microcopy:

**Bienvenida:**
- "Hola, [nombre]. Este es tu espacio."
- "Bienvenido de vuelta. Como estas hoy, de verdad?"

**Check-in:**
- "No hay respuestas correctas. Solo las tuyas."
- "Gracias por ser honesto con vos mismo."
- "Registrar como te sentis ya es un paso importante."

**Dias dificiles:**
- "Hoy fue pesado, y esta bien reconocerlo."
- "No tenes que resolverlo todo ahora."
- "A veces la fuerza esta en hacer una pausa."

**Asistente:**
- "Contame, que esta pasando?"
- "Eso suena como mucha carga. Queres que lo desarmemos juntos?"
- "No estoy aca para juzgar. Estoy aca para escuchar."

**Invitaciones a escribir:**
- "A veces escribir ayuda a ver mas claro."
- "Tu diario te esta esperando."
- "No tiene que ser perfecto. Solo tiene que ser honesto."

**Pausas:**
- "Una pausa de 2 minutos puede cambiar tu dia."
- "Tu cuerpo te esta pidiendo un respiro."
- "Respira. El mundo puede esperar un momento."

**Progreso:**
- "Llevas 7 dias cuidando de vos. Eso importa."
- "Tu estres promedio bajo esta semana. Algo estas haciendo bien."
- "No se trata de estar perfecto. Se trata de estar presente."

**Acompanamiento:**
- "Aca estoy, cuando quieras."
- "Emprender es dificil. No tenes que hacerlo solo."
- "Este espacio es tuyo. Usalo como necesites."

---

## 11. Estados Vacios

- **Sin check-ins:** "Todavia no registraste como te sentis hoy. Es un buen momento para empezar."
- **Diario vacio:** "Tu diario esta en blanco, como una pagina nueva. Escribi lo que necesites."
- **Sin conversaciones:** "Cuando quieras hablar, aca voy a estar."
- **Insights sin datos:** "Despues de algunos check-ins, voy a empezar a mostrarte patrones. Date unos dias."
- **Herramientas sin uso:** "Estas herramientas estan pensadas para vos. Explora la que te llame."

---

## 12. Personalizacion

**Segun uso:**
- Si usa mucho el diario → priorizar journaling en home
- Si usa herramientas rapidas → mostrar favoritas primero
- Si conversa seguido con el asistente → sugerir continuar conversacion

**Segun estado:**
- Si estres alto constante → sugerir herramientas de regulacion, contenido sobre burnout
- Si energia baja → rutinas suaves, mensajes de permiso para descansar
- Si presion financiera alta → contenido sobre manejo de estres financiero
- Si poca claridad mental → ejercicios de enfoque

**Segun horario:**
- Manana: rutina de inicio, intencion del dia
- Mediodia: check-in rapido, pausa
- Noche: cierre del dia, descarga, gratitud

---

## 13. Engagement Sano y No Invasivo

**Notificaciones:**
- Maximo 1-2 por dia
- Siempre configurables
- Tono calido, nunca urgente
- Ejemplos:
  - "Como fue tu dia? Tu check-in te espera." (noche)
  - "Buenos dias. Un minuto para empezar con intencion?" (manana)
  - NO: "No te olvides de usar Sentio!" (nunca)

**Rachas:**
- Mostrar dias consecutivos de check-in
- Sin penalizar por dias sin uso
- Si vuelve despues de ausencia: "Que bueno verte de vuelta. Sin presion, a tu ritmo."

**Recordatorios:**
- Suaves y configurables
- Respetar que el emprendedor ya tiene suficiente presion
- La app no debe generar mas presion

---

## 14. Premium y Monetizacion

**Plan gratuito:**
- Check-in diario (rapido)
- Diario (5 entradas/mes)
- 3 conversaciones con asistente/mes
- Herramientas basicas
- Insights semanales basicos

**Plan Premium:**
- Check-in profundo
- Diario ilimitado
- Conversaciones ilimitadas con asistente
- Todas las herramientas
- Insights avanzados y patrones
- Rutinas personalizadas
- Contenido completo
- Exportar datos
- Modo oscuro premium

---

## 15. Stack Tecnico

- **Mobile:** Flutter (iOS + Android)
- **Backend:** Supabase (Auth, Database, Storage, Edge Functions)
- **AI:** Claude API (asistente emocional)
- **Admin:** React + Vite + TypeScript + Tailwind CSS + shadcn/ui
- **State Management:** Provider
- **Routing:** GoRouter
- **Notificaciones:** Supabase Edge Functions + FCM/APNs

---

## 16. Admin Dashboard Web

**Funcionalidades:**
1. **Dashboard:** Usuarios activos, check-ins del dia, metricas clave
2. **Usuarios:** Lista, busqueda, perfil detallado, actividad
3. **Analiticas:** Uso por funcion, retencion, emociones mas reportadas
4. **Contenido:** CRUD de articulos, herramientas, frases del dia
5. **Moderacion:** Revision de flags del asistente IA
6. **Configuracion:** Settings generales, notificaciones

---

*Documento creado para el proyecto Sentio — Bienestar emocional para emprendedores.*
*Ultima actualizacion: 2026-03-11*
