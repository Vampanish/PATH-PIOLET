import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:weather/weather.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:intl/intl.dart';
import 'package:geocoding/geocoding.dart';
import '../theme_provider.dart';
import '../config/api_keys.dart';

class TrafficConditionPage extends StatefulWidget {
  final ThemeProvider themeProvider;
  final String initialLanguage;
  
  const TrafficConditionPage({
    super.key, 
    required this.themeProvider,
    required this.initialLanguage,
  });

  @override
  State<TrafficConditionPage> createState() => _TrafficConditionPageState();
}

class _TrafficConditionPageState extends State<TrafficConditionPage> {
  late GoogleMapController _mapController;
  late PanelController _panelController;
  late WeatherFactory _weatherFactory;
  late FlutterLocalNotificationsPlugin _notifications;
  late FlutterTts _flutterTts;
  Position? _currentPosition;
  Weather? _currentWeather;
  double? _compassHeading;
  bool _isLoading = false;
  bool _isMapLoading = true;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  List<TrafficAlert> _alerts = [];
  List<RouteOption> _routeOptions = [];
  late String _currentLanguage;

  @override
  void initState() {
    super.initState();
    _currentLanguage = widget.initialLanguage;
    _panelController = PanelController();
    _weatherFactory = WeatherFactory(ApiKeys.openWeatherKey);
    _initializeNotifications();
    _initializeLocation();
    _initializeCompass();
    _initializeTts();
    _loadTrafficData();
  }

  Future<void> _initializeNotifications() async {
    _notifications = FlutterLocalNotificationsPlugin();
    const initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initializationSettings = InitializationSettings(android: initializationSettingsAndroid);
    await _notifications.initialize(initializationSettings);
  }

  Future<void> _initializeLocation() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        final requestPermission = await Geolocator.requestPermission();
        if (requestPermission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Location permission is required for traffic updates'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location permissions are permanently denied. Please enable in settings.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
      
      _currentPosition = await Geolocator.getCurrentPosition();
      _updateMapCamera();
      _loadWeatherData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error getting location: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _initializeCompass() async {
    FlutterCompass.events?.listen((event) {
      setState(() {
        _compassHeading = event.heading;
      });
    });
  }

  Future<void> _initializeTts() async {
    _flutterTts = FlutterTts();
    await _flutterTts.setLanguage(_currentLanguage);
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);
  }

  Future<void> _speak(String text) async {
    await _flutterTts.speak(text);
  }

  void setLanguage(String languageCode) async {
    _currentLanguage = languageCode;
    await _flutterTts.setLanguage(languageCode);
  }

