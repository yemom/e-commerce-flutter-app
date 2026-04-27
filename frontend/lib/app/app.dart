library;

import 'package:flutter/material.dart';

import 'package:e_commerce_app_with_django/app/presentation/gateway/app_gateway.dart';
import 'package:e_commerce_app_with_django/app/services/app_navigation_service.dart';
import 'package:e_commerce_app_with_django/core/presentation/theme/app_theme.dart';

class KutukuApp extends StatelessWidget {
  const KutukuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Kutuku',
      theme: AppTheme.light,
      navigatorKey: appNavigatorKey,
      scaffoldMessengerKey: appScaffoldMessengerKey,
      home: const AppGateway(),
    );
  }
}
