/// Routes payment requests through method-specific gateway adapters.
library;
import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import 'package:e_commerce_app_with_django/features/payment/domain/models/payment.dart';

@immutable
class PaymentGatewayRequest {
  const PaymentGatewayRequest({
    required this.orderId,
    required this.customerId,
    required this.method,
    required this.amount,
    this.currency = 'ETB',
    this.customerEmail,
  });

  final String orderId;
  final String customerId;
  final PaymentMethod method;
  final double amount;
  final String currency;
  final String? customerEmail;
}

@immutable
class PaymentGatewayResult {
  const PaymentGatewayResult({
    required this.method,
    required this.transactionReference,
    required this.status,
    this.verifiedAt,
    this.checkoutUrl,
  });

  final PaymentMethod method;
  final String transactionReference;
  final PaymentStatus status;
  final DateTime? verifiedAt;
  final String? checkoutUrl;
}

@immutable
class PaymentGatewayVerificationRequest {
  const PaymentGatewayVerificationRequest({
    required this.orderId,
    required this.customerId,
    required this.method,
    required this.transactionReference,
  });

  final String orderId;
  final String customerId;
  final PaymentMethod method;
  final String transactionReference;
}

class PaymentGatewayException implements Exception {
  const PaymentGatewayException(this.message);

  final String message;

  @override
  String toString() => message;
}

abstract class PaymentGatewayAdapter {
  const PaymentGatewayAdapter();

  bool canHandle(PaymentMethod method);

  Future<PaymentGatewayResult> charge(PaymentGatewayRequest request);

  Future<PaymentGatewayResult> verify(PaymentGatewayVerificationRequest request);
}

@immutable
class PaymentGatewayEnvironmentConfig {
  const PaymentGatewayEnvironmentConfig({
    required this.requestTimeout,
    required this.verificationPollInterval,
    required this.verificationMaxAttempts,
    required this.cbeInitializeUrl,
    required this.cbeVerifyUrl,
    required this.cbeProxyInitializeUrl,
    required this.cbeProxyVerifyUrl,
    required this.cbeSecretKey,
    required this.cbeCallbackUrl,
    required this.cbeReturnUrl,
    required this.cbeProxyToken,
    required this.telebirrInitializeUrl,
    required this.telebirrVerifyUrl,
    required this.telebirrProxyInitializeUrl,
    required this.telebirrProxyVerifyUrl,
    required this.telebirrApiKey,
    required this.telebirrMerchantId,
    required this.telebirrNotifyUrl,
    required this.telebirrCallbackUrl,
    required this.telebirrProxyToken,
  });

