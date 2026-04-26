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
  ConsumerState<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends ConsumerState<OrderTrackingScreen> {
  final Completer<GoogleMapController> _mapController = Completer<GoogleMapController>();

  static const LatLng _addisAbabaFallback = LatLng(9.005401, 38.763611);

  Timer? _refreshTimer;
  LatLng? _userLocation;
  LatLng? _lastAnimatedDriverLocation;
  late Order _currentOrder;

  String get _orderId => widget.order.id;

  @override
  void initState() {
    super.initState();
    _currentOrder = widget.order;

    Future<void>.microtask(_tryLoadUserLocation);
    Future<void>.microtask(_refreshOrderFromApi);

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
      final orders = await ref.read(orderRepositoryProvider).getOrders(
        branchId: _currentOrder.branchId,
      );
      final latest = orders.where((order) => order.id == _orderId).firstOrNull;
      if (!mounted || latest == null) {
        return;
      }
      setState(() => _currentOrder = latest);
    } catch (_) {
      // Keep current view if refresh fails.
    }
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

      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
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

  Future<void> _animateToDriver(LatLng driverLocation) async {
    if (_lastAnimatedDriverLocation == driverLocation) {
      return;
    }
    _lastAnimatedDriverLocation = driverLocation;

    if (!_mapController.isCompleted) {
      return;
    }

    final controller = await _mapController.future;
    await controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: driverLocation, zoom: 15),
      ),
    );
  }

  String _statusLabel(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return 'Processing';
      case OrderStatus.confirmed:
        return 'Confirmed';
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
    final driverLocation = _currentOrder.status == OrderStatus.delivered
        ? customerLocation
        : _currentOrder.status == OrderStatus.shipped
            ? LatLng(
                (storeLocation.latitude + customerLocation.latitude) / 2,
                (storeLocation.longitude + customerLocation.longitude) / 2,
              )
            : storeLocation;

    unawaited(_animateToDriver(driverLocation));

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
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet),
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
        : _currentOrder.status == OrderStatus.shipped
            ? 18
            : 30;

    return Scaffold(
      appBar: AppBar(title: const Text('Order Tracking')),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: const Color(0xFFF0EEFF),
            child: Text(
              'Order Status: ${_statusLabel(_currentOrder.status)}',
              style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF3D36B4)),
            ),
          ),
          Expanded(
            child: GoogleMap(
              initialCameraPosition: CameraPosition(target: driverLocation, zoom: 14),
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
                const Text('Name: Assigned delivery partner'),
                const Text('Phone: Available after dispatch'),
                Text('Estimated arrival: ${etaMinutes == 0 ? 'Arrived' : '$etaMinutes min'}'),
                const SizedBox(height: 8),
                Text(
                  'Total: ${formatPrice(_currentOrder.total)}',
                  style: const TextStyle(color: Color(0xFF6B7280), fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
