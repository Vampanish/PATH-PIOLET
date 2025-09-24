import 'dart:async';
import 'dart:math';
import '../services/ai_traffic_monitoring_service.dart';

/// IoT Sensor Management and Monitoring System
class IoTSensorManager {
  IoTSensorManager._();
  static final instance = IoTSensorManager._();
  
  final _random = Random();
  final Map<String, IoTSensor> _sensors = {};
  final Map<String, SensorHealthStatus> _sensorHealth = {};
  Timer? _healthCheckTimer;
  
  final _sensorDataController = StreamController<IoTSensorData>.broadcast();
  final _sensorHealthController = StreamController<SensorHealthStatus>.broadcast();
  
  Stream<IoTSensorData> get sensorDataStream => _sensorDataController.stream;
  Stream<SensorHealthStatus> get sensorHealthStream => _sensorHealthController.stream;
  
  void initialize() {
    if (_sensors.isNotEmpty) return; // Already initialized
    _setupSensors();
    _startHealthMonitoring();
  }
  
  void dispose() {
    _healthCheckTimer?.cancel();
    _sensorDataController.close();
    _sensorHealthController.close();
  }
  
  /// Setup various IoT sensors in the traffic network
  void _setupSensors() {
    // Vehicle Counter Sensors
    for (int i = 1; i <= 8; i++) {
      _addSensor(IoTSensor(
        id: 'VC_$i',
        type: IoTSensorType.vehicleCounter,
        location: 'Junction $i Entrance',
        coordinates: _generateCoordinates(),
        isActive: true,
        lastDataTime: DateTime.now(),
        batteryLevel: 70 + _random.nextInt(30),
      ));
    }
    
    // Speed Sensors
    for (int i = 1; i <= 6; i++) {
      _addSensor(IoTSensor(
        id: 'SP_$i',
        type: IoTSensorType.speedSensor,
        location: 'Highway Segment $i',
        coordinates: _generateCoordinates(),
        isActive: true,
        lastDataTime: DateTime.now(),
        batteryLevel: 60 + _random.nextInt(40),
      ));
    }
    
    // Pollution Sensors
    for (int i = 1; i <= 4; i++) {
      _addSensor(IoTSensor(
        id: 'PS_$i',
        type: IoTSensorType.pollutionSensor,
        location: 'Urban Area $i',
        coordinates: _generateCoordinates(),
        isActive: true,
        lastDataTime: DateTime.now(),
        batteryLevel: 50 + _random.nextInt(50),
      ));
    }
    
    // Accident Detection Sensors
    for (int i = 1; i <= 10; i++) {
      _addSensor(IoTSensor(
        id: 'AD_$i',
        type: IoTSensorType.accidentDetector,
        location: 'High-Risk Zone $i',
        coordinates: _generateCoordinates(),
        isActive: true,
        lastDataTime: DateTime.now(),
        batteryLevel: 80 + _random.nextInt(20),
      ));
    }
    
    // Signal Timer Sensors
    for (int i = 1; i <= 12; i++) {
      _addSensor(IoTSensor(
        id: 'ST_$i',
        type: IoTSensorType.signalTimer,
        location: 'Traffic Light $i',
        coordinates: _generateCoordinates(),
        isActive: true,
        lastDataTime: DateTime.now(),
        batteryLevel: 90 + _random.nextInt(10),
      ));
    }
    
    // Emergency Vehicle Detection Sensors (RF/Transponder based)
    for (int i = 1; i <= 15; i++) {
      _addSensor(IoTSensor(
        id: 'EVD_$i',
        type: IoTSensorType.emergencyVehicleDetector,
        location: 'Emergency Route Point $i',
        coordinates: _generateCoordinates(),
        isActive: true,
        lastDataTime: DateTime.now(),
        batteryLevel: 85 + _random.nextInt(15),
      ));
    }
    
    // Audio Siren Detection Sensors
    for (int i = 1; i <= 8; i++) {
      _addSensor(IoTSensor(
        id: 'ASD_$i',
        type: IoTSensorType.audioSensorSiren,
        location: 'Audio Monitoring Point $i',
        coordinates: _generateCoordinates(),
        isActive: true,
        lastDataTime: DateTime.now(),
        batteryLevel: 75 + _random.nextInt(25),
      ));
    }
  }
  
