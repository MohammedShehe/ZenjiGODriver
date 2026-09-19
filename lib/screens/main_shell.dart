import 'package:flutter/material.dart';
import '../core/app_state.dart';
import 'chat.dart';
import 'earnings.dart';
import 'home.dart';
import 'profile.dart';

class MainShell extends StatelessWidget {
  const MainShell({super.key});
  @override Widget build(BuildContext context){
    final state=AppScope.of(context);
    const screens=[HomeScreen(),EarningsScreen(),ChatListScreen(),ProfileScreen()];
    return PopScope(canPop:state.navIndex==0,onPopInvokedWithResult:(didPop,_){if(!didPop)state.setNav(0);},child:Scaffold(body:IndexedStack(index:state.navIndex,children:screens),bottomNavigationBar:NavigationBar(selectedIndex:state.navIndex,onDestinationSelected:state.setNav,destinations:const[
      NavigationDestination(icon:Icon(Icons.home_outlined),selectedIcon:Icon(Icons.home_rounded),label:'Home'),
      NavigationDestination(icon:Icon(Icons.account_balance_wallet_outlined),selectedIcon:Icon(Icons.account_balance_wallet_rounded),label:'Earnings'),
      NavigationDestination(icon:Badge(label:Text('3'),child:Icon(Icons.chat_bubble_outline)),selectedIcon:Badge(label:Text('3'),child:Icon(Icons.chat_bubble)),label:'Chat'),
      NavigationDestination(icon:Icon(Icons.person_outline),selectedIcon:Icon(Icons.person),label:'Profile'),
    ])));
  }
}
