import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/offline_route.dart';

class OfflineRouteMapScreen extends StatefulWidget {
  final OfflineRoute route;

  const OfflineRouteMapScreen({
    super.key,
    required this.route,
  });

  @override
  State<OfflineRouteMapScreen> createState() => _OfflineRouteMapScreenState();
}

class _OfflineRouteMapScreenState extends State<OfflineRouteMapScreen> {
  GoogleMapController? mapController;
  Set<Polyline> _polylines = {};
  Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _setupRoute();
  }

  void _setupRoute() {
    // Add polyline for the route
    _polylines.add(
      Polyline(
        polylineId: const PolylineId('offline_route'),
        color: Colors.blue,
        width: 5,
        points: widget.route.routePoints,
      ),
    );

    // Add markers for start and end points
    if (widget.route.routePoints.isNotEmpty) {
      final startPoint = widget.route.routePoints.first;
      final endPoint = widget.route.routePoints.last;

      _markers.add(
        Marker(
          markerId: const MarkerId('start'),
          position: startPoint,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          infoWindow: InfoWindow(title: 'Start: ${widget.route.sourceAddress}'),
        ),
      );

      _markers.add(
        Marker(
          markerId: const MarkerId('end'),
          position: endPoint,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: InfoWindow(title: 'End: ${widget.route.destinationAddress}'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.route.name),
      ),
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: (GoogleMapController controller) {
              mapController = controller;
              _fitMapToRoute();
            },
            initialCameraPosition: CameraPosition(
              target: widget.route.routePoints.isNotEmpty
                  ? widget.route.routePoints.first
                  : const LatLng(0, 0),
              zoom: 15,
            ),
            polylines: _polylines,
            markers: _markers,
          ),
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Route Details',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text('Distance: ${widget.route.distance}'),
                    Text('Duration: ${widget.route.duration}'),
                    Text('Transport Mode: ${widget.route.transportMode.toString().split('.').last}'),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _fitMapToRoute() {
    if (mapController != null && widget.route.routePoints.isNotEmpty) {
      final bounds = _boundsFromLatLngList(widget.route.routePoints);
      mapController!.animateCamera(
        CameraUpdate.newLatLngBounds(bounds, 50.0),
      );
    }
  }

  LatLngBounds _boundsFromLatLngList(List<LatLng> list) {
    double x0 = list.first.latitude;
    double x1 = list.first.latitude;
    double y0 = list.first.longitude;
    double y1 = list.first.longitude;

    for (LatLng latLng in list) {
      if (latLng.latitude < x0) x0 = latLng.latitude;
      if (latLng.latitude > x1) x1 = latLng.latitude;
      if (latLng.longitude < y0) y0 = latLng.longitude;
      if (latLng.longitude > y1) y1 = latLng.longitude;
    }
    return LatLngBounds(
      southwest: LatLng(x0, y0),
      northeast: LatLng(x1, y1),
    );
  }
} 