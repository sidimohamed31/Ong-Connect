import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Charify-inspired theme for ONG Connect
/// Modern charity app design with vibrant colors and clean typography
class CharifyTheme {
  // ==================== Colors ====================

  // Primary Colors - Vibrant Green (Wecare theme)
  static const Color primaryGreen = Color(0xFF00D09E);
  static const Color primaryGreenDark = Color(0xFF00B386);
  static const Color primaryGreenLight = Color(0xFF33DAB3);

  // Accent Colors - Warm Orange (Call-to-action)
  static const Color accentOrange = Color(0xFFF39C12);
  static const Color accentOrangeLight = Color(0xFFF5B041);

  // Status Colors
  static const Color successGreen = Color(0xFF28A745);
  static const Color warningYellow = Color(0xFFFFC107);
  static const Color dangerRed = Color(0xFFDC3545);
  static const Color infoBlue = Color(0xFF17A2B8);

  // Neutral Colors
  static const Color darkGrey = Color(0xFF2C3E50);
  static const Color mediumGrey = Color(0xFF7F8C8D);
  static const Color textSecondary = mediumGrey;
  static const Color lightGrey = Color(0xFFECF0F1);
  static const Color backgroundGrey = Color(0xFFF8F9FA);
  static const Color white = Color(0xFFFFFFFF);

