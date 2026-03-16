/// Builds the main app shell and routes users into the right flow.
library;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:e_commerce_app_with_django/core/presentation/theme/app_theme.dart';
import 'package:e_commerce_app_with_django/features/admin/presentation/screens/add_product_screen.dart';
import 'package:e_commerce_app_with_django/features/admin/presentation/screens/admin_dashboard_screen.dart';
import 'package:e_commerce_app_with_django/features/admin/presentation/providers/admin_settings_provider.dart';
import 'package:e_commerce_app_with_django/features/auth/domain/models/user_role.dart';
import 'package:e_commerce_app_with_django/features/auth/presentation/providers/auth_provider.dart';
import 'package:e_commerce_app_with_django/features/auth/presentation/screens/login_screen.dart';
import 'package:e_commerce_app_with_django/features/auth/presentation/screens/profile_screen.dart';
import 'package:e_commerce_app_with_django/features/auth/presentation/screens/sign_up_screen.dart';
import 'package:e_commerce_app_with_django/features/branches/domain/models/branch.dart';
import 'package:e_commerce_app_with_django/features/branches/presentation/providers/branch_provider.dart';
import 'package:e_commerce_app_with_django/features/branches/presentation/screens/branch_selection_screen.dart';
import 'package:e_commerce_app_with_django/features/cart/presentation/providers/cart_provider.dart';
import 'package:e_commerce_app_with_django/features/cart/presentation/screens/cart_screen.dart';
import 'package:e_commerce_app_with_django/features/categories/presentation/providers/category_provider.dart';
import 'package:e_commerce_app_with_django/features/categories/presentation/screens/category_screen.dart';
import 'package:e_commerce_app_with_django/features/checkout/presentation/screens/address_screen.dart';
import 'package:e_commerce_app_with_django/features/checkout/presentation/screens/checkout_screen.dart';
import 'package:e_commerce_app_with_django/features/checkout/presentation/screens/flow/checkout_success_screen.dart';
import 'package:e_commerce_app_with_django/features/checkout/presentation/screens/flow/order_tracking_screen.dart';
import 'package:e_commerce_app_with_django/features/orders/domain/models/order.dart';
import 'package:e_commerce_app_with_django/features/orders/presentation/providers/order_provider.dart';
import 'package:e_commerce_app_with_django/features/orders/presentation/screens/user_orders_screen.dart';
import 'package:e_commerce_app_with_django/features/payment/domain/models/payment.dart';
import 'package:e_commerce_app_with_django/features/payment/application/payment_gateway_adapter.dart';
import 'package:e_commerce_app_with_django/features/payment/presentation/providers/payment_provider.dart';
import 'package:e_commerce_app_with_django/features/products/domain/models/product.dart';
import 'package:e_commerce_app_with_django/features/products/presentation/providers/product_provider.dart';
import 'package:e_commerce_app_with_django/features/products/presentation/screens/product_detail_screen.dart';
import 'package:e_commerce_app_with_django/features/products/presentation/screens/product_list_screen.dart';

class KutukuApp extends StatelessWidget {
  const KutukuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Kutuku',
      theme: AppTheme.light,
      home: const AppGateway(),
    );
  }
}

class AppGateway extends ConsumerStatefulWidget {
  const AppGateway({super.key});

  @override
  ConsumerState<AppGateway> createState() => _AppGatewayState();
}

class _AppGatewayState extends ConsumerState<AppGateway> {
  _AuthFlowStep _authFlowStep = _AuthFlowStep.login;

