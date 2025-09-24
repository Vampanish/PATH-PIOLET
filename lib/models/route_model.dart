import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class RouteData {
  final String duration;
  final String distance;
  final Color routeColor;
  final List<LatLng> points;

  RouteData({
    required this.duration,
    required this.distance,
    required this.routeColor,
    required this.points,
  });
} 