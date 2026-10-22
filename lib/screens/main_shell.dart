import 'package:flutter/material.dart';
import '../core/app_state.dart';
import 'chat.dart';
import 'earnings.dart';
import 'home.dart';
import 'profile.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  @override
  void initState() {
    super.initState();
    // Refresh unread count when shell mounts and periodically while visible.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AppScope.of(context).refreshUnreadMessages();
    });
  }

  Widget _chatIcon({required bool selected, required int unread}) {
    final icon = Icon(selected ? Icons.chat_bubble : Icons.chat_bubble_outline);
    if (unread <= 0) return icon;
    final label = unread > 99 ? '99+' : '$unread';
    return Badge(
      label: Text(label),
      isLabelVisible: true,
      child: icon,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    const screens = [
      HomeScreen(),
      EarningsScreen(),
      ChatListScreen(),
      ProfileScreen(),
    ];
    final unread = state.unreadMessages;
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
              icon: _chatIcon(selected: false, unread: unread),
              selectedIcon: _chatIcon(selected: true, unread: unread),
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
