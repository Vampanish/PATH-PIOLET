import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/offline_route.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'maps_service.dart';

class OfflineRouteService {
  static const String _storageKey = 'offline_routes';
  final _uuid = Uuid();

  Future<List<OfflineRoute>> getOfflineRoutes() async {
    final prefs = await SharedPreferences.getInstance();
    final routesJson = prefs.getStringList(_storageKey) ?? [];
    
    return routesJson
        .map((json) => OfflineRoute.fromJson(jsonDecode(json)))
        .toList();
  }

  Future<void> saveRoute({
    required String name,
    required String sourceAddress,
    required String destinationAddress,
    required List<LatLng> routePoints,
    required String duration,
    required String distance,
    required TransportationMode transportMode,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final routes = await getOfflineRoutes();

    final newRoute = OfflineRoute(
      id: _uuid.v4(),
      name: name,
      sourceAddress: sourceAddress,
      destinationAddress: destinationAddress,
      routePoints: routePoints,
      duration: duration,
      distance: distance,
      downloadDate: DateTime.now(),
      transportMode: transportMode,
    );

    routes.add(newRoute);
    
    final routesJson = routes
        .map((route) => jsonEncode(route.toJson()))
        .toList();

    await prefs.setStringList(_storageKey, routesJson);
  }

  Future<void> deleteRoute(String routeId) async {
    final prefs = await SharedPreferences.getInstance();
    final routes = await getOfflineRoutes();
    
    routes.removeWhere((route) => route.id == routeId);
    
    final routesJson = routes
        .map((route) => jsonEncode(route.toJson()))
        .toList();

    await prefs.setStringList(_storageKey, routesJson);
  }

  Future<OfflineRoute?> getRouteById(String routeId) async {
    final routes = await getOfflineRoutes();
    return routes.firstWhere(
      (route) => route.id == routeId,
      orElse: () => throw Exception('Route not found'),
    );
  }
} 