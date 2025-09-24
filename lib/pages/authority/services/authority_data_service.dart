import 'dart:async';
import 'dart:math';
import '../../../services/ai_traffic_monitoring_service.dart';
import '../../../services/iot_sensor_manager.dart';
import '../../../services/computer_vision_engine.dart';

class AuthorityDataService {
  AuthorityDataService._();
  static final instance = AuthorityDataService._();
  final _rng = Random();

  // Stats streams (existing dashboard)
  final _vehiclesCtrl = StreamController<num>.broadcast();
  final _avgCommuteCtrl = StreamController<num>.broadcast();
  final _avgWaitCtrl = StreamController<num>.broadcast();

  // Intersections
  final _intersectionsCtrl = StreamController<List<IntersectionState>>.broadcast();
  List<IntersectionState> _intersections = [];

  // Alerts
  final _alertsCtrl = StreamController<AlertItem>.broadcast();

  // AI Integration
  final _aiAlertsCtrl = StreamController<AIGeneratedAlert>.broadcast();
  final _trafficHeatmapCtrl = StreamController<TrafficHeatmap>.broadcast();
  
  // Last action log (for overrides / mode changes)
  final _lastActionCtrl = StreamController<String>.broadcast();
  String? _lastAction;

  // Global modes
  bool aiMode = true; // Global AI vs Manual (manual still allows per-signal overrides)
  bool emergencyMode = false; // When true all signals are forced RED

  Stream<num> get vehiclesOnRoadStream => _vehiclesCtrl.stream;
  Stream<num> get avgCommuteTimeStream => _avgCommuteCtrl.stream;
  Stream<num> get avgSignalWaitStream => _avgWaitCtrl.stream;
  Stream<List<IntersectionState>> get intersectionsStream => _intersectionsCtrl.stream;
  Stream<AlertItem> get alertsStream => _alertsCtrl.stream;
  Stream<AIGeneratedAlert> get aiAlertsStream => _aiAlertsCtrl.stream;
  Stream<TrafficHeatmap> get trafficHeatmapStream => _trafficHeatmapCtrl.stream;
  Stream<String> get lastActionStream => _lastActionCtrl.stream;
  String? get lastAction => _lastAction;

  Timer? _ticker;
  Timer? _alertTicker;
  Timer? _aiIntegrationTimer;

  void start() {
    if (_ticker != null) return;
    _seed();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    _alertTicker = Timer.periodic(const Duration(seconds: 7), (_) => _maybeAlert());
    _startAIIntegration();
  }
  
  void _startAIIntegration() {
    // Initialize AI services
    AITrafficMonitoringService.instance.initialize();
    IoTSensorManager.instance.initialize();
    
    // Listen to AI-generated alerts
    AITrafficMonitoringService.instance.aiAlertsStream.listen((aiAlert) {
      _processAIAlert(aiAlert);
    });
    
    // Listen to CV analysis for heatmap updates
    AITrafficMonitoringService.instance.cvAnalysisStream.listen((cvData) {
      _updateTrafficHeatmap(cvData);
    });
    
    // Listen to IoT sensor data for system status
    IoTSensorManager.instance.sensorDataStream.listen((sensorData) {
      _processSensorData(sensorData);
    });
    
    // Regular AI analysis for patterns
    _aiIntegrationTimer = Timer.periodic(const Duration(seconds: 10), (_) => _performAIAnalysis());
  }

  void dispose() {
    _ticker?.cancel();
    _alertTicker?.cancel();
    _aiIntegrationTimer?.cancel();
    AITrafficMonitoringService.instance.dispose();
    IoTSensorManager.instance.dispose();
  }

  // --- Public control APIs ---

  void setAIMode(bool value) {
    aiMode = value;
    _logAction('AI Mode ${value ? 'ENABLED' : 'DISABLED'}');
    _publish();
  }

