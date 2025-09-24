import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

class TurnByTurnPage extends StatefulWidget {
  final List<Map<String, dynamic>> routeSteps;
  final Set<Polyline> polylines;
  final Set<Marker> markers;
  final LatLng initialCameraPosition;

  const TurnByTurnPage({
    super.key,
    required this.routeSteps,
    required this.polylines,
    required this.markers,
    required this.initialCameraPosition,
  });

  @override
  State<TurnByTurnPage> createState() => _TurnByTurnPageState();
}

class _TurnByTurnPageState extends State<TurnByTurnPage> {
  late FlutterTts flutterTts;
  late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;
  GoogleMapController? mapController;
  int currentStepIndex = 0;
  Position? currentPosition;
  bool isNavigating = true;
  static const double notificationDistance = 100.0; // meters

  @override
  void initState() {
    super.initState();
    _initTts();
    _initNotifications();
    _startLocationTracking();
  }

  @override
  void dispose() {
    isNavigating = false;
    flutterTts.stop();
    mapController?.dispose();
    super.dispose();
  }

  void _initTts() {
    flutterTts = FlutterTts();
    flutterTts.setLanguage("en-US");
    flutterTts.setSpeechRate(0.5);
    flutterTts.setVolume(1.0);
    flutterTts.setPitch(1.0);
  }

  void _initNotifications() {
    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    final DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
            onDidReceiveLocalNotification: (id, title, body, payload) async {});
    final InitializationSettings initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsDarwin);
    flutterLocalNotificationsPlugin.initialize(initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) async {});
  }

  Future<void> _showNotification(String title, String body) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'navigation_channel',
      'Navigation Notifications',
      channelDescription: 'Notifications for turn-by-turn navigation',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: false,
    );
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin.show(
      0,
      title,
      body,
      platformChannelSpecifics,
      payload: 'navigation_payload',
    );
  }

  Future<void> _speak(String text) async {
    await flutterTts.speak(text);
  }

  Future<void> _startLocationTracking() async {
    // Request location permission
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return;
      }
    }

    // Start location updates
    Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Update every 10 meters
      ),
    ).listen((Position position) {
      if (!isNavigating) return;
      
      setState(() {
        currentPosition = position;
      });
      
      _checkDistanceToNextTurn();
    });
  }

  void _checkDistanceToNextTurn() async {
    if (currentPosition == null || currentStepIndex >= widget.routeSteps.length) return;

    final step = widget.routeSteps[currentStepIndex];
    final endLocation = step['end_location'];
    final endLatLng = LatLng(endLocation['lat'], endLocation['lng']);

    // Calculate distance to next turn
    final distance = Geolocator.distanceBetween(
      currentPosition!.latitude,
      currentPosition!.longitude,
      endLatLng.latitude,
      endLatLng.longitude,
    );

    // If within notification distance, show notification and move to next step
    if (distance <= notificationDistance) {
      final instruction = step['html_instructions'].replaceAll(RegExp(r'<[^>]*>|&[^;]+;'), ' ');
      final distance = step['distance']['text'];
      final message = "In $distance, $instruction.";

      await _showNotification("Next Turn", message);
      await _speak(message);

      // Move to next step
      setState(() {
        currentStepIndex++;
      });

      // Update camera position to follow user
      if (mapController != null) {
        mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(
            LatLng(currentPosition!.latitude, currentPosition!.longitude),
            15,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A237E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D47A1),
        title: const Text(
          'Turn-by-Turn Directions',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Expanded(
            flex: 1,
            child: GoogleMap(
              onMapCreated: (controller) {
                mapController = controller;
                mapController!.animateCamera(
                  CameraUpdate.newLatLngZoom(widget.initialCameraPosition, 15),
                );
              },
              initialCameraPosition: CameraPosition(
                target: widget.initialCameraPosition,
                zoom: 15,
              ),
              polylines: widget.polylines,
              markers: widget.markers,
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
              zoomControlsEnabled: false,
              compassEnabled: true,
            ),
          ),
          Expanded(
            flex: 1,
            child: ListView.builder(
              itemCount: widget.routeSteps.length,
              itemBuilder: (context, index) {
                final step = widget.routeSteps[index];
                final instruction = step['html_instructions'].replaceAll(RegExp(r'<[^>]*>|&[^;]+;'), ' ');
                return Card(
                  color: const Color(0xFF212B50), // Blue-Gray surface for cards
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${index + 1}. $instruction',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white), // White text
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Distance: ${step['distance']['text']}',
                          style: const TextStyle(color: Color(0xFF00E5FF)), // Cyan/Neon Blue for details
                        ),
                        Text(
                          'Duration: ${step['duration']['text']}',
                          style: const TextStyle(color: Color(0xFF00E5FF)), // Cyan/Neon Blue for details
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
} 