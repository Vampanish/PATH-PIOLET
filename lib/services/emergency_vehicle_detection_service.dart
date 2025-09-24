import 'dart:async';
import 'dart:math';
import 'iot_sensor_manager.dart';
import 'ai_traffic_monitoring_service.dart';
import '../pages/authority/services/authority_data_service.dart' show AlertSeverity;

/// Emergency Vehicle Detection and Alert Management Service
class EmergencyVehicleDetectionService {
  EmergencyVehicleDetectionService._();
  static final instance = EmergencyVehicleDetectionService._();
  
  final _random = Random();
  Timer? _detectionTimer;
  Timer? _simulationTimer;
  
  final _emergencyAlertController = StreamController<EmergencyVehicleAlert>.broadcast();
  final _trafficControlController = StreamController<TrafficControlAction>.broadcast();
  
  Stream<EmergencyVehicleAlert> get emergencyAlertStream => _emergencyAlertController.stream;
  Stream<TrafficControlAction> get trafficControlStream => _trafficControlController.stream;
  
  final List<EmergencyVehicleAlert> _activeAlerts = [];
  final List<EmergencyVehicle> _simulatedVehicles = [];
  
  void initialize() {
    _startEmergencyDetection();
    _startEmergencyVehicleSimulation();
  }
  
  void dispose() {
    _detectionTimer?.cancel();
    _simulationTimer?.cancel();
    _emergencyAlertController.close();
    _trafficControlController.close();
  }
  