  void setEmergencyMode(bool value) {
    emergencyMode = value;
    if (value) {
      for (final i in _intersections) {
        i.phase = SignalPhase.red;
        i.remainingSeconds = 9999; // effectively frozen until released
        i.forcedPhase = SignalPhase.red;
        i.manualOverride = true;
      }
      _logAction('EMERGENCY MODE ACTIVATED (All RED)');
    } else {
      for (final i in _intersections) {
        i.remainingSeconds = 10 + _rng.nextInt(30);
        i.manualOverride = false;
        i.forcedPhase = null;
      }
      _logAction('Emergency mode cleared, returning to ${aiMode ? 'AI control' : 'manual'}');
    }
    _publish();
  }

  void resetToDefaults() {
    setEmergencyMode(false);
    setAIMode(true);
    for (final i in _intersections) {
      i.manualOverride = false;
      i.forcedPhase = null;
    }
    _logAction('System reset to AI defaults');
    _publish();
  }

  void addIntersection() {
    final nextIndex = _intersections.length + 1;
    final state = IntersectionState(
      id: 'I$nextIndex',
      name: 'Junction $nextIndex',
      phase: SignalPhase.values[_rng.nextInt(3)],
      remainingSeconds: 10 + _rng.nextInt(40),
      cycleSeconds: 60,
      vehicleCount: 20 + _rng.nextInt(200),
      queueLength: 1 + _rng.nextInt(25),
      lastUpdated: DateTime.now(),
    );
    _intersections.add(state);
    _logAction('Added new signal ${state.id}');
    _publish();
  }

  void forcePhase(String id, SignalPhase phase) {
    final idx = _intersections.indexWhere((e) => e.id == id);
    if (idx == -1) return;
    final i = _intersections[idx];
    i.phase = phase;
    i.remainingSeconds = phase == SignalPhase.green ? 25 : phase == SignalPhase.yellow ? 5 : 30;
    i.manualOverride = true;
    i.forcedPhase = phase;
    i.lastAction = 'Forced ${phase.name.toUpperCase()}';
    i.lastActionAt = DateTime.now();
    _logAction('Override ${i.id} -> ${phase.name.toUpperCase()}');
    _publish();
  }

  void releaseOverride(String id) {
    final idx = _intersections.indexWhere((e) => e.id == id);
    if (idx == -1) return;
    final i = _intersections[idx];
    i.manualOverride = false;
    i.forcedPhase = null;
    i.lastAction = 'Override released';
    i.lastActionAt = DateTime.now();
    _logAction('Override released on ${i.id}');
    _publish();
  }

  // --- Internal logic ---

  void _seed() {
    _intersections = List.generate(12, (i) => IntersectionState(
          id: 'I${i + 1}',
          name: 'Junction ${i + 1}',
          phase: SignalPhase.values[_rng.nextInt(3)],
          remainingSeconds: 10 + _rng.nextInt(40),
          cycleSeconds: 60,
          vehicleCount: 20 + _rng.nextInt(200),
          queueLength: 1 + _rng.nextInt(25),
          lastUpdated: DateTime.now(),
        ));
    _publish();
  }

