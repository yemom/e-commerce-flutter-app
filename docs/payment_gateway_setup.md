# Payment Gateway Setup

This app reads payment gateway values from compile-time environment variables.

## Why this setup

- No secrets are hardcoded in source code.
- You can use different keys/URLs per environment (dev, staging, prod).
- You can route through your backend proxy to avoid exposing provider secrets in the client.

## Recommended security model

Use proxy URLs for both gateways so secret keys stay only on your backend.

- `CBE_PROXY_INITIALIZE_URL`
- `CBE_PROXY_VERIFY_URL`
- `TELEBIRR_PROXY_INITIALIZE_URL`
- `TELEBIRR_PROXY_VERIFY_URL`

Optional proxy auth tokens:

- `CBE_PROXY_TOKEN`
- `TELEBIRR_PROXY_TOKEN`

## Direct provider mode (less secure)

If you do not use a backend proxy, provide direct provider credentials:

- `CBE_INITIALIZE_URL`
- `CBE_VERIFY_URL`
- `CBE_SECRET_KEY`
- `CBE_CALLBACK_URL` (optional)
- `CBE_RETURN_URL` (optional)
- `TELEBIRR_INITIALIZE_URL`
- `TELEBIRR_VERIFY_URL`
- `TELEBIRR_API_KEY`
- `TELEBIRR_MERCHANT_ID` (optional)
- `TELEBIRR_NOTIFY_URL` (optional)
- `TELEBIRR_CALLBACK_URL` (optional)
- `PAYMENT_REQUEST_TIMEOUT_SECONDS` (optional, default `20`)
- `PAYMENT_VERIFICATION_INTERVAL_SECONDS` (optional, default `3`)
- `PAYMENT_VERIFICATION_MAX_ATTEMPTS` (optional, default `10`)

## Example `--dart-define` run

```bash
flutter run \
  --dart-define=CBE_PROXY_INITIALIZE_URL=https://api.yourdomain.com/payments/cbe/init \
  --dart-define=CBE_PROXY_VERIFY_URL=https://api.yourdomain.com/payments/cbe/verify \
  --dart-define=CBE_PROXY_TOKEN=replace_me \
  --dart-define=TELEBIRR_PROXY_INITIALIZE_URL=https://api.yourdomain.com/payments/telebirr/init \
  --dart-define=TELEBIRR_PROXY_VERIFY_URL=https://api.yourdomain.com/payments/telebirr/verify \
  --dart-define=TELEBIRR_PROXY_TOKEN=replace_me
```

## Example `--dart-define-from-file`

Create a local file like `env/payment.dev.json` (do not commit real secrets):

```json
{
  "CBE_PROXY_INITIALIZE_URL": "https://api.yourdomain.com/payments/cbe/init",
  "CBE_PROXY_VERIFY_URL": "https://api.yourdomain.com/payments/cbe/verify",
  "CBE_PROXY_TOKEN": "replace_me",
  "TELEBIRR_PROXY_INITIALIZE_URL": "https://api.yourdomain.com/payments/telebirr/init",
  "TELEBIRR_PROXY_VERIFY_URL": "https://api.yourdomain.com/payments/telebirr/verify",
  "TELEBIRR_PROXY_TOKEN": "replace_me",
  "PAYMENT_VERIFICATION_INTERVAL_SECONDS": "3",
  "PAYMENT_VERIFICATION_MAX_ATTEMPTS": "10",
  "PAYMENT_REQUEST_TIMEOUT_SECONDS": "20"
}
```

Then run:

```bash
flutter run --dart-define-from-file=env/payment.dev.json
```

## Webhook and signature verification contract

Your backend endpoints should:

- Verify provider signatures before accepting callback/webhook payloads.
- Store a normalized payment status and trusted transaction reference.
- Expose a secure verify endpoint the app can use to confirm final payment status.

Recommended payload from proxy `init` endpoints (both Telebirr and CBE):

```json
{
  "success": true,
  "transactionReference": "txn_123",
  "status": "pending",
  "message": "Payment initialized"
}
```

Recommended payload from proxy `verify` endpoints:

```json
{
  "success": true,
  "transactionReference": "txn_123",
  "status": "verified",
  "message": "Payment verified"
}
```
