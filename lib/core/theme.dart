import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ── VailMeds Palette ─────────────────────────────────────────
  static const Color primaryColor = Color(0xFFEC5B13);
  static const Color secondaryColor = Color(0xFFD97706); // Burnished Gold
  static const Color backgroundColor = Color(0xFFF8F6F6);
  static const Color darkBackgroundColor = Color(0xFF0F172A); // Midnight Obsidian
  static const Color surfaceColor = Colors.white;
  static const Color darkSurfaceColor = Color(0xFF1E293B);

  static const Color textPrimaryColor = Color(0xFF1E293B);
  static const Color textSecondaryColor = Color(0xFF64748B);
  static const Color textTertiaryColor = Color(0xFF94A3B8);
  static const Color borderColor = Color(0xFFE2E8F0);

  // ── VailMeds Glassmorphism ───────────────────────────────
  static const double glassBlur = 20.0;
  static double glassOpacity = 0.65;
  
  static BoxDecoration get glassDecoration => BoxDecoration(
    color: Colors.white.withValues(alpha: glassOpacity),
    borderRadius: BorderRadius.circular(cardRadius),
    border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
  );

  static LinearGradient get premiumGradient => const LinearGradient(
    colors: [primaryColor, secondaryColor],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ── Antigravity Spacing ─────────────────────────────────────────
  static const double pagePadding = 24.0;
  static const double cardRadius = 20.0; // Increased for modern look
  static const double inputRadius = 14.0;
  static const double buttonRadius = 14.0;
  static const double buttonHeight = 56.0;

  /// Signature floating shadow — barely visible, wide spread
  static List<BoxShadow> get floatingShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 30,
          offset: const Offset(0, 12),
        ),
      ];

  /// Accent glow shadow for primary-colored elements
  static List<BoxShadow> get primaryGlow => [
        BoxShadow(
          color: primaryColor.withValues(alpha: 0.2),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
      ];

  // ── Light Theme ─────────────────────────────────────────────────
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: false,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: backgroundColor,
      colorScheme: const ColorScheme.light(
        primary: primaryColor,
        secondary: secondaryColor,
        surface: surfaceColor,
        onSurface: textPrimaryColor,
      ),
      fontFamily: GoogleFonts.outfit().fontFamily,
      textTheme: GoogleFonts.outfitTextTheme(
        ThemeData.light().textTheme,
      ).copyWith(
        displayLarge: GoogleFonts.outfit(
            fontSize: 32, fontWeight: FontWeight.bold, color: textPrimaryColor),
        displayMedium: GoogleFonts.outfit(
            fontSize: 28, fontWeight: FontWeight.w700, color: textPrimaryColor),
        displaySmall: GoogleFonts.outfit(
            fontSize: 24, fontWeight: FontWeight.w600, color: textPrimaryColor),
        headlineMedium: GoogleFonts.outfit(
            fontSize: 20, fontWeight: FontWeight.w600, color: textPrimaryColor),
        titleLarge: GoogleFonts.outfit(
            fontSize: 18, fontWeight: FontWeight.bold, color: textPrimaryColor),
        titleMedium: GoogleFonts.outfit(
            fontSize: 16, fontWeight: FontWeight.w600, color: textPrimaryColor),
        bodyLarge: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.normal,
            color: textPrimaryColor),
        bodyMedium: GoogleFonts.outfit(
            fontSize: 14,
            fontWeight: FontWeight.normal,
            color: textSecondaryColor),
        bodySmall: GoogleFonts.outfit(
            fontSize: 12,
            fontWeight: FontWeight.normal,
            color: textTertiaryColor),
        labelLarge: GoogleFonts.outfit(
            fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
      ),

      // ── App Bar ─────────────────────────────────────────────────
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white.withValues(alpha: 0.85),
        elevation: 0,
        iconTheme: const IconThemeData(color: textPrimaryColor),
        titleTextStyle: GoogleFonts.outfit(
          color: textPrimaryColor,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        centerTitle: true,
      ),

      // ── Card ────────────────────────────────────────────────────
      cardTheme: CardThemeData(
        color: surfaceColor,
        elevation: 0,
        shadowColor: Colors.black.withValues(alpha: 0.05),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(cardRadius)),
      ),

      // ── Input ───────────────────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        hintStyle: GoogleFonts.outfit(color: textTertiaryColor, fontSize: 15),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(inputRadius),
          borderSide: const BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(inputRadius),
          borderSide: const BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(inputRadius),
          borderSide: const BorderSide(color: primaryColor, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(inputRadius),
          borderSide: const BorderSide(color: Color(0xFFEF4444)),
        ),
      ),

      // ── Buttons ─────────────────────────────────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size(double.infinity, buttonHeight),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(buttonRadius)),
          textStyle:
              GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          textStyle:
              GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textPrimaryColor,
          side: const BorderSide(color: borderColor),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(buttonRadius)),
          textStyle:
              GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),

      // ── Bottom Navigation ───────────────────────────────────────
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: primaryColor,
        unselectedItemColor: textTertiaryColor,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle:
            GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold),
        unselectedLabelStyle:
            GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w500),
        elevation: 8,
      ),

      // ── Divider ─────────────────────────────────────────────────
      dividerTheme: const DividerThemeData(
        color: borderColor,
        thickness: 1,
        space: 0,
      ),
      scrollbarTheme: ScrollbarThemeData(
        thumbColor: WidgetStateProperty.all(primaryColor.withValues(alpha: 0.8)),
        radius: const Radius.circular(8),
        thickness: WidgetStateProperty.all(6),
      ),
    );
  }

  // ── Dark Theme ──────────────────────────────────────────────────
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: false,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: darkBackgroundColor,
      colorScheme: const ColorScheme.dark(
        primary: primaryColor,
        secondary: secondaryColor,
        surface: darkSurfaceColor,
        onSurface: Colors.white,
      ),
      fontFamily: GoogleFonts.outfit().fontFamily,
      textTheme: GoogleFonts.outfitTextTheme(
        ThemeData.dark().textTheme,
      ).copyWith(
        displayLarge: GoogleFonts.outfit(
            fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
        displayMedium: GoogleFonts.outfit(
            fontSize: 28, fontWeight: FontWeight.w700, color: Colors.white),
        displaySmall: GoogleFonts.outfit(
            fontSize: 24, fontWeight: FontWeight.w600, color: Colors.white),
        headlineMedium: GoogleFonts.outfit(
            fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white),
        titleLarge: GoogleFonts.outfit(
            fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
        titleMedium: GoogleFonts.outfit(
            fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
        bodyLarge: GoogleFonts.outfit(
            fontSize: 16, fontWeight: FontWeight.normal, color: Colors.white70),
        bodyMedium: GoogleFonts.outfit(
            fontSize: 14, fontWeight: FontWeight.normal, color: Colors.white70),
        bodySmall: GoogleFonts.outfit(
            fontSize: 12, fontWeight: FontWeight.normal, color: Colors.white54),
        labelLarge: GoogleFonts.outfit(
            fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: darkSurfaceColor.withValues(alpha: 0.85),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: GoogleFonts.outfit(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        centerTitle: true,
      ),
      cardTheme: CardThemeData(
        color: darkSurfaceColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cardRadius),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkSurfaceColor,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        hintStyle: GoogleFonts.outfit(color: Colors.white38, fontSize: 15),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(inputRadius),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(inputRadius),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(inputRadius),
          borderSide: const BorderSide(color: primaryColor, width: 1.5),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: darkSurfaceColor,
        selectedItemColor: primaryColor,
        unselectedItemColor: Colors.white38,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle:
            GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold),
        unselectedLabelStyle:
            GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w500),
        elevation: 0,
      ),
      dividerTheme: DividerThemeData(
        color: Colors.white.withValues(alpha: 0.1),
        thickness: 1,
        space: 0,
      ),
      scrollbarTheme: ScrollbarThemeData(
        thumbColor: WidgetStateProperty.all(primaryColor.withValues(alpha: 0.8)),
        radius: const Radius.circular(8),
        thickness: WidgetStateProperty.all(6),
      ),
    );

  }
}
