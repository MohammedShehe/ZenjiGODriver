import 'package:flutter/material.dart';

class ZenjiColors {
  static const darkBg = Color(0xFF0B1A33);
  static const darkAccent = Color(0xFF4FC3A1);
  static const skyBlue = Color(0xFF3BA9E0);
  static const darkText = Color(0xFFF2F4F7);
  static const green = Color(0xFF34A853);
  static const darkHighlight = Color(0xFFF9A825);
  static const lightBg = Color(0xFFF9FAFB);
  static const lightNavy = Color(0xFF14213D);
  static const teal = Color(0xFF007B8A);
  static const charcoal = Color(0xFF333333);
  static const lightHighlight = Color(0xFFFDB813);
}

class ZenjiTheme {
  static ThemeData dark() => _theme(
    brightness: Brightness.dark,
    scaffold: ZenjiColors.darkBg,
    text: ZenjiColors.darkText,
    primary: ZenjiColors.darkAccent,
    secondary: ZenjiColors.skyBlue,
    card: const Color(0xFF112747),
    field: const Color(0xFF102340),
  );

  static ThemeData light() => _theme(
    brightness: Brightness.light,
    scaffold: ZenjiColors.lightBg,
    text: ZenjiColors.charcoal,
    primary: ZenjiColors.teal,
    secondary: ZenjiColors.lightNavy,
    card: Colors.white,
    field: const Color(0xFFF0F3F6),
  );

  static ThemeData _theme({required Brightness brightness, required Color scaffold, required Color text, required Color primary, required Color secondary, required Color card, required Color field}) {
    final scheme = ColorScheme.fromSeed(seedColor: primary, brightness: brightness, primary: primary, secondary: secondary, surface: card);
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: scaffold,
      fontFamily: 'Roboto',
      textTheme: ThemeData(brightness: brightness).textTheme.apply(bodyColor: text, displayColor: text),
      cardTheme: CardThemeData(color: card, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
      inputDecorationTheme: InputDecorationTheme(
        filled: true, fillColor: field,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: primary.withValues(alpha: .14))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: primary, width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(style: ElevatedButton.styleFrom(
        backgroundColor: ZenjiColors.green, foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(54), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      )),
      snackBarTheme: SnackBarThemeData(behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
      navigationBarTheme: NavigationBarThemeData(height: 72, backgroundColor: card, indicatorColor: primary.withValues(alpha: .18), labelBehavior: NavigationDestinationLabelBehavior.alwaysShow),
      appBarTheme: AppBarTheme(backgroundColor: Colors.transparent, elevation: 0, scrolledUnderElevation: 0, centerTitle: false),
      dividerTheme: DividerThemeData(color: text.withValues(alpha: .10)),
    );
  }
}
