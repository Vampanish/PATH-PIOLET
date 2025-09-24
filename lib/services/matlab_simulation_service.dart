import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as path;

class MatlabSimulationService {
  static final MatlabSimulationService _instance = MatlabSimulationService._internal();
  factory MatlabSimulationService() => _instance;
  MatlabSimulationService._internal();

  Process? _matlabProcess;
  final StreamController<int> _vehicleCountController = StreamController<int>.broadcast();
  final StreamController<Map<String, dynamic>> _simulationDataController = 
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<bool> _simulationStatusController = StreamController<bool>.broadcast();

  // Streams to expose simulation data
  Stream<int> get vehicleCountStream => _vehicleCountController.stream;
  Stream<Map<String, dynamic>> get simulationDataStream => _simulationDataController.stream;
  Stream<bool> get simulationStatusStream => _simulationStatusController.stream;

  bool _isRunning = false;
  Timer? _simulationTimer;
  int _currentVehicleCount = 0;

  bool get isRunning => _isRunning;
  int get currentVehicleCount => _currentVehicleCount;

  // Start the MATLAB simulation
  Future<bool> startSimulation() async {
    if (_isRunning) {
      print('Simulation is already running');
      return true;
    }

    try {
      // Get the path to drivsim.mat file
      final String projectRoot = Directory.current.path;
      final String matFilePath = path.join(projectRoot, 'drivsim.mat');
      
      if (!await File(matFilePath).exists()) {
        print('drivsim.mat file not found at: $matFilePath');
        return false;
      }

      // Check if MATLAB is available
      final matlabPath = await _findMatlabPath();
      if (matlabPath == null) {
        print('MATLAB not found in system PATH');
        // Fallback to simulation mode without actual MATLAB
        await _startSimulationMode();
        return true;
      }

      // Start MATLAB process with the simulation file
      _matlabProcess = await Process.start(
        matlabPath,
        [
          '-batch', // Run MATLAB in batch mode
          'load(\'$matFilePath\'); run_lidar_simulation();', // Load and run simulation
          '-nodesktop',
          '-nosplash',
          '-minimize'
        ],
        workingDirectory: projectRoot,
      );

      _isRunning = true;
      _simulationStatusController.add(true);

      // Listen to MATLAB output
      _matlabProcess!.stdout.transform(utf8.decoder).listen((data) {
        _processMatlabOutput(data);
      });

      _matlabProcess!.stderr.transform(utf8.decoder).listen((data) {
        print('MATLAB Error: $data');
      });

      // Handle process exit
      _matlabProcess!.exitCode.then((exitCode) {
        print('MATLAB process exited with code: $exitCode');
        _stopSimulation();
      });

      print('MATLAB simulation started successfully');
      return true;

    } catch (e) {
      print('Error starting MATLAB simulation: $e');
      // Fallback to simulation mode
      await _startSimulationMode();
      return true;
    }
  }

