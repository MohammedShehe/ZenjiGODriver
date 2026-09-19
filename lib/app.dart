import 'package:flutter/material.dart';
import 'core/app_state.dart';
import 'core/theme.dart';
import 'screens/onboarding.dart';

class ZenjiGoDriverApp extends StatefulWidget {
  const ZenjiGoDriverApp({super.key});

  @override
  State<ZenjiGoDriverApp> createState() => _ZenjiGoDriverAppState();
}

class _ZenjiGoDriverAppState extends State<ZenjiGoDriverApp> {
  final AppState state = AppState();

  @override
  Widget build(BuildContext context) {
    return AppScope(
      notifier: state,
      child: AnimatedBuilder(
        animation: state,
        builder: (context, _) => MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'ZenjiGO Driver',
          theme: ZenjiTheme.light(),
          darkTheme: ZenjiTheme.dark(),
          themeMode: state.themeMode,
          home: const OnboardingScreen(),
        ),
      ),
    );
  }
}
