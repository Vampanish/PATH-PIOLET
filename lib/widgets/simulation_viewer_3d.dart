import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../services/matlab_simulation_service.dart';

class SimulationViewer3D extends StatefulWidget {
  const SimulationViewer3D({Key? key}) : super(key: key);

  @override
  State<SimulationViewer3D> createState() => _SimulationViewer3DState();
}

class _SimulationViewer3DState extends State<SimulationViewer3D> {
  final MatlabSimulationService _simulationService = MatlabSimulationService();
  
  Map<String, dynamic>? _currentSimulationData;
  bool _isSimulationRunning = false;
  double _rotationX = -0.4; // Fixed nice viewing angle from above
  double _rotationY = 0.8; // Fixed side angle for good perspective
  double _scale = 1.0;

  @override
  void initState() {
    super.initState();

    // Listen to simulation data
    _simulationService.simulationDataStream.listen((data) {
      if (mounted) {
        setState(() {
          _currentSimulationData = data;
        });
      }
    });

    // Listen to simulation status
    _simulationService.simulationStatusStream.listen((isRunning) {
      if (mounted) {
        setState(() {
          _isSimulationRunning = isRunning;
        });
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.black87,
        border: Border.all(color: Colors.grey.withOpacity(0.3)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            // 3D Simulation View
            GestureDetector(
              onScaleStart: (details) {
                // Initialize scale gesture
              },
              onScaleUpdate: (details) {
                setState(() {
                  // Handle rotation (pan)
                  if (details.scale == 1.0) {
                    _rotationY += details.focalPointDelta.dx * 0.01;
                    _rotationX += details.focalPointDelta.dy * 0.01;
                    _rotationX = _rotationX.clamp(-math.pi / 2, math.pi / 2);
                  }
                  // Handle scaling
                  _scale = (_scale * details.scale).clamp(0.5, 3.0);
                });
              },
              child: CustomPaint(
                size: Size.infinite,
                painter: Realistic3DPainter(
                  simulationData: _currentSimulationData,
                  rotationX: _rotationX,
                  rotationY: _rotationY,
                  scale: _scale,
                  isRunning: _isSimulationRunning,
                ),
              ),
            ),
            
            // Status overlay
            Positioned(
              top: 10,
              right: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _isSimulationRunning ? Colors.green : Colors.red,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _isSimulationRunning ? 'LIVE' : 'STOPPED',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            
            // 3D Controls overlay
            Positioned(
              bottom: 10,
              left: 10,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '3D Controls:',
                      style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                    const Text('• Pinch: Zoom', style: TextStyle(color: Colors.white70, fontSize: 8)),
                    const Text('• Pan: Rotate view', style: TextStyle(color: Colors.white70, fontSize: 8)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class Realistic3DPainter extends CustomPainter {
  final Map<String, dynamic>? simulationData;
  final double rotationX;
  final double rotationY;
  final double scale;
  final bool isRunning;

  Realistic3DPainter({
    this.simulationData,
    required this.rotationX,
    required this.rotationY,
    required this.scale,
    required this.isRunning,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    if (!isRunning || simulationData == null) {
      _drawNoSignalMessage(canvas, size);
      return;
    }

    // Draw 3D environment
    _draw3DEnvironment(canvas, size, center);
    
    // Draw LIDAR points as 3D point cloud
    if (simulationData!.containsKey('lidarPoints')) {
      _draw3DLidarPoints(canvas, size, center, simulationData!['lidarPoints']);
    }
    
    // Draw realistic 3D vehicles
    if (simulationData!.containsKey('detectedVehicles')) {
      _draw3DVehicles(canvas, size, center, simulationData!['detectedVehicles']);
    }
    
    // Draw LIDAR sensor
    _drawLidarSensor(canvas, size, center);
  }

  void _drawNoSignalMessage(Canvas canvas, Size size) {
    final textPainter = TextPainter(
      text: const TextSpan(
        text: 'LIDAR SIMULATION STOPPED\n\nClick start to begin 3D vehicle detection',
        style: TextStyle(
          color: Colors.grey,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        size.width / 2 - textPainter.width / 2,
        size.height / 2 - textPainter.height / 2,
      ),
    );
  }

  void _draw3DEnvironment(Canvas canvas, Size size, Offset center) {
    // Draw realistic 3D road
    _draw3DRoadway(canvas, size, center);
    
    // Draw 3D buildings
    _draw3DBuildings(canvas, size, center);
    
    // Draw coordinate axes
    _draw3DAxes(canvas, size, center);
  }

  void _draw3DRoadway(Canvas canvas, Size size, Offset center) {
    // Main road surface - realistic asphalt
    final roadVertices = [
      _project3D(Point3D(-100, -15, 0), center, size),
      _project3D(Point3D(100, -15, 0), center, size),
      _project3D(Point3D(100, 15, 0), center, size),
      _project3D(Point3D(-100, 15, 0), center, size),
    ];

    final roadPath = Path();
    roadPath.moveTo(roadVertices[0].dx, roadVertices[0].dy);
    for (int i = 1; i < roadVertices.length; i++) {
      roadPath.lineTo(roadVertices[i].dx, roadVertices[i].dy);
    }
    roadPath.close();

    // Road texture with gradient
    final roadGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Colors.grey[700]!,
        Colors.grey[800]!,
        Colors.grey[900]!,
      ],
    );

    final roadPaint = Paint()
      ..shader = roadGradient.createShader(_getBounds(roadVertices))
      ..style = PaintingStyle.fill;

    canvas.drawPath(roadPath, roadPaint);

    // Road markings - lane dividers
    _drawRoadMarkings(canvas, size, center);
  }

  void _drawRoadMarkings(Canvas canvas, Size size, Offset center) {
    final markingPaint = Paint()
      ..color = Colors.white.withOpacity(0.9)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // Center dashed line
    for (double x = -100; x <= 100; x += 10) {
      final start = _project3D(Point3D(x, 0, 0.1), center, size);
      final end = _project3D(Point3D(x + 5, 0, 0.1), center, size);
      canvas.drawLine(start, end, markingPaint);
    }

    // Side lines (solid)
    markingPaint.strokeWidth = 3;
    final leftLine = [
      _project3D(Point3D(-100, -12, 0.1), center, size),
      _project3D(Point3D(100, -12, 0.1), center, size),
    ];
    final rightLine = [
      _project3D(Point3D(-100, 12, 0.1), center, size),
      _project3D(Point3D(100, 12, 0.1), center, size),
    ];

    canvas.drawLine(leftLine[0], leftLine[1], markingPaint);
    canvas.drawLine(rightLine[0], rightLine[1], markingPaint);
  }

  void _draw3DBuildings(Canvas canvas, Size size, Offset center) {
    final buildings = [
      // Left side buildings
      {'pos': Point3D(-40, -35, 0), 'size': [12, 8, 20], 'color': Colors.grey[600]!},
      {'pos': Point3D(-20, -40, 0), 'size': [10, 6, 25], 'color': Colors.grey[500]!},
      {'pos': Point3D(-60, -30, 0), 'size': [15, 10, 18], 'color': Colors.grey[700]!},
      
      // Right side buildings
      {'pos': Point3D(35, 30, 0), 'size': [14, 9, 22], 'color': Colors.grey[600]!},
      {'pos': Point3D(55, 35, 0), 'size': [8, 6, 15], 'color': Colors.grey[500]!},
      {'pos': Point3D(15, 35, 0), 'size': [12, 8, 28], 'color': Colors.grey[700]!},
    ];

    for (final building in buildings) {
      _draw3DBuilding(
        canvas, size, center,
        building['pos'] as Point3D,
        building['size'] as List<num>,
        building['color'] as Color,
      );
    }
  }

  void _draw3DBuilding(Canvas canvas, Size size, Offset center, Point3D position, List<num> dimensions, Color color) {
    final length = dimensions[0].toDouble();
    final width = dimensions[1].toDouble();
    final height = dimensions[2].toDouble();

    final vertices = [
      // Bottom face
      Point3D(position.x - length/2, position.y - width/2, position.z),
      Point3D(position.x + length/2, position.y - width/2, position.z),
      Point3D(position.x + length/2, position.y + width/2, position.z),
      Point3D(position.x - length/2, position.y + width/2, position.z),
      // Top face
      Point3D(position.x - length/2, position.y - width/2, position.z + height),
      Point3D(position.x + length/2, position.y - width/2, position.z + height),
      Point3D(position.x + length/2, position.y + width/2, position.z + height),
      Point3D(position.x - length/2, position.y + width/2, position.z + height),
    ];

    final projectedVertices = vertices.map((v) => _project3D(v, center, size)).toList();

    final buildingPaint = Paint()
      ..color = color.withOpacity(0.7)
      ..style = PaintingStyle.fill;

    final buildingOutline = Paint()
      ..color = color.withOpacity(0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    _draw3DBox(canvas, projectedVertices, buildingPaint, buildingOutline);

    // Add windows
    _drawBuildingWindows(canvas, size, center, position, length, width, height);
  }

  void _drawBuildingWindows(Canvas canvas, Size size, Offset center, Point3D position, double length, double width, double height) {
    final windowPaint = Paint()
      ..color = Colors.yellow.withOpacity(0.8)
      ..style = PaintingStyle.fill;

    // Front face windows
    for (int i = 0; i < 3; i++) {
      for (int j = 0; j < (height / 5).floor(); j++) {
        final windowPos = _project3D(
          Point3D(
            position.x - length*0.4 + i * (length * 0.3),
            position.y - width*0.45,
            position.z + 2 + j * 4,
          ),
          center, size
        );
        canvas.drawRect(
          Rect.fromCenter(center: windowPos, width: 3, height: 2),
          windowPaint,
        );
      }
    }
  }

  void _draw3DAxes(Canvas canvas, Size size, Offset center) {
    final axisPaint = Paint()
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final origin = _project3D(Point3D(0, 0, 0), center, size);
    
    // X-axis (red) - Forward/Backward
    axisPaint.color = Colors.red;
    final xEnd = _project3D(Point3D(25, 0, 0), center, size);
    canvas.drawLine(origin, xEnd, axisPaint);
    
    // Y-axis (green) - Left/Right
    axisPaint.color = Colors.green;
    final yEnd = _project3D(Point3D(0, 25, 0), center, size);
    canvas.drawLine(origin, yEnd, axisPaint);
    
    // Z-axis (blue) - Up/Down
    axisPaint.color = Colors.blue;
    final zEnd = _project3D(Point3D(0, 0, 25), center, size);
    canvas.drawLine(origin, zEnd, axisPaint);
  }

  void _draw3DLidarPoints(Canvas canvas, Size size, Offset center, List<dynamic> lidarPoints) {
    final pointPaint = Paint()..style = PaintingStyle.fill;

    for (final point in lidarPoints) {
      final x = (point['x'] as num).toDouble();
      final y = (point['y'] as num).toDouble();
      final z = (point['z'] as num).toDouble();
      final intensity = (point['intensity'] as num).toDouble();

      final screenPos = _project3D(Point3D(x, y, z), center, size);
      
      // Color based on height and intensity - like real LIDAR
      Color pointColor;
      if (z < 0.5) {
        pointColor = Colors.blue.withOpacity(intensity * 0.8); // Ground level
      } else if (z < 2) {
        pointColor = Colors.green.withOpacity(intensity * 0.8); // Vehicle level
      } else {
        pointColor = Colors.red.withOpacity(intensity * 0.8); // High objects
      }
      
      pointPaint.color = pointColor;
      
      // Point size based on distance and intensity
      final distance = math.sqrt(x * x + y * y + z * z);
      final pointSize = math.max(0.5, (5.0 / (1 + distance * 0.02)) * intensity * scale);
      
      canvas.drawCircle(screenPos, pointSize, pointPaint);
      
      // Add glow effect for bright points
      if (intensity > 0.8) {
        pointPaint.color = pointColor.withOpacity(0.3);
        canvas.drawCircle(screenPos, pointSize * 2, pointPaint);
      }
    }
  }

  void _draw3DVehicles(Canvas canvas, Size size, Offset center, List<dynamic> vehicles) {
    for (final vehicle in vehicles) {
      final x = (vehicle['x'] as num).toDouble();
      final y = (vehicle['y'] as num).toDouble();
      final z = (vehicle['z'] as num).toDouble();
      final confidence = (vehicle['confidence'] as num).toDouble();
      final type = vehicle['type'] as String;

      _drawRealistic3DVehicle(canvas, size, center, Point3D(x, y, z), type, confidence);
    }
  }

  void _drawRealistic3DVehicle(Canvas canvas, Size size, Offset center, Point3D position, String type, double confidence) {
    // Get vehicle specifications
    final specs = _getVehicleSpecs(type);
    final length = specs['length']!;
    final width = specs['width']!;
    final height = specs['height']!;
    
    // Draw main vehicle body
    _drawVehicleBody(canvas, size, center, position, length, width, height, type, confidence);
    
    // Draw vehicle details
    _drawVehicleWheels(canvas, size, center, position, length, width, type, confidence);
    _drawVehicleWindows(canvas, size, center, position, length, width, height, confidence);
    _drawVehicleLights(canvas, size, center, position, length, width, confidence);
    
    // Draw vehicle identification
    _drawVehicleLabel(canvas, size, center, position, type, confidence);
  }

  Map<String, double> _getVehicleSpecs(String type) {
    switch (type) {
      case 'car':
        return {'length': 4.5, 'width': 1.8, 'height': 1.5};
      case 'truck':
        return {'length': 8.0, 'width': 2.5, 'height': 3.0};
      case 'bus':
        return {'length': 12.0, 'width': 2.5, 'height': 3.2};
      case 'motorcycle':
        return {'length': 2.0, 'width': 0.8, 'height': 1.2};
      default:
        return {'length': 4.5, 'width': 1.8, 'height': 1.5};
    }
  }

  void _drawVehicleBody(Canvas canvas, Size size, Offset center, Point3D position, double length, double width, double height, String type, double confidence) {
    // Create 3D box vertices
    final vertices = [
      // Bottom face
      Point3D(position.x - length/2, position.y - width/2, position.z),
      Point3D(position.x + length/2, position.y - width/2, position.z),
      Point3D(position.x + length/2, position.y + width/2, position.z),
      Point3D(position.x - length/2, position.y + width/2, position.z),
      // Top face
      Point3D(position.x - length/2, position.y - width/2, position.z + height),
      Point3D(position.x + length/2, position.y - width/2, position.z + height),
      Point3D(position.x + length/2, position.y + width/2, position.z + height),
      Point3D(position.x - length/2, position.y + width/2, position.z + height),
    ];

    final projectedVertices = vertices.map((v) => _project3D(v, center, size)).toList();

    // Vehicle color
    Color vehicleColor = _getVehicleColor(type);

    // Create realistic gradient
    final bounds = _getBounds(projectedVertices);
    final gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        vehicleColor.withOpacity(confidence * 0.9),
        vehicleColor.withOpacity(confidence * 0.7),
        vehicleColor.withOpacity(confidence * 0.5),
      ],
    );

    final bodyPaint = Paint()
      ..shader = gradient.createShader(bounds)
      ..style = PaintingStyle.fill;

    final outlinePaint = Paint()
      ..color = vehicleColor.withOpacity(confidence)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    _draw3DBox(canvas, projectedVertices, bodyPaint, outlinePaint);
  }

  Color _getVehicleColor(String type) {
    switch (type) {
      case 'car':
        return Colors.blue;
      case 'truck':
        return Colors.red;
      case 'bus':
        return Colors.orange;
      case 'motorcycle':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  void _drawVehicleWheels(Canvas canvas, Size size, Offset center, Point3D position, double length, double width, String type, double confidence) {
    final wheelPaint = Paint()
      ..color = Colors.black87.withOpacity(confidence)
      ..style = PaintingStyle.fill;

    final rimPaint = Paint()
      ..color = Colors.grey[400]!.withOpacity(confidence * 0.8)
      ..style = PaintingStyle.fill;

    // Wheel size based on vehicle type
    final wheelRadius = type == 'truck' || type == 'bus' ? 0.7 : 
                       type == 'motorcycle' ? 0.4 : 0.5;
    
    final wheelOffset = length * 0.35;
    final wheelSideOffset = width * 0.45;

    // Four wheel positions
    final wheelPositions = [
      Point3D(position.x - wheelOffset, position.y - wheelSideOffset, position.z + wheelRadius),
      Point3D(position.x - wheelOffset, position.y + wheelSideOffset, position.z + wheelRadius),
      Point3D(position.x + wheelOffset, position.y - wheelSideOffset, position.z + wheelRadius),
      Point3D(position.x + wheelOffset, position.y + wheelSideOffset, position.z + wheelRadius),
    ];

    for (final wheelPos in wheelPositions) {
      final screenPos = _project3D(wheelPos, center, size);
      final wheelSize = wheelRadius * scale * 25;
      
      // Drop shadow
      final shadowPaint = Paint()
        ..color = Colors.black38
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(screenPos.dx + 3, screenPos.dy + 3), wheelSize, shadowPaint);
      
      // Main wheel
      canvas.drawCircle(screenPos, wheelSize, wheelPaint);
      
      // Wheel rim
      canvas.drawCircle(screenPos, wheelSize * 0.6, rimPaint);
      
      // Center cap
      final capPaint = Paint()
        ..color = Colors.grey[300]!.withOpacity(confidence)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(screenPos, wheelSize * 0.3, capPaint);
    }
  }

  void _drawVehicleWindows(Canvas canvas, Size size, Offset center, Point3D position, double length, double width, double height, double confidence) {
    final windowPaint = Paint()
      ..color = Colors.lightBlue.withOpacity(confidence * 0.6)
      ..style = PaintingStyle.fill;

    // Front windshield
    final windshieldVertices = [
      Point3D(position.x - length*0.3, position.y - width*0.35, position.z + height*0.6),
      Point3D(position.x - length*0.05, position.y - width*0.35, position.z + height*0.9),
      Point3D(position.x - length*0.05, position.y + width*0.35, position.z + height*0.9),
      Point3D(position.x - length*0.3, position.y + width*0.35, position.z + height*0.6),
    ];

    final windshieldPath = Path();
    final projectedWindshield = windshieldVertices.map((v) => _project3D(v, center, size)).toList();
    windshieldPath.moveTo(projectedWindshield[0].dx, projectedWindshield[0].dy);
    for (int i = 1; i < projectedWindshield.length; i++) {
      windshieldPath.lineTo(projectedWindshield[i].dx, projectedWindshield[i].dy);
    }
    windshieldPath.close();
    canvas.drawPath(windshieldPath, windowPaint);

    // Side windows (left and right)
    final sideWindowVertices = [
      Point3D(position.x - length*0.1, position.y - width*0.48, position.z + height*0.5),
      Point3D(position.x + length*0.2, position.y - width*0.48, position.z + height*0.8),
      Point3D(position.x + length*0.1, position.y - width*0.48, position.z + height*0.8),
      Point3D(position.x - length*0.2, position.y - width*0.48, position.z + height*0.5),
    ];

    final sideWindowPath = Path();
    final projectedSideWindow = sideWindowVertices.map((v) => _project3D(v, center, size)).toList();
    sideWindowPath.moveTo(projectedSideWindow[0].dx, projectedSideWindow[0].dy);
    for (int i = 1; i < projectedSideWindow.length; i++) {
      sideWindowPath.lineTo(projectedSideWindow[i].dx, projectedSideWindow[i].dy);
    }
    sideWindowPath.close();
    canvas.drawPath(sideWindowPath, windowPaint);
  }

  void _drawVehicleLights(Canvas canvas, Size size, Offset center, Point3D position, double length, double width, double confidence) {
    // Headlights
    final headlightPaint = Paint()
      ..color = Colors.white.withOpacity(confidence * 0.9)
      ..style = PaintingStyle.fill;

    final headlight1 = _project3D(
      Point3D(position.x - length*0.48, position.y - width*0.3, position.z + 0.8),
      center, size
    );
    final headlight2 = _project3D(
      Point3D(position.x - length*0.48, position.y + width*0.3, position.z + 0.8),
      center, size
    );

    canvas.drawCircle(headlight1, 5 * scale, headlightPaint);
    canvas.drawCircle(headlight2, 5 * scale, headlightPaint);

    // Add headlight glow
    final glowPaint = Paint()
      ..color = Colors.white.withOpacity(confidence * 0.3)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(headlight1, 8 * scale, glowPaint);
    canvas.drawCircle(headlight2, 8 * scale, glowPaint);

    // Taillights
    final taillightPaint = Paint()
      ..color = Colors.red.withOpacity(confidence * 0.8)
      ..style = PaintingStyle.fill;

    final taillight1 = _project3D(
      Point3D(position.x + length*0.48, position.y - width*0.3, position.z + 0.8),
      center, size
    );
    final taillight2 = _project3D(
      Point3D(position.x + length*0.48, position.y + width*0.3, position.z + 0.8),
      center, size
    );

    canvas.drawCircle(taillight1, 4 * scale, taillightPaint);
    canvas.drawCircle(taillight2, 4 * scale, taillightPaint);
  }

  void _drawVehicleLabel(Canvas canvas, Size size, Offset center, Point3D position, String type, double confidence) {
    final labelPosition = _project3D(
      Point3D(position.x, position.y, position.z + 5.0),
      center, size
    );

    // Confidence ring with pulsing effect
    final confidenceColor = confidence >= 0.8 ? Colors.green : 
                           confidence >= 0.6 ? Colors.orange : Colors.red;
    
    final ringPaint = Paint()
      ..color = confidenceColor.withOpacity(0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    canvas.drawCircle(labelPosition, 30 * scale, ringPaint);

    // Inner confidence fill
    final fillPaint = Paint()
      ..color = confidenceColor.withOpacity(0.2)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(labelPosition, 30 * scale * confidence, fillPaint);

    // Vehicle type and confidence text
    final textPainter = TextPainter(
      text: TextSpan(
        children: [
          TextSpan(
            text: type.toUpperCase(),
            style: TextStyle(
              color: Colors.white,
              fontSize: 14 * scale,
              fontWeight: FontWeight.bold,
              shadows: const [
                Shadow(
                  blurRadius: 3,
                  color: Colors.black87,
                  offset: Offset(1, 1),
                ),
              ],
            ),
          ),
          TextSpan(
            text: '\n${(confidence * 100).toInt()}% CONF',
            style: TextStyle(
              color: confidenceColor,
              fontSize: 10 * scale,
              fontWeight: FontWeight.bold,
              shadows: const [
                Shadow(
                  blurRadius: 2,
                  color: Colors.black87,
                  offset: Offset(1, 1),
                ),
              ],
            ),
          ),
        ],
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        labelPosition.dx - textPainter.width / 2,
        labelPosition.dy - textPainter.height / 2,
      ),
    );
  }

  void _drawLidarSensor(Canvas canvas, Size size, Offset center) {
    final sensorPaint = Paint()
      ..color = Colors.cyan
      ..style = PaintingStyle.fill;

    final origin = _project3D(Point3D(0, 0, 4), center, size);
    
    // Main sensor body
    canvas.drawCircle(origin, 10 * scale, sensorPaint);

    // Sensor rays (scanning pattern)
    final rayPaint = Paint()
      ..color = Colors.cyan.withOpacity(0.15)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    for (int angle = 0; angle < 360; angle += 10) {
      final radians = angle * math.pi / 180;
      final endPoint = _project3D(
        Point3D(
          math.cos(radians) * 60,
          math.sin(radians) * 60,
          4,
        ),
        center,
        size,
      );
      canvas.drawLine(origin, endPoint, rayPaint);
    }

    // Sensor mount
    final mountPaint = Paint()
      ..color = Colors.grey[800]!
      ..style = PaintingStyle.fill;
    
    final mountBase = _project3D(Point3D(0, 0, 2), center, size);
    canvas.drawRect(
      Rect.fromCenter(center: mountBase, width: 8 * scale, height: 4 * scale),
      mountPaint,
    );

    // LIDAR label
    final textPainter = TextPainter(
      text: const TextSpan(
        text: 'LIDAR SENSOR',
        style: TextStyle(
          color: Colors.cyan,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(origin.dx - textPainter.width / 2, origin.dy - 25),
    );
  }

  void _draw3DBox(Canvas canvas, List<Offset> vertices, Paint fillPaint, Paint strokePaint) {
    if (vertices.length != 8) return;

    // Define faces (vertex indices)
    final faces = [
      [0, 1, 2, 3], // Bottom
      [4, 5, 6, 7], // Top  
      [0, 1, 5, 4], // Front
      [2, 3, 7, 6], // Back
      [1, 2, 6, 5], // Right
      [0, 3, 7, 4], // Left
    ];

    // Sort faces by depth for proper rendering
    final faceDepths = <int, double>{};
    for (int i = 0; i < faces.length; i++) {
      final face = faces[i];
      double avgZ = 0;
      for (final vertexIndex in face) {
        avgZ += vertices[vertexIndex].dy; // Use screen Y as depth approximation
      }
      faceDepths[i] = avgZ / face.length;
    }

    final sortedFaceIndices = faceDepths.keys.toList()
      ..sort((a, b) => faceDepths[b]!.compareTo(faceDepths[a]!));

    // Draw faces back to front
    for (final faceIndex in sortedFaceIndices) {
      final face = faces[faceIndex];
      final path = Path();
      
      path.moveTo(vertices[face[0]].dx, vertices[face[0]].dy);
      for (int i = 1; i < face.length; i++) {
        path.lineTo(vertices[face[i]].dx, vertices[face[i]].dy);
      }
      path.close();

      // Lighting effect - top faces brighter
      final brightness = faceIndex == 1 ? 1.0 : // top
                        faceIndex == 0 ? 0.3 : // bottom
                        0.7; // sides

      Paint facePaint = Paint()
        ..color = fillPaint.color.withOpacity(brightness * fillPaint.color.opacity)
        ..style = PaintingStyle.fill
        ..shader = fillPaint.shader;

      canvas.drawPath(path, facePaint);
      canvas.drawPath(path, strokePaint);
    }
  }

  Rect _getBounds(List<Offset> points) {
    if (points.isEmpty) return Rect.zero;
    
    double minX = points.first.dx;
    double maxX = points.first.dx;
    double minY = points.first.dy;
    double maxY = points.first.dy;
    
    for (final point in points) {
      minX = math.min(minX, point.dx);
      maxX = math.max(maxX, point.dx);
      minY = math.min(minY, point.dy);
      maxY = math.max(maxY, point.dy);
    }
    
    return Rect.fromLTRB(minX, minY, maxX, maxY);
  }

  Offset _project3D(Point3D point, Offset center, Size size) {
    // Apply 3D rotations
    final cosX = math.cos(rotationX);
    final sinX = math.sin(rotationX);
    final cosY = math.cos(rotationY);
    final sinY = math.sin(rotationY);

    // Rotate around X-axis
    final y1 = point.y * cosX - point.z * sinX;
    final z1 = point.y * sinX + point.z * cosX;

    // Rotate around Y-axis
    final x2 = point.x * cosY + z1 * sinY;
    final z2 = -point.x * sinY + z1 * cosY;

    // Perspective projection with proper depth
    final distance = 400.0; // Camera distance
    final perspective = distance / (distance + z2 + 50);

    return Offset(
      center.dx + x2 * perspective * scale * 4,
      center.dy - y1 * perspective * scale * 4,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class Point3D {
  final double x;
  final double y;
  final double z;

  Point3D(this.x, this.y, this.z);

  Point3D operator -(Point3D other) {
    return Point3D(x - other.x, y - other.y, z - other.z);
  }

  double get magnitude => math.sqrt(x * x + y * y + z * z);
}