  void _tick() {
    // Update stats
    _vehiclesCtrl.add(1000 + _rng.nextInt(500));
    _avgCommuteCtrl.add(15 + _rng.nextInt(20));
    _avgWaitCtrl.add(30 + _rng.nextInt(40));

    // If emergency mode we only update timestamps & maybe slight counts
    for (final i in _intersections) {
      if (!emergencyMode) {
        // Only AI progression if global AI and not manual override for that signal
        if (aiMode && !i.manualOverride) {
          i.remainingSeconds -= 1;
          if (i.remainingSeconds <= 0) {
            switch (i.phase) {
              case SignalPhase.green:
                i.phase = SignalPhase.yellow;
                i.remainingSeconds = 5;
                break;
              case SignalPhase.yellow:
                i.phase = SignalPhase.red;
                i.remainingSeconds = 30;
                break;
              case SignalPhase.red:
                i.phase = SignalPhase.green;
                i.remainingSeconds = 25;
                break;
            }
            i.lastAction = 'Auto -> ${i.phase.name.toUpperCase()}';
            i.lastActionAt = DateTime.now();
          }
        }
      }

      // Simulate flow changes
      final old = i.vehicleCount;
      i.vehicleCount = (i.vehicleCount + _rng.nextInt(40) - 15).clamp(0, 500);
      i.queueLength = (i.queueLength + _rng.nextInt(10) - 3).clamp(0, 60);
      final delta = i.vehicleCount - old;
      i.flowRatePerTick = delta; // simplistic delta
      i.history.add(i.vehicleCount);
      if (i.history.length > 30) i.history.removeAt(0);
      i.lastUpdated = DateTime.now();

      // Derive anomaly flags
      i.zeroFlow = i.vehicleCount == 0;
      i.jammed = i.queueLength > 45 || (i.queueLength > 25 && i.phase == SignalPhase.red && i.remainingSeconds > 20);
    }
    _publish();
  }

  void _publish() {
    _intersectionsCtrl.add(List.unmodifiable(_intersections));
  }