  factory PaymentGatewayEnvironmentConfig.fromEnvironment() {
    const cbeInitializeFromNewKey = String.fromEnvironment('CBE_INITIALIZE_URL');
    const cbeInitializeFromLegacyKey = String.fromEnvironment('CHAPA_INITIALIZE_URL');
    const cbeProxyFromNewKey = String.fromEnvironment('CBE_PROXY_INITIALIZE_URL');
    const cbeProxyFromLegacyKey = String.fromEnvironment('CHAPA_PROXY_INITIALIZE_URL');
    const cbeSecretFromNewKey = String.fromEnvironment('CBE_SECRET_KEY');
    const cbeSecretFromLegacyKey = String.fromEnvironment('CHAPA_SECRET_KEY');
    const cbeCallbackFromNewKey = String.fromEnvironment('CBE_CALLBACK_URL');
    const cbeCallbackFromLegacyKey = String.fromEnvironment('CHAPA_CALLBACK_URL');
    const cbeReturnFromNewKey = String.fromEnvironment('CBE_RETURN_URL');
    const cbeReturnFromLegacyKey = String.fromEnvironment('CHAPA_RETURN_URL');
    const cbeProxyTokenFromNewKey = String.fromEnvironment('CBE_PROXY_TOKEN');
    const cbeProxyTokenFromLegacyKey = String.fromEnvironment('CHAPA_PROXY_TOKEN');
    const cbeVerifyFromNewKey = String.fromEnvironment('CBE_VERIFY_URL');
    const cbeVerifyFromLegacyKey = String.fromEnvironment('CHAPA_VERIFY_URL');
    const cbeProxyVerifyFromNewKey = String.fromEnvironment('CBE_PROXY_VERIFY_URL');
    const cbeProxyVerifyFromLegacyKey = String.fromEnvironment('CHAPA_PROXY_VERIFY_URL');

    const telebirrVerifyFromNewKey = String.fromEnvironment('TELEBIRR_VERIFY_URL');
    const telebirrProxyVerifyFromNewKey = String.fromEnvironment('TELEBIRR_PROXY_VERIFY_URL');

    final timeoutSeconds = int.tryParse(
          const String.fromEnvironment('PAYMENT_REQUEST_TIMEOUT_SECONDS', defaultValue: '20'),
        ) ??
        20;
    final verificationIntervalSeconds = int.tryParse(
          const String.fromEnvironment('PAYMENT_VERIFICATION_INTERVAL_SECONDS', defaultValue: '3'),
        ) ??
        3;
    final verificationMaxAttempts = int.tryParse(
          const String.fromEnvironment('PAYMENT_VERIFICATION_MAX_ATTEMPTS', defaultValue: '10'),
        ) ??
        10;

    return PaymentGatewayEnvironmentConfig(
      requestTimeout: Duration(seconds: timeoutSeconds.clamp(5, 120)),
      verificationPollInterval: Duration(seconds: verificationIntervalSeconds.clamp(1, 30)),
      verificationMaxAttempts: verificationMaxAttempts.clamp(1, 120),
      cbeInitializeUrl: cbeInitializeFromNewKey.isNotEmpty
          ? cbeInitializeFromNewKey
          : cbeInitializeFromLegacyKey,
      cbeVerifyUrl: cbeVerifyFromNewKey.isNotEmpty ? cbeVerifyFromNewKey : cbeVerifyFromLegacyKey,
      cbeProxyInitializeUrl: cbeProxyFromNewKey.isNotEmpty ? cbeProxyFromNewKey : cbeProxyFromLegacyKey,
      cbeProxyVerifyUrl: cbeProxyVerifyFromNewKey.isNotEmpty
          ? cbeProxyVerifyFromNewKey
          : cbeProxyVerifyFromLegacyKey,
      cbeSecretKey: cbeSecretFromNewKey.isNotEmpty ? cbeSecretFromNewKey : cbeSecretFromLegacyKey,
      cbeCallbackUrl: cbeCallbackFromNewKey.isNotEmpty ? cbeCallbackFromNewKey : cbeCallbackFromLegacyKey,
      cbeReturnUrl: cbeReturnFromNewKey.isNotEmpty ? cbeReturnFromNewKey : cbeReturnFromLegacyKey,
      cbeProxyToken: cbeProxyTokenFromNewKey.isNotEmpty ? cbeProxyTokenFromNewKey : cbeProxyTokenFromLegacyKey,
      telebirrInitializeUrl: const String.fromEnvironment('TELEBIRR_INITIALIZE_URL'),
      telebirrVerifyUrl: telebirrVerifyFromNewKey,
      telebirrProxyInitializeUrl: const String.fromEnvironment('TELEBIRR_PROXY_INITIALIZE_URL'),
      telebirrProxyVerifyUrl: telebirrProxyVerifyFromNewKey,
      telebirrApiKey: const String.fromEnvironment('TELEBIRR_API_KEY'),
      telebirrMerchantId: const String.fromEnvironment('TELEBIRR_MERCHANT_ID'),
      telebirrNotifyUrl: const String.fromEnvironment('TELEBIRR_NOTIFY_URL'),
      telebirrCallbackUrl: const String.fromEnvironment('TELEBIRR_CALLBACK_URL'),
      telebirrProxyToken: const String.fromEnvironment('TELEBIRR_PROXY_TOKEN'),
    );
  }

  final Duration requestTimeout;
  final Duration verificationPollInterval;
  final int verificationMaxAttempts;

  final String cbeInitializeUrl;
  final String cbeVerifyUrl;
  final String cbeProxyInitializeUrl;
  final String cbeProxyVerifyUrl;
  final String cbeSecretKey;
  final String cbeCallbackUrl;
  final String cbeReturnUrl;
  final String cbeProxyToken;

