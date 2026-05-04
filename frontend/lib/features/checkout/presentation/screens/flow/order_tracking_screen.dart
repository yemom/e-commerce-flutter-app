/// Shows delivery tracking map and status without Firebase dependencies.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:e_commerce_app_with_django/core/presentation/widgets/app_formatters.dart';
import 'package:e_commerce_app_with_django/features/orders/domain/models/order.dart';
import 'package:e_commerce_app_with_django/features/orders/presentation/providers/order_provider.dart';

/// Screen for Order Tracking.
class OrderTrackingScreen extends ConsumerStatefulWidget {
  const OrderTrackingScreen({super.key, required this.order});

  final Order order;

  @override
  ConsumerState<OrderTrackingScreen> createState() =>
      _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends ConsumerState<OrderTrackingScreen> {
  final Completer<GoogleMapController> _mapController =
      Completer<GoogleMapController>();

  static const LatLng _addisAbabaFallback = LatLng(9.005401, 38.763611);

  Timer? _refreshTimer;
  LatLng? _userLocation;
  LatLng? _driverLocation;
  LatLng? _lastAnimatedDriverLocation;
  late Order _currentOrder;

  String get _orderId => widget.order.id;

  @override
  void initState() {
    super.initState();
    _currentOrder = widget.order;

    Future<void>.microtask(_tryLoadUserLocation);
    Future<void>.microtask(_refreshOrderFromApi);

    // Extract any driver location included in the initial order payload.
    _driverLocation = _extractDriverLocationFromAssignedDriver(_currentOrder.assignedDriver);

    _refreshTimer = Timer.periodic(const Duration(seconds: 8), (_) {
      unawaited(_refreshOrderFromApi());
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _refreshOrderFromApi() async {
    try {
      final orders = await ref
          .read(orderRepositoryProvider)
          .getOrders(branchId: _currentOrder.branchId);
      final latest = orders.where((order) => order.id == _orderId).firstOrNull;
      if (!mounted || latest == null) {
        return;
      }
      // Try to extract a concrete driver location from the refreshed order payload.
      final extractedDriverLoc = _extractDriverLocationFromAssignedDriver(latest.assignedDriver);
      setState(() {
        _currentOrder = latest;
        _driverLocation = extractedDriverLoc;
      });
    } catch (_) {
      // Keep current view if refresh fails.
    }
  }

  LatLng? _extractDriverLocationFromAssignedDriver(Map<String, dynamic> assigned) {
    if (assigned.isEmpty) return null;

    // Common shapes: { 'location': { 'lat': .., 'lng': .. } }
    final location = assigned['location'];
    if (location is Map<String, dynamic>) {
      final lat = _asNum(location['lat'] ?? location['latitude']);
      final lng = _asNum(location['lng'] ?? location['longitude']);
      if (lat != null && lng != null) return LatLng(lat, lng);
    }

    // Flat shape on assigned driver: { 'lat': .., 'lng': .. }
    final flatLat = _asNum(assigned['lat'] ?? assigned['latitude'] ?? assigned['latLng']?['lat']);
    final flatLng = _asNum(assigned['lng'] ?? assigned['longitude'] ?? assigned['latLng']?['lng']);
    if (flatLat != null && flatLng != null) return LatLng(flatLat, flatLng);

    // Some backends may provide coordinates as an array [lng, lat] or [lat, lng]
    final coords = assigned['coordinates'];
    if (coords is List && coords.length >= 2) {
      final a = _asNum(coords[0]);
      final b = _asNum(coords[1]);
      if (a != null && b != null) {
        // Try both orders: prefer (lat, lng) if values look like lat/lng ranges
        if (a.abs() <= 90 && b.abs() <= 180) return LatLng(a, b);
        if (b.abs() <= 90 && a.abs() <= 180) return LatLng(b, a);
      }
    }

    return null;
  }

  LatLng? _latLngFromDeliveryAddress(Map<String, dynamic> address) {
    if (address.isEmpty) return null;

    // Common shapes: { 'location': { 'lat': .., 'lng': .. } }
    final location = address['location'];
    if (location is Map<String, dynamic>) {
      final lat = _asNum(location['lat'] ?? location['latitude']);
      final lng = _asNum(location['lng'] ?? location['longitude']);
      if (lat != null && lng != null) return LatLng(lat, lng);
    }

    // Flat shape: { 'lat': .., 'lng': .. }
    final flatLat = _asNum(address['lat'] ?? address['latitude']);
    final flatLng = _asNum(address['lng'] ?? address['longitude']);
    if (flatLat != null && flatLng != null) return LatLng(flatLat, flatLng);

    return null;
  }

  double? _asNum(Object? value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  Future<void> _tryLoadUserLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }

      final position = await Geolocator.getCurrentPosition();
      if (!mounted) {
        return;
      }

      setState(() {
        _userLocation = LatLng(position.latitude, position.longitude);
      });
    } catch (_) {
      // Keep map available even if location fails.
    }
  }

  Future<void> _animateToDriver(LatLng driverLocation, {LatLng? customer, LatLng? store}) async {
    if (_lastAnimatedDriverLocation == driverLocation) {
      return;
    }
    _lastAnimatedDriverLocation = driverLocation;

    if (!_mapController.isCompleted) {
      return;
    }

    final controller = await _mapController.future;
    // Try to compute a camera position that fits store, driver and customer.
    final customerLocation = customer ?? _userLocation ?? _addisAbabaFallback;
    final storeLocation = store ?? _addisAbabaFallback;
    try {
      final latMin = [driverLocation.latitude, customerLocation.latitude, storeLocation.latitude].reduce((a, b) => a < b ? a : b);
      final latMax = [driverLocation.latitude, customerLocation.latitude, storeLocation.latitude].reduce((a, b) => a > b ? a : b);
      final lngMin = [driverLocation.longitude, customerLocation.longitude, storeLocation.longitude].reduce((a, b) => a < b ? a : b);
      final lngMax = [driverLocation.longitude, customerLocation.longitude, storeLocation.longitude].reduce((a, b) => a > b ? a : b);
      final bounds = LatLngBounds(southwest: LatLng(latMin, lngMin), northeast: LatLng(latMax, lngMax));
      await controller.animateCamera(CameraUpdate.newLatLngBounds(bounds, 60));
    } catch (_) {
      await controller.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: driverLocation, zoom: 15),
        ),
      );
    }
  }

  String _statusLabel(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return 'Processing';
      case OrderStatus.confirmed:
        return 'Confirmed';
      case OrderStatus.assigned:
        return 'Driver assigned';
      case OrderStatus.out_for_delivery:
      case OrderStatus.shipped:
        return 'Out for Delivery';
      case OrderStatus.delivered:
        return 'Delivered';
    }
  }

  @override
  Widget build(BuildContext context) {
    final storeLocation = _addisAbabaFallback;
    final customerLocation = _userLocation ?? _addisAbabaFallback;

    // Prefer exact persisted deliveryAddress location when available (persisted by admin assign).
    LatLng? deliveryLatLng;
    try {
      deliveryLatLng = _latLngFromDeliveryAddress(_currentOrder.deliveryAddress);
    } catch (_) {
      deliveryLatLng = null;
    }

    final computedDriverLocation = _currentOrder.status == OrderStatus.delivered
      ? customerLocation
      : deliveryLatLng ??
        (_currentOrder.status == OrderStatus.shipped ||
            _currentOrder.status == OrderStatus.out_for_delivery
          ? LatLng(
            (storeLocation.latitude + customerLocation.latitude) / 2,
            (storeLocation.longitude + customerLocation.longitude) / 2,
            )
          : storeLocation);

    // Prefer an extracted precise driver location when available from API payloads.
    final driverLocation = _driverLocation ?? computedDriverLocation;

    unawaited(_animateToDriver(driverLocation, customer: customerLocation, store: storeLocation));

    final markers = <Marker>{
      Marker(
        markerId: const MarkerId('store'),
        position: storeLocation,
        infoWindow: const InfoWindow(title: 'Store'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
      ),
      Marker(
        markerId: const MarkerId('driver'),
        position: driverLocation,
        infoWindow: const InfoWindow(title: 'Delivery Driver'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
      ),
      Marker(
        markerId: const MarkerId('customer'),
        position: customerLocation,
        infoWindow: const InfoWindow(title: 'Customer'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      ),
      if (_userLocation != null)
        Marker(
          markerId: const MarkerId('user'),
          position: _userLocation!,
          infoWindow: const InfoWindow(title: 'You'),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueViolet,
          ),
        ),
    };

    final routePolyline = Polyline(
      polylineId: const PolylineId('delivery-route'),
      points: [storeLocation, driverLocation, customerLocation],
      width: 5,
      color: const Color(0xFF5E56E7),
    );

    final etaMinutes = _currentOrder.status == OrderStatus.delivered
        ? 0
        : _currentOrder.status == OrderStatus.shipped ||
              _currentOrder.status == OrderStatus.out_for_delivery
        ? 18
        : 30;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Tracking'),
        actions: [
          IconButton(
            tooltip: 'Refresh location',
            onPressed: () => unawaited(_refreshOrderFromApi()),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: const Color(0xFFF0EEFF),
            child: Text(
              'Order Status: ${_statusLabel(_currentOrder.status)}',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: Color(0xFF3D36B4),
              ),
            ),
          ),
          Expanded(
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: driverLocation,
                zoom: 14,
              ),
              onMapCreated: (controller) {
                if (!_mapController.isCompleted) {
                  _mapController.complete(controller);
                }
              },
              myLocationEnabled: _userLocation != null,
              myLocationButtonEnabled: true,
              zoomControlsEnabled: false,
              markers: markers,
              polylines: {routePolyline},
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Color(0xFFE5E7F0))),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Driver Info',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text(
                  'Name: ${_currentOrder.assignedDriver['name']?.toString().trim().isNotEmpty == true ? _currentOrder.assignedDriver['name'].toString() : 'Assigned delivery partner'}',
                ),
                Text(
                  'Phone: ${_currentOrder.assignedDriver['phone']?.toString().trim().isNotEmpty == true ? _currentOrder.assignedDriver['phone'].toString() : 'Available after dispatch'}',
                ),
                Text(
                  'Estimated arrival: ${etaMinutes == 0 ? 'Arrived' : '$etaMinutes min'}',
                ),
                const SizedBox(height: 8),
                Text(
                  'Total: ${formatPrice(_currentOrder.total)}',
                  style: const TextStyle(
                    color: Color(0xFF6B7280),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
