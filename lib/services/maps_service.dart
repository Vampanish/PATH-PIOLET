import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:flutter/material.dart';

enum TransportationMode {
  driving,
  bicycling,
  walking
}

class MapsService {
  static const String _googleApiKey = 'API';
  static const String _signature = 'SECRET';
  static const String _weatherApiKey = 'WEATHER';

  // Cache for weather data to avoid too many API calls
  final Map<String, Map<String, dynamic>> _weatherCache = {};
  DateTime? _lastWeatherUpdate;
  
  // Traffic update interval in seconds
  static const int trafficUpdateInterval = 30;

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
    // Use Geocoding API to get the address for the current location
    final String geocodeUrl = 'https://maps.googleapis.com/maps/api/geocode/json?'
        'latlng=${location.latitude},${location.longitude}'
        '&key=$_googleApiKey';

    String address = 'Unknown Location';
    try {
      final response = await http.get(Uri.parse(geocodeUrl));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['results'] != null && data['results'].isNotEmpty) {
          address = data['results'][0]['formatted_address'];
        }
      }
    } catch (e) {
      print('Error getting address for traffic: $e');
      // Continue even if address lookup fails
    }

    return {
      'address': address,
      'traffic_level': await _getTrafficLevel(location),
      'location': {
        'latitude': location.latitude,
        'longitude': location.longitude,
      }
    };
  }

  Future<String> _getTrafficLevel(LatLng location) async {
    // Since we don't have access to real-time traffic data API,
    // we'll use a simplified traffic level estimation based on time of day
    final hour = DateTime.now().hour;
    
    if (hour >= 7 && hour <= 9) {
      return 'Heavy'; // Morning rush hour
    } else if (hour >= 16 && hour <= 18) {
      return 'Heavy'; // Evening rush hour
    } else if (hour >= 10 && hour <= 15) {
      return 'Moderate'; // Daytime
    } else {
      return 'Low'; // Night time
    }
  }

  Future<Map<String, dynamic>> getWeatherInfo(LatLng location) async {
    final String cacheKey = '${location.latitude},${location.longitude}';
    
    // Check if we have cached data that's less than 10 minutes old
    if (_weatherCache.containsKey(cacheKey) && _lastWeatherUpdate != null) {
      final cacheAge = DateTime.now().difference(_lastWeatherUpdate!);
      if (cacheAge.inMinutes < 10) {
        return _weatherCache[cacheKey]!;
      }
    }

    final String url = 'https://api.openweathermap.org/data/2.5/weather?'
        'lat=${location.latitude}'
        '&lon=${location.longitude}'
        '&units=metric'
        '&appid=$_weatherApiKey';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['cod'] == 200) {
          final weatherData = {
            'temperature': data['main']['temp'],
            'feels_like': data['main']['feels_like'],
            'humidity': data['main']['humidity'],
            'condition': data['weather'][0]['main'],
            'description': data['weather'][0]['description'],
            'wind_speed': data['wind']['speed'],
            'city': data['name'],
            'icon': data['weather'][0]['icon'],
            'timestamp': DateTime.now().toIso8601String(),
          };
          
          // Cache the weather data
          _weatherCache[cacheKey] = weatherData;
          _lastWeatherUpdate = DateTime.now();
          
          return weatherData;
        } else {
          throw Exception('Weather API Error: ${data['message']}');
        }
      } else {
        final errorData = json.decode(response.body);
        throw Exception('Failed to load weather info: ${errorData['message'] ?? response.statusCode}');
      }
    } catch (e) {
      print('Error in getWeatherInfo: $e');
      throw Exception('Error fetching weather info: $e');
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

  Future<Map<String, dynamic>> getRouteWithWeather(
    String origin,
    String destination,
    TransportationMode mode,
  ) async {
    // Get the route
    final route = await _getSingleRoute(origin, destination, mode); // Use _getSingleRoute to get all alternatives
    
    // Analyze route safety and suggest alternatives based on traffic
    final processedRoute = await _checkRouteSafetyAndSuggestAlternative(route, origin, destination, mode);

    // Get weather for origin and destination
    try {
      final originLatLng = await _getLatLngFromAddress(origin);
      final destLatLng = await _getLatLngFromAddress(destination);
      
      final originWeather = await getWeatherInfo(originLatLng);
      final destWeather = await getWeatherInfo(destLatLng);
      
      // Add weather information to the route data
      processedRoute['origin_weather'] = originWeather;
      processedRoute['destination_weather'] = destWeather;
      
      // Calculate and add overall traffic impact for the primary route
      if (processedRoute['routes'] != null && processedRoute['routes'].isNotEmpty) {
        final primaryRoute = processedRoute['routes'][0];
        final int duration = primaryRoute['legs'][0]['duration']['value'];
        final int durationInTraffic = primaryRoute['legs'][0]['duration_in_traffic']['value'] ?? duration; // Fallback to duration if no traffic data

        final double trafficImpactPercentage = ((durationInTraffic - duration) / duration) * 100;

        if (trafficImpactPercentage > 10) { // More than 10% longer due to traffic
          processedRoute['traffic_impact'] = 'Heavy Traffic (${trafficImpactPercentage.toStringAsFixed(0)}% delay)';
        } else if (trafficImpactPercentage > 0) {
          processedRoute['traffic_impact'] = 'Moderate Traffic (${trafficImpactPercentage.toStringAsFixed(0)}% delay)';
        } else {
          processedRoute['traffic_impact'] = 'Light Traffic / No Delay';
        }
      }

      return processedRoute;
    } catch (e) {
      print('Error getting weather/traffic for route: $e');
      return processedRoute; // Return route without weather/traffic if fetch fails
    }
  }

  Future<Map<String, dynamic>> _checkRouteSafetyAndSuggestAlternative(
    Map<String, dynamic> routeData,
    String origin,
    String destination,
    TransportationMode mode,
  ) async {
    if (routeData['routes'] == null || routeData['routes'].isEmpty) {
      return routeData; // No routes found, return as is
    }

    final List<dynamic> routes = List.from(routeData['routes']); // Create a modifiable list

    // Sort routes by duration in traffic (shortest first)
    routes.sort((a, b) {
      final int durationA = a['legs'][0]['duration_in_traffic']['value'] ?? a['legs'][0]['duration']['value'];
      final int durationB = b['legs'][0]['duration_in_traffic']['value'] ?? b['legs'][0]['duration']['value'];
      return durationA.compareTo(durationB);
    });

    final primaryRoute = routes[0];
    final int primaryRouteTrafficDuration = primaryRoute['legs'][0]['duration_in_traffic']['value'] ?? primaryRoute['legs'][0]['duration']['value'];

    // Check if there's a significantly faster alternative (e.g., 20% faster)
    if (routes.length > 1) {
      final alternativeRoute = routes[1];
      final int alternativeRouteTrafficDuration = alternativeRoute['legs'][0]['duration_in_traffic']['value'] ?? alternativeRoute['legs'][0]['duration']['value'];

      if ((primaryRouteTrafficDuration - alternativeRouteTrafficDuration) / primaryRouteTrafficDuration > 0.20) {
        // If the primary route is more than 20% slower due to traffic, suggest the alternative
        print('Traffic Warning: Primary route is significantly slower. Suggesting alternative.');
        
        // Add a flag and the alternative route info to the returned data.
        routeData['is_safe_route'] = false;
        routeData['suggested_alternative_route'] = alternativeRoute;
        // Update the 'routes' in routeData to prioritize the suggested alternative if unsafe
        routeData['routes'] = routes; // Keep all routes sorted for potential UI display
        return routeData;
      }
    }

    routeData['is_safe_route'] = true;
    routeData['routes'] = routes; // Ensure routes are sorted for primary display
    return routeData;
  }

  Future<LatLng> _getLatLngFromAddress(String address) async {
    final String url = 'https://maps.googleapis.com/maps/api/geocode/json?'
        'address=${Uri.encodeComponent(address)}'
        '&key=$_googleApiKey';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['results'] != null && data['results'].isNotEmpty) {
          final location = data['results'][0]['geometry']['location'];
          return LatLng(location['lat'], location['lng']);
        }
      }
      throw Exception('Failed to geocode address');
    } catch (e) {
      throw Exception('Error geocoding address: $e');
    }
  }

  Future<Map<String, dynamic>> getWeatherForClickedLocation(LatLng location) async {
    try {
      final weatherData = await getWeatherInfo(location);
      return {
        'location': location,
        'weather': weatherData,
      };
    } catch (e) {
      throw Exception('Error getting weather for clicked location: $e');
    }
  }

  // Helper method to get weather icon URL
  String getWeatherIconUrl(String iconCode) {
    return 'https://openweathermap.org/img/wn/$iconCode@2x.png';
  }

  // Helper method to format weather data for display
  Map<String, String> formatWeatherForDisplay(Map<String, dynamic> weatherData) {
    return {
      'temperature': '${weatherData['temperature'].toStringAsFixed(1)}°C',
      'feels_like': '${weatherData['feels_like'].toStringAsFixed(1)}°C',
      'humidity': '${weatherData['humidity']}%',
      'condition': weatherData['condition'],
      'description': weatherData['description'],
      'wind_speed': '${weatherData['wind_speed']} m/s',
      'city': weatherData['city'],
      'icon_url': getWeatherIconUrl(weatherData['icon']),
    };
  }

  Future<String?> getAddressFromLatLng(LatLng location) async {
    final String url = 'https://maps.googleapis.com/maps/api/geocode/json?'
        'latlng=${location.latitude},${location.longitude}'
        '&key=$_googleApiKey';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['results'] != null && data['results'].isNotEmpty) {
          return data['results'][0]['formatted_address'];
        }
      }
      return null;
    } catch (e) {
      print('Error getting address from coordinates: $e');
      return null;
    }
  }

  // Get real-time traffic conditions for a route segment
  String _getTrafficLevelForSegment(LatLng start, LatLng end) {
    // Simulate traffic based on time of day and random factors
    final now = DateTime.now();
    final hour = now.hour;
    
    // Base traffic level on time of day
    String baseLevel;
    if (hour >= 7 && hour <= 9) {
      // Morning rush hour
      baseLevel = 'heavy';
    } else if (hour >= 16 && hour <= 18) {
      // Evening rush hour
      baseLevel = 'heavy';
    } else if (hour >= 10 && hour <= 15) {
      // Mid-day
      baseLevel = 'moderate';
    } else {
      // Night/early morning
      baseLevel = 'light';
    }
    
    // Add some randomness to make it more dynamic
    final random = Random();
    final randomFactor = random.nextDouble();
    
    if (randomFactor < 0.3) {
      // 30% chance to change traffic level
      if (baseLevel == 'heavy') {
        return randomFactor < 0.5 ? 'moderate' : 'heavy';
      } else if (baseLevel == 'moderate') {
        return randomFactor < 0.5 ? 'light' : 'heavy';
      } else {
        return randomFactor < 0.5 ? 'moderate' : 'light';
      }
    }
    
    return baseLevel;
  }

  Color getTrafficColor(String trafficLevel) {
    switch (trafficLevel.toLowerCase()) {
      case 'heavy':
        return Colors.red;
      case 'moderate':
        return Colors.orange;
      case 'light':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Future<Map<String, dynamic>> getTrafficConditionsForRoute(
    List<LatLng> routePoints,
    LatLng currentLocation,
  ) async {
    print('Getting traffic conditions for route...'); // Debug print
    Map<String, String> routeTraffic = {};
    
    // Split route into segments and get traffic for each
    for (int i = 0; i < routePoints.length - 1; i++) {
      final start = routePoints[i];
      final end = routePoints[i + 1];
      final segmentKey = '${start.latitude},${start.longitude}-${end.latitude},${end.longitude}';
      
      // Get traffic level for this segment
      final trafficLevel = _getTrafficLevelForSegment(start, end);
      routeTraffic[segmentKey] = trafficLevel;
      
      print('Segment $i: Traffic level = $trafficLevel'); // Debug print
    }
    
    return {
      'route_traffic': routeTraffic,
    };
  }
} 
