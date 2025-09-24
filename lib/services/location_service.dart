import 'package:location/location.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';

class LocationService {
  final Location _location = Location();
  LatLng? _currentUserLocation;

  Future<LatLng?> getCurrentLocation() async {
    print('Getting current location...'); // Debug log
    try {
      // First check location permission
      var permissionStatus = await Permission.location.status;
      if (!permissionStatus.isGranted) {
        print('Requesting location permission...'); // Debug log
        permissionStatus = await Permission.location.request();
        if (!permissionStatus.isGranted) {
          print('Location permission denied'); // Debug log
          return null;
        }
      }

      bool serviceEnabled = await _location.serviceEnabled();
      print('Location service enabled: $serviceEnabled'); // Debug log
      
      if (!serviceEnabled) {
        print('Requesting location service...'); // Debug log
        serviceEnabled = await _location.requestService();
        if (!serviceEnabled) {
          print('Location service request denied'); // Debug log
          return null;
        }
      }

      print('Getting location data...'); // Debug log
      final locationData = await _location.getLocation();
      print('Location data received: $locationData'); // Debug log
      
      if (locationData.latitude != null && locationData.longitude != null) {
        _currentUserLocation = LatLng(locationData.latitude!, locationData.longitude!);
        print('Current location set to: $_currentUserLocation'); // Debug log
        return _currentUserLocation;
      }
      print('Location data is null'); // Debug log
      return null;
    } catch (e) {
      print('Error getting location: $e'); // Debug log
      return null;
    }
  }

  Stream<LocationData> get locationStream => _location.onLocationChanged;

  LatLng? get currentLocation => _currentUserLocation;
} 