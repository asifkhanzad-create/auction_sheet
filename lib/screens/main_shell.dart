import 'package:flutter/material.dart';
import '../widgets/nav_icons.dart';
import '../widgets/floating_nav_bar.dart';
import 'new_request_screen.dart';
import 'my_requests_screen.dart';
import 'profile_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          const NewRequestScreen(),
          MyRequestsScreen(isActive: _index == 1),
          const ProfileScreen(),
        ],
      ),
      extendBody: true,
      bottomNavigationBar: FloatingNavBar(
        selectedIndex: _index,
        onSelect: (i) => setState(() => _index = i),
        items: const [
          FloatingNavItem(icon: NavIconType.home, label: 'Home'),
          FloatingNavItem(icon: NavIconType.inbox, label: 'Inbox'),
          FloatingNavItem(icon: NavIconType.account, label: 'Profile'),
        ],
      ),
    );
  }
}