  void _maybeAlert() {
    final roll = _rng.nextDouble();
    if (roll < 0.5) {
      final severity = roll < 0.15 ? AlertSeverity.critical : AlertSeverity.warning;
      _alertsCtrl.add(AlertItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: severity == AlertSeverity.critical ? 'Accident Detected' : 'Unusual Congestion',
        description: severity == AlertSeverity.critical
            ? 'Collision near Junction ${_rng.nextInt(_intersections.length) + 1}'
            : 'Heavy build-up at Junction ${_rng.nextInt(_intersections.length) + 1}',
        severity: severity,
        timestamp: DateTime.now(),
      ));
    }
  }

  void _logAction(String msg) {
    _lastAction = '${DateTime.now().toIso8601String()}  $msg';
    _lastActionCtrl.add(_lastAction!);
  }
  
  // --- AI Integration Methods ---
  
  void _processAIAlert(AIGeneratedAlert aiAlert) {
    // Convert AI alert to authority alert
    final authorityAlert = AlertItem(
      id: aiAlert.id,
      title: aiAlert.title,
      description: '${aiAlert.description}\n\nSource: ${aiAlert.sourceType.name} (${aiAlert.sourceId})\nConfidence: ${(aiAlert.confidence * 100).toInt()}%\nLocation: ${aiAlert.location['lat']?.toStringAsFixed(4)}, ${aiAlert.location['lng']?.toStringAsFixed(4)}',
      severity: aiAlert.severity,
      timestamp: aiAlert.timestamp,
    );
    
    _alertsCtrl.add(authorityAlert);
    _aiAlertsCtrl.add(aiAlert);
    
    // Update intersection states based on AI alerts
    _updateIntersectionsFromAIAlert(aiAlert);
    
    _logAction('AI Alert: ${aiAlert.type.name} detected at ${aiAlert.sourceId}');
  }
  
  void _updateIntersectionsFromAIAlert(AIGeneratedAlert aiAlert) {
    // Find nearby intersections and update their status
    for (final intersection in _intersections) {
      // Simulate proximity check (in real implementation, use actual coordinates)
      if (_rng.nextDouble() < 0.3) { // 30% chance this intersection is affected
        switch (aiAlert.type) {
          case AIAlertType.accident:
            intersection.jammed = true;
            intersection.queueLength = (intersection.queueLength * 1.5).round().clamp(0, 60);
            break;
          case AIAlertType.heavyCongestion:
            intersection.jammed = true;
            intersection.vehicleCount = (intersection.vehicleCount * 1.3).round().clamp(0, 500);
            break;
          case AIAlertType.stalledVehicle:
            intersection.queueLength = (intersection.queueLength + 10).clamp(0, 60);
            break;
          case AIAlertType.sensorFailure:
            // Mark as requiring manual override
            if (!intersection.manualOverride) {
              intersection.lastAction = 'Sensor failure - manual check required';
              intersection.lastActionAt = DateTime.now();
            }
            break;
          case AIAlertType.unusualPattern:
            // Adjust signal timing
            intersection.remainingSeconds = (intersection.remainingSeconds * 0.8).round().clamp(5, 120);
            break;
        }
      }
    }
  }
  
  void _updateTrafficHeatmap(CVAnalysisResult cvData) {
    // Process CV data for heatmap generation
    // This would be called periodically to generate comprehensive heatmaps
    _generateTrafficHeatmap();
  }
  
  void _processSensorData(IoTSensorData sensorData) {
    if (!sensorData.isHealthy) {
      // Generate sensor failure alert
      final sensorFailureAlert = AlertItem(
        id: 'SENSOR_${sensorData.sensorId}_${DateTime.now().millisecondsSinceEpoch}',
        title: 'IoT Sensor Failure',
        description: 'Sensor ${sensorData.sensorId} (${sensorData.sensorType.name}) has failed. Battery: ${sensorData.batteryLevel}%, Signal: ${sensorData.signalStrength}%',
        severity: sensorData.batteryLevel < 10 ? AlertSeverity.critical : AlertSeverity.warning,
        timestamp: sensorData.timestamp,
      );
      
      _alertsCtrl.add(sensorFailureAlert);
    }
    
    // Update intersection data with sensor readings
    _updateIntersectionsFromSensorData(sensorData);
  }
  
  void _updateIntersectionsFromSensorData(IoTSensorData sensorData) {
    // Find relevant intersection for this sensor
    final relevantIntersection = _intersections[_rng.nextInt(_intersections.length)];
    
    switch (sensorData.sensorType) {
      case IoTSensorType.vehicleCounter:
        if (sensorData.isHealthy) {
          relevantIntersection.vehicleCount = sensorData.value.round();
        }
        break;
      case IoTSensorType.signalTimer:
        if (sensorData.isHealthy && !relevantIntersection.manualOverride) {
          // Update timing based on sensor data
          relevantIntersection.remainingSeconds = sensorData.value.round();
        }
        break;
      case IoTSensorType.accidentDetector:
        if (sensorData.value == 1.0) {
          // Accident detected
          relevantIntersection.jammed = true;
          relevantIntersection.lastAction = 'Accident detected by sensor';
          relevantIntersection.lastActionAt = DateTime.now();
        }
        break;
      case IoTSensorType.speedSensor:
        // Update flow rate based on speed
        if (sensorData.isHealthy) {
          final speedFactor = (sensorData.value / 50.0).clamp(0.1, 2.0);
          relevantIntersection.flowRatePerTick = (relevantIntersection.flowRatePerTick * speedFactor).round();
        }
        break;
      case IoTSensorType.pollutionSensor:
        // High pollution might indicate heavy congestion
        if (sensorData.value > 200) {
          relevantIntersection.queueLength = (relevantIntersection.queueLength + 5).clamp(0, 60);
        }
        break;
    }
  }
  
  void _performAIAnalysis() {
    // Generate comprehensive traffic heatmap
    _generateTrafficHeatmap();
    
    // Analyze patterns and predict traffic flow
    _analyzeTrafficPatterns();
    
    // Update AI recommendations
    _generateAIRecommendations();
  }
  
  void _generateTrafficHeatmap() {
    final heatmapData = <String, double>{};
    
    // Generate heatmap based on intersection data
    for (final intersection in _intersections) {
      final congestionLevel = _calculateIntersectionCongestion(intersection);
      heatmapData[intersection.id] = congestionLevel;
    }
    
    final overallCongestion = heatmapData.values.isNotEmpty 
        ? heatmapData.values.reduce((a, b) => a + b) / heatmapData.length 
        : 0.0;
    
    final heatmap = TrafficHeatmap(
      timestamp: DateTime.now(),
      heatmapData: heatmapData,
      overallCongestionLevel: overallCongestion,
    );
    
    _trafficHeatmapCtrl.add(heatmap);
  }
  
  double _calculateIntersectionCongestion(IntersectionState intersection) {
    // Calculate congestion based on multiple factors
    final densityFactor = (intersection.vehicleCount / 200.0).clamp(0.0, 1.0);
    final queueFactor = (intersection.queueLength / 40.0).clamp(0.0, 1.0);
    final jammedFactor = intersection.jammed ? 0.8 : 0.0;
    
    return ((densityFactor * 0.4) + (queueFactor * 0.4) + (jammedFactor * 0.2)).clamp(0.0, 1.0);
  }
  
  void _analyzeTrafficPatterns() {
    // Analyze historical data for patterns
    final currentHour = DateTime.now().hour;
    final isRushHour = (currentHour >= 7 && currentHour <= 9) || (currentHour >= 17 && currentHour <= 19);
    
    if (isRushHour) {
      // During rush hour, be more proactive with signal timing
      for (final intersection in _intersections.where((i) => !i.manualOverride)) {
        if (intersection.queueLength > 30) {
          // Extend green phase for heavily congested intersections
          if (intersection.phase == SignalPhase.green) {
            intersection.remainingSeconds = (intersection.remainingSeconds + 10).clamp(5, 60);
          }
        }
      }
    }
  }
  
  void _generateAIRecommendations() {
    // Generate recommendations based on current traffic state
    final heavilyCongested = _intersections.where((i) => i.jammed || i.queueLength > 35).toList();
    
    if (heavilyCongested.length > _intersections.length * 0.3) {
      // More than 30% of intersections are congested
      _logAction('AI Recommendation: Consider activating emergency traffic management protocols');
      
      // Generate system-wide recommendation alert
      final recommendationAlert = AlertItem(
        id: 'AI_REC_${DateTime.now().millisecondsSinceEpoch}',
        title: 'AI Traffic Management Recommendation',
        description: 'High congestion detected across ${heavilyCongested.length} intersections. Consider activating coordinated signal timing or emergency protocols.',
        severity: AlertSeverity.warning,
        timestamp: DateTime.now(),
      );
      
      _alertsCtrl.add(recommendationAlert);
    }
  }
}

