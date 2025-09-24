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
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Trigger manual emergency detection for testing
          _triggerManualTest();
        },
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.emergency),
        label: const Text('TEST EMERGENCY'),
      ),
    );
  }

  Widget _buildSensorNetworkStatus() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.sensors, color: Colors.blue),
                const SizedBox(width: 8),
                const Text(
                  'IoT Sensor Network Status',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    return Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.5 + (_pulseController.value * 0.5)),
                        shape: BoxShape.circle,
                      ),
                    );
                  },
                ),
                const SizedBox(width: 8),
                const Text('ONLINE', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatusCard('Total Sensors', '$_totalSensors', Icons.device_hub, Colors.blue),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatusCard('Active', '$_activeSensors', Icons.check_circle, Colors.green),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatusCard('Health', '${_networkHealth.toStringAsFixed(1)}%', Icons.health_and_safety, Colors.orange),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text('🛡️ RF Sensors (5.9 GHz): 15 units • 📢 Audio Sensors: 8 units', 
                 style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildLiveMonitoring() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.monitor_heart, color: Colors.red),
                const SizedBox(width: 8),
                const Text(
                  'Live Emergency Monitoring',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    return Icon(
                      Icons.fiber_manual_record,
                      color: Colors.red.withOpacity(0.5 + (_pulseController.value * 0.5)),
                      size: 16,
                    );
                  },
                ),
                const SizedBox(width: 4),
                const Text('SCANNING', style: TextStyle(color: Colors.red, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                children: [
                  const Text('🔍 Monitoring RF frequencies at 5.9 GHz'),
                  const Text('🎵 Listening for emergency sirens (300-3000 Hz)'),
                  const Text('🚦 Connected to traffic management system'),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: _pulseController.value,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetectionStats() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '📊 Detection Statistics',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard('Today', '$_todayDetections', '🚨', Colors.red),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard('Total', '$_totalDetections', '📈', Colors.blue),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard('Avg Response', '${_avgResponseTime}s', '⚡', Colors.green),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveAlerts() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '🚨 Active Emergency Alerts',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (_activeAlerts.isEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                child: const Center(
                  child: Text(
                    'No active emergency alerts',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _activeAlerts.length,
                itemBuilder: (context, index) {
                  final alert = _activeAlerts[index];
                  return _buildAlertCard(alert);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrafficControlActions() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '🚦 Traffic Control Actions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (_trafficActions.isEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                child: const Center(
                  child: Text(
                    'No recent traffic actions',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _trafficActions.length,
                itemBuilder: (context, index) {
                  final action = _trafficActions[index];
                  return _buildTrafficActionCard(action);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildManualTestingPanel() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '🧪 Manual Testing & Simulation',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _triggerTestEmergency(EmergencyVehicleType.ambulance),
                    icon: const Icon(Icons.local_hospital),
                    label: const Text('Test Ambulance'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _triggerTestEmergency(EmergencyVehicleType.fireEngine),
                    icon: const Icon(Icons.local_fire_department),
                    label: const Text('Test Fire'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _triggerTestEmergency(EmergencyVehicleType.policeVehicle),
                    icon: const Icon(Icons.local_police),
                    label: const Text('Test Police'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showSimulationOptions(),
                    icon: const Icon(Icons.settings),
                    label: const Text('Simulation'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSystemAnalytics() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '📈 System Performance Analytics',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildAnalyticsRow('Detection Accuracy', '95.8%', Colors.green),
            _buildAnalyticsRow('RF Detection Success', '97.2%', Colors.blue),
            _buildAnalyticsRow('Audio Detection Success', '92.4%', Colors.orange),
            _buildAnalyticsRow('False Positive Rate', '2.1%', Colors.red),
            _buildAnalyticsRow('System Uptime', '99.7%', Colors.green),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
          Text(title, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, String emoji, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
          Text(title, style: const TextStyle(fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildAlertCard(EmergencyVehicleAlert alert) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Text(alert.vehicleType.icon, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(alert.vehicleType.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(alert.detectionLocation, style: const TextStyle(fontSize: 12)),
                Text('${alert.estimatedSpeed.toInt()} km/h • ${alert.direction}', 
                     style: const TextStyle(fontSize: 10, color: Colors.grey)),
              ],
            ),
          ),
          Text(alert.timestamp.toString().substring(11, 16)),
        ],
      ),
    );
  }

  Widget _buildTrafficActionCard(TrafficControlAction action) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.traffic, color: Colors.blue),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(action.type.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(action.description, style: const TextStyle(fontSize: 12)),
                Text('${action.location} • ${action.estimatedDuration.inMinutes}min', 
                     style: const TextStyle(fontSize: 10, color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsRow(String metric, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(metric, style: const TextStyle(fontSize: 14)),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  void _triggerManualTest() {
    EmergencyVehicleDetectionService.instance.triggerEmergencyDetection(
      EmergencyVehicleType.ambulance,
      'Manual Test - Main Street',
    );
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🚨 Manual emergency test triggered!'),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _triggerTestEmergency(EmergencyVehicleType type) {
    EmergencyVehicleDetectionService.instance.triggerEmergencyDetection(
      type,
      'Test Location - ${type.name}',
    );
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('🧪 ${type.name} test triggered!'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _showSimulationOptions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Simulation Options'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.radio),
              title: const Text('RF Transponder Test'),
              subtitle: const Text('Simulate 5.9 GHz detection'),
              onTap: () {
                Navigator.pop(context);
                _triggerTestEmergency(EmergencyVehicleType.ambulance);
              },
            ),
            ListTile(
              leading: const Icon(Icons.volume_up),
              title: const Text('Audio Siren Test'),
              subtitle: const Text('Simulate siren detection'),
              onTap: () {
                Navigator.pop(context);
                _triggerTestEmergency(EmergencyVehicleType.fireEngine);
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Full System Test'),
              subtitle: const Text('Comprehensive simulation'),
              onTap: () {
                Navigator.pop(context);
                _triggerTestEmergency(EmergencyVehicleType.policeVehicle);
              },
            ),
          ],
        ),
      ),
    );
  }
}