  void _addSensor(IoTSensor sensor) {
    _sensors[sensor.id] = sensor;
    _sensorHealth[sensor.id] = SensorHealthStatus(
      sensorId: sensor.id,
      isHealthy: true,
      lastHealthCheck: DateTime.now(),
      issues: [],
    );
  }
  
  /// Get sensor by ID
  IoTSensor? getSensor(String sensorId) {
    return _sensors[sensorId];
  }
  
  /// Start continuous health monitoring of all sensors
  void _startHealthMonitoring() {
    _healthCheckTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _performHealthCheck();
    });
  }
  
  /// Read data from all active sensors
  Future<List<IoTSensorData>> readAllSensorData() async {
    final allData = <IoTSensorData>[];
    
    for (final sensor in _sensors.values) {
      if (sensor.isActive) {
        final data = await _readSensorData(sensor);
        allData.add(data);
        _sensorDataController.add(data);
      }
    }
    
    return allData;
  }
  
  /// Read data from a specific sensor
  Future<IoTSensorData> _readSensorData(IoTSensor sensor) async {
    // Simulate sensor communication delay
    await Future.delayed(Duration(milliseconds: 100 + _random.nextInt(200)));
    
    final now = DateTime.now();
    sensor.lastDataTime = now;
    
    // Check for sensor failures
    final healthStatus = _sensorHealth[sensor.id]!;
    if (!healthStatus.isHealthy) {
      return _createFailedSensorData(sensor, now);
    }
    
    // Simulate random sensor failures (2% chance)
    if (_random.nextDouble() < 0.02) {
      _markSensorUnhealthy(sensor.id, 'Sensor communication failure');
      return _createFailedSensorData(sensor, now);
    }
    
    // Generate realistic sensor data based on type
    final value = _generateSensorValue(sensor.type);
    final signalStrength = _calculateSignalStrength(sensor);
    
    // Update battery level (gradually decreases)
    if (_random.nextDouble() < 0.1) {
      sensor.batteryLevel = (sensor.batteryLevel - _random.nextInt(2)).clamp(0, 100);
    }
    
    return IoTSensorData(
      sensorId: sensor.id,
      sensorType: sensor.type,
      timestamp: now,
      value: value,
      isHealthy: true,
      batteryLevel: sensor.batteryLevel,
      signalStrength: signalStrength,
    );
  }
  
  /// Generate realistic sensor values based on sensor type
  double _generateSensorValue(IoTSensorType type) {
    switch (type) {
      case IoTSensorType.vehicleCounter:
        // Simulate vehicle counting with traffic patterns
        final baseCount = _getTimeBasedTrafficDensity();
        return (baseCount + _random.nextInt(20) - 10).toDouble().clamp(0, 200);
        
      case IoTSensorType.speedSensor:
        // Simulate speed readings with traffic conditions
        final baseSpeed = _getTimeBasedSpeed();
        final variation = (_random.nextDouble() - 0.5) * 20;
        return (baseSpeed + variation).clamp(0, 80);
        
      case IoTSensorType.pollutionSensor:
        // Simulate AQI readings with time-of-day variations
        final baseAQI = _getTimeBasedPollution();
        final variation = (_random.nextDouble() - 0.5) * 50;
        return (baseAQI + variation).clamp(0, 500);
        
      case IoTSensorType.accidentDetector:
        // Binary sensor: 0 = no accident, 1 = accident detected
        return _random.nextDouble() < 0.005 ? 1.0 : 0.0; // 0.5% accident chance
        
      case IoTSensorType.signalTimer:
        // Current signal phase timing (0-120 seconds)
        return _random.nextInt(121).toDouble();
        
      case IoTSensorType.emergencyVehicleDetector:
        // RF/Transponder detection: 0 = no emergency vehicle, 1 = emergency vehicle detected
        return _random.nextDouble() < 0.03 ? 1.0 : 0.0; // 3% chance of emergency vehicle
        
      case IoTSensorType.audioSensorSiren:
        // Audio level in decibels: normal traffic vs siren detection
        final baseNoise = 60 + _random.nextInt(20); // Normal traffic noise
        final hasSiren = _random.nextDouble() < 0.02; // 2% chance of siren
        return hasSiren ? (100 + _random.nextInt(20)).toDouble() : baseNoise.toDouble();
    }
  }
  
  /// Get time-based traffic density (higher during rush hours)
  int _getTimeBasedTrafficDensity() {
    final hour = DateTime.now().hour;
    if (hour >= 7 && hour <= 9 || hour >= 17 && hour <= 19) {
      // Rush hour: higher traffic
      return 50 + _random.nextInt(100);
    } else if (hour >= 22 || hour <= 5) {
      // Night: lower traffic
      return 5 + _random.nextInt(20);
    } else {
      // Regular hours: moderate traffic
      return 20 + _random.nextInt(60);
    }
  }
  
  /// Get time-based speed patterns
  double _getTimeBasedSpeed() {
    final hour = DateTime.now().hour;
    if (hour >= 7 && hour <= 9 || hour >= 17 && hour <= 19) {
      // Rush hour: slower speeds
      return 15 + _random.nextDouble() * 25;
    } else if (hour >= 22 || hour <= 5) {
      // Night: higher speeds (less traffic)
      return 40 + _random.nextDouble() * 30;
    } else {
      // Regular hours: moderate speeds
      return 25 + _random.nextDouble() * 35;
    }
  }
  
  /// Get time-based pollution levels
  double _getTimeBasedPollution() {
    final hour = DateTime.now().hour;
    if (hour >= 7 && hour <= 9 || hour >= 17 && hour <= 19) {
      // Rush hour: higher pollution
      return 150 + _random.nextDouble() * 200;
    } else if (hour >= 22 || hour <= 5) {
      // Night: lower pollution
      return 30 + _random.nextDouble() * 70;
    } else {
      // Regular hours: moderate pollution
      return 80 + _random.nextDouble() * 120;
    }
  }
  
  /// Calculate signal strength based on environmental factors
  int _calculateSignalStrength(IoTSensor sensor) {
    var baseStrength = 70 + _random.nextInt(30);
    
    // Weather impact simulation
    if (_random.nextDouble() < 0.1) {
      baseStrength -= _random.nextInt(20); // Weather interference
    }
    
    // Battery impact
    if (sensor.batteryLevel < 20) {
      baseStrength -= _random.nextInt(15);
    }
    
    return baseStrength.clamp(0, 100);
  }
  
  /// Create failed sensor data
  IoTSensorData _createFailedSensorData(IoTSensor sensor, DateTime timestamp) {
    return IoTSensorData(
      sensorId: sensor.id,
      sensorType: sensor.type,
      timestamp: timestamp,
      value: 0,
      isHealthy: false,
      batteryLevel: sensor.batteryLevel,
      signalStrength: 0,
    );
  }
  
  /// Perform comprehensive health check on all sensors
  void _performHealthCheck() {
    for (final sensor in _sensors.values) {
      final healthStatus = _sensorHealth[sensor.id]!;
      final now = DateTime.now();
      
      // Check if sensor has been silent for too long
      final timeSinceLastData = now.difference(sensor.lastDataTime);
      if (timeSinceLastData.inMinutes > 5) {
        _markSensorUnhealthy(sensor.id, 'No data received for ${timeSinceLastData.inMinutes} minutes');
      }
      
      // Check battery level
      if (sensor.batteryLevel < 10) {
        _markSensorUnhealthy(sensor.id, 'Critical battery level: ${sensor.batteryLevel}%');
      } else if (sensor.batteryLevel < 20) {
        _markSensorWarning(sensor.id, 'Low battery level: ${sensor.batteryLevel}%');
      }
      
      // Random recovery from failures (10% chance per check)
      if (!healthStatus.isHealthy && _random.nextDouble() < 0.1) {
        _markSensorHealthy(sensor.id);
      }
      
      healthStatus.lastHealthCheck = now;
      _sensorHealthController.add(healthStatus);
    }
  }
  
  void _markSensorUnhealthy(String sensorId, String issue) {
    final sensor = _sensors[sensorId];
    final healthStatus = _sensorHealth[sensorId];
    
    if (sensor != null && healthStatus != null) {
      sensor.isActive = false;
      healthStatus.isHealthy = false;
      healthStatus.issues.add(SensorIssue(
        description: issue,
        severity: IssueSeverity.critical,
        timestamp: DateTime.now(),
      ));
    }
  }
  
  void _markSensorWarning(String sensorId, String warning) {
    final healthStatus = _sensorHealth[sensorId];
    
    if (healthStatus != null) {
      healthStatus.issues.add(SensorIssue(
        description: warning,
        severity: IssueSeverity.warning,
        timestamp: DateTime.now(),
      ));
    }
  }
  
  void _markSensorHealthy(String sensorId) {
    final sensor = _sensors[sensorId];
    final healthStatus = _sensorHealth[sensorId];
    
    if (sensor != null && healthStatus != null) {
      sensor.isActive = true;
      healthStatus.isHealthy = true;
      healthStatus.issues.clear();
    }
  }
  
  /// Get sensor statistics and diagnostics
  SensorNetworkStatistics getNetworkStatistics() {
    final totalSensors = _sensors.length;
    final activeSensors = _sensors.values.where((s) => s.isActive).length;
    final healthySensors = _sensorHealth.values.where((h) => h.isHealthy).length;
    
    final typeDistribution = <IoTSensorType, int>{};
    for (final sensor in _sensors.values) {
      typeDistribution[sensor.type] = (typeDistribution[sensor.type] ?? 0) + 1;
    }
    
    final avgBatteryLevel = _sensors.values.isNotEmpty
        ? _sensors.values.map((s) => s.batteryLevel).reduce((a, b) => a + b) / _sensors.length
        : 0.0;
    
    return SensorNetworkStatistics(
      totalSensors: totalSensors,
      activeSensors: activeSensors,
      healthySensors: healthySensors,
      averageBatteryLevel: avgBatteryLevel,
      sensorTypeDistribution: typeDistribution,
      timestamp: DateTime.now(),
    );
  }
  
  Map<String, double> _generateCoordinates() => {
    'lat': 37.7749 + (_random.nextDouble() - 0.5) * 0.1,
    'lng': -122.4194 + (_random.nextDouble() - 0.5) * 0.1,
  };
  
  List<IoTSensor> get allSensors => _sensors.values.toList();
  SensorHealthStatus? getSensorHealth(String id) => _sensorHealth[id];
}

// Data Models

class SensorHealthStatus {
  final String sensorId;
  bool isHealthy;
  DateTime lastHealthCheck;
  final List<SensorIssue> issues;
  
  SensorHealthStatus({
    required this.sensorId,
    required this.isHealthy,
    required this.lastHealthCheck,
    required this.issues,
  });
}

class SensorIssue {
  final String description;
  final IssueSeverity severity;
  final DateTime timestamp;
  
  SensorIssue({
    required this.description,
    required this.severity,
    required this.timestamp,
  });
}

class SensorNetworkStatistics {
  final int totalSensors;
  final int activeSensors;
  final int healthySensors;
  final double averageBatteryLevel;
  final Map<IoTSensorType, int> sensorTypeDistribution;
  final DateTime timestamp;
  
  SensorNetworkStatistics({
    required this.totalSensors,
    required this.activeSensors,
    required this.healthySensors,
    required this.averageBatteryLevel,
    required this.sensorTypeDistribution,
    required this.timestamp,
  });
  
  double get healthPercentage => totalSensors > 0 ? (healthySensors / totalSensors) * 100 : 0.0;
  double get activePercentage => totalSensors > 0 ? (activeSensors / totalSensors) * 100 : 0.0;
}

enum IssueSeverity { info, warning, critical }