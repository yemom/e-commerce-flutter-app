library;

import 'package:flutter/material.dart';

class BottomNavShell extends StatelessWidget {
  const BottomNavShell({
    super.key,
    required this.currentIndex,
    required this.pages,
    required this.onDestinationSelected,
  });

  final int currentIndex;
  final List<Widget> pages;
  final ValueChanged<int> onDestinationSelected;

  static const _destinations = [
    NavigationDestination(icon: Icon(Icons.storefront_outlined), label: 'Shop'),
    NavigationDestination(
      icon: Icon(Icons.shopping_bag_outlined),
      label: 'Cart',
    ),
    NavigationDestination(
      icon: Icon(Icons.receipt_long_outlined),
      label: 'Orders',
    ),
    NavigationDestination(
      icon: Icon(Icons.person_outline_rounded),
      label: 'Profile',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: currentIndex, children: pages),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x140F172A),
                  blurRadius: 24,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: NavigationBar(
              selectedIndex: currentIndex,
              onDestinationSelected: onDestinationSelected,
              destinations: _destinations,
            ),
          ),
        ),
      ),
    );
  }
}
