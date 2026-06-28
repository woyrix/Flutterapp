import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  AppTheme._();

  static const Color _cream = Color(0xFFFAF6EE);
  static const Color _ink = Color(0xFF1C1008);
  static const Color _bgDark = Color(0xFF120901);
  static const Color _darkSurface = Color(0xFF1E1108);
  static const Color _darkDrawer = Color(0xFF160D04);

  static TextTheme _buildTextTheme(Color bodyColor, Color displayColor) {
    return TextTheme(
      displayLarge: GoogleFonts.notoSerifDevanagari(
          fontSize: 40, fontWeight: FontWeight.w600, color: displayColor),
      displayMedium: GoogleFonts.notoSerifDevanagari(
          fontSize: 32, fontWeight: FontWeight.w600, color: displayColor),
      displaySmall: GoogleFonts.notoSerifDevanagari(
          fontSize: 24, fontWeight: FontWeight.w600, color: displayColor),
      headlineMedium: GoogleFonts.notoSerifDevanagari(
          fontSize: 20, fontWeight: FontWeight.w700, color: displayColor),
      headlineSmall: GoogleFonts.notoSerifDevanagari(
          fontSize: 18, fontWeight: FontWeight.w600, color: displayColor),
      titleLarge: GoogleFonts.notoSerifDevanagari(
          fontSize: 17, fontWeight: FontWeight.w600, color: displayColor),
      titleMedium: GoogleFonts.notoSerifDevanagari(
          fontSize: 15, fontWeight: FontWeight.w600, color: bodyColor),
      bodyLarge: GoogleFonts.notoSerifDevanagari(fontSize: 18, height: 1.85, color: bodyColor),
      bodyMedium: GoogleFonts.notoSerifDevanagari(fontSize: 16, height: 1.75, color: bodyColor),
      bodySmall: GoogleFonts.notoSerifDevanagari(fontSize: 13, color: bodyColor.withOpacity(0.65)),
      labelLarge: GoogleFonts.notoSerifDevanagari(
          fontSize: 14, fontWeight: FontWeight.w600, color: bodyColor),
      labelSmall: GoogleFonts.notoSerifDevanagari(
          fontSize: 11, color: bodyColor.withOpacity(0.55)),
    );
  }

  static ThemeData light(Color accent) {
    const Color bg = _cream;
    const Color surface = Color(0xFFF3ECE0);
    const Color onBg = _ink;

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: bg,
      colorScheme: ColorScheme.light(
        primary: accent,
        onPrimary: Colors.white,
        secondary: accent,
        onSecondary: _ink,
        surface: surface,
        onSurface: _ink,
        background: bg,
        onBackground: onBg,
        outline: accent.withOpacity(0.35),
        surfaceVariant: const Color(0xFFEDE4D3),
        onSurfaceVariant: _ink.withOpacity(0.75),
      ),
      textTheme: _buildTextTheme(onBg, accent),
      iconTheme: IconThemeData(color: accent),
      appBarTheme: AppBarTheme(
        backgroundColor: bg,
        foregroundColor: accent,
        elevation: 0,
        scrolledUnderElevation: 1,
        shadowColor: accent.withOpacity(0.2),
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        titleTextStyle: GoogleFonts.notoSerifDevanagari(
            fontSize: 20, fontWeight: FontWeight.w700, color: accent),
        iconTheme: IconThemeData(color: accent),
        actionsIconTheme: IconThemeData(color: accent),
      ),
      drawerTheme: const DrawerThemeData(
          backgroundColor: _cream, surfaceTintColor: Colors.transparent),
      bottomAppBarTheme: const BottomAppBarThemeData(
          color: bg, elevation: 4, shadowColor: Colors.black26),
      dividerTheme: DividerThemeData(color: accent.withOpacity(0.2), thickness: 0.8),
      listTileTheme: const ListTileThemeData(textColor: _ink),
      sliderTheme: SliderThemeData(
        activeTrackColor: accent,
        thumbColor: accent,
        inactiveTrackColor: accent.withOpacity(0.2),
        overlayColor: accent.withOpacity(0.12),
        trackHeight: 2.5,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: _ink,
        contentTextStyle: GoogleFonts.notoSerifDevanagari(color: accent, fontSize: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: accent.withOpacity(0.2))),
      ),
      textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(foregroundColor: accent)),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }

  static ThemeData dark(Color accent) {
    const Color bg = _bgDark;
    const Color surface = _darkSurface;
    const Color onBg = Color(0xFFEDE0CC);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bg,
      colorScheme: ColorScheme.dark(
        primary: accent,
        onPrimary: _ink,
        secondary: accent,
        onSecondary: Colors.white,
        surface: surface,
        onSurface: onBg,
        background: bg,
        onBackground: onBg,
        outline: accent.withOpacity(0.3),
        surfaceVariant: const Color(0xFF251A0A),
        onSurfaceVariant: onBg.withOpacity(0.75),
      ),
      textTheme: _buildTextTheme(onBg, accent),
      iconTheme: IconThemeData(color: accent),
      appBarTheme: AppBarTheme(
        backgroundColor: bg,
        foregroundColor: accent,
        elevation: 0,
        scrolledUnderElevation: 1,
        shadowColor: Colors.black45,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: GoogleFonts.notoSerifDevanagari(
            fontSize: 20, fontWeight: FontWeight.w700, color: accent),
        iconTheme: IconThemeData(color: accent),
        actionsIconTheme: IconThemeData(color: accent),
      ),
      drawerTheme: const DrawerThemeData(
          backgroundColor: _darkDrawer, surfaceTintColor: Colors.transparent),
      bottomAppBarTheme: const BottomAppBarThemeData(
          color: _darkSurface, elevation: 8, shadowColor: Colors.black87),
      dividerTheme: DividerThemeData(color: accent.withOpacity(0.15), thickness: 0.8),
      listTileTheme: ListTileThemeData(textColor: onBg),
      sliderTheme: SliderThemeData(
        activeTrackColor: accent,
        thumbColor: accent,
        inactiveTrackColor: accent.withOpacity(0.2),
        overlayColor: accent.withOpacity(0.12),
        trackHeight: 2.5,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: _darkSurface,
        contentTextStyle: GoogleFonts.notoSerifDevanagari(color: accent, fontSize: 15),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: accent.withOpacity(0.3))),
        behavior: SnackBarBehavior.floating,
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: accent.withOpacity(0.15))),
      ),
      textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(foregroundColor: accent)),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: _ink,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }
}