# E-Commerce App With Riverpod (Flutter + Node.js + MongoDB)

Author
- Name: Esrom Basazinaw
- GitHub: https://github.com/yemom
- Repository: https://github.com/yemom/e-commerce-flutter-app

## Project Overview

This is a full-stack e-commerce project with:
- Flutter frontend app (customer, driver, admin flows)
- Express backend API
- MongoDB persistence

The backend is mounted under `/api`, and the Flutter app can run in local asset mode or API mode using `APP_API_BASE_URL`.

## Tech Stack

- Frontend: Flutter, Riverpod, Shared Preferences, HTTP, Google Maps
- Backend: Node.js, Express, Mongoose, JWT, bcryptjs, multer, nodemailer
- Database: MongoDB

## Monorepo Structure

This repository contains two main runtime projects:
- `frontend/` (Flutter app)
- `server/` (Node/Express API)

It also includes shared docs in `docs/`.

## Full Source Folder Structure

Notes:
- Generated/build/dependency folders are intentionally omitted from the deep tree (`build`, `.dart_tool`, `node_modules`, platform generated outputs).
- Upload files are runtime-generated under `server/uploads/`.

```text
e_commerce_app_with_riverpod/
|- docs/
|  |- admin_delivery_dashboard.md
|  |- delivery_api.md
|  |- postman_delivery_collection.json
|- frontend/
|  |- android/
|  |- assets/
|  |  |- data/
|  |- docs/
|  |- ios/
|  |- lib/
|  |  |- main.dart
|  |  |- app/
|  |  |  |- app.dart
|  |  |  |- presentation/
|  |  |  |  |- gateway/
|  |  |  |  |  |- app_gateway.dart
|  |  |  |  |  |- auth_flow_switcher.dart
|  |  |  |  |  |- branch_gate.dart
|  |  |  |  |  |- role_gate.dart
|  |  |  |  |- shells/
|  |  |  |  |  |- admin_portal_shell.dart
|  |  |  |  |  |- app_shell.dart
|  |  |  |  |  |- bottom_nav_shell.dart
|  |  |  |  |- tabs/
|  |  |  |  |  |- cart_tab.dart
|  |  |  |  |  |- home_tab.dart
|  |  |  |  |  |- orders_tab.dart
|  |  |  |  |  |- profile_tab.dart
|  |  |  |  |- widgets/
|  |  |  |     |- app_status_screen.dart
|  |  |  |- providers/
|  |  |  |  |- app_flow_providers.dart
|  |  |  |- services/
|  |  |     |- app_navigation_service.dart
|  |  |- core/
|  |  |  |- auth/
|  |  |  |  |- auth_storage.dart
|  |  |  |- data/
|  |  |  |  |- providers.dart
|  |  |  |  |- datasources/
|  |  |  |  |  |- asset_commerce_data_source.dart
|  |  |  |  |  |- commerce_api_data_source.dart
|  |  |  |  |  |- preferences_data_source.dart
|  |  |  |  |- dtos/
|  |  |  |  |  |- branch_dto.dart
|  |  |  |  |  |- category_dto.dart
|  |  |  |  |  |- order_dto.dart
|  |  |  |  |  |- payment_dto.dart
|  |  |  |  |  |- product_dto.dart
|  |  |  |  |- repositories/
|  |  |  |     |- asset_branch_repository.dart
|  |  |  |     |- asset_category_repository.dart
|  |  |  |     |- asset_order_repository.dart
|  |  |  |     |- asset_payment_repository.dart
|  |  |  |     |- asset_product_repository.dart
|  |  |  |     |- remote_branch_repository.dart
|  |  |  |     |- remote_category_repository.dart
|  |  |  |     |- remote_order_repository.dart
|  |  |  |     |- remote_payment_repository.dart
|  |  |  |     |- remote_product_repository.dart
|  |  |  |- presentation/
|  |  |     |- theme/
|  |  |     |  |- app_theme.dart
|  |  |     |- widgets/
|  |  |        |- app_formatters.dart
|  |  |        |- app_network_image.dart
|  |  |        |- product_image_gallery.dart
|  |  |- driver_app/
|  |  |  |- app_router.dart
|  |  |  |- driver_app_shell.dart
|  |  |  |- models/
|  |  |  |  |- driver.dart
|  |  |  |  |- driver_profile.dart
|  |  |  |  |- order.dart
|  |  |  |- providers/
|  |  |  |  |- auth_provider.dart
|  |  |  |  |- orders_provider.dart
|  |  |  |  |- profile_provider.dart
|  |  |  |- screens/
|  |  |  |  |- driver_eddite_profile.dart
|  |  |  |  |- driver_entry_screen.dart
|  |  |  |  |- home_screen.dart
|  |  |  |  |- order_detail_screen.dart
|  |  |  |  |- orders_screen.dart
|  |  |  |  |- register_screen.dart
|  |  |  |  |- unknown_route_screen.dart
|  |  |  |- services/
|  |  |  |  |- api_service.dart
|  |  |  |  |- auth_service.dart
|  |  |  |- widgets/
|  |  |     |- order_card.dart
|  |  |- features/
|  |  |  |- admin/
|  |  |  |  |- application/
|  |  |  |  |- auth/
|  |  |  |  |- dashboard/
|  |  |  |  |- domain/
|  |  |  |  |- presentation/
|  |  |  |- auth/
|  |  |  |- branches/
|  |  |  |- cart/
|  |  |  |- categories/
|  |  |  |- checkout/
|  |  |  |- driver/
|  |  |  |- orders/
|  |  |  |- payment/
|  |  |  |- products/
|  |  |  |- user/
|  |- linux/
|  |- macos/
|  |- web/
|  |- windows/
|  |- test/
|  |  |- features/
|  |  |- support/
|  |- analysis_options.yaml
|  |- firebase.json
|  |- firestore.rules
|  |- package.json
|  |- pubspec.yaml
|  |- storage.rules
|  |- README.md
|- server/
|  |- app.js
|  |- server.js
|  |- e2e_backend_check.ps1
|  |- package.json
|  |- README.md
|  |- config/
|  |  |- database.js
|  |  |- env.js
|  |- constants/
|  |  |- statuses.js
|  |- controllers/
|  |  |- driver.controller.js
|  |  |- order.controller.js
|  |  |- product.controller.js
|  |  |- auth/
|  |     |- admin.controller.js
|  |     |- driver.controller.js
|  |     |- user.controller.js
|  |- middleware/
|  |  |- auth.js
|  |  |- error-handler.js
|  |  |- not-found.js
|  |  |- role-guard.js
|  |- models/
|  |  |- branch.js
|  |  |- category.js
|  |  |- driver.js
|  |  |- index.js
|  |  |- order.js
|  |  |- payment-option.js
|  |  |- payment-record.js
|  |  |- product.js
|  |  |- shared.js
|  |  |- user.js
|  |- routes/
|  |  |- auth.js
|  |  |- branches.js
|  |  |- categories.js
|  |  |- drivers.js
|  |  |- health.js
|  |  |- orders.js
|  |  |- payment-options.js
|  |  |- payments.js
|  |  |- products.js
|  |  |- uploads.js
|  |  |- auth/
|  |     |- admin.auth.js
|  |     |- driver.auth.js
|  |     |- user.auth.js
|  |- scripts/
|  |  |- list_routes.js
|  |- test/
|  |  |- e2e.integration.test.js
|  |  |- orders-serialization.test.js
|  |- utils/
|     |- errors.js
|     |- mailer.js
|     |- persistence.js
|     |- super-admin.js
|     |- validation.js
```

