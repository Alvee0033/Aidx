import 'package:flutter/material.dart';

class AppColors {
  // Primary colors (subtle, modern)
  static const Color primaryColor = Color(0xFF60A5FA); // blue-400
  static const Color accentColor = Color(0xFF22D3EE);  // cyan-400
  static const Color backgroundColor = Color(0xFF0F172A); // slate-900
  
  // Secondary colors
  static const Color secondaryColor = Color(0xFF1E293B); // slate-800
  static const Color surfaceColor = Color(0xFF111827);   // gray-900
  
  // Text colors (for dark background)
  static const Color textPrimary = Color(0xFFE5E7EB);   // gray-200
  static const Color textSecondary = Color(0xFF9CA3AF); // gray-400
  static const Color textLight = Color(0xFF6B7280);     // gray-500
  
  // Status colors (softened)
  static const Color successColor = Color(0xFF22C55E); // green-500
  static const Color warningColor = Color(0xFFF59E0B); // amber-500
  static const Color errorColor   = Color(0xFFEF4444); // red-500
  static const Color infoColor    = Color(0xFF3B82F6); // blue-500
  
  // Gradients (subtle)
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryColor, accentColor],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient accentGradient = LinearGradient(
    colors: [accentColor, primaryColor],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
} 