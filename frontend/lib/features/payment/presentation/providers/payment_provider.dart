/// Tracks payment options, selected method, and payment verification state.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:e_commerce_app_with_django/core/data/providers.dart';
import 'package:e_commerce_app_with_django/features/payment/domain/models/payment.dart';
import 'package:e_commerce_app_with_django/features/payment/domain/repositories/payment_repository.dart';

final paymentRepositoryProvider = Provider<PaymentRepository>(
  (ref) => ref.watch(defaultPaymentRepositoryProvider),
);

@immutable
/// Holds UI state for Payment.
class PaymentState {
  const PaymentState({
    this.options = const [],
    this.selectedMethod = PaymentMethod.telebirr,
    this.activePayment,
    this.isLoading = false,
  });

  final List<PaymentOption> options;
  final PaymentMethod selectedMethod;
  final Payment? activePayment;
  final bool isLoading;

  PaymentState copyWith({
    List<PaymentOption>? options,
    PaymentMethod? selectedMethod,
    Payment? activePayment,
    bool? isLoading,
  }) {
    return PaymentState(
      options: options ?? this.options,
      selectedMethod: selectedMethod ?? this.selectedMethod,
      activePayment: activePayment ?? this.activePayment,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

/// Handles Payment state and actions.
class PaymentNotifier extends StateNotifier<PaymentState> {
  PaymentNotifier(this._repository, this._ref) : super(const PaymentState());

  final PaymentRepository _repository;
  final Ref _ref;

  PaymentMethod _resolveSelectedMethod(List<PaymentOption> options) {
    // Preserve the user's current selection when still available.
    if (options.isEmpty) {
      return state.selectedMethod;
    }

    final existing = options.where(
      (option) => option.method == state.selectedMethod,
    );
    if (existing.isNotEmpty) {
      return state.selectedMethod;
    }

    return options.first.method;
  }

  Future<void> loadPaymentOptions() async {
    state = state.copyWith(isLoading: true);

    try {
      // Primary source: backend-configured payment options.
      final options = await _repository.getPaymentOptions();
      state = state.copyWith(
        options: options,
        selectedMethod: _resolveSelectedMethod(options),
        isLoading: false,
      );
    } catch (_) {
      // Fall back to bundled options so checkout still works when the remote backend is unavailable.
      final options = await _ref
          .read(assetPaymentRepositoryProvider)
          .getPaymentOptions();
      state = state.copyWith(
        options: options,
        selectedMethod: _resolveSelectedMethod(options),
        isLoading: false,
      );
    }
  }

  void selectMethod(PaymentMethod method) {
    // UI-only selection state; no network call required.
    state = state.copyWith(selectedMethod: method);
  }

  Future<void> verifyPayment({
    required String paymentId,
    required String transactionReference,
  }) async {
    // Store the latest verified payment so checkout flows can react without another fetch.
    final payment = await _repository.verifyPayment(
      paymentId: paymentId,
      transactionReference: transactionReference,
    );
    state = state.copyWith(activePayment: payment);
  }
}

final paymentProvider = StateNotifierProvider<PaymentNotifier, PaymentState>(
  (ref) => PaymentNotifier(ref.watch(paymentRepositoryProvider), ref),
);