## Setup Guide

### 1) Prerequisites

- Flutter SDK
- Dart SDK (included with Flutter)
- Node.js 18+ and npm
- MongoDB Atlas or local MongoDB
- Android Studio / VS Code

### 2) Clone and Install

```bash
git clone https://github.com/yemom/e-commerce-flutter-app.git
cd e_commerce_app_with_riverpod
```

Backend:

```bash
cd server
npm install
```

Frontend:

```bash
cd ../frontend
flutter pub get
```

### 3) Backend Environment

Create `server/.env` and set values like:

```env
PORT=8000
MONGODB_URI=mongodb+srv://...
JWT_SECRET=change-this-in-production
SUPER_ADMIN_EMAIL=owner@example.com
SUPER_ADMIN_PASSWORD=Admin@1234!

SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_SECURE=false
SMTP_USER=you@example.com
SMTP_PASS=your-app-password
EMAIL_FROM=you@example.com
APP_NAME=Gulit

CORS_ORIGIN=*
```

### 4) Run Backend

```bash
cd server
npm run server
```

API starts on:
- `http://0.0.0.0:8000`
- Route prefix: `/api`

### 5) Run Flutter Against API

From `frontend/`:

```bash
flutter run --dart-define=APP_API_BASE_URL=http://localhost:8000/api
```

