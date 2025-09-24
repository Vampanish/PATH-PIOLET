import 'dart:async';
import 'dart:math';
import '../pages/authority/services/authority_data_service.dart';

/// Main AI Traffic Monitoring Service that processes Computer Vision and IoT data
class AITrafficMonitoringService {
  AITrafficMonitoringService._();
  static final instance = AITrafficMonitoringService._();
  
  final _random = Random();
  Timer? _cvProcessingTimer;
  Timer? _iotSensorTimer;
  Timer? _alertAnalysisTimer;
  
  // CV Processing Controllers
  final _cvDataController = StreamController<CVAnalysisResult>.broadcast();
  final _iotDataController = StreamController<IoTSensorData>.broadcast();
  final _aiAlertsController = StreamController<AIGeneratedAlert>.broadcast();
  
  // Streams
  Stream<CVAnalysisResult> get cvAnalysisStream => _cvDataController.stream;
  Stream<IoTSensorData> get iotDataStream => _iotDataController.stream;
  Stream<AIGeneratedAlert> get aiAlertsStream => _aiAlertsController.stream;
  
  // Data storage for analysis
  final List<CVAnalysisResult> _recentCVData = [];
  final List<IoTSensorData> _recentIoTData = [];
  final Map<String, CameraFeed> _activeCameras = {};
  final Map<String, IoTSensor> _activeSensors = {};
  
  bool _isRunning = false;
  
  void initialize() {
    if (_isRunning) return;
    _isRunning = true;
    
    _setupCamerasAndSensors();
    _startCVProcessing();
    _startIoTMonitoring();
    _startAIAnalysis();
    
    // Listen to AI alerts and forward to Authority system
    aiAlertsStream.listen((aiAlert) {
      _forwardToAuthoritySystem(aiAlert);
    });
  }
  
  void dispose() {
    _isRunning = false;
    _cvProcessingTimer?.cancel();
    _iotSensorTimer?.cancel();
    _alertAnalysisTimer?.cancel();
    _cvDataController.close();
    _iotDataController.close();
    _aiAlertsController.close();
  }
  
  /// Setup simulated camera feeds and IoT sensors
  void _setupCamerasAndSensors() {
    // Initialize traffic cameras
    for (int i = 1; i <= 8; i++) {
      _activeCameras['CAM_$i'] = CameraFeed(
        id: 'CAM_$i',
        location: 'Junction $i',
        coordinates: _generateRandomCoordinates(),
        isActive: true,
        quality: CameraQuality.hd,
        lastFrameTime: DateTime.now(),
      );
    }
    
    // Initialize IoT sensors
    for (int i = 1; i <= 12; i++) {
      _activeSensors['SENSOR_$i'] = IoTSensor(
        id: 'SENSOR_$i',
        type: IoTSensorType.values[_random.nextInt(IoTSensorType.values.length)],
        location: 'Location $i',
        coordinates: _generateRandomCoordinates(),
        isActive: true,
        lastDataTime: DateTime.now(),
        batteryLevel: 80 + _random.nextInt(20),
      );
    }
  }
  
