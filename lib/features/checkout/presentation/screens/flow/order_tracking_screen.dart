/// Shows real-time delivery tracking with map markers and order status.
library;
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:e_commerce_app_with_django/core/presentation/widgets/app_formatters.dart';
import 'package:e_commerce_app_with_django/features/orders/domain/models/order.dart';

class OrderTrackingScreen extends StatefulWidget {
  const OrderTrackingScreen({super.key, required this.order});

  final Order order;

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  final Completer<GoogleMapController> _mapController = Completer<GoogleMapController>();

  static const LatLng _addisAbabaFallback = LatLng(9.005401, 38.763611);

  LatLng? _userLocation;
  LatLng? _lastAnimatedDriverLocation;

  String get _orderId => widget.order.id;

  Future<void> _tryLoadUserLocation() async {
    try {
      // Try to locate user for better map context, but do not block tracking.
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

  @override
  void initState() {
    super.initState();
    Future<void>.microtask(_tryLoadUserLocation);
  }

  Future<void> _animateToDriver(LatLng driverLocation) async {
    // Recenter map only when driver location actually changes.
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

  LatLng _latLngFromData(Map<String, dynamic>? data, String key, {LatLng? fallback}) {
    final raw = data?[key];
    if (raw is Map<String, dynamic>) {
      final lat = (raw['lat'] as num?)?.toDouble();
      final lng = (raw['lng'] as num?)?.toDouble();
      if (lat != null && lng != null) {
        return LatLng(lat, lng);
      }
    }
    return fallback ?? _addisAbabaFallback;
  }

  String _statusLabel(String rawStatus) {
    switch (rawStatus) {
      case 'processing':
        return 'Processing';
      case 'packed':
        return 'Packed';
      case 'out_for_delivery':
      case 'shipped':
        return 'Out for Delivery';
      case 'delivered':
        return 'Delivered';
      default:
        return rawStatus.replaceAll('_', ' ').trim();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Order Tracking')),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('orders').doc(_orderId).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data?.data();
          final statusRaw = (data?['orderStatus'] as String?) ?? widget.order.status.name;

          final storeLocation = _latLngFromData(
            data,
            'storeLocation',
            fallback: _addisAbabaFallback,
          );
          final customerLocation = _latLngFromData(
            data,
            'customerLocation',
            fallback: _userLocation ?? _addisAbabaFallback,
          );
          final driverLocation = _latLngFromData(
            data,
            'driverLocation',
            fallback: storeLocation,
          );

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

          final driverName = (data?['driverName'] as String?) ?? 'Driver assigned';
          final driverPhone = (data?['driverPhone'] as String?) ?? 'Phone number will appear soon';
          final eta = (data?['etaMinutes'] as num?)?.toInt();

          return Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                color: const Color(0xFFF0EEFF),
                child: Text(
                  'Order Status: ${_statusLabel(statusRaw)}',
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
                    Text('Name: $driverName'),
                    Text('Phone: $driverPhone'),
                    Text('Estimated arrival: ${eta != null ? '$eta min' : 'Calculating...'}'),
                    const SizedBox(height: 8),
                    Text(
                      'Total: ${formatPrice(widget.order.total)}',
                      style: const TextStyle(color: Color(0xFF6B7280), fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
