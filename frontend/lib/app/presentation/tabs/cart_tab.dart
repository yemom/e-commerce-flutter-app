library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:e_commerce_app_with_django/app/providers/app_flow_providers.dart';
import 'package:e_commerce_app_with_django/app/services/app_navigation_service.dart';
import 'package:e_commerce_app_with_django/app/presentation/widgets/app_status_screen.dart';
import 'package:e_commerce_app_with_django/features/auth/presentation/providers/auth_provider.dart';
import 'package:e_commerce_app_with_django/features/branches/presentation/providers/branch_provider.dart';
import 'package:e_commerce_app_with_django/features/cart/presentation/providers/cart_provider.dart';
import 'package:e_commerce_app_with_django/features/cart/presentation/screens/cart_screen.dart';
import 'package:e_commerce_app_with_django/features/checkout/application/checkout_service.dart';
import 'package:e_commerce_app_with_django/features/checkout/presentation/screens/address_screen.dart';
import 'package:e_commerce_app_with_django/features/checkout/presentation/screens/checkout_screen.dart';
import 'package:e_commerce_app_with_django/features/checkout/presentation/screens/flow/checkout_success_screen.dart';
import 'package:e_commerce_app_with_django/features/checkout/presentation/screens/flow/order_tracking_screen.dart';
import 'package:e_commerce_app_with_django/features/payment/application/payment_gateway_adapter.dart';
import 'package:e_commerce_app_with_django/features/payment/presentation/providers/payment_provider.dart';

class CartTab extends ConsumerWidget {
  const CartTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final branchState = ref.watch(branchProvider);
    final cartState = ref.watch(cartProvider);
    final paymentState = ref.watch(paymentProvider);
    final session = authState.session;

    if (session == null) {
      return const AppLoadingScreen();
    }

    final navigation = ref.read(appNavigationServiceProvider);
    final checkoutService = ref.read(checkoutServiceProvider);

    return CartScreen(
      state: cartState,
      onQuantityChanged: ({required productId, required quantity}) {
        ref
            .read(cartProvider.notifier)
            .updateQuantity(productId: productId, quantity: quantity);
      },
      onRemoveProduct: (productId) {
        ref.read(cartProvider.notifier).removeProduct(productId);
      },
      onCheckout: () async {
        final address = await navigation.push<String>(const AddressScreen());
        if (address == null || address.isEmpty) {
          return;
        }

        final previewOrder = checkoutService.buildPreviewOrder(
          cartState: cartState,
          selectedMethod: paymentState.selectedMethod,
          branchId: branchState.selectedBranchId ?? '',
          customerId: session.userId,
          customerName: session.userName,
          customerEmail: session.email,
          deliveryAddress: address,
        );

        await navigation.push(
          CheckoutScreen(
            orderPreview: previewOrder,
            deliveryAddress: address,
            paymentOptions: paymentState.options,
            selectedMethod: paymentState.selectedMethod,
            onPaymentMethodSelected: (method) {
              ref.read(paymentProvider.notifier).selectMethod(method);
            },
            onConfirmOrder: () async {
              try {
                final confirmed = await checkoutService.confirmCheckout(
                  cartState: ref.read(cartProvider),
                  selectedMethod: ref.read(paymentProvider).selectedMethod,
                  branchId: ref.read(branchProvider).selectedBranchId ?? '',
                  customerId: session.userId,
                  customerName: session.userName,
                  customerEmail: session.email,
                  deliveryAddress: address,
                );

                if (confirmed == null) {
                  navigation.showSnackBar(
                    'Payment is still pending. You can continue once you return from payment.',
                  );
                  return;
                }

                ref.read(storefrontTabIndexProvider.notifier).state = 2;
                navigation.pushReplacement(
                  CheckoutSuccessScreen(
                    onTrackOrder: () {
                      ref.read(storefrontTabIndexProvider.notifier).state = 2;
                      navigation.pushReplacement(
                        OrderTrackingScreen(order: confirmed),
                      );
                    },
                    onBackToShop: () {
                      ref.read(storefrontTabIndexProvider.notifier).state = 2;
                      navigation.popUntilFirst();
                    },
                  ),
                );
              } on PaymentGatewayException catch (error) {
                navigation.showSnackBar(error.message);
              } catch (_) {
                navigation.showSnackBar(
                  'We could not process your payment. Please try again.',
                );
              }
            },
          ),
        );
      },
    );
  }
}
