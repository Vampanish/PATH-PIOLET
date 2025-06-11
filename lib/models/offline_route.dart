import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/material.dart';
import '../services/maps_service.dart';

class OfflineRoute {
  final String id;
  final String name;
  final String sourceAddress;
  final String destinationAddress;
  final List<LatLng> routePoints;
  final String duration;
  final String distance;
  final DateTime downloadDate;
  final TransportationMode transportMode;

  OfflineRoute({
    required this.id,
    required this.name,
    required this.sourceAddress,
    required this.destinationAddress,
    required this.routePoints,
    required this.duration,
    required this.distance,
    required this.downloadDate,
    required this.transportMode,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'sourceAddress': sourceAddress,
      'destinationAddress': destinationAddress,
      'routePoints': routePoints.map((point) => {
        'latitude': point.latitude,
        'longitude': point.longitude,
      }).toList(),
      'duration': duration,
      'distance': distance,
      'downloadDate': downloadDate.toIso8601String(),
      'transportMode': transportMode.toString(),
    };
  }

  factory OfflineRoute.fromJson(Map<String, dynamic> json) {
    return OfflineRoute(
      id: json['id'],
      name: json['name'],
      sourceAddress: json['sourceAddress'],
      destinationAddress: json['destinationAddress'],
      routePoints: (json['routePoints'] as List).map((point) => 
        LatLng(point['latitude'], point['longitude'])).toList(),
      duration: json['duration'],
      distance: json['distance'],
      downloadDate: DateTime.parse(json['downloadDate']),
      transportMode: TransportationMode.values.firstWhere(
        (e) => e.toString() == json['transportMode'],
      ),
    );
  }
} 