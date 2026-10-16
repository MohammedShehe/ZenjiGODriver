import 'package:flutter/material.dart';
import 'core/app_state.dart';
import 'core/theme.dart';
import 'core/beach_atmosphere.dart';
import 'core/min_size_guard.dart';
import 'screens/onboarding.dart';
import 'screens/login.dart';
import 'screens/main_shell.dart';

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
          builder: (context, child) => MinSizeGuard(
            child: BeachAtmosphere(child: child ?? const SizedBox.shrink()),
          ),
          home: AnimatedBuilder(animation: state,builder: (context,_) { if(state.authenticated) return const MainShell(); return const DriverEntryScreen(); }),
        ),
      ),
    );
  }
}

class DriverEntryScreen extends StatelessWidget {
 const DriverEntryScreen({super.key});
 @override Widget build(BuildContext context)=>Scaffold(body:SafeArea(child:Column(children:[
  Expanded(child:Center(child:Padding(padding:const EdgeInsets.all(24),child:Column(mainAxisSize:MainAxisSize.min,children:[
   const Icon(Icons.local_taxi,size:72),const SizedBox(height:18),Text('ZenjiGO Driver',style:TextStyle(fontSize:28,fontWeight:FontWeight.w900)),const SizedBox(height:10),const Text('Earn safely, receive nearby trips and manage your settlements.'),const SizedBox(height:28),
   SizedBox(width:double.infinity,child:FilledButton(onPressed:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const DriverLoginScreen())),child:const Text('SIGN IN'))),
   const SizedBox(height:10),SizedBox(width:double.infinity,child:OutlinedButton(onPressed:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const OnboardingScreen())),child:const Text('REGISTER'))),
  ])))),
 ])));
}
