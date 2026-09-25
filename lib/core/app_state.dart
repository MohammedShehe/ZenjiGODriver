import 'package:flutter/material.dart';

class AppState extends ChangeNotifier {
  ThemeMode themeMode = ThemeMode.dark;
  bool isSwahili = false;
  bool online = false;
  int navIndex = 0;
  String applicationStatus = 'Pending';

  void setTheme(ThemeMode mode) { themeMode = mode; notifyListeners(); }
  void toggleTheme(bool dark) => setTheme(dark ? ThemeMode.dark : ThemeMode.light);
  void setLanguage(bool swahili) { isSwahili = swahili; notifyListeners(); }
  void setOnline(bool value) { online = value; notifyListeners(); }
  void setNav(int index) { navIndex = index; notifyListeners(); }
  void setApplicationStatus(String status) { applicationStatus = status; notifyListeners(); }

  /// Translate helper: returns Swahili when language is Kiswahili, otherwise English.
  String t(String en, String sw) => isSwahili ? sw : en;
}

class AppScope extends InheritedNotifier<AppState> {
  const AppScope({super.key, required AppState notifier, required super.child}) : super(notifier: notifier);
  static AppState of(BuildContext context) => context.dependOnInheritedWidgetOfExactType<AppScope>()!.notifier!;
}