class IntersectionState {
  final String id;
  final String name;
  SignalPhase phase;
  int remainingSeconds;
  int cycleSeconds;
  int vehicleCount;
  int queueLength;
  DateTime lastUpdated;

  // Enhanced analytics data
  final List<int> history = [];
  int flowRatePerTick = 0; // delta of vehicle count since last tick

  // Control meta
  bool manualOverride = false;
  SignalPhase? forcedPhase;
  String? lastAction; // last action description
  DateTime? lastActionAt;

  // Derived alert flags
  bool jammed = false;
  bool zeroFlow = false;

  IntersectionState({
    required this.id,
    required this.name,
    required this.phase,
    required this.remainingSeconds,
    required this.cycleSeconds,
    required this.vehicleCount,
    required this.queueLength,
    required this.lastUpdated,
  });

  SignalPhase get predictedNextPhase {
    switch (phase) {
      case SignalPhase.green:
        return SignalPhase.yellow;
      case SignalPhase.yellow:
        return SignalPhase.red;
      case SignalPhase.red:
        return SignalPhase.green;
    }
  }
}

enum SignalPhase { green, yellow, red }

enum AlertSeverity { info, warning, critical }

class AlertItem {
  final String id;
  final String title;
  final String description;
  final AlertSeverity severity;
  final DateTime timestamp;
  bool resolved;
  AlertItem({
    required this.id,
    required this.title,
    required this.description,
    required this.severity,
    required this.timestamp,
    this.resolved = false,
  });
}

// Ensure service starts automatically
final _autoStart = AuthorityDataService.instance..start();
