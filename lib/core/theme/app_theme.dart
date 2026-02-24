/// Dr. Vroom Trainer App Theme
/// Distinct from the Client App (green/teal accent for trainer role)
import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get trainerTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF00C896),
        brightness: Brightness.dark,
        primary: const Color(0xFF00C896),
        secondary: const Color(0xFF0088FF),
        surface: const Color(0xFF1A1A2E),
        error: const Color(0xFFFF4444),
      ),
      scaffoldBackgroundColor: const Color(0xFF0D0D1A),
      cardTheme: CardThemeData(
        color: const Color(0xFF1A1A2E),
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF0D0D1A),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          letterSpacing: 1,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF00C896),
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF1A1A2E),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF00C896), width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF00C896), width: 2),
        ),
        labelStyle: const TextStyle(color: Colors.white70),
        prefixIconColor: const Color(0xFF00C896),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFF1A1A2E),
        selectedColor: const Color(0xFF00C896),
        labelStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xFF1A1A2E),
        selectedItemColor: Color(0xFF00C896),
        unselectedItemColor: Colors.white38,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }

  // Status colors
  static Color statusColor(String status) {
    switch (status) {
      case 'normal': return const Color(0xFF00C896);
      case 'warning': return const Color(0xFFFFB800);
      case 'critical': return const Color(0xFFFF4444);
      default: return Colors.grey;
    }
  }

  // Component colors
  static Color componentColor(String component) {
    switch (component) {
      case 'engine': return const Color(0xFFFF6B35);
      case 'transmission': return const Color(0xFF9B59B6);
      case 'bearing': return const Color(0xFF3498DB);
      case 'brake': return const Color(0xFFE74C3C);
      case 'exhaust': return const Color(0xFF2ECC71);
      case 'belt': return const Color(0xFFF39C12);
      default: return Colors.grey;
    }
  }
}
