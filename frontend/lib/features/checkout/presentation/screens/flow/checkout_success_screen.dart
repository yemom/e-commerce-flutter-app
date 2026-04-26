/// Confirms a successful checkout and guides the user forward.
library;
import 'package:flutter/material.dart';

/// Screen for Checkout Success.
class CheckoutSuccessScreen extends StatelessWidget {
  const CheckoutSuccessScreen({
    super.key,
    required this.onTrackOrder,
    required this.onBackToShop,
  });

  final VoidCallback onTrackOrder;
  final VoidCallback onBackToShop;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF5E56E7), Color(0xFF756DF2), Color(0xFFF7F8FC)],
            stops: [0, .34, .34],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Container(
                padding: const EdgeInsets.all(26),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(32),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircleAvatar(
                      radius: 46,
                      backgroundColor: Color(0xFFE7FFF1),
                      child: Icon(Icons.check, color: Color(0xFF1FB56C), size: 42),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Order placed successfully',
                      style: Theme.of(context).textTheme.titleLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Your order has been confirmed and is now being processed.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 22),
                    ElevatedButton(onPressed: onTrackOrder, child: const Text('Track Order')),
                    const SizedBox(height: 10),
                    TextButton(onPressed: onBackToShop, child: const Text('Back to shop')),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