  /// Start Computer Vision processing simulation
  void _startCVProcessing() {
    _cvProcessingTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      for (final camera in _activeCameras.values) {
        if (!camera.isActive) continue;
        
        final result = _processComputerVision(camera);
        _cvDataController.add(result);
        
        // Keep recent data for analysis
        _recentCVData.add(result);
        if (_recentCVData.length > 50) {
          _recentCVData.removeAt(0);
        }
      }
    });
  }
  
  /// Start IoT sensor monitoring simulation
  void _startIoTMonitoring() {
    _iotSensorTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      for (final sensor in _activeSensors.values) {
        final data = _readIoTSensorData(sensor);
        _iotDataController.add(data);
        
        // Keep recent data for analysis
        _recentIoTData.add(data);
        if (_recentIoTData.length > 100) {
          _recentIoTData.removeAt(0);
        }
      }
    });
  }
  
  /// Start AI analysis that generates alerts
  void _startAIAnalysis() {
    // Generate alerts more frequently for demonstration (every 10 seconds)
    _alertAnalysisTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _performAIAnalysis();
    });
    
    // Generate an immediate alert to test the system
    Timer(const Duration(seconds: 2), () {
      _generateTestAlert();
    });
  }
  
  /// Generate a test alert to demonstrate the system
  void _generateTestAlert() {
    final alert = AIGeneratedAlert(
      id: _generateAlertId(),
      type: AIAlertType.accident,
      title: 'LIVE DEMO: Traffic Incident Detected',
      description: 'Real-time AI system test - Emergency vehicle blocking traffic on Highway 405',
      severity: AlertSeverity.critical,
      location: _generateRandomCoordinates(),
      confidence: 0.89,
      timestamp: DateTime.now(),
      sourceType: AlertSourceType.computerVision,
      sourceId: 'DEMO_CAM_01',
    );
    _generateAlert(alert);
  }
  
  /// Process external alerts (e.g., from emergency vehicle detection)
  void processAlert(AIGeneratedAlert alert) {
    _generateAlert(alert);
  }
  
  /// Process computer vision data from camera feed
  CVAnalysisResult _processComputerVision(CameraFeed camera) {
    final now = DateTime.now();
    camera.lastFrameTime = now;
    
    // Simulate CV processing with realistic scenarios
    final vehicleCount = 5 + _random.nextInt(25);
    final speedAnalysis = _analyzeTrafficSpeed();
    final anomalyDetection = _detectAnomalies();
    
    return CVAnalysisResult(
      cameraId: camera.id,
      timestamp: now,
      vehicleCount: vehicleCount,
      averageSpeed: speedAnalysis.averageSpeed,
      congestionLevel: speedAnalysis.congestionLevel,
      detectedAnomalies: anomalyDetection,
      processingConfidence: 0.85 + _random.nextDouble() * 0.14,
    );
  }
  
  /// Read data from IoT sensor
  IoTSensorData _readIoTSensorData(IoTSensor sensor) {
    final now = DateTime.now();
    
    // Simulate sensor failure occasionally
    if (_random.nextDouble() < 0.05) {
      sensor.isActive = false;
      return IoTSensorData(
        sensorId: sensor.id,
        sensorType: sensor.type,
        timestamp: now,
        value: 0,
        isHealthy: false,
        batteryLevel: sensor.batteryLevel,
        signalStrength: 0,
      );
    }
    
    sensor.isActive = true;
    sensor.lastDataTime = now;
    
    double value;
    switch (sensor.type) {
      case IoTSensorType.vehicleCounter:
        value = (_random.nextInt(50)).toDouble();
        break;
      case IoTSensorType.speedSensor:
        value = 20 + _random.nextDouble() * 40; // km/h
        break;
      case IoTSensorType.pollutionSensor:
        value = 50 + _random.nextDouble() * 200; // AQI
        break;
      case IoTSensorType.accidentDetector:
        value = _random.nextDouble() < 0.02 ? 1.0 : 0.0; // Binary
        break;
      case IoTSensorType.signalTimer:
        value = (_random.nextInt(120)).toDouble(); // Signal timing
        break;
      case IoTSensorType.emergencyVehicleDetector:
        value = _random.nextDouble() < 0.03 ? 1.0 : 0.0; // 3% chance of emergency vehicle
        break;
      case IoTSensorType.audioSensorSiren:
        value = _random.nextDouble() < 0.02 ? (100 + _random.nextInt(20)).toDouble() : (60 + _random.nextInt(20)).toDouble();
        break;
      case IoTSensorType.signalTimer:
        value = (_random.nextInt(120)).toDouble(); // seconds
        break;
    }
    
    return IoTSensorData(
      sensorId: sensor.id,
      sensorType: sensor.type,
      timestamp: now,
      value: value,
      isHealthy: true,
      batteryLevel: sensor.batteryLevel,
      signalStrength: 70 + _random.nextInt(30),
    );
  }
  
  /// Perform AI analysis on collected data to generate alerts
  void _performAIAnalysis() {
    _analyzeAccidents();
    _analyzeCongestion();
    _analyzeSensorFailures();
    _analyzeTrafficPatterns();
  }
  
  /// Analyze for accident detection
  void _analyzeAccidents() {
    // Check accident detectors
    for (final data in _recentIoTData.where((d) => d.sensorType == IoTSensorType.accidentDetector)) {
      if (data.value == 1.0 && data.isHealthy) {
        _generateAlert(AIGeneratedAlert(
          id: _generateAlertId(),
          type: AIAlertType.accident,
          title: 'Accident Detected',
          description: 'AI detected potential accident at ${_getSensorLocation(data.sensorId)}',
          severity: AlertSeverity.critical,
          location: _getSensorCoordinates(data.sensorId),
          confidence: 0.92,
          timestamp: DateTime.now(),
          sourceType: AlertSourceType.iotSensor,
          sourceId: data.sensorId,
        ));
      }
    }
    
    // Check CV for stalled vehicles or unusual patterns
    for (final cvData in _recentCVData) {
      for (final anomaly in cvData.detectedAnomalies) {
        if (anomaly.type == AnomalyType.stalledVehicle) {
          _generateAlert(AIGeneratedAlert(
            id: _generateAlertId(),
            type: AIAlertType.stalledVehicle,
            title: 'Stalled Vehicle Detected',
            description: 'CV system detected stalled vehicle at ${_getCameraLocation(cvData.cameraId)}',
            severity: AlertSeverity.warning,
            location: _getCameraCoordinates(cvData.cameraId),
            confidence: anomaly.confidence,
            timestamp: DateTime.now(),
            sourceType: AlertSourceType.computerVision,
            sourceId: cvData.cameraId,
          ));
        }
      }
    }
  }
  
  /// Analyze for congestion patterns
  void _analyzeCongestion() {
    // Group CV data by location and analyze trends
    final locationGroups = <String, List<CVAnalysisResult>>{};
    for (final data in _recentCVData) {
      locationGroups.putIfAbsent(data.cameraId, () => []).add(data);
    }
    
    for (final entry in locationGroups.entries) {
      final cameraId = entry.key;
      final dataList = entry.value;
      
      if (dataList.length >= 5) {
        final recentData = dataList.take(5).toList();
        final avgCongestion = recentData.map((d) => d.congestionLevel).reduce((a, b) => a + b) / recentData.length;
        final avgVehicles = recentData.map((d) => d.vehicleCount).reduce((a, b) => a + b) / recentData.length;
        
        // High congestion alert
        if (avgCongestion > 0.8 && avgVehicles > 20) {
          _generateAlert(AIGeneratedAlert(
            id: _generateAlertId(),
            type: AIAlertType.heavyCongestion,
            title: 'Heavy Congestion Alert',
            description: 'AI detected heavy traffic congestion at ${_getCameraLocation(cameraId)}. Average congestion: ${(avgCongestion * 100).toInt()}%',
            severity: AlertSeverity.warning,
            location: _getCameraCoordinates(cameraId),
            confidence: 0.88,
            timestamp: DateTime.now(),
            sourceType: AlertSourceType.computerVision,
            sourceId: cameraId,
          ));
        }
      }
    }
  }
  
  /// Analyze for sensor failures
  void _analyzeSensorFailures() {
    for (final data in _recentIoTData) {
      if (!data.isHealthy || data.signalStrength < 20 || data.batteryLevel < 15) {
        _generateAlert(AIGeneratedAlert(
          id: _generateAlertId(),
          type: AIAlertType.sensorFailure,
          title: 'Sensor Failure Alert',
          description: 'IoT sensor ${data.sensorId} (${data.sensorType.name}) is experiencing issues. Battery: ${data.batteryLevel}%, Signal: ${data.signalStrength}%',
          severity: data.batteryLevel < 10 ? AlertSeverity.critical : AlertSeverity.warning,
          location: _getSensorCoordinates(data.sensorId),
          confidence: 0.95,
          timestamp: DateTime.now(),
          sourceType: AlertSourceType.system,
          sourceId: data.sensorId,
        ));
      }
    }
  }
  
  /// Analyze traffic patterns for predictions
  void _analyzeTrafficPatterns() {
    // This would implement more sophisticated pattern analysis
    // For now, simulate occasional pattern-based alerts
    if (_random.nextDouble() < 0.1) {
      final cameraId = _activeCameras.keys.elementAt(_random.nextInt(_activeCameras.length));
      _generateAlert(AIGeneratedAlert(
        id: _generateAlertId(),
        type: AIAlertType.unusualPattern,
        title: 'Unusual Traffic Pattern',
        description: 'AI detected unusual traffic flow pattern at ${_getCameraLocation(cameraId)}',
        severity: AlertSeverity.info,
        location: _getCameraCoordinates(cameraId),
        confidence: 0.75,
        timestamp: DateTime.now(),
        sourceType: AlertSourceType.aiAnalysis,
        sourceId: 'AI_PATTERN_ANALYZER',
      ));
    }
  }
  
  void _generateAlert(AIGeneratedAlert alert) {
    _aiAlertsController.add(alert);
  }
  
  void _forwardToAuthoritySystem(AIGeneratedAlert aiAlert) {
    // Note: This would typically use a public method to add alerts
    // For now, we'll just trigger the alert generation in the authority service
    print('AI Alert Generated: ${aiAlert.title} - Confidence: ${(aiAlert.confidence * 100).toInt()}%');
  }
  
  // Helper methods
  TrafficSpeedAnalysis _analyzeTrafficSpeed() {
    final avgSpeed = 20 + _random.nextDouble() * 40;
    final congestion = avgSpeed < 25 ? 0.8 : avgSpeed < 35 ? 0.5 : 0.2;
    return TrafficSpeedAnalysis(averageSpeed: avgSpeed, congestionLevel: congestion);
  }
  
  List<DetectedAnomaly> _detectAnomalies() {
    final anomalies = <DetectedAnomaly>[];
    if (_random.nextDouble() < 0.1) {
      anomalies.add(DetectedAnomaly(
        type: AnomalyType.stalledVehicle,
        confidence: 0.8 + _random.nextDouble() * 0.2,
        description: 'Vehicle stationary for extended period',
      ));
    }
    if (_random.nextDouble() < 0.05) {
      anomalies.add(DetectedAnomaly(
        type: AnomalyType.wrongWayVehicle,
        confidence: 0.9 + _random.nextDouble() * 0.1,
        description: 'Vehicle moving against traffic flow',
      ));
    }
    return anomalies;
  }
  
  String _generateAlertId() => 'AI_${DateTime.now().millisecondsSinceEpoch}';
  
  Map<String, double> _generateRandomCoordinates() => {
    'lat': 37.7749 + (_random.nextDouble() - 0.5) * 0.1,
    'lng': -122.4194 + (_random.nextDouble() - 0.5) * 0.1,
  };
  
  String _getCameraLocation(String cameraId) => _activeCameras[cameraId]?.location ?? 'Unknown Location';
  String _getSensorLocation(String sensorId) => _activeSensors[sensorId]?.location ?? 'Unknown Location';
  
  Map<String, double> _getCameraCoordinates(String cameraId) => _activeCameras[cameraId]?.coordinates ?? {};
  Map<String, double> _getSensorCoordinates(String sensorId) => _activeSensors[sensorId]?.coordinates ?? {};
}

