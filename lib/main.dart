import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'services/maps_service.dart';
import 'services/location_service.dart';
import 'widgets/route_info_card.dart';
import 'models/route_model.dart';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Maps App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MapsHomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MapsHomePage extends StatefulWidget {
  const MapsHomePage({super.key});

  @override
  State<MapsHomePage> createState() => _MapsHomePageState();
}

class _MapsHomePageState extends State<MapsHomePage> {
  final MapsService _mapsService = MapsService();
  final LocationService _locationService = LocationService();
  GoogleMapController? mapController;
  
  final TextEditingController _sourceController = TextEditingController();
  final TextEditingController _destinationController = TextEditingController();
  Set<Polyline> _polylines = {};
  Set<Marker> _markers = {};
  Set<Marker> _nearbyPlacesMarkers = {};
  String? _routeDuration;
  String? _routeDistance;
  List<Map<String, dynamic>> _alternativeRoutes = [];
  int _selectedRouteIndex = 0;
  Color? _routeColor;
  BitmapDescriptor? _customMarkerIcon;
  bool _isMapReady = false;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    print("Initializing app...");
    await _loadCustomMarker();
    await _locationService.getCurrentLocation();
    if (mounted) {
      setState(() {
        _isMapReady = true;
        print("App initialized and map ready.");
      });
    }
  }

  Future<void> _loadCustomMarker() async {
    print("Loading custom marker...");
    try {
      final ByteData byteData = await rootBundle.load('assets/images/custom_marker.png');
      final ui.Codec codec = await ui.instantiateImageCodec(byteData.buffer.asUint8List(), targetWidth: 100);
      final ui.FrameInfo frameInfo = await codec.getNextFrame();
      final ByteData? resizedByteData = await frameInfo.image.toByteData(format: ui.ImageByteFormat.png);
      if (resizedByteData != null) {
        _customMarkerIcon = BitmapDescriptor.fromBytes(resizedByteData.buffer.asUint8List());
        print("Custom marker loaded successfully.");
      } else {
        print("Failed to resize custom marker image. Using default.");
        _customMarkerIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
      }
    } catch (e) {
      print("Error loading custom marker: $e. Using default.");
      _customMarkerIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
    }
  }

  @override
  void dispose() {
    _sourceController.dispose();
    _destinationController.dispose();
    super.dispose();
  }

  Color _getRouteColor(int index) {
    if (_alternativeRoutes.isEmpty) return Colors.cyanAccent[700]!;
    
    List<int> durations = _alternativeRoutes.map((route) {
      if (route['legs'] != null && route['legs'].isNotEmpty) {
        String duration = route['legs'][0]['duration']['text'];
        int minutes = 0;
        if (duration.contains('hour')) {
          minutes += int.parse(duration.split('hour')[0].trim()) * 60;
          if (duration.contains('min')) {
            minutes += int.parse(duration.split('hour')[1].split('min')[0].trim());
          }
        } else if (duration.contains('min')) {
          minutes = int.parse(duration.split('min')[0].trim());
        }
        return minutes;
      }
      return 0;
    }).toList();

    int minDuration = durations.reduce((a, b) => a < b ? a : b);
    int maxDuration = durations.reduce((a, b) => a > b ? a : b);
    int currentDuration = durations[index];

    if (currentDuration == minDuration) return Colors.green;
    if (currentDuration == maxDuration) return Colors.red;
    return Colors.orange;
  }

  Future<void> _getRoute() async {
    if (!_isMapReady) {
      print("Map is not yet ready. Please wait for initialization to complete.");
      return;
    }
    if (_sourceController.text.isEmpty || _destinationController.text.isEmpty) {
      print("Source or Destination is empty.");
      return;
    }

    print("Attempting to get route from: ${_sourceController.text} to: ${_destinationController.text}");
    
    // Clear the map first
    setState(() {
      _clearMap();
    });
    
    try {
      final data = await _mapsService.getRoute(
        _sourceController.text,
        _destinationController.text,
      );

      if (data['routes'] != null && data['routes'].isNotEmpty) {
        print("Route data received. Processing ${data['routes'].length} routes.");
        // Process routes and update state immediately
        setState(() {
          _processRoutes(data['routes']);
        });
      } else if (data['status'] == 'ZERO_RESULTS') {
        print("No route found for the given locations.");
      } else {
        print("Google Directions API Error: ${data['error_message'] ?? 'Unknown error'}");
      }
    } catch (e) {
      print('Error fetching route: $e');
    }
  }

  void _clearMap() {
    print("Clearing map components.");
    _polylines.clear();
    _markers.clear();
    _nearbyPlacesMarkers.clear();
    _routeDuration = null;
    _routeDistance = null;
    _alternativeRoutes.clear();
    _selectedRouteIndex = 0;
    _routeColor = null;
  }

  void _processRoutes(List<dynamic> routes) {
    _alternativeRoutes = List<Map<String, dynamic>>.from(routes);
    
    for (int i = 0; i < routes.length; i++) {
      final route = routes[i];
      final polyline = route['overview_polyline']['points'];
      final polylinePoints = PolylinePoints();
      final pointCoords = polylinePoints.decodePolyline(polyline);

      _polylines.add(
        Polyline(
          polylineId: PolylineId('route_$i'),
          color: i == 0 ? Colors.blue : Colors.lightBlue.withOpacity(0.7),
          width: i == 0 ? 5 : 4,
          points: pointCoords.map((point) => LatLng(point.latitude, point.longitude)).toList(),
          onTap: () => _selectRoute(i),
          consumeTapEvents: true,
        ),
      );

      if (i == 0) {
        print("Processing first route and adding markers.");
        _processFirstRoute(route, pointCoords);
      }
    }

    print("Setting state after processing routes. Markers count: ${_markers.length}, Polylines count: ${_polylines.length}");
    _fitMapToRoutes();
  }

  void _processFirstRoute(Map<String, dynamic> route, List<PointLatLng> pointCoords) {
    if (route['legs'] != null && route['legs'].isNotEmpty) {
      final leg = route['legs'][0];
      _routeDuration = leg['duration']['text'];
      _routeDistance = leg['distance']['text'];
      _routeColor = _getRouteColor(0);
    }

    if (pointCoords.isNotEmpty) {
      final LatLng startLatLng = LatLng(pointCoords.first.latitude, pointCoords.first.longitude);
      final LatLng endLatLng = LatLng(pointCoords.last.latitude, pointCoords.last.longitude);

      _markers.add(
        Marker(
          markerId: const MarkerId('start_point'),
          position: startLatLng,
          icon: _customMarkerIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          infoWindow: InfoWindow(title: 'Start: ${_sourceController.text}'),
        ),
      );
      print("Added start marker at: $startLatLng");

      _markers.add(
        Marker(
          markerId: const MarkerId('end_point'),
          position: endLatLng,
          icon: _customMarkerIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: InfoWindow(title: 'End: ${_destinationController.text}'),
        ),
      );
      print("Added end marker at: $endLatLng");
    }
  }

  void _fitMapToRoutes() {
    if (mapController != null && _polylines.isNotEmpty) {
      if (_selectedRouteIndex == 0 && _polylines.isNotEmpty) {
        final firstRoutePolyline = _polylines.firstWhere(
          (p) => p.polylineId.value == 'route_0',
          orElse: () => _polylines.first,
        );
        if (firstRoutePolyline.points.isNotEmpty) {
          mapController!.animateCamera(
            CameraUpdate.newLatLng(firstRoutePolyline.points.first),
          );
          return;
        }
      }
      
      final allPoints = _polylines.expand((polyline) => polyline.points).toList();
      final bounds = _boundsFromLatLngList(allPoints);
      mapController!.animateCamera(
        CameraUpdate.newLatLngBounds(bounds, 50.0),
      );
    }
  }

  void _selectRoute(int index) {
    if (index >= 0 && index < _alternativeRoutes.length) {
      setState(() {
        _selectedRouteIndex = index;
        final route = _alternativeRoutes[index];
        
        if (route['legs'] != null && route['legs'].isNotEmpty) {
          final leg = route['legs'][0];
          _routeDuration = leg['duration']['text'];
          _routeDistance = leg['distance']['text'];
          _routeColor = _getRouteColor(index);
        }

        _updatePolylines(index);
        _fitSelectedRoute(index);
      });
    }
  }

  void _updatePolylines(int selectedIndex) {
    _polylines = _polylines.map((polyline) {
      final polylineId = polyline.polylineId.value;
      final routeIndex = int.parse(polylineId.split('_')[1]);
      
      return Polyline(
        polylineId: polyline.polylineId,
        points: polyline.points,
        color: routeIndex == selectedIndex ? Colors.blue : Colors.lightBlue.withOpacity(0.7),
        width: routeIndex == selectedIndex ? 5 : 4,
        onTap: () => _selectRoute(routeIndex),
        consumeTapEvents: true,
      );
    }).toSet();
  }

  void _fitSelectedRoute(int index) {
    if (mapController != null) {
      final selectedPolyline = _polylines.firstWhere(
        (p) => p.polylineId.value == 'route_$index',
        orElse: () => _polylines.first,
      );
      
      if (selectedPolyline.points.isNotEmpty) {
        final bounds = _boundsFromLatLngList(selectedPolyline.points);
        mapController!.animateCamera(
          CameraUpdate.newLatLngBounds(bounds, 50.0),
        );
      }
    }
  }

  LatLngBounds _boundsFromLatLngList(List<LatLng> list) {
    if (list.isEmpty) return LatLngBounds(southwest: LatLng(0, 0), northeast: LatLng(0, 0));

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
    return LatLngBounds(southwest: LatLng(x0, y0), northeast: LatLng(x1, y1));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: Stack(
              children: [
                _isMapReady
                    ? _buildMap()
                    : const Center(child: CircularProgressIndicator()),
                if (_routeDuration != null && _routeDistance != null)
                  Positioned(
                    bottom: 16,
                    left: 16,
                    right: 16,
                    child: RouteInfoCard(
                      duration: _routeDuration!,
                      distance: _routeDistance!,
                      routeColor: _routeColor,
                      alternativeRoutesCount: _alternativeRoutes.length,
                    ),
                  ),
                _buildAppTitle(),
                _buildCategoryChips(),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.explore), label: 'Explore'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'You'),
          BottomNavigationBarItem(icon: Icon(Icons.add), label: 'Contribute'),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          TextField(
            controller: _sourceController,
            decoration: _buildTextFieldDecoration('Enter Source'),
          ),
          SizedBox(height: 10),
          TextField(
            controller: _destinationController,
            decoration: _buildTextFieldDecoration('Enter Destination'),
          ),
          SizedBox(height: 10),
          ElevatedButton(
            onPressed: _isMapReady ? _getRoute : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.cyanAccent[400],
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
            ),
            child: const Text('Show Route'),
          ),
        ],
      ),
    );
  }

  InputDecoration _buildTextFieldDecoration(String hintText) {
    return InputDecoration(
      hintText: hintText,
      prefixIcon: Icon(Icons.location_on, color: Colors.cyanAccent[400]),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: BorderSide(color: Colors.cyanAccent[400]!, width: 2.0),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: BorderSide(color: Colors.cyanAccent[700]!, width: 2.0),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: BorderSide(color: Colors.cyanAccent[400]!, width: 1.0),
      ),
    );
  }

  Widget _buildMap() {
    return GoogleMap(
      onMapCreated: (GoogleMapController controller) {
        mapController = controller;
        if (_locationService.currentLocation != null) {
          controller.animateCamera(
            CameraUpdate.newLatLng(_locationService.currentLocation!),
          );
        }
      },
      initialCameraPosition: CameraPosition(
        target: _locationService.currentLocation ?? const LatLng(11.6643, 78.1460),
        zoom: 16,
      ),
      myLocationEnabled: true,
      myLocationButtonEnabled: true,
      mapType: MapType.normal,
      zoomControlsEnabled: true,
      compassEnabled: true,
      polylines: _polylines,
      markers: _markers.union(_nearbyPlacesMarkers),
      onTap: (_) {},
    );
  }

  Widget _buildAppTitle() {
    return Positioned(
      top: 16,
      left: 16,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          'PathPilot',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.cyanAccent[700],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryChips() {
    return Positioned(
      top: 10,
      left: 16,
      right: 16,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildChip('Restaurants', Icons.restaurant),
            _buildChip('Hotels', Icons.hotel),
            _buildChip('Petrol', Icons.local_gas_station),
            _buildChip('Cafes', Icons.local_cafe),
            _buildChip('Groceries', Icons.local_grocery_store),
          ],
        ),
      ),
    );
  }

  Widget _buildChip(String label, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: GestureDetector(
        onTap: () => _searchNearbyPlaces(label),
        child: Chip(
          avatar: Icon(icon, size: 18, color: Colors.cyanAccent[700]),
          label: Text(label, style: TextStyle(color: Colors.cyanAccent[700])),
          backgroundColor: Colors.cyanAccent[100]?.withOpacity(0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
            side: BorderSide(color: Colors.cyanAccent[400]!, width: 1.0),
          ),
        ),
      ),
    );
  }

  Future<void> _searchNearbyPlaces(String label) async {
    if (_locationService.currentLocation == null) return;

    String placeType = '';
    switch (label) {
      case 'Restaurants': placeType = 'restaurant'; break;
      case 'Hotels': placeType = 'hotel'; break;
      case 'Petrol': placeType = 'gas_station'; break;
      case 'Cafes': placeType = 'cafe'; break;
      case 'Groceries': placeType = 'supermarket'; break;
    }

    if (placeType.isEmpty) return;

    _clearMap();
    
    try {
      final data = await _mapsService.searchNearbyPlaces(
        placeType,
        _locationService.currentLocation!,
      );

      if (data['places'] != null && data['places'].isNotEmpty) {
        _processNearbyPlaces(data['places']);
      }
    } catch (e) {
      print('Error searching nearby places: $e');
    }
  }

  void _processNearbyPlaces(List<dynamic> places) {
    List<Marker> newMarkers = [];
    for (var place in places) {
      final String name = place['displayName']['text'] ?? 'Unknown Place';
      final double lat = place['location']['latitude'];
      final double lng = place['location']['longitude'];

      newMarkers.add(
        Marker(
          markerId: MarkerId(place['id']),
          position: LatLng(lat, lng),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
          infoWindow: InfoWindow(title: name),
        ),
      );
    }

    setState(() {
      _nearbyPlacesMarkers.addAll(newMarkers);
    });

    if (mapController != null) {
      mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(_locationService.currentLocation!, 14),
      );
    }
  }
}