  /// Start monitoring IoT sensors for emergency vehicle detection
  void _startEmergencyDetection() {
    _detectionTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      _processEmergencyDetection();
    });
  }
  
  /// Start simulation of emergency vehicles for testing
  void _startEmergencyVehicleSimulation() {
    _simulationTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _simulateEmergencyVehicle();
    });
  }
  
  /// Process real-time emergency vehicle detection from IoT sensors
  Future<void> _processEmergencyDetection() async {
    try {
      final sensorData = await IoTSensorManager.instance.readAllSensorData();
      
      // Check RF/Transponder sensors
      final emergencyDetections = sensorData.where((data) => 
        data.sensorType == IoTSensorType.emergencyVehicleDetector && 
        data.value == 1.0 && 
        data.isHealthy
      ).toList();
      
      // Check Audio Siren sensors (high decibel readings)
      final sirenDetections = sensorData.where((data) => 
        data.sensorType == IoTSensorType.audioSensorSiren && 
        data.value > 95.0 && // High audio level indicating siren
        data.isHealthy
      ).toList();
      
      // Process RF detections
      for (final detection in emergencyDetections) {
        await _handleEmergencyVehicleDetection(detection, EmergencyDetectionMethod.rfTransponder);
      }
      
      // Process Audio detections
      for (final detection in sirenDetections) {
        await _handleEmergencyVehicleDetection(detection, EmergencyDetectionMethod.audioSiren);
      }
      
    } catch (e) {
      print('Error in emergency detection: $e');
    }
  }
  
  /// Handle individual emergency vehicle detection
  Future<void> _handleEmergencyVehicleDetection(
    IoTSensorData sensorData, 
    EmergencyDetectionMethod method
  ) async {
    final sensor = IoTSensorManager.instance.getSensor(sensorData.sensorId);
    if (sensor == null) return;
    
    // Check if this is a duplicate detection (within 2 minutes)
    final recentAlert = _activeAlerts.where((alert) => 
      alert.detectionLocation == sensor.location &&
      DateTime.now().difference(alert.timestamp).inMinutes < 2
    ).isNotEmpty;
    
    if (recentAlert) return; // Skip duplicate
    
    // Determine emergency vehicle type based on detection pattern
    final vehicleType = _determineVehicleType(method, sensorData.value);
    
    // Create emergency alert
    final alert = EmergencyVehicleAlert(
      id: _generateAlertId(),
      vehicleType: vehicleType,
      detectionMethod: method,
      detectionLocation: sensor.location,
      coordinates: Coordinates(
        latitude: sensor.coordinates['latitude']!,
        longitude: sensor.coordinates['longitude']!,
      ),
      timestamp: DateTime.now(),
      priority: _getPriorityLevel(vehicleType),
      estimatedSpeed: _estimateVehicleSpeed(sensorData, method),
      direction: _estimateDirection(),
      isActive: true,
      sensorId: sensorData.sensorId,
    );
    
    _activeAlerts.add(alert);
    _emergencyAlertController.add(alert);
    
    // Trigger traffic control actions
    await _triggerTrafficControl(alert);
    
    // Forward to AI monitoring system
    _forwardToAISystem(alert);
    
    // Auto-deactivate alert after 5 minutes
    Timer(const Duration(minutes: 5), () {
      _deactivateAlert(alert.id);
    });
  }
  
  /// Simulate emergency vehicle for demonstration
  void _simulateEmergencyVehicle() {
    final vehicleTypes = [
      EmergencyVehicleType.ambulance,
      EmergencyVehicleType.fireEngine,
      EmergencyVehicleType.policeVehicle,
      EmergencyVehicleType.paramedicsUnit,
    ];
    
    final locations = [
      'Main Street Junction',
      'Hospital Route',
      'Fire Station Exit',
      'Police Headquarters',
      'Emergency Route A',
      'Highway Emergency Lane',
    ];
    
    final vehicle = EmergencyVehicle(
      id: 'SIM_${DateTime.now().millisecondsSinceEpoch}',
      type: vehicleTypes[_random.nextInt(vehicleTypes.length)],
      currentLocation: locations[_random.nextInt(locations.length)],
      destination: locations[_random.nextInt(locations.length)],
      speed: 60 + _random.nextInt(40), // 60-100 km/h
      isActive: true,
      respondingToEmergency: true,
    );
    
    _simulatedVehicles.add(vehicle);
    
    // Create corresponding alert
    final alert = EmergencyVehicleAlert(
      id: _generateAlertId(),
      vehicleType: vehicle.type,
      detectionMethod: EmergencyDetectionMethod.simulation,
      detectionLocation: vehicle.currentLocation,
      coordinates: _generateRandomCoordinates(),
      timestamp: DateTime.now(),
      priority: EmergencyPriority.high,
      estimatedSpeed: vehicle.speed.toDouble(),
      direction: _estimateDirection(),
      isActive: true,
      sensorId: 'SIMULATION',
    );
    
    _activeAlerts.add(alert);
    _emergencyAlertController.add(alert);
    
    // Trigger traffic control
    _triggerTrafficControl(alert);
  }
  
  /// Trigger appropriate traffic control actions
  Future<void> _triggerTrafficControl(EmergencyVehicleAlert alert) async {
    final actions = <TrafficControlAction>[];
    
    // Signal control action
    actions.add(TrafficControlAction(
      id: _generateActionId(),
      type: TrafficActionType.signalOverride,
      location: alert.detectionLocation,
      description: 'Override traffic signals to clear path for ${alert.vehicleType.name}',
      priority: alert.priority,
      timestamp: DateTime.now(),
      estimatedDuration: const Duration(minutes: 3),
    ));
    
    // Lane management
    actions.add(TrafficControlAction(
      id: _generateActionId(),
      type: TrafficActionType.laneControl,
      location: alert.detectionLocation,
      description: 'Clear emergency lane and redirect traffic',
      priority: alert.priority,
      timestamp: DateTime.now(),
      estimatedDuration: const Duration(minutes: 5),
    ));
    
    // Public notification
    actions.add(TrafficControlAction(
      id: _generateActionId(),
      type: TrafficActionType.publicNotification,
      location: alert.detectionLocation,
      description: 'Broadcast emergency vehicle alert to nearby traffic',
      priority: alert.priority,
      timestamp: DateTime.now(),
      estimatedDuration: const Duration(minutes: 2),
    ));
    
    // Send actions
    for (final action in actions) {
      _trafficControlController.add(action);
    }
  }
  
  /// Forward alert to AI monitoring system
  void _forwardToAISystem(EmergencyVehicleAlert alert) {
    final aiAlert = AIGeneratedAlert(
      id: alert.id,
      type: AIAlertType.emergencyVehicleDetected,
      title: 'Emergency Vehicle Alert',
      severity: _mapPriorityToSeverity(alert.priority),
      description: 'Emergency vehicle detected: ${alert.vehicleType.name} at ${alert.detectionLocation}',
      location: {
        'latitude': alert.coordinates.latitude,
        'longitude': alert.coordinates.longitude,
      },
      timestamp: alert.timestamp,
      sourceType: AlertSourceType.iotSensor,
      sourceId: alert.sensorId,
      confidence: 0.95, // High confidence for IoT sensor detection
    );
    
    AITrafficMonitoringService.instance.processAlert(aiAlert);
  }
  
  /// Helper methods
  EmergencyVehicleType _determineVehicleType(EmergencyDetectionMethod method, double sensorValue) {
    if (method == EmergencyDetectionMethod.audioSiren) {
      // Different siren patterns for different vehicles
      if (sensorValue > 110) return EmergencyVehicleType.fireEngine; // Loudest
      if (sensorValue > 105) return EmergencyVehicleType.ambulance;
      return EmergencyVehicleType.policeVehicle;
    }
    
    // For RF detection, randomize based on common emergency vehicles
    final types = [
      EmergencyVehicleType.ambulance,
      EmergencyVehicleType.policeVehicle,
      EmergencyVehicleType.fireEngine,
      EmergencyVehicleType.paramedicsUnit,
    ];
    return types[_random.nextInt(types.length)];
  }
  
  EmergencyPriority _getPriorityLevel(EmergencyVehicleType type) {
    switch (type) {
      case EmergencyVehicleType.fireEngine:
        return EmergencyPriority.critical;
      case EmergencyVehicleType.ambulance:
        return EmergencyPriority.high;
      case EmergencyVehicleType.policeVehicle:
        return EmergencyPriority.high;
      case EmergencyVehicleType.paramedicsUnit:
        return EmergencyPriority.high;
      case EmergencyVehicleType.rescueVehicle:
        return EmergencyPriority.critical;
    }
  }
  
  double _estimateVehicleSpeed(IoTSensorData sensorData, EmergencyDetectionMethod method) {
    // Estimate based on detection method and signal strength
    if (method == EmergencyDetectionMethod.audioSiren) {
      return (70 + _random.nextInt(30)).toDouble(); // 70-100 km/h for siren detection
    }
    return (60 + _random.nextInt(40)).toDouble(); // 60-100 km/h for RF detection
  }
  
  String _estimateDirection() {
    final directions = ['North', 'South', 'East', 'West', 'Northeast', 'Northwest', 'Southeast', 'Southwest'];
    return directions[_random.nextInt(directions.length)];
  }
  
  Coordinates _generateRandomCoordinates() {
    return Coordinates(
      latitude: 28.5355 + (_random.nextDouble() - 0.5) * 0.1, // Delhi area
      longitude: 77.3910 + (_random.nextDouble() - 0.5) * 0.1,
    );
  }
  
  String _generateAlertId() => 'ALERT_${DateTime.now().millisecondsSinceEpoch}';
  String _generateActionId() => 'ACTION_${DateTime.now().millisecondsSinceEpoch}';
  
  AlertSeverity _mapPriorityToSeverity(EmergencyPriority priority) {
    switch (priority) {
      case EmergencyPriority.critical:
        return AlertSeverity.critical;
      case EmergencyPriority.high:
        return AlertSeverity.warning;
      case EmergencyPriority.medium:
        return AlertSeverity.warning;
      case EmergencyPriority.low:
        return AlertSeverity.info;
    }
  }
  
  void _deactivateAlert(String alertId) {
    final alertIndex = _activeAlerts.indexWhere((alert) => alert.id == alertId);
    if (alertIndex != -1) {
      _activeAlerts[alertIndex] = _activeAlerts[alertIndex].copyWith(isActive: false);
    }
  }
  
  // Public methods for getting current state
  List<EmergencyVehicleAlert> get activeAlerts => List.unmodifiable(_activeAlerts.where((a) => a.isActive));
  List<EmergencyVehicle> get simulatedVehicles => List.unmodifiable(_simulatedVehicles);
  
  // Method to manually trigger emergency detection for testing
  void triggerEmergencyDetection(EmergencyVehicleType type, String location) {
    final alert = EmergencyVehicleAlert(
      id: _generateAlertId(),
      vehicleType: type,
      detectionMethod: EmergencyDetectionMethod.manual,
      detectionLocation: location,
      coordinates: _generateRandomCoordinates(),
      timestamp: DateTime.now(),
      priority: _getPriorityLevel(type),
      estimatedSpeed: 75.0,
      direction: _estimateDirection(),
      isActive: true,
      sensorId: 'MANUAL_TRIGGER',
    );
    
    _activeAlerts.add(alert);
    _emergencyAlertController.add(alert);
    _triggerTrafficControl(alert);
  }
}

