import 'package:flutter/material.dart';

class AppColors {
  // Dark/Sleek Theme Palette
  static const Color background = Color(0xFF0F172A);      // Slate 900
  static const Color surface = Color(0xFF1E293B);         // Slate 800
  static const Color primary = Color(0xFF6366F1);         // Indigo 500
  static const Color primaryDark = Color(0xFF4F46E5);     // Indigo 600
  static const Color accent = Color(0xFF10B981);          // Emerald 500
  static const Color textPrimary = Color(0xFFF8FAFC);     // Slate 50
  static const Color textSecondary = Color(0xFF94A3B8);   // Slate 400
  static const Color border = Color(0xFF334155);          // Slate 700
  static const Color error = Color(0xFFEF4444);           // Red 500
  
  // Gradients
  static const Gradient primaryGradient = LinearGradient(
    colors: [primary, Color(0xFF8B5CF6)],                // Indigo to Purple
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const Gradient cardGradient = LinearGradient(
    colors: [surface, Color(0xFF0F172A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
