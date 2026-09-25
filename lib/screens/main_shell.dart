import 'package:flutter/material.dart';
import '../core/app_state.dart';
import 'chat.dart';
import 'earnings.dart';
import 'home.dart';
import 'profile.dart';

class MainShell extends StatelessWidget {
  const MainShell({super.key});
  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    const screens = [
      HomeScreen(),
      EarningsScreen(),
      ChatListScreen(),
      ProfileScreen(),
    ];
    return PopScope(
      canPop: state.navIndex == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) state.setNav(0);
      },
      child: Scaffold(
        body: IndexedStack(index: state.navIndex, children: screens),
        bottomNavigationBar: NavigationBar(
          selectedIndex: state.navIndex,
          onDestinationSelected: state.setNav,
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.home_outlined),
              selectedIcon: const Icon(Icons.home_rounded),
              label: state.t('Home', 'Nyumbani'),
            ),
            NavigationDestination(
              icon: const Icon(Icons.account_balance_wallet_outlined),
              selectedIcon: const Icon(Icons.account_balance_wallet_rounded),
              label: state.t('Earnings', 'Mapato'),
            ),
            NavigationDestination(
              icon: const Badge(label: Text('3'), child: Icon(Icons.chat_bubble_outline)),
              selectedIcon: const Badge(label: Text('3'), child: Icon(Icons.chat_bubble)),
              label: state.t('Chat', 'Mazungumzo'),
            ),
            NavigationDestination(
              icon: const Icon(Icons.person_outline),
              selectedIcon: const Icon(Icons.person),
              label: state.t('Profile', 'Wasifu'),
            ),
          ],
        ),
      ),
    );
  }
}