  final String telebirrInitializeUrl;
  final String telebirrVerifyUrl;
  final String telebirrProxyInitializeUrl;
  final String telebirrProxyVerifyUrl;
  final String telebirrApiKey;
  final String telebirrMerchantId;
  final String telebirrNotifyUrl;
  final String telebirrCallbackUrl;
  final String telebirrProxyToken;
}

class TelebirrPaymentGatewayAdapter extends PaymentGatewayAdapter {
  TelebirrPaymentGatewayAdapter(this._httpClient, this._config);

  final http.Client _httpClient;
  final PaymentGatewayEnvironmentConfig _config;

  @override
  bool canHandle(PaymentMethod method) => method.id == PaymentMethod.telebirr.id;

  @override
  Future<PaymentGatewayResult> charge(PaymentGatewayRequest request) async {
    if (request.amount <= 0) {
      throw const PaymentGatewayException('Please enter a valid payment amount.');
    }

    final endpoint = _resolveTelebirrEndpoint();
    final response = await _postJson(
      client: _httpClient,
      uri: endpoint,
      headers: _telebirrHeaders(),
      payload: _withoutNullOrEmpty(
        {
          'merchantOrderNo': request.orderId,
          'amount': request.amount.toStringAsFixed(2),
          'currency': request.currency,
          'title': 'Order ${request.orderId}',
          'customerId': request.customerId,
          'notifyUrl': _config.telebirrNotifyUrl,
          'callbackUrl': _config.telebirrCallbackUrl,
        },
      ),
      timeout: _config.requestTimeout,
    );

    if (!_isResponseSuccessful(response)) {
      throw PaymentGatewayException(_bestUserMessage(
        response,
        fallback: 'Telebirr payment could not be started. Please try again.',
      ));
    }

    final reference = _firstPresentString(
      response,
      const [
        'transactionReference',
        'transactionNo',
        'prepayId',
        'data.transactionReference',
        'data.transactionNo',
        'data.prepayId',
        'biz_content.prepay_id',
        'bizContent.prepayId',
      ],
    );

    if (reference == null || reference.isEmpty) {
      throw const PaymentGatewayException(
        'Telebirr returned an unexpected response. Please try again.',
      );
    }

    return PaymentGatewayResult(
      method: request.method,
      transactionReference: reference,
      status: PaymentStatus.pending,
      checkoutUrl: _firstPresentString(
        response,
        const [
          'checkoutUrl',
          'checkout_url',
          'redirectUrl',
          'redirect_url',
          'paymentUrl',
          'payment_url',
          'toPayUrl',
          'to_pay_url',
          'data.checkoutUrl',
          'data.checkout_url',
          'data.redirectUrl',
          'data.redirect_url',
          'data.paymentUrl',
          'data.payment_url',
          'data.toPayUrl',
          'data.to_pay_url',
          'biz_content.toPayUrl',
          'bizContent.toPayUrl',
        ],
      ),
    );
  }

  @override
  Future<PaymentGatewayResult> verify(PaymentGatewayVerificationRequest request) async {
    final endpoint = _resolveTelebirrVerifyEndpoint();
    final response = await _postJson(
      client: _httpClient,
      uri: endpoint,
      headers: _telebirrHeaders(),
      payload: _withoutNullOrEmpty(
        {
          'merchantOrderNo': request.orderId,
          'customerId': request.customerId,
          'transactionReference': request.transactionReference,
          'transactionNo': request.transactionReference,
        },
      ),
      timeout: _config.requestTimeout,
    );

    if (!_isResponseSuccessful(response)) {
      throw PaymentGatewayException(
        _bestUserMessage(response, fallback: 'Telebirr payment verification failed. Please try again.'),
      );
    }

    final status = _resolvePaymentStatus(response);
    final reference = _firstPresentString(
          response,
          const [
            'transactionReference',
            'transactionNo',
            'prepayId',
            'data.transactionReference',
            'data.transactionNo',
            'data.prepayId',
          ],
        ) ??
        request.transactionReference;

    return PaymentGatewayResult(
      method: request.method,
      transactionReference: reference,
      status: status,
      verifiedAt: status == PaymentStatus.verified ? DateTime.now().toUtc() : null,
    );
  }

