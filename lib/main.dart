import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'services/maps_service.dart';
import 'services/location_service.dart';
import 'services/offline_route_service.dart';
import 'widgets/route_info_card.dart';
import 'models/route_model.dart';
import 'screens/offline_routes_screen.dart';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// Global variable to persist route data across hot reloads
class RouteState {
  static LatLng? sourceLocation;
  static String? sourceAddress;
  static String? destinationAddress;
  static Set<Polyline> polylines = {};
  static Set<Marker> markers = {};
  static String? routeDuration;
  static String? routeDistance;
  static List<Map<String, dynamic>> alternativeRoutes = [];
  static int selectedRouteIndex = 0;
  static Color? routeColor;
}

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
  final OfflineRouteService _offlineRouteService = OfflineRouteService();
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
  List<Map<String, dynamic>> _sourceSuggestions = [];
  List<Map<String, dynamic>> _destinationSuggestions = [];
  bool _isSourceFocused = false;
  bool _isDestinationFocused = false;
  final FocusNode _sourceFocusNode = FocusNode();
  final FocusNode _destinationFocusNode = FocusNode();
  OverlayEntry? _overlayEntry;
  final LayerLink _sourceLayerLink = LayerLink();
  final LayerLink _destinationLayerLink = LayerLink();
  TransportationMode _selectedTransportMode = TransportationMode.driving;
  Map<String, dynamic>? _trafficInfo;
  Map<String, dynamic>? _weatherInfo;
  bool _showTrafficInfo = false;
  bool _showWeatherInfo = false;

  @override
  void initState() {
    super.initState();
    _initializeApp();
    _sourceFocusNode.addListener(_handleSourceFocus);
    _destinationFocusNode.addListener(_handleDestinationFocus);
    if (RouteState.sourceLocation != null) {
      _sourceController.text = RouteState.sourceAddress ?? '';
      _destinationController.text = RouteState.destinationAddress ?? '';
      _polylines = RouteState.polylines;
      _markers = RouteState.markers;
      _routeDuration = RouteState.routeDuration;
      _routeDistance = RouteState.routeDistance;
      _alternativeRoutes = RouteState.alternativeRoutes;
      _selectedRouteIndex = RouteState.selectedRouteIndex;
      _routeColor = RouteState.routeColor;
    }
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
    _sourceFocusNode.removeListener(_handleSourceFocus);
    _destinationFocusNode.removeListener(_handleDestinationFocus);
    _sourceFocusNode.dispose();
    _destinationFocusNode.dispose();
    _sourceController.dispose();
    _destinationController.dispose();
    _removeOverlay();
    super.dispose();
  }

  void _handleSourceFocus() {
    _isSourceFocused = _sourceFocusNode.hasFocus;
    if (_isSourceFocused) {
      _getPlaceSuggestions(_sourceController.text, true);
    } else {
      _removeOverlay();
    }
  }

  void _handleDestinationFocus() {
    _isDestinationFocused = _destinationFocusNode.hasFocus;
    if (_isDestinationFocused) {
      _getPlaceSuggestions(_destinationController.text, false);
    } else {
      _removeOverlay();
    }
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  Future<void> _getPlaceSuggestions(String input, bool isSource) async {
    if (input.isEmpty) {
      setState(() {
        if (isSource) {
          _sourceSuggestions = [];
        } else {
          _destinationSuggestions = [];
        }
      });
      _removeOverlay();
      return;
    }

    final String apiKey = 'API_KEY';
    final String signature = 'SIGNATURE';
    final String url = 'https://maps.googleapis.com/maps/api/place/autocomplete/json'
        '?input=${Uri.encodeComponent(input)}'
        '&key=$apiKey'
        '&signature=$signature';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['predictions'] != null) {
          setState(() {
            if (isSource) {
              _sourceSuggestions = List<Map<String, dynamic>>.from(data['predictions']);
            } else {
              _destinationSuggestions = List<Map<String, dynamic>>.from(data['predictions']);
            }
          });
          _showSuggestionsOverlay(isSource);
        }
      }
    } catch (e) {
      print('Error fetching place suggestions: $e');
    }
  }

  void _showSuggestionsOverlay(bool isSource) {
    _removeOverlay();
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: size.width - 32,
        child: CompositedTransformFollower(
          link: isSource ? _sourceLayerLink : _destinationLayerLink,
          showWhenUnlinked: false,
          offset: Offset(0, 50),
          child: Material(
            elevation: 4,
            child: Container(
              color: Colors.white,
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: isSource ? _sourceSuggestions.length : _destinationSuggestions.length,
                itemBuilder: (context, index) {
                  final suggestion = isSource ? _sourceSuggestions[index] : _destinationSuggestions[index];
                  return ListTile(
                    title: Text(suggestion['description']),
                    onTap: () {
                      if (isSource) {
                        _sourceController.text = suggestion['description'];
                        _sourceFocusNode.unfocus();
                      } else {
                        _destinationController.text = suggestion['description'];
                        _destinationFocusNode.unfocus();
                      }
                      _removeOverlay();
                    },
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  Color _getRouteColor(int index) {
    if (_alternativeRoutes.isEmpty) return Colors.cyanAccent[700]!;
    
    List<double> distances = _alternativeRoutes.map((route) {
      if (route['legs'] != null && route['legs'].isNotEmpty) {
        String distance = route['legs'][0]['distance']['text'];
        double meters = 0;
        try {
          if (distance.contains('km')) {
            String kmStr = distance.split('km')[0].trim();
            meters = double.parse(kmStr) * 1000;
          } else if (distance.contains('m')) {
            String mStr = distance.split('m')[0].trim();
            meters = double.parse(mStr);
          }
        } catch (e) {
          print('Error parsing distance: $e');
          return 0.0;
        }
        return meters;
      }
      return 0.0;
    }).toList();

    double minDistance = distances.reduce((a, b) => a < b ? a : b);
    double maxDistance = distances.reduce((a, b) => a > b ? a : b);
    double currentDistance = distances[index];

    if (currentDistance == minDistance) return Colors.green;
    if (currentDistance == maxDistance) return Colors.red;
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
    
    setState(() {
      _clearMap();
      _trafficInfo = null;
      _weatherInfo = null;
    });
    
    try {
      final data = await _mapsService.getRoute(
        _sourceController.text,
        _destinationController.text,
        _selectedTransportMode,
      );

      if (data['routes'] != null && data['routes'].isNotEmpty) {
        print("Route data received. Processing ${data['routes'].length} routes.");
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
    
    // Clear global state
    RouteState.sourceLocation = null;
    RouteState.sourceAddress = null;
    RouteState.destinationAddress = null;
    RouteState.polylines.clear();
    RouteState.markers.clear();
    RouteState.routeDuration = null;
    RouteState.routeDistance = null;
    RouteState.alternativeRoutes.clear();
    RouteState.selectedRouteIndex = 0;
    RouteState.routeColor = null;
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

    // Update global state
    RouteState.polylines = _polylines;
    RouteState.markers = _markers;
    RouteState.routeDuration = _routeDuration;
    RouteState.routeDistance = _routeDistance;
    RouteState.alternativeRoutes = _alternativeRoutes;
    RouteState.selectedRouteIndex = _selectedRouteIndex;
    RouteState.routeColor = _routeColor;
    RouteState.sourceAddress = _sourceController.text;
    RouteState.destinationAddress = _destinationController.text;

    print("Setting state after processing routes. Markers count: ${_markers.length}, Polylines count: ${_polylines.length}");
    _fitMapToRoutes();
  }

  void _processFirstRoute(Map<String, dynamic> route, List<PointLatLng> pointCoords) {
    if (route['legs'] != null && route['legs'].isNotEmpty) {
      try {
        final leg = route['legs'][0];
        _routeDuration = leg['duration']['text'];
        _routeDistance = leg['distance']['text'];
        _routeColor = _getRouteColor(0);
      } catch (e) {
        print('Error processing route leg: $e');
        _routeDuration = 'Unknown';
        _routeDistance = 'Unknown';
        _routeColor = Colors.grey;
      }
    }

    if (pointCoords.isNotEmpty) {
      try {
        final LatLng startLatLng = LatLng(pointCoords.first.latitude, pointCoords.first.longitude);
        final LatLng endLatLng = LatLng(pointCoords.last.latitude, pointCoords.last.longitude);

        // Store source location in global state
        RouteState.sourceLocation = startLatLng;

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
      } catch (e) {
        print('Error processing route points: $e');
      }
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
            CameraUpdate.newLatLngZoom(firstRoutePolyline.points.first, 15),
          );
          return;
        }
      }
      
      final selectedPolyline = _polylines.firstWhere(
        (p) => p.polylineId.value == 'route_$_selectedRouteIndex',
        orElse: () => _polylines.first,
      );
      
      if (selectedPolyline.points.isNotEmpty) {
        mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(selectedPolyline.points.first, 15),
        );
      }
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

  Future<void> _updateTrafficAndWeatherInfo(LatLng location) async {
    try {
      final trafficData = await _mapsService.getTrafficConditions(location);
      final weatherData = await _mapsService.getWeatherInfo(location);
      
      setState(() {
        _trafficInfo = trafficData;
        _weatherInfo = weatherData;
      });
    } catch (e) {
      print('Error updating traffic and weather info: $e');
    }
  }

  Future<void> _downloadRouteForOffline() async {
    if (_sourceController.text.isEmpty || _destinationController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter source and destination')),
      );
      return;
    }

    try {
      final routeName = await _showRouteNameDialog();
      if (routeName == null) return;

      final data = await _mapsService.getRoute(
        _sourceController.text,
        _destinationController.text,
        _selectedTransportMode,
      );

      if (data['routes'] != null && data['routes'].isNotEmpty) {
        final route = data['routes'][0];
        final polyline = route['overview_polyline']['points'];
        final polylinePoints = PolylinePoints();
        final pointCoords = polylinePoints.decodePolyline(polyline);
        
        final routePoints = pointCoords
            .map((point) => LatLng(point.latitude, point.longitude))
            .toList();

        final leg = route['legs'][0];
        final duration = leg['duration']['text'];
        final distance = leg['distance']['text'];

        await _offlineRouteService.saveRoute(
          name: routeName,
          sourceAddress: _sourceController.text,
          destinationAddress: _destinationController.text,
          routePoints: routePoints,
          duration: duration,
          distance: distance,
          transportMode: _selectedTransportMode,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Route downloaded successfully')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error downloading route: $e')),
        );
      }
    }
  }

  Future<String?> _showRouteNameDialog() async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Save Route'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Route Name',
            hintText: 'Enter a name for this route',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                Navigator.pop(context, controller.text);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
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
                    child: Column(
                      children: [
                        RouteInfoCard(
                          duration: _routeDuration!,
                          distance: _routeDistance!,
                          routeColor: _routeColor,
                          alternativeRoutesCount: _alternativeRoutes.length,
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          onPressed: _downloadRouteForOffline,
                          icon: const Icon(Icons.download),
                          label: const Text('Download for Offline'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                _buildAppTitle(),
                _buildInfoButtons(),
                _buildTrafficAndWeatherInfo(),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.explore), label: 'Explore'),
          BottomNavigationBarItem(icon: Icon(Icons.download), label: 'Offline'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'You'),
        ],
        onTap: (index) {
          if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const OfflineRoutesScreen(),
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          CompositedTransformTarget(
            link: _sourceLayerLink,
            child: TextField(
              controller: _sourceController,
              focusNode: _sourceFocusNode,
              decoration: _buildTextFieldDecoration('Enter Source'),
              onChanged: (value) => _getPlaceSuggestions(value, true),
            ),
          ),
          SizedBox(height: 10),
          CompositedTransformTarget(
            link: _destinationLayerLink,
            child: TextField(
              controller: _destinationController,
              focusNode: _destinationFocusNode,
              decoration: _buildTextFieldDecoration('Enter Destination'),
              onChanged: (value) => _getPlaceSuggestions(value, false),
            ),
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
          SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildTransportModeButton(
                Icons.directions_car,
                'Car',
                TransportationMode.driving,
              ),
              SizedBox(width: 8),
              _buildTransportModeButton(
                Icons.directions_bike,
                'Bike',
                TransportationMode.bicycling,
              ),
              SizedBox(width: 8),
              _buildTransportModeButton(
                Icons.directions_walk,
                'Walk',
                TransportationMode.walking,
              ),
            ],
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
        if (RouteState.sourceLocation != null) {
          // If we have a stored source location, move to it
          controller.animateCamera(
            CameraUpdate.newLatLngZoom(RouteState.sourceLocation!, 15),
          );
        } else if (_locationService.currentLocation != null) {
          // Otherwise use current location
          controller.animateCamera(
            CameraUpdate.newLatLng(_locationService.currentLocation!),
          );
        }
      },
      initialCameraPosition: CameraPosition(
        target: RouteState.sourceLocation ?? _locationService.currentLocation ?? const LatLng(11.6643, 78.1460),
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

  Widget _buildInfoButtons() {
    return Positioned(
      top: 70,
      left: 16,
      child: Row(
        children: [
          _buildInfoButton(
            'Traffic',
            Icons.traffic,
            _showTrafficInfo,
            () {
              setState(() {
                _showTrafficInfo = !_showTrafficInfo;
                if (_showTrafficInfo && _locationService.currentLocation != null) {
                  _updateTrafficAndWeatherInfo(_locationService.currentLocation!);
                }
              });
            },
          ),
          SizedBox(width: 8),
          _buildInfoButton(
            'Weather',
            Icons.wb_sunny,
            _showWeatherInfo,
            () {
              setState(() {
                _showWeatherInfo = !_showWeatherInfo;
                if (_showWeatherInfo && _locationService.currentLocation != null) {
                  _updateTrafficAndWeatherInfo(_locationService.currentLocation!);
                }
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInfoButton(String label, IconData icon, bool isSelected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.cyanAccent[100] : Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.cyanAccent[700] : Colors.grey[600],
              size: 20,
            ),
            SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.cyanAccent[700] : Colors.grey[600],
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrafficAndWeatherInfo() {
    if (!_showTrafficInfo && !_showWeatherInfo) return SizedBox.shrink();

    return Positioned(
      top: 130,
      left: 16,
      right: 16,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_showTrafficInfo && _trafficInfo != null) ...[
                Row(
                  children: [
                    Icon(Icons.traffic, color: Colors.orange),
                    SizedBox(width: 8),
                    Text(
                      'Traffic Conditions',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  'Location: ${_trafficInfo!['address']}',
                  style: TextStyle(fontSize: 14),
                ),
                Text(
                  'Traffic Level: ${_trafficInfo!['traffic_level']}',
                  style: TextStyle(fontSize: 14),
                ),
                SizedBox(height: 16),
              ],
              if (_showWeatherInfo && _weatherInfo != null) ...[
                Row(
                  children: [
                    Icon(Icons.wb_sunny, color: Colors.amber),
                    SizedBox(width: 8),
                    Text(
                      'Weather Information',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  'Location: ${_weatherInfo!['address']}',
                  style: TextStyle(fontSize: 14),
                ),
                Text(
                  'Temperature: ${_weatherInfo!['temperature'].toStringAsFixed(1)}°C',
                  style: TextStyle(fontSize: 14),
                ),
                Text(
                  'Condition: ${_weatherInfo!['condition']}',
                  style: TextStyle(fontSize: 14),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTransportModeButton(IconData icon, String label, TransportationMode mode) {
    final bool isSelected = _selectedTransportMode == mode;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedTransportMode = mode;
        });
        _getRoute();
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.cyanAccent[100] : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Colors.cyanAccent[700]! : Colors.grey[300]!,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.cyanAccent[700] : Colors.grey[600],
              size: 20,
            ),
            SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.cyanAccent[700] : Colors.grey[600],
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
