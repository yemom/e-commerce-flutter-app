library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final appNavigatorKey = GlobalKey<NavigatorState>();
final appScaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

final appNavigationServiceProvider = Provider<AppNavigationService>(
  (ref) => const AppNavigationService(),
);

class AppNavigationService {
  const AppNavigationService();

  NavigatorState get _navigator {
    final navigator = appNavigatorKey.currentState;
    if (navigator == null) {
      throw StateError('Navigator is not ready yet.');
    }
    return navigator;
  }

  BuildContext get _context {
    final context = appNavigatorKey.currentContext;
    if (context == null) {
      throw StateError('Navigation context is not ready yet.');
    }
    return context;
  }

  ScaffoldMessengerState get _messenger {
    final messenger = appScaffoldMessengerKey.currentState;
    if (messenger == null) {
      throw StateError('ScaffoldMessenger is not ready yet.');
    }
    return messenger;
  }

  Future<T?> push<T>(Widget page) {
    return _navigator.push(_route<T>(page));
  }

  Future<T?> pushReplacement<T extends Object?, TO extends Object?>(
    Widget page,
  ) {
    return _navigator.pushReplacement<T, TO>(_route<T>(page));
  }

  void pop<T extends Object?>([T? result]) {
    if (_navigator.canPop()) {
      _navigator.pop(result);
    }
  }

  void popUntilFirst() {
    _navigator.popUntil((route) => route.isFirst);
  }

  void showSnackBar(String message) {
    _messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<T?> showAppDialog<T>({
    required WidgetBuilder builder,
    bool barrierDismissible = true,
  }) {
    return showDialog<T>(
      context: _context,
      barrierDismissible: barrierDismissible,
      builder: builder,
    );
  }

  Future<T> runWithBlockingDialog<T>({
    required String message,
    required Future<T> Function() task,
  }) async {
    showDialog<void>(
      context: _context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        content: Row(
          children: [
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
            const SizedBox(width: 16),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );

    try {
      return await task();
    } finally {
      final context = appNavigatorKey.currentContext;
      if (context != null &&
          Navigator.of(context, rootNavigator: true).canPop()) {
        Navigator.of(context, rootNavigator: true).pop();
      }
    }
  }

  MaterialPageRoute<T> _route<T>(Widget page) {
    return MaterialPageRoute<T>(builder: (_) => page);
  }
}
