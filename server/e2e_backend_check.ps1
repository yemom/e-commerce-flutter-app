$ErrorActionPreference = 'Stop'
$base = 'http://localhost:8000/api'

$adminLogin = Invoke-RestMethod -Uri "$base/auth/admin" -Method Post -ContentType 'application/json' -Body (@{ identifier = '12yemom@gmail.com'; password = '12345678' } | ConvertTo-Json)
$token = $adminLogin.token
if (-not $token) { throw 'Admin login did not return a token.' }
$headers = @{ Authorization = "Bearer $token" }

$drivers = Invoke-RestMethod -Uri "$base/auth/drivers" -Headers $headers -Method Get
$users = Invoke-RestMethod -Uri "$base/auth/users" -Headers $headers -Method Get
$orders = Invoke-RestMethod -Uri "$base/orders" -Method Get

if ($drivers -isnot [System.Array]) { $drivers = @($drivers) }
if ($users -isnot [System.Array]) { $users = @($users) }
if ($orders -isnot [System.Array]) { $orders = @($orders) }

$driver = $drivers | Select-Object -First 1
$user = $users | Where-Object { $_.role -eq 'user' } | Select-Object -First 1
$template = $orders | Where-Object { $_.status -ne 'delivered' } | Select-Object -First 1

if (-not $driver) { throw 'No driver available.' }
if (-not $user) { throw 'No user account available.' }
if (-not $template) { throw 'No template order available.' }

$orderId = 'e2e-' + [guid]::NewGuid().ToString('N').Substring(0, 12)
$paymentId = 'pay-' + [guid]::NewGuid().ToString('N').Substring(0, 12)

$createBody = @{
  id = $orderId
  branchId = $template.branchId
  customerId = $user.id
  customerName = $user.name
  customerEmail = $user.email
  deliveryAddress = @{
    label = 'Test drop'
    line1 = 'Addis Ababa, Ethiopia'
    city = 'Addis Ababa'
    country = 'Ethiopia'
    lat = 9.01
    lng = 38.76
  }
  items = @(@{ productId = 'p-test'; productName = 'Tracking Test Item'; quantity = 1; unitPrice = 100.0 })
  subtotal = 100.0
  deliveryFee = 15.0
  total = 115.0
  payment = @{ id = $paymentId; method = 'cash'; amount = 115.0; createdAt = (Get-Date).ToUniversalTime().ToString('o') }
  createdAt = (Get-Date).ToUniversalTime().ToString('o')
} | ConvertTo-Json -Depth 10

$created = Invoke-RestMethod -Uri "$base/orders" -Method Post -ContentType 'application/json' -Body $createBody
$assignBody = @{ driverId = $driver.id; location = $created.deliveryAddress } | ConvertTo-Json -Depth 10
$assigned = Invoke-RestMethod -Uri "$base/orders/$orderId/assign-driver" -Headers $headers -Method Post -ContentType 'application/json' -Body $assignBody
$allAfter = Invoke-RestMethod -Uri "$base/orders" -Method Get
if ($allAfter -isnot [System.Array]) { $allAfter = @($allAfter) }
$refetched = $allAfter | Where-Object { $_.id -eq $orderId } | Select-Object -First 1

[ordered]@{
  createdOrderId = $created.id
  createdDeliveryLat = $created.deliveryAddress.lat
  createdDeliveryLng = $created.deliveryAddress.lng
  assignedStatus = $assigned.status
  assignedDriverId = $assigned.driverId
  assignedDriverName = $assigned.assignedDriver.name
  assignedDriverPhone = $assigned.assignedDriver.phone
  refetchedDriverId = $refetched.driverId
  refetchedAssignedDriver = $refetched.assignedDriver.name
  refetchedLat = $refetched.deliveryAddress.lat
  refetchedLng = $refetched.deliveryAddress.lng
} | ConvertTo-Json -Compress -Depth 10
