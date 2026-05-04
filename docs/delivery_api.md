Delivery API
===========

Endpoints:

- POST /api/drivers/register
  - body: { name, phone, password, vehicleType, licenseNumber }
- POST /api/drivers/login
  - body: { phone, password }
- PATCH /api/drivers/:driverId
  - auth: Bearer JWT
  - body: { name?, vehicleType?, licenseNumber?, isOnline? }

- POST /api/orders/:orderId/assign-driver
  - body: { driverId }
  - auth: admin

- POST /api/orders/:orderId/delivery-status
  - body: { status: 'assigned'|'out_for_delivery'|'delivered' }

Models added:
- Driver (drivers collection)
- Order extended with driverId, timestamps

Flutter examples:

1) Assign driver
```
POST http://localhost:8000/api/orders/ORDER_ID/assign-driver
Authorization: Bearer <admin-token>
Body JSON: { "driverId": "DRIVER_ID" }
```

2) Driver register
```
POST http://localhost:8000/api/drivers/register
Body JSON: { "name":"Bob","phone":"+251...","password":"secret","vehicleType":"bike","licenseNumber":"ABC123" }
```