  // Fallback simulation mode (for demo purposes when MATLAB is not available)
  Future<void> _startSimulationMode() async {
    _isRunning = true;
    _simulationStatusController.add(true);
    
    // Simulate LIDAR vehicle detection with random data
    _simulationTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (!_isRunning) {
        timer.cancel();
        return;
      }

      // Simulate vehicle count changes (0-25 vehicles)
      final random = DateTime.now().millisecondsSinceEpoch % 100;
      _currentVehicleCount = 5 + (random % 20); // Random between 5-25
      
      _vehicleCountController.add(_currentVehicleCount);

      // Simulate 3D simulation data
      final simulationData = {
        'timestamp': DateTime.now().toIso8601String(),
        'vehicleCount': _currentVehicleCount,
        'lidarPoints': _generateMockLidarData(),
        'detectedVehicles': _generateMockVehiclePositions(),
        'sensorStatus': 'Active',
        'accuracy': 0.85 + (random % 15) / 100, // 85-99% accuracy
      };

      _simulationDataController.add(simulationData);
    });

    print('Started simulation mode (MATLAB fallback)');
  }

  // Generate mock LIDAR point cloud data
  List<Map<String, double>> _generateMockLidarData() {
    final points = <Map<String, double>>[];
    final random = DateTime.now().millisecondsSinceEpoch;
    
    for (int i = 0; i < 1000; i++) {
      points.add({
        'x': -50.0 + (random + i) % 100,
        'y': -50.0 + (random + i * 2) % 100,
        'z': 0.0 + (random + i * 3) % 10,
        'intensity': 0.1 + (random + i) % 90 / 100.0,
      });
    }
    
    return points;
  }

  // Generate mock vehicle positions
  List<Map<String, dynamic>> _generateMockVehiclePositions() {
    final vehicles = <Map<String, dynamic>>[];
    final random = DateTime.now().millisecondsSinceEpoch;
    
    for (int i = 0; i < _currentVehicleCount; i++) {
      vehicles.add({
        'id': 'vehicle_$i',
        'x': -30.0 + (random + i * 10) % 60,
        'y': -30.0 + (random + i * 15) % 60,
        'z': 0.0,
        'confidence': 0.7 + (random + i) % 30 / 100.0,
        'type': ['car', 'truck', 'motorcycle'][(random + i) % 3],
      });
    }
    
    return vehicles;
  }

  // Process MATLAB output to extract vehicle count and simulation data
  void _processMatlabOutput(String output) {
    try {
      // Look for vehicle count in MATLAB output
      final vehicleCountMatch = RegExp(r'VEHICLE_COUNT:\s*(\d+)').firstMatch(output);
      if (vehicleCountMatch != null) {
        _currentVehicleCount = int.parse(vehicleCountMatch.group(1)!);
        _vehicleCountController.add(_currentVehicleCount);
      }

      // Look for JSON simulation data in MATLAB output
      final jsonMatch = RegExp(r'SIMULATION_DATA:\s*(\{.*\})').firstMatch(output);
      if (jsonMatch != null) {
        final data = jsonDecode(jsonMatch.group(1)!);
        _simulationDataController.add(data);
      }

    } catch (e) {
      print('Error processing MATLAB output: $e');
    }
  }

  // Find MATLAB installation path
  Future<String?> _findMatlabPath() async {
    try {
      final result = await Process.run('where', ['matlab'], runInShell: true);
      if (result.exitCode == 0 && result.stdout.toString().isNotEmpty) {
        return result.stdout.toString().trim().split('\n').first;
      }
    } catch (e) {
      print('Error finding MATLAB: $e');
    }
    
    // Try common MATLAB installation paths
    final commonPaths = [
      r'C:\Program Files\MATLAB\R2023b\bin\matlab.exe',
      r'C:\Program Files\MATLAB\R2024a\bin\matlab.exe',
      r'C:\Program Files\MATLAB\R2024b\bin\matlab.exe',
      r'C:\Program Files\MATLAB\R2025a\bin\matlab.exe',
    ];

    for (final matlabPath in commonPaths) {
      if (await File(matlabPath).exists()) {
        return matlabPath;
      }
    }

    return null;
  }

  // Stop the simulation
  Future<void> stopSimulation() async {
    await _stopSimulation();
  }

  Future<void> _stopSimulation() async {
    _isRunning = false;
    _simulationStatusController.add(false);
    
    _simulationTimer?.cancel();
    _simulationTimer = null;

    if (_matlabProcess != null) {
      _matlabProcess!.kill();
      _matlabProcess = null;
    }

    print('Simulation stopped');
  }

  // Restart the simulation
  Future<bool> restartSimulation() async {
    await stopSimulation();
    await Future.delayed(const Duration(seconds: 1));
    return await startSimulation();
  }

  // Clean up resources
  void dispose() {
    _stopSimulation();
    _vehicleCountController.close();
    _simulationDataController.close();
    _simulationStatusController.close();
  }
}