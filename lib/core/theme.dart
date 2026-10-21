// ============================================================
// Jakdrain — Konstanta Warna & Tema Utama
// Sistem Monitoring Drainase Mikro Pemprov DKI Jakarta
// ============================================================
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Palet warna utama sesuai identitas visual Jakarta Smart City.
class JakdrainColors {
  JakdrainColors._();

  // ─── Primary Blues ──────────────────────────────────────────
  static const Color deepNavy = Color(0xFF0F172A);
  static const Color electricBlue = Color(0xFF0284C7);
  static const Color brandBlue = Color(0xFF0066FF);
  static const Color skyBlueAccent = Color(0xFF38BDF8);
  static const Color lightBlue50 = Color(0xFFE0F2FE);

  // ─── Surfaces ───────────────────────────────────────────────
  static const Color surface = Color(0xFFF8FAFC);
  static const Color cardWhite = Color(0xFFFFFFFF);
  static const Color divider = Color(0xFFE2E8F0);
  static const Color subtleGray = Color(0xFF94A3B8);
  static const Color darkText = Color(0xFF1E293B);

  // ─── Status & Alert ─────────────────────────────────────────
  static const Color critical = Color(0xFFEF4444);
  static const Color criticalLight = Color(0xFFFEE2E2);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFEF3C7);
  static const Color safe = Color(0xFF10B981);
  static const Color safeLight = Color(0xFFD1FAE5);

  // ─── Gradient Presets ───────────────────────────────────────
  static const LinearGradient headerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0066FF), Color(0xFF0284C7), Color(0xFF06B6D4)],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0284C7), Color(0xFF0066FF)],
  );
}

/// Tema aplikasi Jakdrain — berbasis Material 3.
class JakdrainTheme {
  JakdrainTheme._();

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: JakdrainColors.surface,
      colorScheme: ColorScheme.fromSeed(
        seedColor: JakdrainColors.electricBlue,
        brightness: Brightness.light,
        primary: JakdrainColors.electricBlue,
        secondary: JakdrainColors.skyBlueAccent,
        surface: JakdrainColors.surface,
        error: JakdrainColors.critical,
      ),
      textTheme: GoogleFonts.plusJakartaSansTextTheme().copyWith(
        headlineLarge: GoogleFonts.plusJakartaSans(
          fontSize: 28,
          fontWeight: FontWeight.w800,
          color: JakdrainColors.deepNavy,
        ),
        headlineMedium: GoogleFonts.plusJakartaSans(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: JakdrainColors.deepNavy,
        ),
        titleLarge: GoogleFonts.plusJakartaSans(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: JakdrainColors.deepNavy,
        ),
        titleMedium: GoogleFonts.plusJakartaSans(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: JakdrainColors.deepNavy,
        ),
        bodyLarge: GoogleFonts.plusJakartaSans(
          fontSize: 15,
          fontWeight: FontWeight.w400,
          color: JakdrainColors.darkText,
        ),
        bodyMedium: GoogleFonts.plusJakartaSans(
          fontSize: 13,
          fontWeight: FontWeight.w400,
          color: JakdrainColors.subtleGray,
        ),
        labelLarge: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: JakdrainColors.electricBlue,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: JakdrainColors.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: JakdrainColors.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: JakdrainColors.electricBlue,
            width: 2,
          ),
        ),
        hintStyle: GoogleFonts.plusJakartaSans(
          color: JakdrainColors.subtleGray,
          fontSize: 14,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: JakdrainColors.cardWhite,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        margin: EdgeInsets.zero,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
    );
  }
}