  Future<void> _loadWeatherData() async {
    if (_currentPosition != null) {
      try {
        _currentWeather = await _weatherFactory.currentWeatherByLocation(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
        );
        setState(() {});
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error loading weather: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _searchLocation(String query) async {
    try {
      setState(() => _isLoading = true);
      
      // Use geocoding to convert address to coordinates
      List<Location> locations = await locationFromAddress(query);
      
      if (locations.isNotEmpty) {
        Location location = locations.first;
        LatLng searchLocation = LatLng(location.latitude, location.longitude);
        
        // Update map camera to the searched location
        _mapController.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: searchLocation,
              zoom: 15,
            ),
          ),
        );
        
        // Add a marker for the searched location
        setState(() {
          _markers.add(
            Marker(
              markerId: const MarkerId('search_location'),
              position: searchLocation,
              infoWindow: InfoWindow(
                title: query,
                snippet: 'Searched Location',
              ),
            ),
          );
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error searching location: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadTrafficData() async {
    setState(() => _isLoading = true);
    // Simulate API call
    await Future.delayed(const Duration(seconds: 1));
    
    // Sample data with multilingual messages
    _alerts = [
      TrafficAlert(
        type: AlertType.accident,
        message: _currentLanguage == 'hi' ? 'आगे 1 किलोमीटर दुर्घटना की सूचना' :
                _currentLanguage == 'ta' ? 'முன்னால் 1 கிலோமீட்டரில் விபத்து அறிக்கை' :
                _currentLanguage == 'bn' ? 'সামনে 1 কিলোমিটার দুর্ঘটনার রিপোর্ট' :
                'Accident reported 1km ahead',
        location: const LatLng(37.7749, -122.4194),
        severity: AlertSeverity.high,
      ),
      TrafficAlert(
        type: AlertType.construction,
        message: _currentLanguage == 'hi' ? 'सड़क निर्माण कार्य जारी' :
                _currentLanguage == 'ta' ? 'சாலை பணிகள் நடைபெற்று வருகின்றன' :
                _currentLanguage == 'bn' ? 'রাস্তার কাজ চলছে' :
                'Road work in progress',
        location: const LatLng(37.7833, -122.4167),
        severity: AlertSeverity.medium,
      ),
    ];

    _routeOptions = [
      RouteOption(
        name: _currentLanguage == 'hi' ? 'सबसे तेज़ मार्ग' :
              _currentLanguage == 'ta' ? 'வேகமான பாதை' :
              _currentLanguage == 'bn' ? 'দ্রুততম রুট' :
              'Fastest Route',
        duration: const Duration(minutes: 25),
        distance: 12.5,
        type: RouteType.fastest,
      ),
      RouteOption(
        name: _currentLanguage == 'hi' ? 'सुंदर मार्ग' :
              _currentLanguage == 'ta' ? 'அழகிய பாதை' :
              _currentLanguage == 'bn' ? 'সুন্দর রুট' :
              'Scenic Route',
        duration: const Duration(minutes: 35),
        distance: 15.0,
        type: RouteType.scenic,
      ),
      RouteOption(
        name: _currentLanguage == 'hi' ? 'AI अनुशंसित' :
              _currentLanguage == 'ta' ? 'AI பரிந்துரைக்கப்பட்டது' :
              _currentLanguage == 'bn' ? 'AI সুপারিশকৃত' :
              'AI Recommended',
        duration: const Duration(minutes: 28),
        distance: 13.2,
        type: RouteType.aiRecommended,
      ),
    ];

    _updateMapMarkers();
    setState(() => _isLoading = false);

    // Speak the first alert
    if (_alerts.isNotEmpty) {
      _speak(_alerts[0].message);
    }
  }

  void _updateMapMarkers() {
    _markers = _alerts.map((alert) {
      return Marker(
        markerId: MarkerId(alert.message),
        position: alert.location,
        icon: BitmapDescriptor.defaultMarkerWithHue(
          alert.severity == AlertSeverity.high ? BitmapDescriptor.hueRed :
          alert.severity == AlertSeverity.medium ? BitmapDescriptor.hueOrange :
          BitmapDescriptor.hueYellow,
        ),
        infoWindow: InfoWindow(
          title: alert.type.toString().split('.').last,
          snippet: alert.message,
        ),
      );
    }).toSet();
  }

  void _updateMapCamera() {
    if (_currentPosition != null && _mapController != null) {
      _mapController.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
            zoom: 15,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Map View
          GoogleMap(
            onMapCreated: (controller) {
              _mapController = controller;
              setState(() => _isMapLoading = false);
              _updateMapCamera();
            },
            initialCameraPosition: CameraPosition(
              target: _currentPosition != null
                  ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
                  : const LatLng(37.7749, -122.4194),
              zoom: 15,
            ),
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            markers: _markers,
            polylines: _polylines,
            trafficEnabled: true,
            compassEnabled: true,
            mapToolbarEnabled: true,
            zoomControlsEnabled: true,
          ),

          // Weather Overlay
          if (_currentWeather != null)
            Positioned(
              top: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getWeatherIcon(_currentWeather!.weatherMain ?? 'clear'),
                      color: Colors.blue,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${_currentWeather!.temperature?.celsius?.round()}°C',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Sliding Panel
          SlidingUpPanel(
            controller: _panelController,
            minHeight: 100,
            maxHeight: MediaQuery.of(context).size.height * 0.7,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            panel: _buildPanel(),
            collapsed: _buildCollapsedPanel(),
            body: Container(),
          ),

          // Loading Indicator
          if (_isLoading || _isMapLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadTrafficData,
        child: const Icon(Icons.refresh),
      ),
    );
  }

  Widget _buildPanel() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Panel Handle
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // AI Traffic Predictor
          if (_routeOptions.isNotEmpty)
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.blue.withOpacity(0.1),
                    Colors.blue.withOpacity(0.2),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'AI Traffic Prediction',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Traffic will slow down in 15 mins ahead on this route',
                    style: TextStyle(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),

          // Route Options
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _routeOptions.length,
              itemBuilder: (context, index) {
                final route = _routeOptions[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: Icon(
                      _getRouteIcon(route.type),
                      color: _getRouteColor(route.type),
                    ),
                    title: Text(route.name),
                    subtitle: Text(
                      '${route.duration.inMinutes} mins • ${route.distance} km',
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      // Handle route selection
                    },
                  ),
                );
              },
            ),
          ),

          // Traffic Alerts
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Traffic Alerts',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                ..._alerts.map((alert) => _buildAlertCard(alert)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCollapsedPanel() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Traffic Information',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Icon(
                  Icons.keyboard_arrow_up,
                  color: Colors.grey[600],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertCard(TrafficAlert alert) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(
          _getAlertIcon(alert.type),
          color: _getAlertColor(alert.severity),
        ),
        title: Text(alert.message),
        subtitle: Text(
          '${alert.type.toString().split('.').last} • ${alert.severity.toString().split('.').last}',
        ),
        trailing: IconButton(
          icon: const Icon(Icons.volume_up),
          onPressed: () => _speak(alert.message),
        ),
      ),
    );
  }

  IconData _getWeatherIcon(String weatherMain) {
    switch (weatherMain.toLowerCase()) {
      case 'clear':
        return Icons.wb_sunny;
      case 'clouds':
        return Icons.cloud;
      case 'rain':
        return Icons.grain;
      case 'snow':
        return Icons.ac_unit;
      default:
        return Icons.wb_sunny;
    }
  }

  IconData _getRouteIcon(RouteType type) {
    switch (type) {
      case RouteType.fastest:
        return Icons.speed;
      case RouteType.scenic:
        return Icons.landscape;
      case RouteType.aiRecommended:
        return Icons.psychology;
    }
  }

  Color _getRouteColor(RouteType type) {
    switch (type) {
      case RouteType.fastest:
        return Colors.green;
      case RouteType.scenic:
        return Colors.blue;
      case RouteType.aiRecommended:
        return Colors.purple;
    }
  }

  IconData _getAlertIcon(AlertType type) {
    switch (type) {
      case AlertType.accident:
        return Icons.car_crash;
      case AlertType.construction:
        return Icons.construction;
      case AlertType.police:
        return Icons.local_police;
      case AlertType.closure:
        return Icons.block;
    }
  }

  Color _getAlertColor(AlertSeverity severity) {
    switch (severity) {
      case AlertSeverity.high:
        return Colors.red;
      case AlertSeverity.medium:
        return Colors.orange;
      case AlertSeverity.low:
        return Colors.yellow;
    }
  }
}

enum AlertType {
  accident,
  construction,
  police,
  closure,
}

enum AlertSeverity {
  high,
  medium,
  low,
}

enum RouteType {
  fastest,
  scenic,
  aiRecommended,
}

class TrafficAlert {
  final AlertType type;
  final String message;
  final LatLng location;
  final AlertSeverity severity;

  TrafficAlert({
    required this.type,
    required this.message,
    required this.location,
    required this.severity,
  });
}

class RouteOption {
  final String name;
  final Duration duration;
  final double distance;
  final RouteType type;

  RouteOption({
    required this.name,
    required this.duration,
    required this.distance,
    required this.type,
  });
} 