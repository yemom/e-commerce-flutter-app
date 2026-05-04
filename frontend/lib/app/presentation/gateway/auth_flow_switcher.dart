library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:e_commerce_app_with_django/app/providers/app_flow_providers.dart';
import 'package:e_commerce_app_with_django/app/services/app_navigation_service.dart';
import 'package:e_commerce_app_with_django/features/auth/presentation/providers/auth_provider.dart';
import 'package:e_commerce_app_with_django/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:e_commerce_app_with_django/features/auth/presentation/screens/login_screen.dart';
import 'package:e_commerce_app_with_django/features/auth/presentation/screens/sign_up_screen.dart';

class AuthFlowSwitcher extends ConsumerWidget {
  const AuthFlowSwitcher({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final authNotifier = ref.read(authProvider.notifier);
    final authFlowStep = ref.watch(authFlowStepProvider);
    final navigation = ref.read(appNavigationServiceProvider);

    switch (authFlowStep) {
      case AuthFlowStep.createAccount:
        return CreateAccountScreen(
          error: authState.error,
          onBackToLogin: () {
            ref.read(authFlowStepProvider.notifier).state = AuthFlowStep.login;
          },
          onCreateAccount:
              ({
                required fullName,
                required identifier,
                required password,
                required registerAsDriver,
                vehicleType,
                licenseNumber,
              }) async {
                await authNotifier.signUp(
                  fullName: fullName,
                  identifier: identifier,
                  password: password,
                  registerAsDriver: registerAsDriver,
                  vehicleType: vehicleType,
                  licenseNumber: licenseNumber,
                );
              },
        );
      case AuthFlowStep.login:
        return LoginScreen(
          error: authState.error,
          onCreateAccount: () {
            ref.read(authFlowStepProvider.notifier).state =
                AuthFlowStep.createAccount;
          },
          onForgotPassword: () {
            navigation.push(
              ForgotPasswordScreen(
                onRequestReset: ({required email}) {
                  return authNotifier.requestPasswordReset(email: email);
                },
                onConfirmReset:
                    ({required email, required token, required newPassword}) {
                      return authNotifier.resetPassword(
                        email: email,
                        token: token,
                        newPassword: newPassword,
                      );
                    },
              ),
            );
          },
          onLogin: ({required identifier, required password}) async {
            await authNotifier.login(
              identifier: identifier,
              password: password,
            );
          },
        );
    }
  }
}
