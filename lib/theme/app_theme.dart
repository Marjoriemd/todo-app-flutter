import 'package:flutter/material.dart';

/// Define el tema visual de la aplicación.
/// Centraliza colores, tipografía y estilos para mantener consistencia.
class AppTheme {
  AppTheme._(); // Clase no instanciable

  // ─── Colores principales ─────────────────────────────────────────────────
  static const Color primaryColor = Color(0xFF6C63FF);
  static const Color secondaryColor = Color(0xFF03DAC6);
  static const Color backgroundColor = Color(0xFFF8F9FF);
  static const Color surfaceColor = Colors.white;
  static const Color errorColor = Color(0xFFB00020);

  // ─── Colores de prioridad ────────────────────────────────────────────────
  static const Color priorityHigh = Color(0xFFE53935);
  static const Color priorityMedium = Color(0xFFFB8C00);
  static const Color priorityLow = Color(0xFF43A047);

  /// Retorna el color correspondiente a la prioridad de la tarea.
  static Color getPriorityColor(String priority) {
    switch (priority) {
      case 'alta':
        return priorityHigh;
      case 'media':
        return priorityMedium;
      case 'baja':
        return priorityLow;
      default:
        return priorityMedium;
    }
  }

  /// Retorna el ícono correspondiente a la prioridad de la tarea.
  static IconData getPriorityIcon(String priority) {
    switch (priority) {
      case 'alta':
        return Icons.keyboard_double_arrow_up_rounded;
      case 'media':
        return Icons.drag_handle_rounded;
      case 'baja':
        return Icons.keyboard_double_arrow_down_rounded;
      default:
        return Icons.drag_handle_rounded;
    }
  }

  /// Tema claro de la aplicación.
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.light,
        surface: surfaceColor,
      ),
      scaffoldBackgroundColor: backgroundColor,
      fontFamily: 'Roboto',
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      cardTheme: CardThemeData(
        color: surfaceColor,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
      ),
    );
  }
}