  Uri _resolveTelebirrEndpoint() {
    final proxyUrl = _config.telebirrProxyInitializeUrl.trim();
    if (proxyUrl.isNotEmpty) {
      return _safeUri(proxyUrl, 'Telebirr proxy URL');
    }

    final directUrl = _config.telebirrInitializeUrl.trim();
    if (directUrl.isEmpty) {
      throw const PaymentGatewayException(
        'Telebirr is not configured yet. Please contact support.',
      );
    }
    return _safeUri(directUrl, 'Telebirr initialize URL');
  }

  Uri _resolveTelebirrVerifyEndpoint() {
    final proxyVerifyUrl = _config.telebirrProxyVerifyUrl.trim();
    if (proxyVerifyUrl.isNotEmpty) {
      return _safeUri(proxyVerifyUrl, 'Telebirr proxy verify URL');
    }

    final directVerifyUrl = _config.telebirrVerifyUrl.trim();
    if (directVerifyUrl.isNotEmpty) {
      return _safeUri(directVerifyUrl, 'Telebirr verify URL');
    }

    throw const PaymentGatewayException(
      'Telebirr verification endpoint is not configured. Please contact support.',
    );
  }

  Map<String, String> _telebirrHeaders() {
    final isProxy = _config.telebirrProxyInitializeUrl.trim().isNotEmpty;
    final headers = <String, String>{'Content-Type': 'application/json'};

    if (isProxy) {
      if (_config.telebirrProxyToken.trim().isNotEmpty) {
        headers['Authorization'] = 'Bearer ${_config.telebirrProxyToken.trim()}';
      }
      return headers;
    }

    final apiKey = _config.telebirrApiKey.trim();
    if (apiKey.isEmpty) {
      throw const PaymentGatewayException(
        'Telebirr setup is incomplete. Please contact support.',
      );
    }

    headers['Authorization'] = 'Bearer $apiKey';
    if (_config.telebirrMerchantId.trim().isNotEmpty) {
      headers['X-Merchant-Id'] = _config.telebirrMerchantId.trim();
    }
    return headers;
  }
}

class CbePaymentGatewayAdapter extends PaymentGatewayAdapter {
  CbePaymentGatewayAdapter(this._httpClient, this._config);

  final http.Client _httpClient;
  final PaymentGatewayEnvironmentConfig _config;

  @override
  bool canHandle(PaymentMethod method) => method.id == PaymentMethod.cbe.id;

  @override
  Future<PaymentGatewayResult> charge(PaymentGatewayRequest request) async {
    if (request.amount <= 0) {
      throw const PaymentGatewayException('Please enter a valid payment amount.');
    }

    final txRef = 'CBE-${DateTime.now().millisecondsSinceEpoch}-${_randomDigits(6)}';
    final endpoint = _resolveCbeEndpoint();
    final response = await _postJson(
      client: _httpClient,
      uri: endpoint,
      headers: _cbeHeaders(),
      payload: _withoutNullOrEmpty(
        {
          'amount': request.amount.toStringAsFixed(2),
          'currency': request.currency,
          'email': _customerEmail(request),
          'first_name': 'Customer',
          'last_name': request.customerId,
          'tx_ref': txRef,
          'callback_url': _config.cbeCallbackUrl,
          'return_url': _config.cbeReturnUrl,
          'customization': {
            'title': 'Order ${request.orderId}',
            'description': 'Payment for order ${request.orderId}',
          },
          'meta': {
            'order_id': request.orderId,
            'customer_id': request.customerId,
          },
        },
      ),
      timeout: _config.requestTimeout,
    );

    if (!_isResponseSuccessful(response)) {
      throw PaymentGatewayException(
        _bestUserMessage(response, fallback: 'CBE payment could not be started. Please try again.'),
      );
    }

    final reference = _firstPresentString(
          response,
          const [
            'data.tx_ref',
            'tx_ref',
            'data.reference',
            'reference',
            'transactionReference',
          ],
        ) ??
        txRef;

    return PaymentGatewayResult(
      method: request.method,
      transactionReference: reference,
      status: PaymentStatus.pending,
      checkoutUrl: _firstPresentString(
        response,
        const [
          'checkoutUrl',
          'checkout_url',
          'redirectUrl',
          'redirect_url',
          'paymentUrl',
          'payment_url',
          'data.checkoutUrl',
          'data.checkout_url',
          'data.redirectUrl',
          'data.redirect_url',
          'data.paymentUrl',
          'data.payment_url',
        ],
      ),
    );
  }

