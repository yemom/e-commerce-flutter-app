# Admin Delivery Dashboard

This document describes the driver management and delivery operations dashboard for the e-commerce app.

## Backend Architecture

The backend already uses Express, Mongoose, and JWT. The delivery module now fits into the same structure:

- `server/routes/drivers.js` handles driver CRUD, authentication, detail lookups, and assigned order history.
- `server/routes/orders.js` handles assignment and delivery status changes.
- `server/middleware/auth.js` provides JWT guards for users, drivers, and super-admin actions.
- `server/models/driver.js` stores driver profile and availability.
- `server/models/order.js` stores `driverId`, delivery timestamps, and order status.

## API Routes

### Driver management

- `POST /api/drivers`
- `GET /api/drivers`
- `GET /api/drivers/:id`
- `PATCH /api/drivers/:id`
- `DELETE /api/drivers/:id`

### Driver auth

- `POST /api/drivers/register`
- `POST /api/drivers/login`
- `GET /api/drivers/me/orders`

### Order assignment and tracking

- `PATCH /api/orders/:id/assign-driver`
- `PATCH /api/orders/:id/status`
- `POST /api/orders/:id/delivery-status` for backward compatibility

## Security Model

- Admin-only endpoints require a valid JWT from `/api/auth/login` and the `super_admin` role.
- Driver endpoints require a driver JWT from `/api/drivers/login`.
- Drivers can only update their own profile and delivery progress.
- Admins can assign drivers and inspect driver delivery history.

## Driver List UI Structure

Recommended dashboard layout:

- Top bar with global search, add-driver button, and delivery metrics.
- Filter row with status chips and vehicle-type dropdown.
- Table/list columns:
  - Name
  - Phone
  - Email
  - Vehicle type
  - Status
  - Actions
- Actions:
  - View details
  - Edit
  - Delete
  - Assign orders

## Driver Detail Page

Display:

- Full driver profile
- Availability status
- Assigned orders
- Delivery history
- Quick actions to update status or edit profile

## Order Assignment Flow

1. Admin opens an order detail row.
2. Admin selects an available driver from a dropdown/modal.
3. UI calls `PATCH /api/orders/:id/assign-driver` with `driverId`.
4. Backend sets `driverId` and updates order status to `assigned`.

## Order Tracking

Show order cards with:

- Customer name
- Delivery address
- Assigned driver
- Current status
- Delivery timestamps

If coordinates are available, show a map preview for the active delivery.

## Real-Time Updates

Options for live operations:

- Poll `GET /api/drivers` and `GET /api/drivers/:id` every 10-30 seconds.
- Add WebSocket events for:
  - driver availability changes
  - order assignment changes
  - delivery status updates

## Example Postman Requests

### Create driver

```http
POST /api/drivers
Authorization: Bearer <super-admin-jwt>
Content-Type: application/json

{
  "name": "John Driver",
  "phone": "+251900000001",
  "email": "john@example.com",
  "password": "Driver123!",
  "vehicleType": "bike",
  "licenseNumber": "LIC-1001",
  "isOnline": true
}
```

### List drivers

```http
GET /api/drivers?q=john&status=online
Authorization: Bearer <super-admin-jwt>
```

### Driver detail

```http
GET /api/drivers/<driver-id>
Authorization: Bearer <super-admin-jwt>
```

### Update driver

```http
PATCH /api/drivers/<driver-id>
Authorization: Bearer <super-admin-jwt>
Content-Type: application/json

{
  "vehicleType": "car",
  "isOnline": false
}
```

### Delete driver

```http
DELETE /api/drivers/<driver-id>
Authorization: Bearer <super-admin-jwt>
```

### Assign driver to order

```http
PATCH /api/orders/<order-id>/assign-driver
Authorization: Bearer <super-admin-jwt>
Content-Type: application/json

{
  "driverId": "driver-uuid"
}
```

### Update delivery status

```http
PATCH /api/orders/<order-id>/status
Authorization: Bearer <driver-jwt>
Content-Type: application/json

{
  "status": "out_for_delivery"
}
```

## Frontend Code Structure

The existing Flutter admin portal can host this module using the current `AdminPortalShell`.

Suggested folder layout:

- `frontend/lib/features/admin/presentation/screens/admin_drivers_screen.dart`
- `frontend/lib/features/admin/presentation/screens/admin_driver_detail_screen.dart`
- `frontend/lib/features/admin/presentation/providers/admin_drivers_provider.dart`
- `frontend/lib/features/admin/application/admin_driver_service.dart`
- `frontend/lib/features/admin/domain/models/admin_driver.dart`

## Clean Scalable Practices

- Keep API calls in a service class.
- Keep widget state in Riverpod providers.
- Keep driver/order DTOs in separate model files.
- Use one screen per responsibility: list, detail, edit, assign.
- Keep admin-only behavior on the backend even if the UI hides actions.

## Next Implementation Steps

- Add a dedicated admin drivers screen to the Flutter admin portal.
- Add order assignment modal.
- Add map integration with a Google Maps widget.
- Add polling or WebSocket updates for live driver status changes.
