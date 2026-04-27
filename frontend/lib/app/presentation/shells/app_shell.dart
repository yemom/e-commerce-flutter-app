library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:e_commerce_app_with_django/app/presentation/shells/bottom_nav_shell.dart';
import 'package:e_commerce_app_with_django/app/presentation/tabs/cart_tab.dart';
import 'package:e_commerce_app_with_django/app/presentation/tabs/home_tab.dart';
import 'package:e_commerce_app_with_django/app/presentation/tabs/orders_tab.dart';
import 'package:e_commerce_app_with_django/app/presentation/tabs/profile_tab.dart';
import 'package:e_commerce_app_with_django/app/presentation/widgets/app_status_screen.dart';
import 'package:e_commerce_app_with_django/app/providers/app_flow_providers.dart';
import 'package:e_commerce_app_with_django/features/orders/application/order_service.dart';

class AppShell extends ConsumerWidget {
  const AppShell({super.key});

  static const _pages = [HomeTab(), CartTab(), OrdersTab(), ProfileTab()];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bootstrap = ref.watch(storefrontBootstrapProvider);
    final currentIndex = ref.watch(storefrontTabIndexProvider);

    if (bootstrap.isLoading) {
      return const AppLoadingScreen();
    }

    if (bootstrap.hasError) {
      return const AppMessageScreen(
        message: 'We could not load the storefront. Please try again.',
      );
    }

    if (currentIndex >= _pages.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(storefrontTabIndexProvider.notifier).state = 0;
      });
    }

    final safeIndex = currentIndex >= _pages.length ? 0 : currentIndex;
    return BottomNavShell(
      currentIndex: safeIndex,
      pages: _pages,
      onDestinationSelected: (index) {
        ref.read(storefrontTabIndexProvider.notifier).state = index;
        if (index == 2) {
          ref.read(orderServiceProvider).refreshOrders();
        }
      },
    );
  }
}