  @override
  Future<PaymentGatewayResult> verify(PaymentGatewayVerificationRequest request) async {
    final endpoint = _resolveCbeVerifyEndpoint();
    final response = await _postJson(
      client: _httpClient,
      uri: endpoint,
      headers: _cbeHeaders(),
      payload: _withoutNullOrEmpty(
        {
          'tx_ref': request.transactionReference,
          'transactionReference': request.transactionReference,
          'order_id': request.orderId,
          'customer_id': request.customerId,
        },
      ),
      timeout: _config.requestTimeout,
    );

    if (!_isResponseSuccessful(response)) {
      throw PaymentGatewayException(
        _bestUserMessage(response, fallback: 'CBE payment verification failed. Please try again.'),
      );
    }

    final status = _resolvePaymentStatus(response);
    final reference = _firstPresentString(
          response,
          const [
            'data.tx_ref',
            'tx_ref',
            'data.reference',
            'reference',
            'transactionReference',
          ],
        ) ??
        request.transactionReference;

    return PaymentGatewayResult(
      method: request.method,
      transactionReference: reference,
      status: status,
      verifiedAt: status == PaymentStatus.verified ? DateTime.now().toUtc() : null,
    );
  }

  Uri _resolveCbeEndpoint() {
    final proxyUrl = _config.cbeProxyInitializeUrl.trim();
    if (proxyUrl.isNotEmpty) {
      return _safeUri(proxyUrl, 'CBE proxy URL');
    }
    return _safeUri(_config.cbeInitializeUrl.trim(), 'CBE initialize URL');
  }

  Uri _resolveCbeVerifyEndpoint() {
    final proxyUrl = _config.cbeProxyVerifyUrl.trim();
    if (proxyUrl.isNotEmpty) {
      return _safeUri(proxyUrl, 'CBE proxy verify URL');
    }

    final directUrl = _config.cbeVerifyUrl.trim();
    if (directUrl.isNotEmpty) {
      return _safeUri(directUrl, 'CBE verify URL');
    }

    throw const PaymentGatewayException(
      'CBE verification endpoint is not configured. Please contact support.',
    );
  }

  Map<String, String> _cbeHeaders() {
    final isProxy = _config.cbeProxyInitializeUrl.trim().isNotEmpty;
    final headers = <String, String>{'Content-Type': 'application/json'};

    if (isProxy) {
      if (_config.cbeProxyToken.trim().isNotEmpty) {
        headers['Authorization'] = 'Bearer ${_config.cbeProxyToken.trim()}';
      }
      return headers;
    }

    final secretKey = _config.cbeSecretKey.trim();
    if (secretKey.isEmpty) {
      throw const PaymentGatewayException(
        'CBE setup is incomplete. Please contact support.',
      );
    }

    headers['Authorization'] = 'Bearer $secretKey';
    return headers;
  }

  String _customerEmail(PaymentGatewayRequest request) {
    final provided = request.customerEmail?.trim();
    if (provided != null && provided.isNotEmpty && provided.contains('@')) {
      return provided;
    }

    final sanitizedCustomerId = request.customerId
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9._-]'), '_');
    final localPart = sanitizedCustomerId.isEmpty ? 'customer' : sanitizedCustomerId;
    return '$localPart@checkout.local';
  }
}

class CashOnDeliveryGatewayAdapter extends PaymentGatewayAdapter {
  const CashOnDeliveryGatewayAdapter();

  @override
  bool canHandle(PaymentMethod method) => method.id == PaymentMethod.cashOnDelivery.id;

  @override
  Future<PaymentGatewayResult> charge(PaymentGatewayRequest request) async {
    return PaymentGatewayResult(
      method: request.method,
      transactionReference: 'COD-${DateTime.now().millisecondsSinceEpoch}-${request.orderId}',
      status: PaymentStatus.verified,
      verifiedAt: DateTime.now().toUtc(),
    );
  }

