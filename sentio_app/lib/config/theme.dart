import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SentioColors {
  // Core palette (B2Better template)
  static const primary = Color(0xFF0404FB); // Electric Blue
  static const primaryLight = Color(0xFF3030FF);
  static const accent = Color(0xFF00FFBD); // Cyan Green
  static const secondary = Color(0xFFC9A96E); // Warm Gold (kept for legacy)
  static const success = Color(0xFF00FFBD);
  static const warning = Color(0xFFD4A574);
  static const error = Color(0xFFE05252);

  // Backgrounds
  static const background = Color(0xFF0F0F0F);
  static const surface = Color(0xFF1A1A1A);
  static const card = Color(0xFF1A1A1A);

  // Text
  static const textPrimary = Color(0xFFF0F0F0);
  static const textSecondary = Color(0xFF808080);
  static const textTertiary = Color(0xFF606060);

  // Borders & dividers
  static final border = Colors.white.withOpacity(0.1);
  static final borderSubtle = Colors.white.withOpacity(0.05);
  static const divider = Color(0xFF2A2A2A);

  // Dark theme aliases (same as core)
  static const darkBackground = background;
  static const darkSurface = surface;
  static const darkCard = card;
  static const darkTextPrimary = textPrimary;
  static const darkTextSecondary = textSecondary;
  static const darkDivider = divider;

  // Emotion colors
  static const emotionCalm = Color(0xFF7B9E87);
  static const emotionFocused = Color(0xFF3D5A80);
  static const emotionMotivated = Color(0xFFC9A96E);
  static const emotionGrateful = Color(0xFF9B8EC4);
  static const emotionHopeful = Color(0xFF6DB3C4);
  static const emotionTired = Color(0xFF8E8E93);
  static const emotionOverwhelmed = Color(0xFFD4A574);
  static const emotionAnxious = Color(0xFFD4856A);
  static const emotionFrustrated = Color(0xFFC75B5B);
  static const emotionSad = Color(0xFF7A8BA8);
  static const emotionInsecure = Color(0xFFB8A9C9);
  static const emotionLonely = Color(0xFF8B9DC3);
  static const emotionPressured = Color(0xFFCC8B6E);
  static const emotionAngry = Color(0xFFBF4E4E);
  static const emotionBlocked = Color(0xFF6B7280);
}

class SentioEffects {
  static BoxDecoration glowCard({Color? glowColor}) {
    return BoxDecoration(
      color: SentioColors.surface,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: SentioColors.border),
      boxShadow: glowColor != null
          ? [BoxShadow(color: glowColor.withOpacity(0.3), blurRadius: 15, spreadRadius: -2)]
          : null,
    );
  }

  static BoxDecoration gradientCard({Color? glowColor}) {
    return BoxDecoration(
      gradient: const LinearGradient(
        colors: [SentioColors.surface, Color(0xFF0F0F0F)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: SentioColors.border),
      boxShadow: glowColor != null
          ? [BoxShadow(color: glowColor.withOpacity(0.2), blurRadius: 20, spreadRadius: -4)]
          : null,
    );
  }

  static BoxDecoration standardCard() {
    return BoxDecoration(
      color: SentioColors.surface,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: SentioColors.border),
    );
  }

  static List<BoxShadow> glow(Color color, {double blur = 10, double opacity = 0.3}) {
    return [BoxShadow(color: color.withOpacity(opacity), blurRadius: blur, spreadRadius: -2)];
  }
}

class SentioTheme {
  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: SentioColors.background,
      colorScheme: const ColorScheme.dark(
        primary: SentioColors.primary,
        secondary: SentioColors.secondary,
        tertiary: SentioColors.accent,
        surface: SentioColors.surface,
        error: SentioColors.error,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: SentioColors.textPrimary,
        onError: Colors.white,
      ),
      textTheme: _buildTextTheme(),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.manrope(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: SentioColors.textPrimary,
          letterSpacing: -0.3,
        ),
        iconTheme: const IconThemeData(color: SentioColors.textPrimary),
      ),
      cardTheme: CardThemeData(
        color: SentioColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: SentioColors.border),
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: SentioColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.manrope(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: SentioColors.primary,
          side: const BorderSide(color: SentioColors.primary),
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.manrope(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: SentioColors.primary,
          textStyle: GoogleFonts.manrope(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: SentioColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: SentioColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: SentioColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: SentioColors.primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        hintStyle: GoogleFonts.manrope(
          color: SentioColors.textSecondary,
          fontSize: 14,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.transparent,
        selectedItemColor: SentioColors.primary,
        unselectedItemColor: SentioColors.textSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        showUnselectedLabels: true,
      ),
      dividerTheme: const DividerThemeData(
        color: SentioColors.divider,
        thickness: 1,
        space: 1,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: SentioColors.surface,
        selectedColor: SentioColors.primary.withOpacity(0.15),
        labelStyle: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w500),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: SentioColors.border),
        ),
        side: BorderSide(color: SentioColors.border),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }

  static ThemeData dark() {
    return light();
  }

  static TextTheme _buildTextTheme() {
    const color = SentioColors.textPrimary;
    const secondaryColor = SentioColors.textSecondary;

    final base = TextTheme(
      displayLarge: GoogleFonts.manrope(
        fontSize: 32,
        fontWeight: FontWeight.w800,
        color: color,
        letterSpacing: -0.5,
      ),
      displayMedium: GoogleFonts.manrope(
        fontSize: 28,
        fontWeight: FontWeight.w800,
        color: color,
        letterSpacing: -0.5,
      ),
      displaySmall: GoogleFonts.manrope(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: color,
        letterSpacing: -0.3,
      ),
      headlineLarge: GoogleFonts.manrope(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: color,
        letterSpacing: -0.3,
      ),
      headlineMedium: GoogleFonts.manrope(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: color,
        letterSpacing: -0.2,
      ),
      headlineSmall: GoogleFonts.manrope(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: color,
        letterSpacing: -0.2,
      ),
      titleLarge: GoogleFonts.manrope(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: color,
      ),
      titleMedium: GoogleFonts.manrope(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: color,
      ),
      titleSmall: GoogleFonts.manrope(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: color,
      ),
      bodyLarge: GoogleFonts.manrope(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: color,
      ),
      bodyMedium: GoogleFonts.manrope(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: color,
      ),
      bodySmall: GoogleFonts.manrope(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: secondaryColor,
      ),
      labelLarge: GoogleFonts.manrope(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: color,
      ),
      labelMedium: GoogleFonts.manrope(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: secondaryColor,
      ),
      labelSmall: GoogleFonts.manrope(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: secondaryColor,
      ),
    );

    // Fallback de emoji en TODOS los estilos: garantiza que los emojis
    // (usados como íconos en varias pantallas) se rendericen y no como cuadros.
    TextStyle? e(TextStyle? s) =>
        s?.copyWith(fontFamilyFallback: const ['NotoEmoji']);
    return base.copyWith(
      displayLarge: e(base.displayLarge),
      displayMedium: e(base.displayMedium),
      displaySmall: e(base.displaySmall),
      headlineLarge: e(base.headlineLarge),
      headlineMedium: e(base.headlineMedium),
      headlineSmall: e(base.headlineSmall),
      titleLarge: e(base.titleLarge),
      titleMedium: e(base.titleMedium),
      titleSmall: e(base.titleSmall),
      bodyLarge: e(base.bodyLarge),
      bodyMedium: e(base.bodyMedium),
      bodySmall: e(base.bodySmall),
      labelLarge: e(base.labelLarge),
      labelMedium: e(base.labelMedium),
      labelSmall: e(base.labelSmall),
    );
  }
}
