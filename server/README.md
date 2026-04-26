# Backend API

## Structure

- `server/server.js`: startup entry point
- `server/app.js`: Express app wiring
- `server/config/`: env and Mongo connection
- `server/models/`: Mongoose models
- `server/routes/`: API routes split by resource
- `server/middleware/`: shared Express middleware
- `server/utils/`: validation and persistence helpers

## Setup

1. Copy `server/.env.example` to `server/.env`.
2. Put your real MongoDB Atlas connection string in `MONGODB_URI`.
3. Configure SMTP values if you want password reset emails delivered.
4. Start the server:

```bash
npm install
npm run server
```

## Routes

- `GET /api/health`
- `POST /api/auth/signup`
- `POST /api/auth/login`
- `POST /api/auth/password-reset/request`
- `POST /api/auth/password-reset/confirm`
- `GET /api/auth/me`
- `GET /api/auth/admin-accounts`
- `GET /api/auth/admin-accounts/:userId`
- `POST /api/auth/admin-accounts`
- `PATCH /api/auth/admin-accounts/:userId`
- `POST /api/auth/admin-accounts/promote`
- `PATCH /api/auth/admin-accounts/:userId/approval`
- `DELETE /api/auth/admin-accounts/:userId/admin-access`
- `GET /api/branches`
- `POST /api/branches`
- `PATCH /api/branches/:branchId/inventory`
- `GET /api/categories`
- `POST /api/categories`
- `PATCH /api/categories/:categoryId`
- `DELETE /api/categories/:categoryId`
- `GET /api/products`
- `POST /api/products`
- `PATCH /api/products/:productId`
- `DELETE /api/products/:productId`
- `PATCH /api/products/:productId/branches/:branchId`
- `GET /api/orders`
- `POST /api/orders`
- `PATCH /api/orders/:orderId`
- `PATCH /api/orders/:orderId/payment`
- `GET /api/payment-options`
- `POST /api/payment-options`
- `PATCH /api/payment-options/:optionId`
- `POST /api/payments/:paymentId/verify`

## Flutter

Run Flutter against this backend with:

```bash
flutter run --dart-define=APP_API_BASE_URL=http://localhost:8000/api
```

For Android:

- Emulator: `flutter run --dart-define=APP_API_BASE_URL=http://10.0.2.2:8000/api`
- Real device on the same Wi-Fi: `flutter run --dart-define=APP_API_BASE_URL=http://YOUR_COMPUTER_LAN_IP:8000/api`

`10.0.2.2` only works on the Android emulator. A physical device cannot use `localhost` or `10.0.2.2` to reach the backend running on your computer.