  @override
  Future<PaymentGatewayResult> verify(PaymentGatewayVerificationRequest request) async {
    return PaymentGatewayResult(
      method: request.method,
      transactionReference: request.transactionReference,
      status: PaymentStatus.verified,
      verifiedAt: DateTime.now().toUtc(),
    );
  }
}

class UnifiedPaymentGateway {
  const UnifiedPaymentGateway(this._adapters, this._config);

  final List<PaymentGatewayAdapter> _adapters;
  final PaymentGatewayEnvironmentConfig _config;

  Future<PaymentGatewayResult> charge(PaymentGatewayRequest request) async {
    final adapter = _adapters.where((candidate) => candidate.canHandle(request.method)).firstOrNull;

    if (adapter == null) {
      throw PaymentGatewayException('No payment gateway is configured for ${request.method.label}.');
    }

    return adapter.charge(request);
  }

  Future<PaymentGatewayResult> verifyWithPolling(PaymentGatewayVerificationRequest request) async {
    final adapter = _adapters.where((candidate) => candidate.canHandle(request.method)).firstOrNull;

    if (adapter == null) {
      throw PaymentGatewayException('No payment gateway is configured for ${request.method.label}.');
    }

    PaymentGatewayResult latestResult = await adapter.verify(request);
    for (var attempt = 1; attempt < _config.verificationMaxAttempts; attempt++) {
      if (latestResult.status != PaymentStatus.pending) {
        return latestResult;
      }

      await Future<void>.delayed(_config.verificationPollInterval);
      latestResult = await adapter.verify(request);
    }

    return latestResult;
  }
}

final telebirrPaymentGatewayAdapterProvider = Provider<PaymentGatewayAdapter>(
  (ref) => TelebirrPaymentGatewayAdapter(
    ref.watch(paymentGatewayHttpClientProvider),
    ref.watch(paymentGatewayEnvironmentConfigProvider),
  ),
);

final cbePaymentGatewayAdapterProvider = Provider<PaymentGatewayAdapter>(
  (ref) => CbePaymentGatewayAdapter(
    ref.watch(paymentGatewayHttpClientProvider),
    ref.watch(paymentGatewayEnvironmentConfigProvider),
  ),
);

final cashOnDeliveryGatewayAdapterProvider = Provider<PaymentGatewayAdapter>(
  (ref) => const CashOnDeliveryGatewayAdapter(),
);

final unifiedPaymentGatewayProvider = Provider<UnifiedPaymentGateway>(
  (ref) => UnifiedPaymentGateway(
    [
      ref.watch(telebirrPaymentGatewayAdapterProvider),
      ref.watch(cbePaymentGatewayAdapterProvider),
      ref.watch(cashOnDeliveryGatewayAdapterProvider),
    ],
    ref.watch(paymentGatewayEnvironmentConfigProvider),
  ),
);

final paymentGatewayEnvironmentConfigProvider = Provider<PaymentGatewayEnvironmentConfig>(
  (ref) => PaymentGatewayEnvironmentConfig.fromEnvironment(),
);

final paymentGatewayHttpClientProvider = Provider<http.Client>(
  (ref) {
    final client = http.Client();
    ref.onDispose(client.close);
    return client;
  },
);

String _randomDigits(int length) {
  final random = Random();
  final buffer = StringBuffer();
  for (var i = 0; i < length; i++) {
    buffer.write(random.nextInt(10));
  }
  return buffer.toString();
}

Future<Map<String, dynamic>> _postJson({
  required http.Client client,
  required Uri uri,
  required Map<String, String> headers,
  required Map<String, dynamic> payload,
  required Duration timeout,
}) async {
  http.Response response;
  try {
    response = await client
        .post(uri, headers: headers, body: jsonEncode(payload))
        .timeout(timeout);
  } on TimeoutException {
    throw const PaymentGatewayException(
      'The payment service is taking too long. Please try again.',
    );
  } catch (_) {
    throw const PaymentGatewayException(
      'Unable to reach the payment service right now. Please try again.',
    );
  }

  if (response.body.trim().isEmpty) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return <String, dynamic>{};
    }
    throw const PaymentGatewayException(
      'Payment service returned an empty response. Please try again.',
    );
  }

  final decoded = jsonDecode(response.body);
  if (decoded is! Map<String, dynamic>) {
    throw const PaymentGatewayException(
      'Payment service returned an invalid response. Please try again.',
    );
  }

  if (response.statusCode < 200 || response.statusCode >= 300) {
    throw PaymentGatewayException(
      _bestUserMessage(decoded, fallback: 'Payment request failed. Please try again.'),
    );
  }

  return decoded;
}