// Data Models

class EmergencyVehicleAlert {
  final String id;
  final EmergencyVehicleType vehicleType;
  final EmergencyDetectionMethod detectionMethod;
  final String detectionLocation;
  final Coordinates coordinates;
  final DateTime timestamp;
  final EmergencyPriority priority;
  final double estimatedSpeed;
  final String direction;
  final bool isActive;
  final String sensorId;
  
  const EmergencyVehicleAlert({
    required this.id,
    required this.vehicleType,
    required this.detectionMethod,
    required this.detectionLocation,
    required this.coordinates,
    required this.timestamp,
    required this.priority,
    required this.estimatedSpeed,
    required this.direction,
    required this.isActive,
    required this.sensorId,
  });
  
  EmergencyVehicleAlert copyWith({
    String? id,
    EmergencyVehicleType? vehicleType,
    EmergencyDetectionMethod? detectionMethod,
    String? detectionLocation,
    Coordinates? coordinates,
    DateTime? timestamp,
    EmergencyPriority? priority,
    double? estimatedSpeed,
    String? direction,
    bool? isActive,
    String? sensorId,
  }) {
    return EmergencyVehicleAlert(
      id: id ?? this.id,
      vehicleType: vehicleType ?? this.vehicleType,
      detectionMethod: detectionMethod ?? this.detectionMethod,
      detectionLocation: detectionLocation ?? this.detectionLocation,
      coordinates: coordinates ?? this.coordinates,
      timestamp: timestamp ?? this.timestamp,
      priority: priority ?? this.priority,
      estimatedSpeed: estimatedSpeed ?? this.estimatedSpeed,
      direction: direction ?? this.direction,
      isActive: isActive ?? this.isActive,
      sensorId: sensorId ?? this.sensorId,
    );
  }
}

