import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// Zanzibar coastal palette shared by the entire Driver app.
class ZenjiColors {
  // Evening ocean
  static const darkBg = Color(0xFF06283A);
  static const darkAccent = Color(0xFF31D0C6);
  static const skyBlue = Color(0xFF45B9E8);
  static const darkText = Color(0xFFF7FBFA);
  static const green = Color(0xFF149B72);
  static const darkHighlight = Color(0xFFF39A5A);

  // Daylight / sand / lagoon
  static const lightBg = Color(0xFFFDF7E9);
  static const lightNavy = Color(0xFF073B4C);
  static const teal = Color(0xFF008F91);
  static const charcoal = Color(0xFF20363D);
  static const lightHighlight = Color(0xFFF7C65C);
  static const sand = Color(0xFFF4D9A6);
  static const coral = Color(0xFFE98263);
  static const lagoon = Color(0xFF39C6C0);
  static const seaFoam = Color(0xFFE7FAF6);
  static const error = Color(0xFFD94A4A);
}

class ZenjiTheme {
  static ThemeData dark() => _theme(
        brightness: Brightness.dark,
        scaffold: ZenjiColors.darkBg,
        text: ZenjiColors.darkText,
        primary: ZenjiColors.darkAccent,
        secondary: ZenjiColors.skyBlue,
        card: const Color(0xE61A4B58),
        field: const Color(0xD9133D4C),
      );

  static ThemeData light() => _theme(
        brightness: Brightness.light,
        scaffold: ZenjiColors.lightBg,
        text: ZenjiColors.charcoal,
        primary: ZenjiColors.teal,
        secondary: ZenjiColors.coral,
        card: const Color(0xF7FFFFFF),
        field: const Color(0xEFFFFFFF),
      );

  static ThemeData _theme({
    required Brightness brightness,
    required Color scaffold,
    required Color text,
    required Color primary,
    required Color secondary,
    required Color card,
    required Color field,
  }) {
    final dark = brightness == Brightness.dark;
    final scheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: brightness,
      primary: primary,
      secondary: secondary,
      surface: card,
      error: ZenjiColors.error,
    );

    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: Colors.transparent,
      fontFamily: GoogleFonts.poppins().fontFamily,
      fontFamilyFallback: const [
        'Noto Sans',
        'Noto Color Emoji',
        'Segoe UI Emoji',
        'Apple Color Emoji',
      ],
    );

    return base.copyWith(
      textTheme: GoogleFonts.poppinsTextTheme(base.textTheme).apply(
        bodyColor: text,
        displayColor: text,
      ).copyWith(
        displayLarge: GoogleFonts.playfairDisplay(fontWeight: FontWeight.w700, color: text),
        displayMedium: GoogleFonts.playfairDisplay(fontWeight: FontWeight.w700, color: text),
        displaySmall: GoogleFonts.playfairDisplay(fontWeight: FontWeight.w700, color: text),
        headlineLarge: GoogleFonts.playfairDisplay(fontWeight: FontWeight.w700, color: text),
        headlineMedium: GoogleFonts.playfairDisplay(fontWeight: FontWeight.w700, color: text),
        headlineSmall: GoogleFonts.playfairDisplay(fontWeight: FontWeight.w700, color: text),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        systemOverlayStyle: dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
        titleTextStyle: GoogleFonts.playfairDisplay(
          color: text,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
        iconTheme: IconThemeData(color: text),
      ),
      cardTheme: CardThemeData(
        color: card,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shadowColor: dark ? Colors.black26 : ZenjiColors.lightNavy.withValues(alpha: .10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: dark ? ZenjiColors.darkBg : Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          minimumSize: const Size.fromHeight(54),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          textStyle: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: BorderSide(color: primary, width: 1.4),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 15),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          textStyle: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: field,
        contentPadding: const EdgeInsets.symmetric(horizontal: 17, vertical: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: primary.withValues(alpha: .14)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: ZenjiColors.error, width: 1.5),
        ),
        hintStyle: GoogleFonts.poppins(
          color: dark ? const Color(0xFFB7D2D4) : const Color(0xFF5E7478),
          fontSize: 14,
        ),
        labelStyle: GoogleFonts.poppins(
          color: dark ? const Color(0xFFB7D2D4) : const Color(0xFF5E7478),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 76,
        backgroundColor: card,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        indicatorColor: primary.withValues(alpha: .18),
        labelTextStyle: WidgetStatePropertyAll(
          GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w700),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: dark ? const Color(0xFF1A4B58) : ZenjiColors.lightNavy,
        contentTextStyle: GoogleFonts.poppins(color: Colors.white),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: card,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
        titleTextStyle: GoogleFonts.playfairDisplay(fontSize: 21, fontWeight: FontWeight.w700, color: text),
        contentTextStyle: GoogleFonts.poppins(fontSize: 14, color: text),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: card,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      dividerTheme: DividerThemeData(color: primary.withValues(alpha: .14)),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) => states.contains(WidgetState.selected) ? primary : null),
        trackColor: WidgetStateProperty.resolveWith((states) => primary.withValues(alpha: states.contains(WidgetState.selected) ? .28 : .10)),
      ),
    );
  }
}
