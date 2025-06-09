import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'api_keys.dart';

class MapsService {
  static const String _googleApiKey = ApiKeys.googleMapsApiKey;

  Future<Map<String, dynamic>> getRoute(String origin, String destination) async {
    final String url = 'https://maps.googleapis.com/maps/api/directions/json?'
        'origin=${Uri.encodeComponent(origin)}&destination=${Uri.encodeComponent(destination)}'
        '&alternatives=true&key=$_googleApiKey';

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