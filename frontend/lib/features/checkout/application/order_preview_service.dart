library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:e_commerce_app_with_django/features/cart/presentation/providers/cart_provider.dart';
import 'package:e_commerce_app_with_django/features/orders/domain/models/order.dart';
import 'package:e_commerce_app_with_django/features/payment/domain/models/payment.dart';
import 'package:e_commerce_app_with_django/features/products/domain/models/product.dart';

final orderPreviewServiceProvider = Provider<OrderPreviewService>(
  (ref) => const OrderPreviewService(),
);

class OrderPreviewService {
  const OrderPreviewService();

  Order buildPreviewOrder({
    required CartState cartState,
    required PaymentMethod selectedMethod,
    required String branchId,
    required String customerId,
  }) {
    final subtotal = cartState.totalPrice;
    const deliveryFee = 50.0;
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final createdAt = DateTime.now().toUtc();
    final orderId = 'order-$timestamp';

    return Order(
      id: orderId,
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
        id: 'pay-$timestamp',
        orderId: orderId,
        method: selectedMethod,
        amount: subtotal + deliveryFee,
        status: PaymentStatus.pending,
        transactionReference: 'TX-$timestamp',
        createdAt: createdAt,
      ),
      subtotal: subtotal,
      deliveryFee: deliveryFee,
      total: subtotal + deliveryFee,
      createdAt: createdAt,
    );
  }

  String _productDisplayName(Product product) {
    final parts = <String>[product.name];
    final selectedSize = product.selectedSize?.trim();

    if (selectedSize != null && selectedSize.isNotEmpty) {
      parts.add(selectedSize);
    }
    if (product.selectedColor != null) {
      parts.add(product.selectedColor!.name);
    }

    return parts.join(' • ');
  }
}
