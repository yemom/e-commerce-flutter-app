# MongoDB backend migration

This Flutter app should not connect directly to MongoDB from the client.

Use a backend API instead, then point the app at it with:

```bash
flutter run --dart-define=APP_API_BASE_URL=http://localhost:8000/api
```

When `APP_API_BASE_URL` is set, the app now prefers remote repositories for:

- branches
- categories
- products
- orders
- payment options
- payment verification

When the value is missing, the app falls back to the bundled asset repositories.

## Expected API routes

The client expects JSON endpoints shaped around these routes:

- `GET /branches`
- `POST /branches`
- `PATCH /branches/:branchId/inventory`
- `GET /categories`
- `POST /categories`
- `PATCH /categories/:categoryId`
- `DELETE /categories/:categoryId`
- `GET /products`
  Query params: `branchId`, `categoryId`, `query`
- `POST /products`
- `PATCH /products/:productId`
- `DELETE /products/:productId`
- `PATCH /products/:productId/branches/:branchId`
- `GET /orders`
  Query params: `branchId`, `status`
- `POST /orders`
- `PATCH /orders/:orderId`
  Body: `{"status":"confirmed|shipped|delivered|pending"}`
- `PATCH /orders/:orderId/payment`
  Body: `{"paymentStatus":"pending|verified|failed"}`
- `GET /payment-options`
- `POST /payment-options`
- `PATCH /payment-options/:optionId`
  Body: `{"isEnabled":true|false}`
- `POST /payments/:paymentId/verify`
  Body: `{"transactionReference":"..."}`

Responses can be either plain JSON objects/lists or wrapped in:

- `{ "data": ... }`
- `{ "items": [...] }`
- `{ "results": [...] }`
- `{ "item": {...} }`
- `{ "result": {...} }`

## Remaining Firebase dependencies

This migration does not remove Firebase from:

- authentication and user profile storage
- admin account approval flows
- live order tracking in `orders` Firestore documents
- image uploads to Firebase Storage

Those parts still need a second migration step if you want the app fully off Firebase.