  @override
  void initState() {
    super.initState();
    // Load auth and branch data before deciding which top-level flow to show.
    Future<void>.microtask(() async {
      await ref.read(authProvider.notifier).bootstrap();
      await ref.read(branchProvider.notifier).loadBranches();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final branchState = ref.watch(branchProvider);

    // Keep the entry screen simple until both auth and branch state are ready.
    if (authState.status == AuthStatus.loading || branchState.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Users who are not signed in stay inside the local auth flow switcher.
    if (authState.status == AuthStatus.unauthenticated) {
      switch (_authFlowStep) {
        case _AuthFlowStep.createAccount:
          return CreateAccountScreen(
            error: authState.error,
            onBackToLogin: () => setState(() => _authFlowStep = _AuthFlowStep.login),
            onCreateAccount: ({required fullName, required identifier, required password}) async {
              await ref.read(authProvider.notifier).signUp(
                    fullName: fullName,
                    email: identifier,
                    password: password,
                  );
            },
          );
        case _AuthFlowStep.login:
          return LoginScreen(
            error: authState.error,
            onCreateAccount: () => setState(() => _authFlowStep = _AuthFlowStep.createAccount),
            onLogin: ({required identifier, required password}) async {
              await ref.read(authProvider.notifier).login(
                    identifier: identifier,
                    password: password,
                  );
            },
          );
      }
    }

    if (branchState.selectedBranchId == null) {
      return BranchSelectionScreen(
        branches: branchState.branches,
        selectedBranchId: branchState.selectedBranchId,
        onSelected: (branchId) async {
          await ref.read(branchProvider.notifier).selectBranch(branchId);
        },
        onContinue: () {},
      );
    }

    final session = authState.session;
    if (session == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (session.role == AppUserRole.admin || session.role == AppUserRole.superAdmin) {
      return const AdminPortalShell();
    }

    // Standard shoppers land in the regular storefront shell.
    return const AppShell();
  }
}

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    // Kick off the shared storefront data load once the shell is created.
    Future<void>.microtask(_bootstrapData);
  }

  Future<void> _bootstrapData() async {
    final branchId = ref.read(branchProvider).selectedBranchId;
    if (branchId != null) {
      await ref.read(productProvider.notifier).loadProducts(branchId: branchId);
    }
    await ref.read(categoryProvider.notifier).loadCategories();
    await ref.read(paymentProvider.notifier).loadPaymentOptions();
    await ref.read(orderProvider.notifier).loadOrders();
  }

  @override
  Widget build(BuildContext context) {
    final branchState = ref.watch(branchProvider);
    final productState = ref.watch(productProvider);
    final categoryState = ref.watch(categoryProvider);
    final cartState = ref.watch(cartProvider);
    final paymentState = ref.watch(paymentProvider);
    final orderState = ref.watch(orderProvider);
    final authState = ref.watch(authProvider);

    final selectedBranchId = branchState.selectedBranchId ?? '';
    final session = authState.session;

    final currentUserId = session?.userId ?? '';

    // Each tab keeps its own screen so bottom navigation can swap without rebuilding navigation state.
    final pages = [
      ProductListScreen(
        products: productState.products,
        branches: branchState.branches,
        categories: categoryState.categories,
        selectedBranchId: selectedBranchId,
        selectedCategoryId: productState.selectedCategoryId,
        searchQuery: productState.searchQuery,
        userName: session?.userName ?? 'Shopper',
        onSearchChanged: (value) => ref.read(productProvider.notifier).searchProducts(value),
        onBranchChanged: (value) async {
          if (value != null) {
            await ref.read(branchProvider.notifier).selectBranch(value);
            await ref.read(productProvider.notifier).loadProducts(branchId: value);
          }
        },
        onCategoryChanged: (value) => ref.read(productProvider.notifier).filterByCategory(value),
        onSeeAll: () {
          ref.read(productProvider.notifier).searchProducts('');
          ref.read(productProvider.notifier).filterByCategory(null);
          ref.read(productProvider.notifier).loadProducts(branchId: selectedBranchId);
        },
        onLogout: () => ref.read(authProvider.notifier).logout(),
        onOpenProfile: () => setState(() => _currentIndex = 3),
        onOpenCategoryScreen: () async {
          // Open a dedicated category page from Home and apply the selected filter.
          await Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (routeContext) => CategoryScreen(
                categories: categoryState.categories,
                selectedCategoryId: productState.selectedCategoryId,
                onBackToHome: () => Navigator.of(routeContext).pop(),
                onCategorySelected: (categoryId) {
                  ref.read(productProvider.notifier).filterByCategory(categoryId);
                  Navigator.of(routeContext).pop();
                },
              ),
            ),
          );
        },
        
        onProductSelected: (product) => _showProductDetail(context, product),
      ),
      CartScreen(
        state: cartState,
        onQuantityChanged: ({required productId, required quantity}) {
          ref.read(cartProvider.notifier).updateQuantity(productId: productId, quantity: quantity);
        },
        onRemoveProduct: (productId) => ref.read(cartProvider.notifier).removeProduct(productId),
        onCheckout: () async {
          // Address is collected first so the preview order can include the full checkout context.
          final address = await Navigator.of(context).push<String>(
            MaterialPageRoute<String>(builder: (_) => const AddressScreen()),
          );

          if (!context.mounted || address == null || address.isEmpty) {
            return;
          }

          final checkoutOrder = _buildPreviewOrder(
            cartState: cartState,
            selectedMethod: paymentState.selectedMethod,
            branchId: selectedBranchId,
            customerId: currentUserId,
          );

          await Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => CheckoutScreen(
                orderPreview: checkoutOrder,
                deliveryAddress: address,
                paymentOptions: paymentState.options,
                selectedMethod: paymentState.selectedMethod,
                onPaymentMethodSelected: (method) {
                  ref.read(paymentProvider.notifier).selectMethod(method);
                },
                onConfirmOrder: () async {
                  try {
                    final selectedMethod = ref.read(paymentProvider).selectedMethod;
                    final previewOrder = _buildPreviewOrder(
                      cartState: cartState,
                      selectedMethod: selectedMethod,
                      branchId: selectedBranchId,
                      customerId: currentUserId,
                    );

                    final gateway = ref.read(unifiedPaymentGatewayProvider);
                    final gatewayResult = await gateway.charge(
                      PaymentGatewayRequest(
                        orderId: previewOrder.id,
                        customerId: currentUserId,
                        method: selectedMethod,
                        amount: previewOrder.total,
                      ),
                    );

                    var finalGatewayResult = gatewayResult;

                    // When a gateway requires an external redirect, wait for the shopper to return first.
                    if (gatewayResult.checkoutUrl != null && gatewayResult.checkoutUrl!.trim().isNotEmpty) {
                      final didReturn = await _startRedirectAndWaitForReturn(
                        context,
                        methodLabel: selectedMethod.label,
                        checkoutUrl: gatewayResult.checkoutUrl!,
                      );

                      if (!didReturn) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Payment is still pending. You can continue once you return from payment.'),
                            ),
                          );
                        }
                        return;
                      }
                    }

                    if (selectedMethod.id != PaymentMethod.cashOnDelivery.id) {
                      finalGatewayResult = await _runWithBlockingDialog<PaymentGatewayResult>(
                        context: context,
                        message: 'Checking your payment status...',
                        task: () => gateway.verifyWithPolling(
                          PaymentGatewayVerificationRequest(
                            orderId: previewOrder.id,
                            customerId: currentUserId,
                            method: selectedMethod,
                            transactionReference: gatewayResult.transactionReference,
                          ),
                        ),
                      );

                      if (finalGatewayResult.status == PaymentStatus.pending) {
                        throw const PaymentGatewayException(
                          'Your payment is still pending. Please wait a moment and try again.',
                        );
                      }

                      if (finalGatewayResult.status == PaymentStatus.failed) {
                        throw const PaymentGatewayException(
                          'Your payment was not completed. Please try again with another method.',
                        );
                      }
                    }

                    final orderToConfirm = previewOrder.copyWith(
                      payment: previewOrder.payment.copyWith(
                        method: finalGatewayResult.method,
                        status: finalGatewayResult.status,
                        transactionReference: finalGatewayResult.transactionReference,
                        verifiedAt: finalGatewayResult.verifiedAt,
                      ),
                    );

                    final confirmed = await ref.read(orderProvider.notifier).confirmOrderAndReturn(orderToConfirm);

                    if (!context.mounted) {
                      return;
                    }

                    // Clear only after the order is confirmed so the cart survives a failed checkout attempt.
                    ref.read(cartProvider.notifier).clear();

                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute<void>(
                        builder: (_) => CheckoutSuccessScreen(
                          onTrackOrder: () {
                            setState(() => _currentIndex = 2);
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute<void>(
                                builder: (_) => OrderTrackingScreen(order: confirmed),
                              ),
                            );
                          },
                          onBackToShop: () {
                            if (context.mounted) {
                              setState(() => _currentIndex = 2);
                              Navigator.of(context).popUntil((route) => route.isFirst);
                            }
                          },
                        ),
                      ),
                    );
                  } on PaymentGatewayException catch (error) {
                    if (!context.mounted) {
                      return;
                    }
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(error.message)),
                    );
                  } catch (_) {
                    if (!context.mounted) {
                      return;
                    }
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('We could not process your payment. Please try again.')),
                    );
                  }
                },
              ),
            ),
          );
        },
      ),
      UserOrdersScreen(
        orders: orderState.orders.where((order) => order.customerId == currentUserId).toList(),
        isLoading: orderState.isLoading,
        onRefresh: () => ref.read(orderProvider.notifier).loadOrders(),
        onTrackOrder: (order) {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => OrderTrackingScreen(order: order),
            ),
          );
        },
      ),
      ProfileScreen(
        userName: session?.userName ?? 'User',
        email: session?.email ?? '',
        role: session?.role ?? AppUserRole.user,
        branchName: branchState.branches.where((branch) => branch.id == selectedBranchId).firstOrNull?.name ?? '',
        onLogout: () => ref.read(authProvider.notifier).logout(),
      ),
    ];

    if (_currentIndex >= pages.length) {
      // Protect against stale tab indexes if the page list changes after a rebuild.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() => _currentIndex = 0);
        }
      });
    }

    final destinations = [
      const NavigationDestination(icon: Icon(Icons.storefront_outlined), label: 'Shop'),
      const NavigationDestination(icon: Icon(Icons.shopping_bag_outlined), label: 'Cart'),
      const NavigationDestination(icon: Icon(Icons.receipt_long_outlined), label: 'Orders'),
      const NavigationDestination(icon: Icon(Icons.person_outline_rounded), label: 'Profile'),
    ];

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: pages),
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
              selectedIndex: _currentIndex,
              onDestinationSelected: (index) async {
                setState(() => _currentIndex = index);
                // Orders are refreshed on demand so the tab shows the latest backend state.
                if (index == 2) {
                  await ref.read(orderProvider.notifier).loadOrders();
                }
              },
              destinations: destinations,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showProductDetail(BuildContext context, Product product) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ProductDetailScreen(
          product: product,
          onAddToCart: (configuredProduct) {
            ref.read(cartProvider.notifier).addProduct(configuredProduct);
          },
        ),
      ),
    );
  }

  Order _buildPreviewOrder({
    required CartState cartState,
    required PaymentMethod selectedMethod,
    required String branchId,
    required String customerId,
  }) {
    final subtotal = cartState.totalPrice;
    const deliveryFee = 50.0;
    final id = DateTime.now().millisecondsSinceEpoch;

    // The preview order uses local cart data first, then the repository returns the confirmed version.
    return Order(
      id: 'order-$id',
      branchId: branchId,
      customerId: customerId,
      items: cartState.items
          .map(
            (item) => OrderItem(
              productId: item.product.id,
              productName: _productDisplayName(item.product),
              quantity: item.quantity,
              unitPrice: item.product.price,
            ),
          )
          .toList(),
      status: OrderStatus.pending,
      payment: Payment(
        id: 'pay-$id',
        orderId: 'order-$id',
        method: selectedMethod,
        amount: subtotal + deliveryFee,
        status: PaymentStatus.pending,
        transactionReference: 'TX-$id',
        createdAt: DateTime.now().toUtc(),
      ),
      subtotal: subtotal,
      deliveryFee: deliveryFee,
      total: subtotal + deliveryFee,
      createdAt: DateTime.now().toUtc(),
    );
  }

  String _productDisplayName(Product product) {
    final parts = <String>[product.name];
    // Variant details are appended so order history clearly shows the configured product.
    if (product.selectedSize != null && product.selectedSize!.isNotEmpty) {
      parts.add(product.selectedSize!);
    }
    if (product.selectedColor != null) {
      parts.add(product.selectedColor!.name);
    }
    return parts.join(' • ');
  }

  Future<bool> _startRedirectAndWaitForReturn(
    BuildContext context, {
    required String methodLabel,
    required String checkoutUrl,
  }) async {
    final checkoutUri = Uri.tryParse(checkoutUrl.trim());
    if (checkoutUri == null) {
      throw const PaymentGatewayException(
        'The payment page link is invalid. Please try again.',
      );
    }

    final opened = await launchUrl(
      checkoutUri,
      mode: LaunchMode.externalApplication,
    );

    if (!opened) {
      throw const PaymentGatewayException(
        'We could not open the payment page. Please try again.',
      );
    }

    if (!context.mounted) {
      return false;
    }

    final returned = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: Text('Complete $methodLabel Payment'),
        content: const Text(
          'After finishing payment in your browser/app, come back here and tap "I have returned" so we can verify it.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('I have returned'),
          ),
        ],
      ),
    );

    return returned ?? false;
  }

  Future<T> _runWithBlockingDialog<T>({
    required BuildContext context,
    required String message,
    required Future<T> Function() task,
  }) async {
    showDialog<void>(
      context: context,
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
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }
    }
  }
}