Android emulator:

```bash
flutter run --dart-define=APP_API_BASE_URL=http://10.0.2.2:8000/api
```

Physical Android device (same Wi-Fi as backend host):

```bash
flutter run --dart-define=APP_API_BASE_URL=http://YOUR_PC_LAN_IP:8000/api
```

## Flutter Route Map

Main app named routes (from `frontend/lib/app/app.dart`):
- `/driver/login`
- `/driver/home`
- `/user/login`
- `/user/home`
- `/admin/login`
- `/admin/home`

The default `home` is `AppGateway`, which decides flow based on bootstrap/auth/branch state.

Legacy driver shell routes (from `frontend/lib/driver_app/app_router.dart`):
- `/`
- `/editProfile`
- `/register`
- `/home`
- `/orders`
- `/orderDetail`

## Backend API Routes

All endpoints below are mounted under `/api`.

### Health

- `GET /health`

### Authentication and Users (`routes/auth.js`)

- `POST /auth/register`
- `POST /auth/signup`
- `POST /auth/login`
- `POST /auth/user`
- `POST /auth/admin`
- `POST /auth/driver`
- `POST /auth/password-reset/request`
- `POST /auth/password-reset/confirm`
- `GET /auth/me`
- `GET /auth/users`
- `GET /auth/admin-accounts`
- `GET /auth/admin-accounts/:userId`
- `POST /auth/admin-accounts`
- `PATCH /auth/admin-accounts/:userId`
- `POST /auth/admin-accounts/promote`
- `PATCH /auth/admin-accounts/:userId/approval`
- `DELETE /auth/admin-accounts/:userId/admin-access`
- `GET /auth/drivers`
- `GET /auth/drivers/:userId`
- `POST /auth/drivers`
- `PATCH /auth/drivers/:userId`
- `DELETE /auth/drivers/:userId`

### Branches

- `GET /branches`
- `POST /branches`
- `DELETE /branches/:branchId`
- `PATCH /branches/:branchId/inventory`

### Categories

- `GET /categories`
- `POST /categories`
- `PATCH /categories/:categoryId`
- `DELETE /categories/:categoryId`

### Products

- `GET /products`
- `GET /products/:productId`
- `POST /products`
- `PATCH /products/:productId`
- `DELETE /products/:productId`
- `PATCH /products/:productId/branches/:branchId`

### Drivers

- `POST /drivers/register`
- `POST /drivers`
- `GET /drivers`
- `GET /drivers/:driverId`
- `PATCH /drivers/:driverId`
- `DELETE /drivers/:driverId`
- `POST /drivers/login`
- `GET /drivers/me/orders`
- `GET /drivers/me/profile`
- `POST /drivers/me/location`
- `PATCH /drivers/me/profile`
- `GET /drivers/:driverId/orders`
- `GET /drivers/locations`

### Orders

- `GET /orders`
- `POST /orders`
- `PATCH /orders/:orderId`
- `POST /orders/:orderId/assign-driver`
- `PATCH /orders/:orderId/assign-driver`
- `POST /orders/:orderId/delivery-status`
- `PATCH /orders/:orderId/status`
- `PATCH /orders/:orderId/payment`

### Payment Options

- `GET /payment-options`
- `POST /payment-options`
- `PATCH /payment-options/:optionId`
- `DELETE /payment-options/:optionId`

### Payments

- `POST /payments/:paymentId/verify`

### Uploads

- `POST /uploads/products` (multipart/form-data, field name: `image`)

## Access Notes

- `requireSuperAdmin` guards many admin and driver-management endpoints.
- `/auth/login` supports user/admin/super-admin and also checks the dedicated driver collection as fallback.
- Driver APIs exist in both `/auth/drivers` (users collection role=driver) and `/drivers` (driver collection compatibility flows).

## Testing

Backend:

```bash
cd server
npm test
```

Frontend:

```bash
cd frontend
flutter test
```

## Useful Docs

- `docs/admin_delivery_dashboard.md`
- `docs/delivery_api.md`
- `docs/postman_delivery_collection.json`
- `frontend/docs/firebase_email_otp_setup.md`
- `frontend/docs/mongodb_backend_migration.md`
- `frontend/docs/payment_gateway_setup.md`
