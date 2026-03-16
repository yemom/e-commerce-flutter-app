/// Test coverage for pump_app behaviors.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> pumpTestApp(
  WidgetTester tester, {
  required Widget child,
  ProviderContainer? container,
  List<Override> overrides = const [],
}) async {
  final resolvedContainer =
      container ?? ProviderContainer(overrides: overrides);

  addTearDown(resolvedContainer.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: resolvedContainer,
      child: MaterialApp(home: child),
    ),
  );

  await tester.pumpAndSettle();
}
