import 'package:location/location.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class LocationService {
  final Location _location = Location();
  LatLng? _currentUserLocation;

  Future<LatLng?> getCurrentLocation() async {
    try {
      bool serviceEnabled = await _location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await _location.requestService();
        if (!serviceEnabled) {
          return null;
        }
      }

      PermissionStatus permission = await _location.hasPermission();
      if (permission == PermissionStatus.denied) {
        permission = await _location.requestPermission();
        if (permission != PermissionStatus.granted) {
          return null;
        }
      }

      final locationData = await _location.getLocation();
      if (locationData.latitude != null && locationData.longitude != null) {
        _currentUserLocation = LatLng(locationData.latitude!, locationData.longitude!);
        return _currentUserLocation;
      }
      return null;
    } catch (e) {
      print('Error getting location: $e');
      return null;
    }
  }

  Stream<LocationData> get locationStream => _location.onLocationChanged;

  LatLng? get currentLocation => _currentUserLocation;
} 