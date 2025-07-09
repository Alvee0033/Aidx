import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Professional Color Palette - Enhanced
  static const Color bgDark = Color(0xFF0A192F);  // Deep midnight blue
  static const Color bgMedium = Color(0xFF112240);  // Rich navy
  static const Color bgLight = Color(0xFF1D3B53);  // Deep slate blue
  
  // Sophisticated Accent Colors
  static const Color primaryColor = Color(0xFF5CDB95);  // Soft mint green
  static const Color accentColor = Color(0xFF38B2AC);  // Teal
  static const Color dangerColor = Color(0xFFFF6B6B);  // Soft coral red
  static const Color warningColor = Color(0xFFFFA726);  // Warm orange
  static const Color successColor = Color(0xFF48BB78);  // Vibrant green
  static const Color infoColor = Color(0xFF4299E1);  // Bright blue
  
  // Refined Background Colors
  static const Color softWhite = Color(0xFFF0F4F8);  // Soft off-white
  static const Color textPrimary = Color(0xFFE2E8F0);  // Light slate
  static const Color textSecondary = Color(0xFFCBD5E0);  // Muted slate
  static const Color textMuted = Color(0xFF718096);  // Dark slate
  
  // Enhanced Gradient and Glass Effects
  static final LinearGradient bgGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      bgMedium.withOpacity(0.95),
      bgDark.withOpacity(0.98),
    ],
    stops: [0.1, 0.9],
    transform: const GradientRotation(0.4),  // Slight angle for more dynamism
  );

  // More Refined Glass Container Decoration
  static BoxDecoration glassContainer = BoxDecoration(
    color: bgLight.withOpacity(0.6),
    borderRadius: BorderRadius.circular(20),  // Slightly larger radius
    border: Border.all(
      color: softWhite.withOpacity(0.05),
      width: 1.5,
    ),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.4),
        blurRadius: 30,
        spreadRadius: 1,
        offset: const Offset(0, 15),
      ),
    ],
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        softWhite.withOpacity(0.1),
        softWhite.withOpacity(0.05),
      ],
      transform: const GradientRotation(0.2),  // Subtle gradient rotation
    ),
  );

  // More Dynamic Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFF5CDB95), Color(0xFF38B2AC), Color(0xFF4FD1C5)],
    transform: GradientRotation(0.3),
  );

  static const LinearGradient vitalsGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0x4D5CDB95), Color(0x4D38B2AC)], // Mint to teal with opacity
    transform: GradientRotation(0.2),
  );

  static const LinearGradient newsGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xCC5CDB95), Color(0xCC38B2AC)], // Mint to teal with opacity
    transform: GradientRotation(0.2),
  );

  // Enhanced Card Decoration
  static BoxDecoration cardDecoration = BoxDecoration(
    color: bgLight,
    borderRadius: BorderRadius.circular(20),  // Larger, softer corners
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.3),
        blurRadius: 25,
        spreadRadius: 1,
        offset: const Offset(0, 12),
      ),
    ],
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        bgMedium.withOpacity(0.8),
        bgDark.withOpacity(0.9),
      ],
      transform: const GradientRotation(0.3),
    ),
  );

  // Enhanced Text Styles
  static final TextStyle headlineLarge = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: softWhite,
    letterSpacing: 0.5,
    shadows: [
      Shadow(
        blurRadius: 10.0,
        color: Colors.black.withOpacity(0.3),
        offset: const Offset(0, 5),
      ),
    ],
  );

  static final TextStyle headlineMedium = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    color: softWhite.withOpacity(0.9),
    letterSpacing: 0.3,
  );

  static final TextStyle bodyText = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: textMuted,
    height: 1.6,
    letterSpacing: 0.2,
  );

  // Button Styles
  static final ButtonStyle primaryButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: primaryColor,
    foregroundColor: Colors.white,
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    elevation: 6,
    shadowColor: primaryColor.withOpacity(0.4),
  );

  // Card Decoration
  static BoxDecoration featureCardDecoration = BoxDecoration(
    color: bgGlassHeavy, // bg-white/70 equivalent
    borderRadius: BorderRadius.circular(16),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.1),
        blurRadius: 4,
        offset: const Offset(0, 2),
      ),
    ],
  );
  
  // Background colors - matching web version exactly
  static const Color bgDarkSecondary = Color(0xFF1B1030);
  static const Color bgGlassLight = Color(0x26FFFFFF); // white/15%
  static const Color bgGlassMedium = Color(0x40FFFFFF); // white/25%
  static const Color bgGlassHeavy = Color(0x1AFFFFFF); // rgba(255,255,255,0.1)
  
  // Text colors - matching web version
  static const Color textTeal = Color(0xFF14B8A6); // teal-500
  
  // The main theme - matching web version exactly
  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: Colors.transparent,
    colorScheme: const ColorScheme.dark(
      primary: primaryColor,
      secondary: accentColor,
      error: dangerColor,
      background: bgDark,
      surface: bgGlassLight,
    ),
    textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme).copyWith(
      displayLarge: const TextStyle(color: textPrimary),
      displayMedium: const TextStyle(color: textPrimary),
      displaySmall: const TextStyle(color: textPrimary),
      headlineLarge: const TextStyle(color: textPrimary),
      headlineMedium: const TextStyle(color: textPrimary),
      headlineSmall: const TextStyle(color: textPrimary, fontWeight: FontWeight.w600),
      titleLarge: const TextStyle(color: textPrimary, fontWeight: FontWeight.w600),
      titleMedium: const TextStyle(color: textPrimary, fontWeight: FontWeight.w600),
      titleSmall: const TextStyle(color: textPrimary, fontWeight: FontWeight.w500),
      bodyLarge: const TextStyle(color: textPrimary),
      bodyMedium: const TextStyle(color: textSecondary),
      bodySmall: const TextStyle(color: textMuted),
      labelLarge: const TextStyle(color: textPrimary),
      labelMedium: const TextStyle(color: textSecondary),
      labelSmall: const TextStyle(color: textMuted),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryColor,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryColor,
        side: const BorderSide(color: primaryColor),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: bgGlassMedium,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: primaryColor),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: dangerColor),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: bgGlassLight,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: textTeal,
      ),
    ),
    cardTheme: CardThemeData(
      color: bgGlassLight,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.white.withOpacity(0.1)),
      ),
    ),
    dividerTheme: DividerThemeData(
      color: Colors.white.withOpacity(0.1),
      thickness: 1,
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: bgGlassHeavy, // bg-white/80 equivalent
      selectedItemColor: textTeal,
      unselectedItemColor: textMuted,
      type: BottomNavigationBarType.fixed,
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: MaterialStateProperty.resolveWith<Color>((states) {
        if (states.contains(MaterialState.selected)) {
          return primaryColor;
        }
        return bgGlassMedium;
      }),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
      ),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: MaterialStateProperty.resolveWith<Color>((states) {
        if (states.contains(MaterialState.selected)) {
          return primaryColor;
        }
        return Colors.grey;
      }),
      trackColor: MaterialStateProperty.resolveWith<Color>((states) {
        if (states.contains(MaterialState.selected)) {
          return primaryColor.withOpacity(0.5);
        }
        return Colors.grey.withOpacity(0.5);
      }),
    ),
    radioTheme: RadioThemeData(
      fillColor: MaterialStateProperty.resolveWith<Color>((states) {
        if (states.contains(MaterialState.selected)) {
          return primaryColor;
        }
        return textMuted;
      }),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: primaryColor,
    ),
    sliderTheme: SliderThemeData(
      activeTrackColor: primaryColor,
      inactiveTrackColor: primaryColor.withOpacity(0.3),
      thumbColor: primaryColor,
      overlayColor: primaryColor.withOpacity(0.2),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: bgDarkSecondary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: bgDarkSecondary,
      contentTextStyle: GoogleFonts.inter(
        color: textPrimary,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    ),
  );

  // New background color
  static const Color backgroundColor = Color(0xFF111827); // gray-900
} 