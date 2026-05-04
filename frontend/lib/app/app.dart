library;

import 'package:flutter/material.dart';

import 'package:e_commerce_app_with_django/app/presentation/gateway/app_gateway.dart';
import 'package:e_commerce_app_with_django/app/services/app_navigation_service.dart';
import 'package:e_commerce_app_with_django/core/presentation/theme/app_theme.dart';
import 'package:e_commerce_app_with_django/features/admin/auth/presentation/screens/admin_login_screen.dart';
import 'package:e_commerce_app_with_django/features/admin/dashboard/presentation/screens/admin_home_screen.dart';
import 'package:e_commerce_app_with_django/features/driver/auth/presentation/screens/driver_login_screen.dart';
import 'package:e_commerce_app_with_django/features/driver/home/presentation/screens/driver_home_screen.dart';
import 'package:e_commerce_app_with_django/features/user/auth/presentation/screens/user_login_screen.dart';
import 'package:e_commerce_app_with_django/features/user/home/presentation/screens/user_home_screen.dart';

class GulitApp extends StatelessWidget {
  const GulitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'GULIT GEBEYA',
      theme: AppTheme.light,
      navigatorKey: appNavigatorKey,
      scaffoldMessengerKey: appScaffoldMessengerKey,
      routes: <String, WidgetBuilder>{
        '/driver/login': (_) => const DriverLoginScreen(),
        '/driver/home': (_) => const DriverHomeScreen(),
        '/user/login': (_) => const UserLoginScreen(),
        '/user/home': (_) => const UserHomeScreen(),
        '/admin/login': (_) => const AdminLoginScreen(),
        '/admin/home': (_) => const AdminHomeScreen(),
      },
      home: const AppGateway(),
    );
  }
}

