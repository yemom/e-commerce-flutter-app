import 'package:e_commerce_app_with_django/driver_app/screens/driver_eddite_profile.dart';
import 'package:flutter/material.dart';

import 'screens/driver_entry_screen.dart';
import 'screens/home_screen.dart';
import 'screens/order_detail_screen.dart';
import 'screens/orders_screen.dart';
import 'screens/unknown_route_screen.dart';
import 'screens/register_screen.dart';

class AppRouter {
  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/':
        return MaterialPageRoute(builder: (_) => const DriverEntryScreen());
      case '/editProfile':
        return MaterialPageRoute(builder: (_) => const EditProfileScreen());
      case '/register':
        return MaterialPageRoute(builder: (_) => const RegisterScreen());
      case '/home':
        return MaterialPageRoute(builder: (_) => const HomeScreen());
      case '/orders':
        return MaterialPageRoute(builder: (_) => const OrdersScreen());
      case '/orderDetail':
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => OrderDetailScreen(orderId: args?['orderId'] ?? ''),
        );
      default:
        return MaterialPageRoute(builder: (_) => const UnknownRouteScreen());
    }
  }
}