class AdminPortalShell extends ConsumerStatefulWidget {
  const AdminPortalShell({super.key});

  @override
  ConsumerState<AdminPortalShell> createState() => _AdminPortalShellState();
}

class _AdminPortalShellState extends ConsumerState<AdminPortalShell> {
  @override
  void initState() {
    super.initState();
    // Admin data is loaded once here so the dashboard can work as a single control surface.
    Future<void>.microtask(_bootstrapData);
  }

  Future<void> _bootstrapData() async {
    final branchId = ref.read(branchProvider).selectedBranchId;
    if (branchId != null) {
      await ref.read(productProvider.notifier).loadProducts(branchId: branchId);
      await ref.read(orderProvider.notifier).loadOrders(branchId: branchId);
    } else {
      await ref.read(orderProvider.notifier).loadOrders();
    }
    await ref.read(categoryProvider.notifier).loadCategories();
    await ref.read(paymentProvider.notifier).loadPaymentOptions();
    await ref.read(adminSettingsProvider.notifier).load();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final branchState = ref.watch(branchProvider);
    final categoryState = ref.watch(categoryProvider);
    final productState = ref.watch(productProvider);
    final orderState = ref.watch(orderProvider);
    final adminSettingsState = ref.watch(adminSettingsProvider);

    final session = authState.session;
    if (session == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final isSuperAdmin = session.isSuperAdmin;
    final canAddCategory = session.role == AppUserRole.admin || isSuperAdmin;
    final canAddPaymentOption = session.role == AppUserRole.admin || isSuperAdmin;
    final sections = isSuperAdmin
        ? const ['Products', 'Categories', 'Orders', 'Payments', 'Admins', 'Branches']
        : const ['Products', 'Orders', 'Payments', 'Categories'];

    // Super admins see account and branch controls that normal admins do not get.
    return AdminDashboardScreen(
      dashboardTitle: isSuperAdmin ? 'Super Admin Dashboard' : 'Admin Dashboard',
      roleSections: sections,
      showBranchesSection: isSuperAdmin,
      onLogout: () => ref.read(authProvider.notifier).logout(),
      branches: branchState.branches,
      orders: orderState.orders,
      products: productState.products,
      adminCategories: adminSettingsState.categories.isNotEmpty
          ? adminSettingsState.categories
          : categoryState.categories,
      adminPaymentOptions: adminSettingsState.paymentOptions,
      adminAccounts: adminSettingsState.adminAccounts,
        onAddCategory: canAddCategory
          ? ({required name, required description, required imageUrl}) async {
              await ref.read(adminSettingsProvider.notifier).addCategory(
                    name: name,
                    description: description,
                    imageUrl: imageUrl,
                  );
              await ref.read(categoryProvider.notifier).loadCategories();
            }
          : null,
      onToggleCategory: isSuperAdmin
          ? (categoryId, isActive) async {
              await ref.read(adminSettingsProvider.notifier).toggleCategory(categoryId, isActive);
              await ref.read(categoryProvider.notifier).loadCategories();
            }
          : null,
      onFetchCategory: isSuperAdmin
          ? (categoryId) async {
              return ref.read(adminSettingsProvider.notifier).fetchCategoryById(categoryId);
            }
          : null,
      onUpdateCategory: isSuperAdmin
          ? ({required categoryId, required name, required description, required imageUrl}) async {
              await ref.read(adminSettingsProvider.notifier).updateCategory(
                    categoryId: categoryId,
                    name: name,
                    description: description,
                    imageUrl: imageUrl,
                  );
              await ref.read(categoryProvider.notifier).loadCategories();
            }
          : null,
      onDeleteCategory: isSuperAdmin
          ? (categoryId) async {
              await ref.read(adminSettingsProvider.notifier).deleteCategory(categoryId);
              await ref.read(categoryProvider.notifier).loadCategories();
            }
          : null,
      onTogglePaymentOption: isSuperAdmin
          ? (optionId, isEnabled) async {
              await ref.read(adminSettingsProvider.notifier).togglePaymentOption(optionId, isEnabled);
              await ref.read(paymentProvider.notifier).loadPaymentOptions();
            }
          : null,
      onAddPaymentOption: canAddPaymentOption
          ? ({required label, iconUrl}) async {
              await ref.read(adminSettingsProvider.notifier).addPaymentOption(
                    label: label,
                    iconUrl: iconUrl,
                  );
              await ref.read(paymentProvider.notifier).loadPaymentOptions();
            }
          : null,
      onFetchPaymentOption: isSuperAdmin
          ? (optionId) async {
              return ref.read(adminSettingsProvider.notifier).fetchPaymentOptionById(optionId);
            }
          : null,
      onUpdatePaymentOption: isSuperAdmin
          ? ({required optionId, required label, iconUrl}) async {
              await ref.read(adminSettingsProvider.notifier).updatePaymentOption(
                    optionId: optionId,
                    label: label,
                    iconUrl: iconUrl,
                  );
              await ref.read(paymentProvider.notifier).loadPaymentOptions();
            }
          : null,
      onDeletePaymentOption: isSuperAdmin
          ? (optionId) async {
              await ref.read(adminSettingsProvider.notifier).deletePaymentOption(optionId);
              await ref.read(paymentProvider.notifier).loadPaymentOptions();
            }
          : null,
      onUpdateProductPrice: (product, newPrice) async {
        await ref.read(productRepositoryProvider).updateProduct(
              product.copyWith(price: newPrice),
            );
        await ref.read(productProvider.notifier).loadProducts(
            branchId: ref.read(branchProvider).selectedBranchId ?? '',
            );
      },
      onDeleteProduct: (productId) async {
        await ref.read(productRepositoryProvider).deleteProduct(productId);
        await ref.read(productProvider.notifier).loadProducts(
            branchId: ref.read(branchProvider).selectedBranchId ?? '',
            );
      },
      onCreateAdminAccount: isSuperAdmin
          ? ({required name, required email, required password}) async {
              await ref.read(adminSettingsProvider.notifier).createAdminAccount(
                    name: name,
                    email: email,
                    password: password,
                  );
            }
          : null,
      onUpdateAdminAccount: isSuperAdmin
          ? ({required userId, required name, required email}) async {
              await ref.read(adminSettingsProvider.notifier).updateAdminAccount(
                    userId: userId,
                    name: name,
                    email: email,
                  );
            }
          : null,
      onFetchAdminAccount: isSuperAdmin
          ? (userId) async {
              return ref.read(adminSettingsProvider.notifier).fetchAdminAccountById(userId);
            }
          : null,
      onApproveAdmin: isSuperAdmin
          ? ({required userId, required approved}) async {
              await ref.read(adminSettingsProvider.notifier).approveAdmin(
                    userId: userId,
                    approved: approved,
                  );
            }
          : null,
      onRemoveAdmin: isSuperAdmin
          ? (userId) async {
              await ref.read(adminSettingsProvider.notifier).removeAdmin(userId);
            }
          : null,
      onFetchBranch: isSuperAdmin
          ? (branchId) async {
              return ref.read(adminSettingsProvider.notifier).fetchBranchById(branchId);
            }
          : null,
      onUpdateBranch: isSuperAdmin
          ? ({required branchId, required name, required location, required phoneNumber, required isActive}) async {
              await ref.read(adminSettingsProvider.notifier).updateBranch(
                    branchId: branchId,
                    name: name,
                    location: location,
                    phoneNumber: phoneNumber,
                    isActive: isActive,
                  );
              ref.read(branchProvider.notifier).updateBranchInState(
                    Branch(
                      id: branchId,
                      name: name,
                      location: location,
                      phoneNumber: phoneNumber,
                      isActive: isActive,
                    ),
                  );
            }
          : null,
      onAddProduct: () async {
        await Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => AddProductScreen(
              categories: categoryState.categories,
              branches: branchState.branches,
              onSubmit: (product) async {
                await ref.read(productRepositoryProvider).addProduct(product);
                // Reload the visible product list so the dashboard reflects the new item immediately.
                await ref.read(productProvider.notifier).loadProducts(
                      branchId: ref.read(branchProvider).selectedBranchId ?? '',
                    );
                if (context.mounted) {
                  Navigator.of(context).pop();
                }
              },
            ),
          ),
        );
      },
      onVerifyPayment: (orderId) async {
        await ref.read(orderProvider.notifier).verifyPayment(
              orderId: orderId,
              paymentStatus: PaymentStatus.verified,
            );
      },
      onMarkOrderShipped: (orderId) async {
        await ref.read(orderProvider.notifier).updateStatus(
              orderId: orderId,
              status: OrderStatus.shipped,
            );
      },
      onMarkOrderDelivered: (orderId) async {
        await ref.read(orderProvider.notifier).updateStatus(
              orderId: orderId,
              status: OrderStatus.delivered,
            );
      },
    );
  }
}

enum _AuthFlowStep { login, createAccount }
