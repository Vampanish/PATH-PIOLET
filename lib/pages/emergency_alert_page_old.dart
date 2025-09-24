import 'package:flutter/material.dart';
import 'dart:async';
import '../theme_provider.dart';
import '../services/emergency_vehicle_detection_service.dart';
import '../services/iot_sensor_manager.dart';

class EmergencyAlertPage extends StatefulWidget {
  final ThemeProvider themeProvider;
  
  const EmergencyAlertPage({super.key, required this.themeProvider});

  @override
  State<EmergencyAlertPage> createState() => _EmergencyAlertPageState();
}

class _EmergencyAlertPageState extends State<EmergencyAlertPage> with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _slideController;
  
  List<EmergencyVehicleAlert> _activeAlerts = [];
  List<TrafficControlAction> _trafficActions = [];
  StreamSubscription<EmergencyVehicleAlert>? _alertSubscription;
  StreamSubscription<TrafficControlAction>? _trafficSubscription;
  
  // IoT Sensor Network Statistics
  int _totalSensors = 23;
  int _activeSensors = 23;
  double _networkHealth = 98.5;
  
  // Detection Statistics
  int _totalDetections = 47;
  int _todayDetections = 12;
  double _avgResponseTime = 1.8;
  
  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat(reverse: true);
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..forward();
    
    _initializeEmergencySystem();
    _startListening();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _slideController.dispose();
    _alertSubscription?.cancel();
    _trafficSubscription?.cancel();
    super.dispose();
  }
  
  void _initializeEmergencySystem() {
    // Initialize the emergency vehicle detection system
    EmergencyVehicleDetectionService.instance.initialize();
    IoTSensorManager.instance.initialize();
  }
  
  void _startListening() {
    // Listen to emergency alerts
    _alertSubscription = EmergencyVehicleDetectionService.instance.emergencyAlertStream.listen((alert) {
      setState(() {
        _activeAlerts.insert(0, alert);
        if (_activeAlerts.length > 10) _activeAlerts.removeLast();
        _todayDetections++;
        _totalDetections++;
      });
    });
    
    // Listen to traffic control actions
    _trafficSubscription = EmergencyVehicleDetectionService.instance.trafficControlStream.listen((action) {
      setState(() {
        _trafficActions.insert(0, action);
        if (_trafficActions.length > 10) _trafficActions.removeLast();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.themeProvider.isDarkMode;
    
    return Scaffold(
      backgroundColor: isDark ? Colors.grey[900] : Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.red[700],
        foregroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return Transform.scale(
                  scale: 1.0 + (_pulseController.value * 0.1),
                  child: const Icon(Icons.emergency, color: Colors.white),
                );
              },
            ),
            const SizedBox(width: 8),
            const Text(
              'Emergency Vehicle Detection',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
            onPressed: () => widget.themeProvider.toggleTheme(),
            tooltip: 'Toggle Theme',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // IoT Sensor Network Status
            _buildSensorNetworkStatus(),
            const SizedBox(height: 16),
            
            // Live Emergency Monitoring
            _buildLiveMonitoring(),
            const SizedBox(height: 16),
            
            // Detection Statistics
            _buildDetectionStats(),
            const SizedBox(height: 16),
            
            // Active Alerts
            _buildActiveAlerts(),
            const SizedBox(height: 16),
            
            // Traffic Control Actions
            _buildTrafficControlActions(),
            const SizedBox(height: 16),
            
            // Manual Testing Panel
            _buildManualTestingPanel(),
            const SizedBox(height: 16),
            
            // System Analytics
            _buildSystemAnalytics(),
                      Row(
                        children: [
                          const Icon(Icons.info, color: Colors.orange),
                          const SizedBox(width: 8),
                          const Text(
                            'Emergency Protocol',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        '• Move to the right side of the road\n'
                        '• Stop your vehicle completely\n'
                        '• Allow emergency vehicle to pass\n'
                        '• Wait for all clear signal\n'
                        '• Resume normal traffic flow',
                        style: TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          Text(
            '$label:',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}