// Data Models
class CameraFeed {
  final String id;
  final String location;
  final Map<String, double> coordinates;
  bool isActive;
  final CameraQuality quality;
  DateTime lastFrameTime;
  
  CameraFeed({
    required this.id,
    required this.location,
    required this.coordinates,
    required this.isActive,
    required this.quality,
    required this.lastFrameTime,
  });
}

class IoTSensor {
  final String id;
  final IoTSensorType type;
  final String location;
  final Map<String, double> coordinates;
  bool isActive;
  DateTime lastDataTime;
  int batteryLevel;
  
  IoTSensor({
    required this.id,
    required this.type,
    required this.location,
    required this.coordinates,
    required this.isActive,
    required this.lastDataTime,
    required this.batteryLevel,
  });
}

class CVAnalysisResult {
  final String cameraId;
  final DateTime timestamp;
  final int vehicleCount;
  final double averageSpeed;
  final double congestionLevel;
  final List<DetectedAnomaly> detectedAnomalies;
  final double processingConfidence;
  
  CVAnalysisResult({
    required this.cameraId,
    required this.timestamp,
    required this.vehicleCount,
    required this.averageSpeed,
    required this.congestionLevel,
    required this.detectedAnomalies,
    required this.processingConfidence,
  });
}

class IoTSensorData {
  final String sensorId;
  final IoTSensorType sensorType;
  final DateTime timestamp;
  final double value;
  final bool isHealthy;
  final int batteryLevel;
  final int signalStrength;
  
