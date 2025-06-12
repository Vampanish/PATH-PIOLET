import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';

enum TransportationMode {
  driving,
  bicycling,
  walking
}

class MapsService {
  static const String _googleApiKey = 'API';
  static const String _signature = 'SECRET';

  Future<Map<String, dynamic>> getRoute(
    String origin, 
    String destination, 
    TransportationMode mode
  ) async {
    if (mode == TransportationMode.bicycling) {
      // Get car route and bike time separately
      final carRoute = await _getSingleRoute(origin, destination, TransportationMode.driving);
      final bikeTime = await _getBikeTime(origin, destination);
      
      // Apply bike time to car route
      final routeWithBikeTime = _applyBikeTimeToRoute(carRoute, bikeTime);
      return routeWithBikeTime;
    } else {
      return await _getSingleRoute(origin, destination, mode);
    }
  }

  Future<Map<String, dynamic>> _getSingleRoute(
    String origin,
    String destination,
    TransportationMode mode,
  ) async {
    final String url = 'https://maps.googleapis.com/maps/api/directions/json?'
        'origin=${Uri.encodeComponent(origin)}'
        '&destination=${Uri.encodeComponent(destination)}'
        '&mode=${mode.toString().split('.').last}'
        '&alternatives=true'
        '&departure_time=now'
        '&traffic_model=best_guess'
        '&key=$_googleApiKey';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      throw Exception('Failed to load route: ${response.statusCode}');
    } catch (e) {
      throw Exception('Error fetching route: $e');
    }
  }

  Future<int> _getBikeTime(String origin, String destination) async {
    final String url = 'https://maps.googleapis.com/maps/api/directions/json?'
        'origin=${Uri.encodeComponent(origin)}'
        '&destination=${Uri.encodeComponent(destination)}'
        '&mode=bicycling'
        '&key=$_googleApiKey';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('Bike time API response: $data'); // Debug log
        
        if (data['status'] == 'OK') {
          if (data['routes'] != null && 
              data['routes'].isNotEmpty &&
              data['routes'][0]['legs'] != null &&
              data['routes'][0]['legs'].isNotEmpty) {
            return data['routes'][0]['legs'][0]['duration']['value'];
          }
          // If no valid route found, estimate bike time based on car route
          return await _estimateBikeTime(origin, destination);
        } else {
          print('API returned status: ${data['status']}'); // Debug log
          return await _estimateBikeTime(origin, destination);
        }
      }
      throw Exception('Failed to get bike time: ${response.statusCode}');
    } catch (e) {
      print('Error in _getBikeTime: $e'); // Debug log
      return await _estimateBikeTime(origin, destination);
    }
  }

  Future<int> _estimateBikeTime(String origin, String destination) async {
    try {
      // Get car route to estimate distance
      final carRoute = await _getSingleRoute(origin, destination, TransportationMode.driving);
      if (carRoute['routes'] != null && 
          carRoute['routes'].isNotEmpty &&
          carRoute['routes'][0]['legs'] != null &&
          carRoute['routes'][0]['legs'].isNotEmpty) {
        
        final distance = carRoute['routes'][0]['legs'][0]['distance']['value']; // in meters
        final carDuration = carRoute['routes'][0]['legs'][0]['duration']['value']; // in seconds
        
        // Estimate bike time: average bike speed is about 1/3 of car speed
        // Add 20% extra time for traffic lights and stops
        final estimatedBikeTime = (carDuration * 3 * 1.2).round();
        return estimatedBikeTime;
      }
      // If we can't even get car route, use a very rough estimate
      return 1800; // 30 minutes as fallback
    } catch (e) {
      print('Error in _estimateBikeTime: $e'); // Debug log
      return 1800; // 30 minutes as fallback
    }
  }

  Map<String, dynamic> _applyBikeTimeToRoute(
    Map<String, dynamic> route,
    int bikeTime
  ) {
    final modifiedRoute = Map<String, dynamic>.from(route);
    modifiedRoute['routes'][0]['legs'][0]['duration']['value'] = bikeTime;
    modifiedRoute['routes'][0]['legs'][0]['duration']['text'] = _formatDuration(bikeTime);
    return modifiedRoute;
  }

  String _formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    
    if (hours > 0) {
      return '$hours hr ${minutes > 0 ? '$minutes min' : ''}';
    } else {
      return '$minutes min';
    }
  }

  Future<Map<String, dynamic>> getTrafficConditions(LatLng location) async {
    final String url = 'https://maps.googleapis.com/maps/api/geocode/json?'
        'latlng=${location.latitude},${location.longitude}'
        '&key=$_googleApiKey'
        '&signature=$_signature';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['results'] != null && data['results'].isNotEmpty) {
          final address = data['results'][0]['formatted_address'];
          return {
            'address': address,
            'traffic_level': await _getTrafficLevel(location),
          };
        }
      }
      throw Exception('Failed to load traffic conditions: ${response.statusCode}');
    } catch (e) {
      throw Exception('Error fetching traffic conditions: $e');
    }
  }

  Future<String> _getTrafficLevel(LatLng location) async {
    // This is a simplified version. In a real app, you would use a traffic API
    // For now, we'll return a random traffic level for demonstration
    final levels = ['Low', 'Moderate', 'Heavy'];
    return levels[DateTime.now().millisecondsSinceEpoch % 3];
  }

  Future<Map<String, dynamic>> getWeatherInfo(LatLng location) async {
    final String url = 'https://maps.googleapis.com/maps/api/geocode/json?'
        'latlng=${location.latitude},${location.longitude}'
        '&key=$_googleApiKey'
        '&signature=$_signature';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['results'] != null && data['results'].isNotEmpty) {
          final address = data['results'][0]['formatted_address'];
          return {
            'address': address,
            'temperature': await _getTemperature(location),
            'condition': await _getWeatherCondition(location),
          };
        }
      }
      throw Exception('Failed to load weather info: ${response.statusCode}');
    } catch (e) {
      throw Exception('Error fetching weather info: $e');
    }
  }

  Future<double> _getTemperature(LatLng location) async {
    // This is a simplified version. In a real app, you would use a weather API
    // For now, we'll return a random temperature for demonstration
    return 20.0 + (DateTime.now().millisecondsSinceEpoch % 20);
  }

  Future<String> _getWeatherCondition(LatLng location) async {
    // This is a simplified version. In a real app, you would use a weather API
    // For now, we'll return a random condition for demonstration
    final conditions = ['Sunny', 'Cloudy', 'Rainy'];
    return conditions[DateTime.now().millisecondsSinceEpoch % 3];
  }

  Future<Map<String, dynamic>> searchNearbyPlaces(String placeType, LatLng location) async {
    final String baseUrl = 'https://places.googleapis.com/v1/places:searchNearby';
    final Map<String, dynamic> requestBody = {
      "includedTypes": [placeType],
      "maxResultCount": 10,
      "locationRestriction": {
        "circle": {
          "center": {
            "latitude": location.latitude,
            "longitude": location.longitude,
          },
          "radius": 5000.0,
        }
      }
    };

    try {
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'X-Goog-Api-Key': _googleApiKey,
          'X-Goog-FieldMask': 'places.displayName,places.location,places.primaryType',
        },
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      throw Exception('Failed to load nearby places: ${response.statusCode}');
    } catch (e) {
      throw Exception('Error fetching nearby places: $e');
    }
  }
} 