  // Gradient Colors
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryGreen, primaryGreenDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [accentOrange, accentOrangeLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ==================== Spacing ====================
  static const double space4 = 4.0;
  static const double space6 = 6.0;
  static const double space8 = 8.0;
  static const double space12 = 12.0;
  static const double space16 = 16.0;
  static const double space20 = 20.0;
  static const double space24 = 24.0;
  static const double space32 = 32.0;
  static const double space48 = 48.0;

  // ==================== Border Radius ====================
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 16.0;
  static const double radiusXLarge = 20.0;
  static const double radiusRound = 100.0;

  // ==================== Typography ====================
  static TextTheme _buildTextTheme(TextTheme base, String locale) {
    // Use Cairo for Arabic, Poppins for French/English
    final fontFamily = locale == 'ar'
        ? GoogleFonts.cairo().fontFamily
        : GoogleFonts.poppins().fontFamily;

    return base.copyWith(
      // Display styles
      displayLarge: TextStyle(
        fontFamily: fontFamily,
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: darkGrey,
        height: 1.2,
      ),
      displayMedium: TextStyle(
        fontFamily: fontFamily,
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: darkGrey,
        height: 1.2,
      ),
      displaySmall: TextStyle(
        fontFamily: fontFamily,
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: darkGrey,
        height: 1.3,
      ),

      // Headline styles
      headlineLarge: TextStyle(
        fontFamily: fontFamily,
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: darkGrey,
        height: 1.3,
      ),
      headlineMedium: TextStyle(
        fontFamily: fontFamily,
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: darkGrey,
        height: 1.3,
      ),
      headlineSmall: TextStyle(
        fontFamily: fontFamily,
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: darkGrey,
        height: 1.4,
      ),

      // Title styles
      titleLarge: TextStyle(
        fontFamily: fontFamily,
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: darkGrey,
        height: 1.4,
      ),
      titleMedium: TextStyle(
        fontFamily: fontFamily,
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: darkGrey,
        height: 1.4,
      ),
      titleSmall: TextStyle(
        fontFamily: fontFamily,
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: darkGrey,
        height: 1.4,
      ),

      // Body styles
      bodyLarge: TextStyle(
        fontFamily: fontFamily,
        fontSize: 16,
        fontWeight: FontWeight.normal,
        color: darkGrey,
        height: 1.5,
      ),
      bodyMedium: TextStyle(
        fontFamily: fontFamily,
        fontSize: 14,
        fontWeight: FontWeight.normal,
        color: darkGrey,
        height: 1.5,
      ),
      bodySmall: TextStyle(
        fontFamily: fontFamily,
        fontSize: 12,
        fontWeight: FontWeight.normal,
        color: mediumGrey,
        height: 1.5,
      ),

      // Label styles
      labelLarge: TextStyle(
        fontFamily: fontFamily,
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: darkGrey,
        height: 1.4,
      ),
      labelMedium: TextStyle(
        fontFamily: fontFamily,
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: mediumGrey,
        height: 1.4,
      ),
      labelSmall: TextStyle(
        fontFamily: fontFamily,
        fontSize: 10,
        fontWeight: FontWeight.w500,
        color: mediumGrey,
        height: 1.4,
      ),
    );
  }

  // ==================== Light Theme ====================
  static ThemeData getLightTheme(String locale) {
    final base = ThemeData.light();

    return ThemeData(
      useMaterial3: true,

      // Color scheme
      colorScheme: ColorScheme.light(
        primary: primaryGreen,
        primaryContainer: primaryGreenLight,
        secondary: accentOrange,
        secondaryContainer: accentOrangeLight,
        error: dangerRed,
        surface: white,
        onPrimary: white,
        onSecondary: white,
        onSurface: darkGrey,
        onError: white,
      ),

      scaffoldBackgroundColor: backgroundGrey,

      // Typography
      textTheme: _buildTextTheme(base.textTheme, locale),

      // App Bar Theme
      appBarTheme: AppBarTheme(
        elevation: 0,
        backgroundColor: white,
        foregroundColor: darkGrey,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: locale == 'ar'
              ? GoogleFonts.cairo().fontFamily
              : GoogleFonts.poppins().fontFamily,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: darkGrey,
        ),
        iconTheme: const IconThemeData(color: darkGrey),
      ),

      // Card Theme
      cardTheme: CardThemeData(
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
        ),
        color: white,
        margin: const EdgeInsets.symmetric(
          horizontal: space16,
          vertical: space8,
        ),
      ),

      // Button Themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGreen,
          foregroundColor: white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: space24,
            vertical: space16,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMedium),
          ),
          textStyle: TextStyle(
            fontFamily: locale == 'ar'
                ? GoogleFonts.cairo().fontFamily
                : GoogleFonts.poppins().fontFamily,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryGreen,
          side: const BorderSide(color: primaryGreen, width: 1.5),
          padding: const EdgeInsets.symmetric(
            horizontal: space24,
            vertical: space16,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMedium),
          ),
          textStyle: TextStyle(
            fontFamily: locale == 'ar'
                ? GoogleFonts.cairo().fontFamily
                : GoogleFonts.poppins().fontFamily,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryGreen,
          padding: const EdgeInsets.symmetric(
            horizontal: space16,
            vertical: space12,
          ),
          textStyle: TextStyle(
            fontFamily: locale == 'ar'
                ? GoogleFonts.cairo().fontFamily
                : GoogleFonts.poppins().fontFamily,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: lightGrey,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: const BorderSide(color: primaryGreen, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: const BorderSide(color: dangerRed, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: space16,
          vertical: space16,
        ),
        hintStyle: TextStyle(
          fontFamily: locale == 'ar'
              ? GoogleFonts.cairo().fontFamily
              : GoogleFonts.poppins().fontFamily,
          fontSize: 14,
          color: mediumGrey,
        ),
      ),

      // Chip Theme
      chipTheme: ChipThemeData(
        backgroundColor: lightGrey,
        selectedColor: primaryGreen,
        labelStyle: TextStyle(
          fontFamily: locale == 'ar'
              ? GoogleFonts.cairo().fontFamily
              : GoogleFonts.poppins().fontFamily,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: space12,
          vertical: space8,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusRound),
        ),
      ),

      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: white,
        selectedItemColor: primaryGreen,
        unselectedItemColor: mediumGrey,
        selectedLabelStyle: TextStyle(
          fontFamily: locale == 'ar'
              ? GoogleFonts.cairo().fontFamily
              : GoogleFonts.poppins().fontFamily,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: TextStyle(
          fontFamily: locale == 'ar'
              ? GoogleFonts.cairo().fontFamily
              : GoogleFonts.poppins().fontFamily,
          fontSize: 12,
          fontWeight: FontWeight.normal,
        ),
        elevation: 8,
        type: BottomNavigationBarType.fixed,
      ),

      // Floating Action Button Theme
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryGreen,
        foregroundColor: white,
        elevation: 4,
      ),
    );
  }
}
