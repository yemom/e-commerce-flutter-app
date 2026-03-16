/// Reviews the order, delivery details, and payment choice before confirmation.
library;
import 'package:flutter/material.dart';

import 'package:e_commerce_app_with_django/core/presentation/widgets/app_formatters.dart';
import 'package:e_commerce_app_with_django/features/orders/domain/models/order.dart';
import 'package:e_commerce_app_with_django/features/payment/domain/models/payment.dart';

class CheckoutScreen extends StatelessWidget {
  const CheckoutScreen({
    super.key,
    required this.orderPreview,
    required this.deliveryAddress,
    required this.paymentOptions,
    required this.selectedMethod,
    required this.onPaymentMethodSelected,
    required this.onConfirmOrder,
  });

  final Order orderPreview;
  final String deliveryAddress;
  final List<PaymentOption> paymentOptions;
  final PaymentMethod selectedMethod;
  final ValueChanged<PaymentMethod> onPaymentMethodSelected;
  final VoidCallback onConfirmOrder;

  @override
  Widget build(BuildContext context) {
    return _CheckoutScreenBody(
      orderPreview: orderPreview,
      deliveryAddress: deliveryAddress,
      paymentOptions: paymentOptions,
      selectedMethod: selectedMethod,
      onPaymentMethodSelected: onPaymentMethodSelected,
      onConfirmOrder: onConfirmOrder,
    );
  }
}

class _CheckoutScreenBody extends StatefulWidget {
  const _CheckoutScreenBody({
    required this.orderPreview,
    required this.deliveryAddress,
    required this.paymentOptions,
    required this.selectedMethod,
    required this.onPaymentMethodSelected,
    required this.onConfirmOrder,
  });

  final Order orderPreview;
  final String deliveryAddress;
  final List<PaymentOption> paymentOptions;
  final PaymentMethod selectedMethod;
  final ValueChanged<PaymentMethod> onPaymentMethodSelected;
  final VoidCallback onConfirmOrder;

  @override
  State<_CheckoutScreenBody> createState() => _CheckoutScreenBodyState();
}

class _CheckoutScreenBodyState extends State<_CheckoutScreenBody> {
  late PaymentMethod _selectedMethod;

  List<PaymentOption> get _effectiveOptions {
    // If admin options are not loaded yet, keep checkout usable with defaults.
    if (widget.paymentOptions.isNotEmpty) {
      return widget.paymentOptions;
    }

    return PaymentMethod.defaults
        .map(
          (method) => PaymentOption(
            id: method.id,
            method: method,
            label: method.label,
            isEnabled: true,
          ),
        )
        .toList();
  }

  @override
  void initState() {
    super.initState();
    _selectedMethod = widget.selectedMethod;
  }

  void _selectMethod(PaymentMethod method) {
    // Keep local selection in sync with parent state.
    setState(() => _selectedMethod = method);
    widget.onPaymentMethodSelected(method);
  }

  @override
  Widget build(BuildContext context) {
    final options = _effectiveOptions;

    if (!options.any((option) => option.method == _selectedMethod)) {
      _selectedMethod = options.first.method;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF0EEFF), Color(0xFFF7F8FC), Color(0xFFF7F8FC)],
            stops: [0, .18, .18],
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF5E56E7), Color(0xFF756DF2)]),
                borderRadius: BorderRadius.circular(28),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Secure payment', style: TextStyle(color: Color(0xFFDCDDFF), fontSize: 13)),
                  const SizedBox(height: 6),
                  const Text(
                    'Choose your preferred payment method',
                    style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800, height: 1.1),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Row(
                      children: [
                        const CircleAvatar(
                          backgroundColor: Colors.white24,
                          child: Icon(Icons.location_on_outlined, color: Colors.white),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Delivery address', style: TextStyle(color: Color(0xFFDCDDFF))),
                              Text(
                                widget.deliveryAddress,
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          'Pay ${formatPrice(widget.orderPreview.total)}',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: const Color(0xFFE7ECF3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Payment method', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  for (final option in options)
                    Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: option.method == _selectedMethod ? const Color(0xFFF0EEFF) : const Color(0xFFF8F8FC),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: option.method == _selectedMethod ? const Color(0xFF5E56E7) : const Color(0xFFE7ECF3),
                        ),
                      ),
                      child: ListTile(
                        key: Key('checkout.payment.${option.method.id}'),
                        onTap: () => _selectMethod(option.method),
                        leading: Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: option.iconUrl?.isNotEmpty == true
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(14),
                                  child: Image.network(
                                    option.iconUrl!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Icon(
                                      _paymentIcon(option.method),
                                      color: const Color(0xFF5E56E7),
                                    ),
                                  ),
                                )
                              : Icon(_paymentIcon(option.method), color: const Color(0xFF5E56E7)),
                        ),
                        title: Text(option.label),
                        trailing: Radio<PaymentMethod>(
                          value: option.method,
                          groupValue: _selectedMethod,
                          onChanged: (value) {
                            if (value != null) {
                              _selectMethod(value);
                            }
                          },
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: const Color(0xFFE7ECF3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Order summary', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 14),
                  ...widget.orderPreview.items.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFF0EEFF), Color(0xFFE7E4FF)],
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(Icons.shopping_bag_outlined, color: Color(0xFF5E56E7)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item.productName, style: Theme.of(context).textTheme.titleSmall),
                                const SizedBox(height: 4),
                                Text('Qty ${item.quantity}', style: const TextStyle(color: Color(0xFF7C8799))),
                              ],
                            ),
                          ),
                          Text(formatPrice(item.quantity * item.unitPrice)),
                        ],
                      ),
                    ),
                  ),
                  const Divider(height: 24),
                  _CheckoutSummaryRow(label: 'Subtotal', value: formatPrice(widget.orderPreview.subtotal)),
                  const SizedBox(height: 10),
                  _CheckoutSummaryRow(label: 'Delivery Fee', value: formatPrice(widget.orderPreview.deliveryFee)),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total', style: TextStyle(fontWeight: FontWeight.w700)),
                      Text(
                        formatPrice(widget.orderPreview.total),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            ElevatedButton(
              key: const Key('checkout.confirm-order'),
              onPressed: () {
                widget.onPaymentMethodSelected(_selectedMethod);
                widget.onConfirmOrder();
              },
              child: const Text('Confirm'),
            ),
          ],
        ),
      ),
    );
  }
}

class _CheckoutSummaryRow extends StatelessWidget {
  const _CheckoutSummaryRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [Text(label), Text(value)],
    );
  }
}

IconData _paymentIcon(PaymentMethod method) {
  if (method.id == PaymentMethod.telebirr.id) {
    return Icons.account_balance_wallet_outlined;
  }
  if (method.id == PaymentMethod.cbe.id) {
    return Icons.flash_on_rounded;
  }
  if (method.id == PaymentMethod.cashOnDelivery.id) {
    return Icons.local_shipping_outlined;
  }
  return Icons.payments_outlined;
}