class EmergencyVehicle {
  final String id;
  final EmergencyVehicleType type;
  final String currentLocation;
  final String destination;
  final int speed;
  final bool isActive;
  final bool respondingToEmergency;
  
  const EmergencyVehicle({
    required this.id,
    required this.type,
    required this.currentLocation,
    required this.destination,
    required this.speed,
    required this.isActive,
    required this.respondingToEmergency,
  });
}

class TrafficControlAction {
  final String id;
  final TrafficActionType type;
  final String location;
  final String description;
  final EmergencyPriority priority;
  final DateTime timestamp;
  final Duration estimatedDuration;
  
  const TrafficControlAction({
    required this.id,
    required this.type,
    required this.location,
    required this.description,
    required this.priority,
    required this.timestamp,
    required this.estimatedDuration,
  });
}

class Coordinates {
  final double latitude;
  final double longitude;
  
  const Coordinates({
    required this.latitude,
    required this.longitude,
  });
}

// Enums

enum EmergencyVehicleType {
  ambulance,
  fireEngine,
  policeVehicle,
  paramedicsUnit,
  rescueVehicle,
}

enum EmergencyDetectionMethod {
  rfTransponder,
  audioSiren,
  manual,
  simulation,
}

enum EmergencyPriority {
  critical,
  high,
  medium,
  low,
}

enum TrafficActionType {
  signalOverride,
  laneControl,
  publicNotification,
  speedLimitAdjustment,
}

// Extensions for better display
extension EmergencyVehicleTypeExtension on EmergencyVehicleType {
  String get name {
    switch (this) {
      case EmergencyVehicleType.ambulance:
        return 'Ambulance';
      case EmergencyVehicleType.fireEngine:
        return 'Fire Engine';
      case EmergencyVehicleType.policeVehicle:
        return 'Police Vehicle';
      case EmergencyVehicleType.paramedicsUnit:
        return 'Paramedics Unit';
      case EmergencyVehicleType.rescueVehicle:
        return 'Rescue Vehicle';
    }
  }
  
  String get icon {
    switch (this) {
      case EmergencyVehicleType.ambulance:
        return '🚑';
      case EmergencyVehicleType.fireEngine:
        return '🚒';
      case EmergencyVehicleType.policeVehicle:
        return '🚓';
      case EmergencyVehicleType.paramedicsUnit:
        return '🚑';
      case EmergencyVehicleType.rescueVehicle:
        return '🚁';
    }
  }
}

extension EmergencyPriorityExtension on EmergencyPriority {
  String get name {
    switch (this) {
      case EmergencyPriority.critical:
        return 'CRITICAL';
      case EmergencyPriority.high:
        return 'HIGH';
      case EmergencyPriority.medium:
        return 'MEDIUM';
      case EmergencyPriority.low:
        return 'LOW';
    }
  }
}