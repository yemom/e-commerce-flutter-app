import 'package:flutter/material.dart';

import 'app_router.dart';

class DriverAppShell extends StatelessWidget {
  const DriverAppShell({super.key});

  @override
  Widget build(BuildContext context) {
    return Navigator(
      initialRoute: '/',
      onGenerateRoute: AppRouter.onGenerateRoute,
    );
  }
}