  IoTSensorData({
    required this.sensorId,
    required this.sensorType,
    required this.timestamp,
    required this.value,
    required this.isHealthy,
    required this.batteryLevel,
    required this.signalStrength,
  });
}

class AIGeneratedAlert {
  final String id;
  final AIAlertType type;
  final String title;
  final String description;
  final AlertSeverity severity;
  final Map<String, double> location;
  final double confidence;
  final DateTime timestamp;
  final AlertSourceType sourceType;
  final String sourceId;
  
  AIGeneratedAlert({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.severity,
    required this.location,
    required this.confidence,
    required this.timestamp,
    required this.sourceType,
    required this.sourceId,
  });
}

class DetectedAnomaly {
  final AnomalyType type;
  final double confidence;
  final String description;
  
  DetectedAnomaly({
    required this.type,
    required this.confidence,
    required this.description,
  });
}

class TrafficSpeedAnalysis {
  final double averageSpeed;
  final double congestionLevel;
  
  TrafficSpeedAnalysis({
    required this.averageSpeed,
    required this.congestionLevel,
  });
}

// Enums
enum CameraQuality { sd, hd, uhd }
enum IoTSensorType { vehicleCounter, speedSensor, pollutionSensor, accidentDetector, signalTimer, emergencyVehicleDetector, audioSensorSiren }
enum AIAlertType { accident, stalledVehicle, heavyCongestion, sensorFailure, unusualPattern, emergencyVehicleDetected, emergencyVehicleApproaching }
enum AlertSourceType { computerVision, iotSensor, aiAnalysis, system }
enum AnomalyType { stalledVehicle, wrongWayVehicle, rapidDeceleration, unusualCrowding }

// Auto-initialize the service
final _aiServiceAutoStart = AITrafficMonitoringService.instance..initialize();