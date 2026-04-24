import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ── Palette ───────────────────────────────────────────────────────────────
  static const Color navy       = Color(0xFF1E3A5F);
  static const Color navyDark   = Color(0xFF0D2137);
  static const Color cyan       = Color(0xFF00BCD4);
  static const Color cyanDark   = Color(0xFF0097A7);
  static const Color surface    = Color(0xFFF8F9FA);
  static const Color white      = Color(0xFFFFFFFF);
  static const Color textDark   = Color(0xFF1A1A2E);
  static const Color textGrey   = Color(0xFF6B7280);
  static const Color border     = Color(0xFFE5E7EB);
  static const Color success    = Color(0xFF10B981);
  static const Color warning    = Color(0xFFF59E0B);
  static const Color error      = Color(0xFFEF4444);
  static const Color aiPurple   = Color(0xFF7C3AED);
  static const Color aiIndigo   = Color(0xFF4F46E5);
  static const Color cardBg     = Color(0xFFFFFFFF);
  static const Color darkBg     = Color(0xFF0D1117);
  static const Color darkSurface = Color(0xFF161B22);
  static const Color darkCard   = Color(0xFF21262D);

  // ── Gradients ─────────────────────────────────────────────────────────────
  static const LinearGradient heroGradient = LinearGradient(
    colors: [navy, navyDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient aiGradient = LinearGradient(
    colors: [aiPurple, aiIndigo],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cyanGradient = LinearGradient(
    colors: [cyan, cyanDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient saveGradient = LinearGradient(
    colors: [navy, cyan],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  // ── Text Styles ───────────────────────────────────────────────────────────
  static TextStyle get displayLarge  => GoogleFonts.inter(fontSize: 32, fontWeight: FontWeight.w800, color: textDark);
  static TextStyle get displayMedium => GoogleFonts.inter(fontSize: 26, fontWeight: FontWeight.w700, color: textDark);
  static TextStyle get headingLarge  => GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700, color: textDark);
  static TextStyle get headingMedium => GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: textDark);
  static TextStyle get headingSmall  => GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: textDark);
  static TextStyle get bodyLarge     => GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w400, color: textDark);
  static TextStyle get bodyMedium    => GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w400, color: textGrey);
  static TextStyle get bodySmall     => GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w400, color: textGrey);
  static TextStyle get labelLarge    => GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: white);
  static TextStyle get labelMedium   => GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: textGrey);

  // ── Light Theme ───────────────────────────────────────────────────────────
  static ThemeData get light {
    final base = ThemeData.light(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: surface,
      colorScheme: const ColorScheme.light(
        primary: navy,
        secondary: cyan,
        surface: white,
        error: error,
        onPrimary: white,
        onSecondary: white,
        onSurface: textDark,
      ),
      textTheme: GoogleFonts.interTextTheme(base.textTheme).copyWith(
        displayLarge: displayLarge,
        headlineMedium: headingLarge,
        titleLarge: headingMedium,
        bodyLarge: bodyLarge,
        bodyMedium: bodyMedium,
        labelLarge: labelLarge,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: navy,
        foregroundColor: white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 18, fontWeight: FontWeight.w700, color: white,
        ),
        iconTheme: const IconThemeData(color: white),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: navy,
          foregroundColor: white,
          elevation: 2,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: navy,
          side: const BorderSide(color: navy, width: 1.5),
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      cardTheme: CardTheme(
        color: white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: border, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: cyan,
        inactiveTrackColor: border,
        thumbColor: navy,
        overlayColor: navy.withOpacity(0.12),
        trackHeight: 3,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: white,
        selectedItemColor: navy,
        unselectedItemColor: textGrey,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600),
        unselectedLabelStyle: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w400),
        elevation: 12,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: navy, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: textDark,
        contentTextStyle: GoogleFonts.inter(color: white, fontSize: 14),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      dividerTheme: const DividerThemeData(color: border, thickness: 1),
      iconTheme: const IconThemeData(color: navy),
    );
  }

  // ── Dark Theme ────────────────────────────────────────────────────────────
  static ThemeData get dark {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: darkBg,
      colorScheme: const ColorScheme.dark(
        primary: cyan,
        secondary: aiPurple,
        surface: darkCard,
        error: error,
        onPrimary: white,
        onSecondary: white,
        onSurface: white,
      ),
      textTheme: GoogleFonts.interTextTheme(base.textTheme),
      appBarTheme: AppBarTheme(
        backgroundColor: darkSurface,
        foregroundColor: white,
        elevation: 0,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 18, fontWeight: FontWeight.w700, color: white,
        ),
      ),
      cardTheme: CardTheme(
        color: darkCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.white.withOpacity(0.08)),
        ),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: cyan,
        inactiveTrackColor: Colors.white24,
        thumbColor: white,
        trackHeight: 3,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: darkCard,
        contentTextStyle: GoogleFonts.inter(color: white, fontSize: 14),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