bool _isResponseSuccessful(Map<String, dynamic> response) {
  final success = response['success'];
  if (success is bool) {
    return success;
  }

  final status = _firstPresentString(response, const ['status', 'data.status'])?.toLowerCase();
  if (status != null && {'success', 'ok', 'accepted', 'pending'}.contains(status)) {
    return true;
  }

  final code = _firstPresentString(response, const ['code', 'status_code', 'data.code'])?.toLowerCase();
  if (code != null && {'0', '200', '201', 'success'}.contains(code)) {
    return true;
  }

  return false;
}

PaymentStatus _resolvePaymentStatus(Map<String, dynamic> response) {
  final statusValue = _firstPresentString(
    response,
    const [
      'status',
      'data.status',
      'paymentStatus',
      'payment_status',
      'data.paymentStatus',
      'data.payment_status',
      'verificationStatus',
      'verification_status',
      'data.verificationStatus',
      'data.verification_status',
    ],
  )?.toLowerCase();

  if (statusValue != null) {
    if ({'verified', 'success', 'successful', 'paid', 'completed', 'complete'}.contains(statusValue)) {
      return PaymentStatus.verified;
    }
    if ({'failed', 'error', 'declined', 'cancelled', 'canceled', 'rejected'}.contains(statusValue)) {
      return PaymentStatus.failed;
    }
    if ({'pending', 'processing', 'initiated', 'in_progress'}.contains(statusValue)) {
      return PaymentStatus.pending;
    }
  }

  final verifiedFlag = _readPath(response, 'verified');
  if (verifiedFlag is bool) {
    return verifiedFlag ? PaymentStatus.verified : PaymentStatus.pending;
  }

  return _isResponseSuccessful(response) ? PaymentStatus.pending : PaymentStatus.failed;
}

String _bestUserMessage(Map<String, dynamic> response, {required String fallback}) {
  return _firstPresentString(
        response,
        const [
          'message',
          'detail',
          'error.message',
          'error_description',
          'errors.0.message',
          'data.message',
        ],
      ) ??
      fallback;
}

Map<String, dynamic> _withoutNullOrEmpty(Map<String, dynamic> value) {
  final result = <String, dynamic>{};

  value.forEach((key, raw) {
    if (raw == null) {
      return;
    }
    if (raw is String && raw.trim().isEmpty) {
      return;
    }
    if (raw is Map<String, dynamic>) {
      final nested = _withoutNullOrEmpty(raw);
      if (nested.isNotEmpty) {
        result[key] = nested;
      }
      return;
    }
    result[key] = raw;
  });

  return result;
}

String? _firstPresentString(Map<String, dynamic> data, List<String> paths) {
  for (final path in paths) {
    final value = _readPath(data, path);
    if (value == null) {
      continue;
    }
    final text = value.toString().trim();
    if (text.isNotEmpty) {
      return text;
    }
  }
  return null;
}

dynamic _readPath(Map<String, dynamic> data, String path) {
  final segments = path.split('.');
  dynamic current = data;

  for (final segment in segments) {
    if (current is Map<String, dynamic>) {
      current = current[segment];
      continue;
    }

    if (current is List) {
      final index = int.tryParse(segment);
      if (index == null || index < 0 || index >= current.length) {
        return null;
      }
      current = current[index];
      continue;
    }

    return null;
  }

  return current;
}

Uri _safeUri(String rawValue, String label) {
  if (rawValue.isEmpty) {
    throw PaymentGatewayException('$label is not configured. Please contact support.');
  }

  final uri = Uri.tryParse(rawValue);
  if (uri == null || !(uri.scheme == 'http' || uri.scheme == 'https')) {
    throw PaymentGatewayException('$label is invalid. Please contact support.');
  }
  return uri;
}
