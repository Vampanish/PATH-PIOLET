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
import 'dart:async';
import 'gnn_page.dart';
import 'turn_by_turn_page.dart';

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
      title: 'PathPilot',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      initialRoute: '/map',
      routes: {
        '/map': (context) => const MapsHomePage(),
        '/profile': (context) => const ProfilePage(),
        '/reward': (context) => const RewardPage(),
      },
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
  Map<String, dynamic>? _destinationWeather;
  LatLng? _lastClickedLocation;
  Map<String, dynamic>? _clickedLocationWeather;
  bool _showCurrentLocationTrafficInfo = false;
  bool _showCurrentLocationWeatherInfo = false;
  bool _showClickedLocationWeather = false;
  String? _routeTrafficImpact;
  bool _showRouteSummaryCard = false;
  Timer? _trafficUpdateTimer;
  Map<String, String> _routeTrafficLevels = {};
  LatLng? _currentLocation;

  @override
  void initState() {
    super.initState();
    _sourceFocusNode.addListener(_onSourceFocusChanged);
    _destinationFocusNode.addListener(_onDestinationFocusChanged);
    _initLocationAndMap();
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
    _initializeLocation();
  }

  Future<void> _initLocationAndMap() async {
    await _locationService.getCurrentLocation();
    setState(() {
      _isMapReady = true;
    });
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
    _sourceFocusNode.removeListener(_onSourceFocusChanged);
    _destinationFocusNode.removeListener(_onDestinationFocusChanged);
    _sourceFocusNode.dispose();
    _destinationFocusNode.dispose();
    _sourceController.dispose();
    _destinationController.dispose();
    _removeOverlay();
    _trafficUpdateTimer?.cancel();
    super.dispose();
  }

  void _onSourceFocusChanged() {
    _isSourceFocused = _sourceFocusNode.hasFocus;
    if (_isSourceFocused) {
      _getPlaceSuggestions(_sourceController.text, true);
    } else {
      _removeOverlay();
    }
  }

  void _onDestinationFocusChanged() {
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

    final String apiKey = 'API';
    final String signature = 'SECRET';
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
      return;
    }
    if (_sourceController.text.isEmpty || _destinationController.text.isEmpty) {
      return;
    }
    
    setState(() {
      _clearMap();
      _trafficInfo = null;
      _weatherInfo = null;
      _destinationWeather = null;
      _routeTrafficImpact = null;
      _showRouteSummaryCard = false;
      _stopTrafficUpdates();
    });
    
    try {
      final data = await _mapsService.getRouteWithWeather(
        _sourceController.text,
        _destinationController.text,
        _selectedTransportMode,
      );

      if (data != null && data['routes'] != null && data['routes'].isNotEmpty) {
        setState(() {
          _processRoutes(data['routes']);
          if (data['destination_weather'] != null) {
            _destinationWeather = data['destination_weather'];
          }
          if (data['traffic_impact'] != null) {
            _routeTrafficImpact = data['traffic_impact'];
          }
          _showRouteSummaryCard = true;
        });
        
        // Start traffic updates for the new route
        print('Starting traffic updates after route selection...'); // Debug print
        _startTrafficUpdates();
      } else if (data['status'] == 'ZERO_RESULTS') {
        print("No route found for the given locations.");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('No route found for ${_selectedTransportMode.toString().split('.').last} mode'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
        }
      } else {
        print("Google Directions API Error: ${data['error_message'] ?? 'Unknown error'}");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error finding route: ${data['error_message'] ?? 'Unknown error'}'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to find route'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error finding route: $e'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
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
    _routeTrafficLevels.clear();
    _stopTrafficUpdates();
    
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
    print('Attempting to update traffic and weather info for: $location'); // Debug: Function call
    try {
      final trafficData = await _mapsService.getTrafficConditions(location);
      final weatherData = await _mapsService.getWeatherInfo(location);
      
      print('Received traffic data: $trafficData'); // Debug: API response
      print('Received weather data: $weatherData'); // Debug: API response
      
      setState(() {
        _trafficInfo = trafficData;
        _weatherInfo = weatherData;
        print('_trafficInfo updated to: $_trafficInfo'); // Debug: State update
        print('_weatherInfo updated to: $_weatherInfo'); // Debug: State update
      });
    } catch (e) {
      print('Error updating traffic and weather info: $e'); // Debug: Error catching
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
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.deepPurple,
              ),
              child: Text('Menu', style: TextStyle(color: Colors.white, fontSize: 24)),
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Profile'),
              onTap: () {
                Navigator.of(context).pushNamed('/profile');
              },
            ),
            ListTile(
              leading: const Icon(Icons.card_giftcard),
              title: const Text('Reward'),
              onTap: () {
                Navigator.of(context).pushNamed('/reward');
              },
            ),
          ],
        ),
      ),
      appBar: AppBar(
        title: const Text('PathPilot'),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.cyanAccent[400]!.withOpacity(0.5),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: CompositedTransformTarget(
                            link: _sourceLayerLink,
                            child: TextField(
                              controller: _sourceController,
                              focusNode: _sourceFocusNode,
                              decoration: _buildTextFieldDecoration('Enter Source', _sourceController),
                              onChanged: (value) {
                                setState(() {});
                                _getPlaceSuggestions(value, true);
                              },
                              style: TextStyle(fontSize: 13.0, color: Colors.black87),
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.cyanAccent[400]!.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.cyanAccent[400]!.withOpacity(0.5),
                              width: 1,
                            ),
                          ),
                          child: IconButton(
                            onPressed: () async {
                              try {
                                final location = await _locationService.getCurrentLocation();
                                if (location != null) {
                                  final address = await _mapsService.getAddressFromLatLng(location);
                                  if (address != null) {
                                    setState(() {
                                      _sourceController.text = address;
                                      _currentLocation = location;
                                    });
                                    if (mapController != null) {
                                      mapController!.animateCamera(
                                        CameraUpdate.newLatLngZoom(location, 15),
                                      );
                                    }
                                  }
                                }
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Error getting current location: $e'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            },
                            icon: Icon(Icons.my_location, color: Colors.cyanAccent[700], size: 20),
                            tooltip: 'Use current location',
                            padding: EdgeInsets.all(8),
                            constraints: BoxConstraints(),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    CompositedTransformTarget(
                      link: _destinationLayerLink,
                      child: TextField(
                        controller: _destinationController,
                        focusNode: _destinationFocusNode,
                        decoration: _buildTextFieldDecoration('Enter Destination', _destinationController),
                        onChanged: (value) {
                          setState(() {});
                          _getPlaceSuggestions(value, false);
                        },
                        style: TextStyle(fontSize: 13.0, color: Colors.black87),
                      ),
                    ),
                    SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isMapReady ? _getRoute : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.cyanAccent[400]!.withOpacity(0.3),
                              foregroundColor: Colors.cyanAccent[700],
                              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              textStyle: TextStyle(fontSize: 14.0),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.0),
                                side: BorderSide(
                                  color: Colors.cyanAccent[400]!.withOpacity(0.5),
                                  width: 1.0,
                                ),
                              ),
                              elevation: 0,
                            ),
                            child: const Text('Show Route'),
                          ),
                        ),
                        SizedBox(width: 8),
                        _buildTransportModeButton(
                          Icons.directions_car,
                          'Car',
                          TransportationMode.driving,
                        ),
                        SizedBox(width: 4),
                        _buildTransportModeButton(
                          Icons.directions_bike,
                          'Bike',
                          TransportationMode.bicycling,
                        ),
                        SizedBox(width: 4),
                        _buildTransportModeButton(
                          Icons.directions_walk,
                          'Walk',
                          TransportationMode.walking,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Stack(
                  children: [
                    _isMapReady
                        ? _buildMap()
                        : const Center(child: CircularProgressIndicator()),
                    if (_showRouteSummaryCard && _routeDuration != null && _routeDistance != null)
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
                    _buildInfoButtons(),
                    _buildTrafficAndWeatherInfo(),
                    Positioned(
                      top: 16,
                      right: 16,
                      child: FloatingActionButton(
                        onPressed: () async {
                          if (_lastClickedLocation != null) {
                            try {
                              final weatherData = await _mapsService.getWeatherForClickedLocation(_lastClickedLocation!);
                              setState(() {
                                _clickedLocationWeather = weatherData;
                                _showClickedLocationWeather = true;
                              });
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error getting weather: $e')),
                              );
                            }
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Please click on a location first')),
                            );
                          }
                        },
                        child: _clickedLocationWeather != null && _clickedLocationWeather!['weather']['icon'] != null
                            ? Image.network(
                                'https://openweathermap.org/img/wn/${_clickedLocationWeather!['weather']['icon']}@2x.png',
                                width: 32,
                                height: 32,
                              )
                            : Icon(Icons.wb_sunny),
                        backgroundColor: Colors.cyanAccent[400]!.withOpacity(0.8),
                      ),
                    ),
                    _buildRouteSummaryToggleButton(),
                  ],
                ),
              ),
            ],
          ),
          if (_selectedRouteIndex >= 0 && _alternativeRoutes.isNotEmpty && RouteState.sourceLocation != null)
            Positioned(
              bottom: 80,
              right: 16,
              child: FloatingActionButton(
                onPressed: () {
                  final route = _alternativeRoutes[_selectedRouteIndex];
                  if (route['legs'] != null && route['legs'].isNotEmpty) {
                    final leg = route['legs'][0];
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TurnByTurnPage(
                          routeSteps: List<Map<String, dynamic>>.from(leg['steps']),
                          polylines: _polylines,
                          markers: _markers,
                          initialCameraPosition: RouteState.sourceLocation!,
                        ),
                      ),
                    );
                  }
                },
                child: const Icon(Icons.navigation),
                backgroundColor: Colors.cyanAccent,
              ),
            ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.explore), label: 'Explore'),
          BottomNavigationBarItem(icon: Icon(Icons.offline_pin), label: 'Offline'),
          BottomNavigationBarItem(icon: Icon(Icons.analytics), label: 'GNN'),
        ],
        onTap: (index) {
          if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const OfflineRoutesScreen(),
              ),
            );
          } else if (index == 2) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const GNNPage()),
            );
          }
        },
      ),
    );
  }

  InputDecoration _buildTextFieldDecoration(String hintText, TextEditingController controller) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(fontSize: 14.0, color: Colors.grey[600]),
      prefixIcon: Icon(Icons.location_on, color: Colors.cyanAccent[400], size: 20.0),
      suffixIcon: controller.text.isNotEmpty
          ? IconButton(
              icon: Icon(Icons.clear, color: Colors.grey[600], size: 20.0),
              onPressed: () {
                controller.clear();
                setState(() {});
              },
            )
          : null,
      fillColor: Colors.white.withOpacity(0.9),
      filled: true,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: BorderSide(color: Colors.cyanAccent[400]!.withOpacity(0.5), width: 1.0),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: BorderSide(color: Colors.cyanAccent[700]!.withOpacity(0.8), width: 2.0),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: BorderSide(color: Colors.cyanAccent[400]!.withOpacity(0.5), width: 1.0),
      ),
      contentPadding: EdgeInsets.symmetric(vertical: 12.0, horizontal: 10.0),
    );
  }

  Widget _buildMap() {
    return GoogleMap(
      onMapCreated: (GoogleMapController controller) {
        mapController = controller;
        if (RouteState.sourceLocation != null) {
          controller.animateCamera(
            CameraUpdate.newLatLngZoom(RouteState.sourceLocation!, 15),
          );
        } else if (_locationService.currentLocation != null) {
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
      mapToolbarEnabled: false,
      polylines: _polylines,
      markers: _markers.union(_nearbyPlacesMarkers).union(
        _lastClickedLocation != null && !_showRouteSummaryCard ? {
          Marker(
            markerId: const MarkerId('clicked_location'),
            position: _lastClickedLocation!,
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
            infoWindow: InfoWindow(title: 'Clicked Location'),
            onTap: () {
              setState(() {
                _lastClickedLocation = null;
                _showClickedLocationWeather = false;
                _clickedLocationWeather = null;
              });
            },
          )
        } : {}
      ),
      onTap: (LatLng location) async {
        setState(() {
          _lastClickedLocation = location;
          _showClickedLocationWeather = false;
          _clickedLocationWeather = null;
          _showRouteSummaryCard = false;
        });
      },
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
            _showCurrentLocationTrafficInfo,
            () async {
              setState(() {
                _showCurrentLocationTrafficInfo = !_showCurrentLocationTrafficInfo;
                _showCurrentLocationWeatherInfo = false;
                _showClickedLocationWeather = false;
              });
              if (_showCurrentLocationTrafficInfo) {
                print('Traffic button toggled ON.'); // Debug: Button toggle
                final currentLocation = await _locationService.getCurrentLocation(); // Ensure current location is fetched
                if (currentLocation != null) {
                  print('Current location available: $currentLocation'); // Debug: Location status
                  await _updateTrafficAndWeatherInfo(currentLocation);
                } else {
                  print('Current location NOT available for traffic info.'); // Debug: Location status
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Current location not available for traffic info.')),
                  );
                }
              }
            },
          ),
          SizedBox(width: 8),
          _buildInfoButton(
            'Weather',
            Icons.wb_sunny,
            _showCurrentLocationWeatherInfo,
            () async {
              setState(() {
                _showCurrentLocationWeatherInfo = !_showCurrentLocationWeatherInfo;
                _showCurrentLocationTrafficInfo = false;
                _showClickedLocationWeather = false;
              });
              if (_showCurrentLocationWeatherInfo) {
                print('Weather button toggled ON.'); // Debug: Button toggle
                final currentLocation = await _locationService.getCurrentLocation(); // Ensure current location is fetched
                if (currentLocation != null) {
                  print('Current location available: $currentLocation'); // Debug: Location status
                  await _updateTrafficAndWeatherInfo(currentLocation);
                } else {
                  print('Current location NOT available for weather info.'); // Debug: Location status
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Current location not available for weather info.')),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInfoButton(String label, IconData icon, bool isActive, VoidCallback onPressed) {
    return Container(
      decoration: BoxDecoration(
        color: isActive ? Colors.cyanAccent[400]!.withOpacity(0.3) : Colors.white.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isActive ? Colors.cyanAccent[400]!.withOpacity(0.5) : Colors.grey.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  color: isActive ? Colors.cyanAccent[700] : Colors.black87,
                  size: 20,
                ),
                SizedBox(width: 4),
                Text(
                  label,
                  style: TextStyle(
                    color: isActive ? Colors.cyanAccent[700] : Colors.black87,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTrafficAndWeatherInfo() {
    if (_showCurrentLocationTrafficInfo && _trafficInfo != null) {
      return _buildCurrentLocationTrafficInfo();
    } else if (_showCurrentLocationWeatherInfo && _weatherInfo != null) {
      return _buildCurrentLocationWeatherInfo();
    } else if (_showClickedLocationWeather && _clickedLocationWeather != null) {
      return _buildClickedLocationWeatherInfo();
    }
    return SizedBox.shrink();
  }

  Widget _buildCurrentLocationTrafficInfo() {
    print('Building Current Location Traffic Info widget.'); // Debug: Widget build
    print('Traffic Info state: $_trafficInfo'); // Debug: Widget state data
    if (_trafficInfo == null) return SizedBox.shrink();

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
              Row(
                children: [
                  Icon(Icons.traffic, color: _getTrafficColor(_trafficInfo!['traffic_level'])),
                  SizedBox(width: 8),
                  Text(
                    'Traffic Conditions (Current Location)',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              if (_trafficInfo!['address'] != null) Text(
                'Location: ${_trafficInfo!['address']}',
                style: TextStyle(fontSize: 14),
              ),
              Text(
                'Traffic Level: ${_trafficInfo!['traffic_level']}',
                style: TextStyle(
                  fontSize: 14,
                  color: _getTrafficColor(_trafficInfo!['traffic_level']),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentLocationWeatherInfo() {
    print('Building Current Location Weather Info widget.'); // Debug: Widget build
    print('Weather Info state: $_weatherInfo'); // Debug: Widget state data
    if (_weatherInfo == null) return SizedBox.shrink();

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
              Row(
                children: [
                  Icon(Icons.wb_sunny, color: Colors.amber),
                  SizedBox(width: 8),
                  Text(
                    'Weather Information (Current Location)',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  if (_weatherInfo!['icon'] != null)
                    Image.network(
                      'https://openweathermap.org/img/wn/${_weatherInfo!['icon']}@2x.png',
                      width: 50,
                      height: 50,
                    ),
                  SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_weatherInfo!['city'] != null) Text(
                        '${_weatherInfo!['city']}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (_weatherInfo!['condition'] != null) Text(
                        '${_weatherInfo!['condition']}',
                        style: TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 8),
              if (_weatherInfo!['temperature'] != null) Text(
                'Temperature: ${_weatherInfo!['temperature'].toStringAsFixed(1)}°C',
                style: TextStyle(fontSize: 14),
              ),
              if (_weatherInfo!['feels_like'] != null) Text(
                'Feels like: ${_weatherInfo!['feels_like'].toStringAsFixed(1)}°C',
                style: TextStyle(fontSize: 14),
              ),
              if (_weatherInfo!['humidity'] != null) Text(
                'Humidity: ${_weatherInfo!['humidity']}%',
                style: TextStyle(fontSize: 14),
              ),
              if (_weatherInfo!['wind_speed'] != null) Text(
                'Wind Speed: ${_weatherInfo!['wind_speed']} m/s',
                style: TextStyle(fontSize: 14),
              ),
              if (_weatherInfo!['description'] != null) Text(
                'Description: ${_weatherInfo!['description']}',
                style: TextStyle(fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildClickedLocationWeatherInfo() {
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
              Row(
                children: [
                  Icon(Icons.location_on, color: Colors.red),
                  SizedBox(width: 8),
                  Text(
                    'Weather at Selected Location',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  if (_clickedLocationWeather!['weather']['icon'] != null)
                    Image.network(
                      'https://openweathermap.org/img/wn/${_clickedLocationWeather!['weather']['icon']}@2x.png',
                      width: 50,
                      height: 50,
                    ),
                  SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_clickedLocationWeather!['weather']['city']}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${_clickedLocationWeather!['weather']['condition']}',
                        style: TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 8),
              Text(
                'Temperature: ${_clickedLocationWeather!['weather']['temperature'].toStringAsFixed(1)}°C',
                style: TextStyle(fontSize: 14),
              ),
              Text(
                'Feels like: ${_clickedLocationWeather!['weather']['feels_like'].toStringAsFixed(1)}°C',
                style: TextStyle(fontSize: 14),
              ),
              Text(
                'Humidity: ${_clickedLocationWeather!['weather']['humidity']}%',
                style: TextStyle(fontSize: 14),
              ),
              Text(
                'Wind Speed: ${_clickedLocationWeather!['weather']['wind_speed']} m/s',
                style: TextStyle(fontSize: 14),
              ),
              Text(
                'Description: ${_clickedLocationWeather!['weather']['description']}',
                style: TextStyle(fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getTrafficColor(String trafficLevel) {
    switch (trafficLevel.toLowerCase()) {
      case 'heavy':
        return Colors.red;
      case 'moderate':
        return Colors.orange;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Widget _buildTransportModeButton(IconData icon, String label, TransportationMode mode) {
    final bool isSelected = _selectedTransportMode == mode;
    return ElevatedButton(
      onPressed: () {
        setState(() {
          _selectedTransportMode = mode;
        });
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? Colors.cyanAccent[400]!.withOpacity(0.3) : Colors.white.withOpacity(0.3),
        foregroundColor: isSelected ? Colors.cyanAccent[700] : Colors.black87,
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
          side: BorderSide(
            color: isSelected ? Colors.cyanAccent[400]!.withOpacity(0.5) : Colors.grey.withOpacity(0.3),
            width: 1.0,
          ),
        ),
        elevation: 0,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20),
          SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildRouteSummaryToggleButton() {
    if (_routeDuration == null || _routeDistance == null) return SizedBox.shrink();
    
    return Positioned(
      bottom: _showRouteSummaryCard ? 200 : 16,
      left: 16,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.3),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: Colors.cyanAccent[400]!.withOpacity(0.5),
            width: 1,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              setState(() {
                _showRouteSummaryCard = !_showRouteSummaryCard;
                _showCurrentLocationTrafficInfo = false;
                _showCurrentLocationWeatherInfo = false;
                _showClickedLocationWeather = false;
              });
            },
            borderRadius: BorderRadius.circular(30),
            child: Padding(
              padding: EdgeInsets.all(12),
              child: Icon(
                _showRouteSummaryCard ? Icons.close : Icons.alt_route,
                color: Colors.cyanAccent[700],
                size: 20,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _initializeLocation() async {
    final location = await _locationService.getCurrentLocation();
    if (location != null) {
      setState(() {
        _currentLocation = location;
      });
    }
  }

  void _startTrafficUpdates() {
    print('Starting traffic updates...'); // Debug print
    _trafficUpdateTimer?.cancel();
    // Update immediately
    _updateTrafficConditions();
    // Then update every 10 seconds (reduced from 30 for testing)
    _trafficUpdateTimer = Timer.periodic(
      Duration(seconds: 10),
      (timer) => _updateTrafficConditions(),
    );
  }

  void _stopTrafficUpdates() {
    _trafficUpdateTimer?.cancel();
    _trafficUpdateTimer = null;
  }

  Future<void> _updateTrafficConditions() async {
    if (_currentLocation == null || _polylines.isEmpty) {
      print('Cannot update traffic: Location or polylines not available');
      return;
    }

    print('Updating traffic conditions...'); // Debug print

    try {
      // Get all route points from polylines
      List<LatLng> allRoutePoints = [];
      for (var polyline in _polylines) {
        allRoutePoints.addAll(polyline.points);
      }

      print('Route points count: ${allRoutePoints.length}'); // Debug print

      // Get traffic conditions
      final trafficData = await _mapsService.getTrafficConditionsForRoute(
        allRoutePoints,
        _currentLocation!,
      );

      print('Received traffic data: $trafficData'); // Debug print

      setState(() {
        _routeTrafficLevels = Map<String, String>.from(trafficData['route_traffic']);
        print('Updated traffic levels: $_routeTrafficLevels'); // Debug print
        _updateRouteColors();
      });
    } catch (e) {
      print('Error updating traffic conditions: $e');
    }
  }

  void _updateRouteColors() {
    print('Updating route colors...'); // Debug print
    Set<Polyline> updatedPolylines = {};
    
    for (var polyline in _polylines) {
      final points = polyline.points;
      List<Color> segmentColors = [];
      
      // Determine color for each segment
      for (int i = 0; i < points.length - 1; i++) {
        final start = points[i];
        final end = points[i + 1];
        final segmentKey = '${start.latitude},${start.longitude}-${end.latitude},${end.longitude}';
        
        final trafficLevel = _routeTrafficLevels[segmentKey] ?? 'unknown';
        final color = _mapsService.getTrafficColor(trafficLevel);
        segmentColors.add(color);
        
        print('Segment $i: Traffic level = $trafficLevel, Color = $color'); // Debug print
      }

      // Create new polyline with updated colors
      updatedPolylines.add(
        Polyline(
          polylineId: polyline.polylineId,
          points: points,
          color: segmentColors.first, // Use first segment color as base
          width: 5, // Increased width for better visibility
          patterns: [PatternItem.dash(20), PatternItem.gap(10)], // Adjusted pattern for better visibility
          onTap: polyline.onTap,
          consumeTapEvents: polyline.consumeTapEvents,
        ),
      );
    }

    print('Updating polylines with new colors...'); // Debug print
    setState(() {
      _polylines = updatedPolylines;
    });
  }
}

// Placeholder Profile Page
class ProfilePage extends StatelessWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: const Center(child: Text('Profile Page')),
    );
  }
}

// Placeholder Reward Page
class RewardPage extends StatelessWidget {
  const RewardPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reward')),
      body: const Center(child: Text('Reward Page')),
    );
  }
}
