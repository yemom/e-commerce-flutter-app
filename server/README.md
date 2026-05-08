# Backend API Documentation

This folder contains the Node.js + Express + MongoDB backend for the e-commerce project.

Main API mount path: `/api`

## Backend Structure

```text
server/
|- app.js
|- server.js
|- e2e_backend_check.ps1
|- package.json
|- README.md
|- config/
|  |- database.js
|  |- env.js
|- constants/
|  |- statuses.js
|- controllers/
|  |- driver.controller.js
|  |- order.controller.js
|  |- product.controller.js
|  |- auth/
|     |- admin.controller.js
|     |- driver.controller.js
|     |- user.controller.js
|- middleware/
|  |- auth.js
|  |- error-handler.js
|  |- not-found.js
|  |- role-guard.js
|- models/
|  |- branch.js
|  |- category.js
|  |- driver.js
|  |- index.js
|  |- order.js
|  |- payment-option.js
|  |- payment-record.js
|  |- product.js
|  |- shared.js
|  |- user.js
|- routes/
|  |- auth.js
|  |- branches.js
|  |- categories.js
|  |- drivers.js
|  |- health.js
|  |- orders.js
|  |- payment-options.js
|  |- payments.js
|  |- products.js
|  |- uploads.js
|  |- auth/
|     |- admin.auth.js
|     |- driver.auth.js
|     |- user.auth.js
|- scripts/
|  |- list_routes.js
|- test/
|  |- e2e.integration.test.js
|  |- orders-serialization.test.js
|- utils/
	|- errors.js
	|- mailer.js
	|- persistence.js
	|- super-admin.js
	|- validation.js
```

## Setup

1. Create `server/.env`.
2. Configure at least:

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
SMTP_PASS=app-password
EMAIL_FROM=you@example.com
APP_NAME=Gulit

CORS_ORIGIN=*
```

3. Install and run:

```bash
npm install
npm run server
```

## API Routes

All routes are under `/api`.

### Health

- `GET /api/health`

### Auth and User Management

- `POST /api/auth/register`
- `POST /api/auth/signup`
- `POST /api/auth/login`
- `POST /api/auth/user`
- `POST /api/auth/admin`
- `POST /api/auth/driver`
- `POST /api/auth/password-reset/request`
- `POST /api/auth/password-reset/confirm`
- `GET /api/auth/me`
- `GET /api/auth/users`
- `GET /api/auth/admin-accounts`
- `GET /api/auth/admin-accounts/:userId`
- `POST /api/auth/admin-accounts`
- `PATCH /api/auth/admin-accounts/:userId`
- `POST /api/auth/admin-accounts/promote`
- `PATCH /api/auth/admin-accounts/:userId/approval`
- `DELETE /api/auth/admin-accounts/:userId/admin-access`
- `GET /api/auth/drivers`
- `GET /api/auth/drivers/:userId`
- `POST /api/auth/drivers`
- `PATCH /api/auth/drivers/:userId`
- `DELETE /api/auth/drivers/:userId`

### Branches

- `GET /api/branches`
- `POST /api/branches`
- `DELETE /api/branches/:branchId`
- `PATCH /api/branches/:branchId/inventory`

### Categories

- `GET /api/categories`
- `POST /api/categories`
- `PATCH /api/categories/:categoryId`
- `DELETE /api/categories/:categoryId`

### Products

- `GET /api/products`
- `GET /api/products/:productId`
- `POST /api/products`
- `PATCH /api/products/:productId`
- `DELETE /api/products/:productId`
- `PATCH /api/products/:productId/branches/:branchId`

### Drivers

- `POST /api/drivers/register`
- `POST /api/drivers`
- `GET /api/drivers`
- `GET /api/drivers/:driverId`
- `PATCH /api/drivers/:driverId`
- `DELETE /api/drivers/:driverId`
- `POST /api/drivers/login`
- `GET /api/drivers/me/orders`
- `GET /api/drivers/me/profile`
- `POST /api/drivers/me/location`
- `PATCH /api/drivers/me/profile`
- `GET /api/drivers/:driverId/orders`
- `GET /api/drivers/locations`

### Orders

- `GET /api/orders`
- `POST /api/orders`
- `PATCH /api/orders/:orderId`
- `POST /api/orders/:orderId/assign-driver`
- `PATCH /api/orders/:orderId/assign-driver`
- `POST /api/orders/:orderId/delivery-status`
- `PATCH /api/orders/:orderId/status`
- `PATCH /api/orders/:orderId/payment`

### Payment Options

- `GET /api/payment-options`
- `POST /api/payment-options`
- `PATCH /api/payment-options/:optionId`
- `DELETE /api/payment-options/:optionId`

### Payments

- `POST /api/payments/:paymentId/verify`

### Uploads

- `POST /api/uploads/products` (multipart/form-data field name: `image`)

## Flutter Connectivity

From `frontend/`:

```bash
flutter run --dart-define=APP_API_BASE_URL=http://localhost:8000/api
```

Android emulator:

```bash
flutter run --dart-define=APP_API_BASE_URL=http://10.0.2.2:8000/api
```

Physical Android device:

```bash
flutter run --dart-define=APP_API_BASE_URL=http://YOUR_PC_LAN_IP:8000/api
```


## Running with Docker

Quick steps to run the backend + MongoDB using Docker Compose from the project root.

1. Copy and edit the environment template:

```bash
cp server/.env.example server/.env
# Edit server/.env and fill real secrets
```

2. Create the uploads folder (bind-mount target):

```powershell
mkdir .\server\uploads
```

3. Build and start services (uses Docker Compose v2 syntax):

```bash
docker compose up -d --build
```

4. Useful commands:

```bash
docker compose ps
docker compose logs -f app
docker compose logs -f mongo
docker compose down            # stop and remove containers
docker compose down -v         # stop and remove containers + volumes (wipe DB)
```

5. Verify the API health endpoint:

```
http://localhost:8000/api/health
```

Important env vars (set in `server/.env`)

- `PORT` — host port to bind the API (default `8000`).
- `JWT_SECRET` — required for signing tokens.
- `SUPER_ADMIN_EMAIL`, `SUPER_ADMIN_PASSWORD` — seeded admin account.
- `MONGODB_URI` — optional: leave unset to use the local `mongo` service; set to an Atlas URI to use external DB.
- `MONGO_ROOT_USER`, `MONGO_ROOT_PASS` — used only if running the included local `mongo` service.

See `server/.env.example` for a sanitized template you can copy.

---


