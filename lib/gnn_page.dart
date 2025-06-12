import 'package:flutter/material.dart';
import 'dart:math' as math;

class GNNPage extends StatefulWidget {
  const GNNPage({Key? key}) : super(key: key);

  @override
  State<GNNPage> createState() => _GNNPageState();
}

class _GNNPageState extends State<GNNPage> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  String? selectedNode;
  bool isSimulating = false;
  final Map<String, double> trafficDensity = {};
  List<Map<String, dynamic>> routeOptions = [];
  
  // Color constants
  static const Color primaryColor = Color(0xFF0D47A1); // Deep Blue
  static const Color secondaryColor = Color(0xFF1976D2); // Medium Blue
  static const Color accentColor = Color(0xFF00E5FF); // Cyan/Neon Blue
  static const Color backgroundColor = Color(0xFF1A237E); // Blue-Gray
  static const Color surfaceColor = Color(0xFF212B50); // Dark Blue-Gray

  // New state variables for traffic control and weather
  final Map<String, bool> trafficLights = {};
  final Map<String, String> weatherConditions = {};
  final Map<String, double> weatherImpact = {};
  bool isTrafficControlEnabled = false;
  String selectedWeather = 'Clear';

  // New state variables for advanced features
  bool isEmergencyMode = false;
  final Map<String, List<double>> historicalTrafficData = {};
  final Map<String, Map<String, dynamic>> nodeStatistics = {};
  int currentHour = 8; // Start at 8 AM
  bool showHistoricalData = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    
    // Initialize traffic density and historical data
    for (var node in ['A', 'B', 'C', 'D', 'E']) {
      trafficDensity[node] = 0.0;
      trafficLights[node] = false;
      weatherConditions[node] = 'Clear';
      weatherImpact[node] = 0.0;
      
      // Initialize historical data
      historicalTrafficData[node] = List.generate(24, (index) => 0.0);
      
      // Initialize node statistics
      nodeStatistics[node] = {
        'peakHour': 8,
        'averageTraffic': 0.0,
        'emergencyRoutes': 0,
        'weatherImpact': 0.0,
      };
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _startTrafficSimulation() {
    setState(() {
      isSimulating = true;
    });
    _updateTrafficDensity();
  }

  void _updateTrafficDensity() {
    if (!isSimulating) return;
    setState(() {
      for (var node in trafficDensity.keys) {
        // Update traffic density considering weather impact and time of day
        double baseDensity = _getTimeBasedDensity(currentHour);
        double weatherFactor = weatherImpact[node] ?? 0.0;
        double randomFactor = math.Random().nextDouble() * 0.2;
        trafficDensity[node] = (baseDensity + weatherFactor + randomFactor).clamp(0.0, 1.0);
        
        // Update historical data
        historicalTrafficData[node]![currentHour] = trafficDensity[node]!;
        
        // Update node statistics
        _updateNodeStatistics(node);
        
        // Update traffic lights
        if (isTrafficControlEnabled) {
          final density = trafficDensity[node] ?? 0.0;
          trafficLights[node] = density > 0.7;
        }
      }
      _calculateRouteOptions();
      
      // Update time
      currentHour = (currentHour + 1) % 24;
    });
    Future.delayed(const Duration(seconds: 2), _updateTrafficDensity);
  }

  double _getTimeBasedDensity(int hour) {
    // Simulate rush hours
    if (hour >= 7 && hour <= 9) return 0.7; // Morning rush
    if (hour >= 16 && hour <= 18) return 0.8; // Evening rush
    if (hour >= 12 && hour <= 14) return 0.5; // Lunch hour
    return 0.3; // Normal hours
  }

  void _updateNodeStatistics(String node) {
    final stats = nodeStatistics[node]!;
    final historicalData = historicalTrafficData[node]!;
    
    // Calculate average traffic
    double sum = historicalData.reduce((a, b) => a + b);
    stats['averageTraffic'] = sum / historicalData.length;
    
    // Find peak hour
    int peakHour = 0;
    double maxDensity = 0.0;
    for (int i = 0; i < historicalData.length; i++) {
      if (historicalData[i] > maxDensity) {
        maxDensity = historicalData[i];
        peakHour = i;
      }
    }
    stats['peakHour'] = peakHour;
    
    // Update weather impact
    stats['weatherImpact'] = weatherImpact[node] ?? 0.0;
  }

  void _updateWeather(String node, String condition) {
    setState(() {
      weatherConditions[node] = condition;
      // Update weather impact on traffic
      switch (condition) {
        case 'Rain':
          weatherImpact[node] = 0.3;
          break;
        case 'Snow':
          weatherImpact[node] = 0.5;
          break;
        case 'Fog':
          weatherImpact[node] = 0.4;
          break;
        default:
          weatherImpact[node] = 0.0;
      }
    });
  }

  void _calculateRouteOptions() {
    routeOptions = [
      {
        'path': ['A', 'B', 'D', 'E'],
        'distance': 12.5,
        'time': 25,
        'traffic': trafficDensity['A'] ?? 0.0,
        'weather': weatherConditions['A'] ?? 'Clear',
        'trafficLights': trafficLights['A'] ?? false,
        'emergency': isEmergencyMode ? 0.8 : 0.0,
      },
      {
        'path': ['A', 'C', 'D', 'E'],
        'distance': 14.2,
        'time': 28,
        'traffic': trafficDensity['C'] ?? 0.0,
        'weather': weatherConditions['C'] ?? 'Clear',
        'trafficLights': trafficLights['C'] ?? false,
        'emergency': isEmergencyMode ? 0.6 : 0.0,
      },
      {
        'path': ['A', 'B', 'E'],
        'distance': 15.0,
        'time': 30,
        'traffic': trafficDensity['B'] ?? 0.0,
        'weather': weatherConditions['B'] ?? 'Clear',
        'trafficLights': trafficLights['B'] ?? false,
        'emergency': isEmergencyMode ? 0.9 : 0.0,
      },
    ];
  }

  @override
  Widget build(BuildContext context) {
    final nodes = ['A', 'B', 'C', 'D', 'E'];
    final edges = [
      ['A', 'B'],
      ['A', 'C'],
      ['B', 'D'],
      ['C', 'D'],
      ['D', 'E'],
      ['B', 'E'],
    ];

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text(
          'GNN for Route Optimization',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: primaryColor,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Graph Neural Networks (GNNs) model traffic as a graph, where intersections are nodes and roads are edges. '
                'GNNs can learn to predict the optimal route by considering real-time traffic, closures and user preferences.',
                style: TextStyle(fontSize: 16, color: Colors.white70),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 16,
                runSpacing: 16,
                alignment: WrapAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: _startTrafficSimulation,
                    style: ElevatedButton.styleFrom(backgroundColor: accentColor, foregroundColor: Colors.black),
                    child: const Text('Start Traffic Simulation'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        isSimulating = false;
                      });
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: secondaryColor, foregroundColor: Colors.white),
                    child: const Text('Stop Simulation'),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Switch(
                        value: isTrafficControlEnabled,
                        onChanged: (value) {
                          setState(() {
                            isTrafficControlEnabled = value;
                          });
                        },
                        activeColor: accentColor,
                      ),
                      const Text('Traffic Control', style: TextStyle(color: Colors.white70)),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Weather:', style: TextStyle(color: Colors.white70)),
                      const SizedBox(width: 8),
                      DropdownButton<String>(
                        value: selectedWeather,
                        dropdownColor: surfaceColor,
                        style: const TextStyle(color: Colors.white, fontSize: 16),
                        items: <String>['Clear', 'Rain', 'Snow', 'Fog'].map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            setState(() {
                              selectedWeather = newValue;
                              for (var node in weatherConditions.keys) {
                                _updateWeather(node, newValue);
                              }
                            });
                          }
                        },
                      ),
                    ],
                  ),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        isEmergencyMode = !isEmergencyMode;
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isEmergencyMode ? Colors.redAccent : secondaryColor,
                      foregroundColor: Colors.white,
                    ),
                    child: Text(isEmergencyMode ? 'Disable Emergency Mode' : 'Enable Emergency Mode'),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Switch(
                        value: showHistoricalData,
                        onChanged: (value) {
                          setState(() {
                            showHistoricalData = value;
                          });
                        },
                        activeColor: accentColor,
                      ),
                      const Text('Show Historical Data', style: TextStyle(color: Colors.white70)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Current Time: ${currentHour}:00',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: CustomPaint(
                        size: const Size(350, 250),
                        painter: _GraphPainter(
                          nodes,
                          edges,
                          selectedNode,
                          trafficDensity,
                          _controller,
                          trafficLights,
                          weatherConditions,
                          isEmergencyMode,
                          showHistoricalData,
                          historicalTrafficData,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 1.8,
                      ),
                      itemCount: nodes.length,
                      itemBuilder: (context, index) {
                        final node = nodes[index];
                        final density = trafficDensity[node] ?? 0.0;
                        final isLightGreen = trafficLights[node] ?? false;
                        return _buildNodeCard(node, density, isLightGreen);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Calculated Route Options',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: accentColor),
              ),
              const SizedBox(height: 16),
              if (routeOptions.isEmpty)
                const Text(
                  'No route options available. Start simulation first.',
                  style: TextStyle(fontSize: 16, color: Colors.white70),
                  textAlign: TextAlign.center,
                )
              else
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: routeOptions.map((option) => Card(
                    color: surfaceColor,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Route: ${option['path']!.join(' -> ')}',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 16,
                            runSpacing: 8,
                            children: [
                              _buildInfoChip('Distance: ${option['distance']} km'),
                              _buildInfoChip('Time: ${option['time']} mins'),
                              _buildInfoChip('Traffic: ${(option['traffic'] * 100).toStringAsFixed(1)}%'),
                              _buildInfoChip('Weather: ${option['weather']}'),
                              _buildInfoChip(
                                'Traffic Light: ${option['trafficLights'] ? 'Red' : 'Green'}',
                                color: option['trafficLights'] ? Colors.red : Colors.greenAccent,
                              ),
                              if (isEmergencyMode)
                                _buildInfoChip(
                                  'Emergency: ${(option['emergency'] * 100).toStringAsFixed(1)}%',
                                  color: Colors.orangeAccent,
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  )).toList(),
                ),
              const SizedBox(height: 24),
              Text(
                'Node Statistics',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: accentColor),
              ),
              const SizedBox(height: 16),
              if (nodeStatistics.isEmpty)
                const Text(
                  'No node statistics available. Start simulation first.',
                  style: TextStyle(fontSize: 16, color: Colors.white70),
                  textAlign: TextAlign.center,
                )
              else
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: nodes.map((node) {
                    final stats = nodeStatistics[node]!;
                    return Card(
                      color: surfaceColor,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Node: $node',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 16,
                              runSpacing: 8,
                              children: [
                                _buildInfoChip('Peak Hour: ${stats['peakHour']}:00'),
                                _buildInfoChip('Avg Traffic: ${(stats['averageTraffic'] * 100).toStringAsFixed(1)}%'),
                                _buildInfoChip('Emergency Routes: ${stats['emergencyRoutes']}'),
                                _buildInfoChip('Weather Impact: ${(stats['weatherImpact'] * 100).toStringAsFixed(1)}%'),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              const SizedBox(height: 24),
              if (showHistoricalData)
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Historical Traffic Data by Hour',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: accentColor),
                    ),
                    const SizedBox(height: 16),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: nodes.map((node) {
                        final data = historicalTrafficData[node]!;
                        return Card(
                          color: surfaceColor,
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Node $node',
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 4,
                                  children: List.generate(data.length, (i) {
                                    return Chip(
                                      backgroundColor: secondaryColor,
                                      label: Text(
                                        '${i}:00: ${(data[i] * 100).toStringAsFixed(1)}%',
                                        style: const TextStyle(color: Colors.white),
                                      ),
                                    );
                                  }),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNodeCard(String node, double density, bool isLightGreen) {
    Color densityColor;
    if (density < 0.3) {
      densityColor = Colors.greenAccent;
    } else if (density < 0.6) {
      densityColor = Colors.orangeAccent;
    } else {
      densityColor = Colors.redAccent;
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: surfaceColor,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Node $node',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text(
              'Traffic: ${(density * 100).toStringAsFixed(1)}%',
              style: TextStyle(color: densityColor, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Light: ${isLightGreen ? 'Green' : 'Red'}',
              style: TextStyle(color: isLightGreen ? Colors.greenAccent : Colors.redAccent, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (weatherConditions[node] != null) Text(
              'Weather: ${weatherConditions[node]}',
              style: const TextStyle(color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(String label, {Color? color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color?.withOpacity(0.2) ?? secondaryColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color ?? secondaryColor,
          width: 1,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color ?? Colors.white70,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _GraphPainter extends CustomPainter {
  final List<String> nodes;
  final List<List<String>> edges;
  final String? selectedNode;
  final Map<String, double> trafficDensity;
  final AnimationController animation;
  final Map<String, bool> trafficLights;
  final Map<String, String> weatherConditions;
  final bool isEmergencyMode;
  final bool showHistoricalData;
  final Map<String, List<double>> historicalTrafficData;

  _GraphPainter(
    this.nodes,
    this.edges,
    this.selectedNode,
    this.trafficDensity,
    this.animation,
    this.trafficLights,
    this.weatherConditions,
    this.isEmergencyMode,
    this.showHistoricalData,
    this.historicalTrafficData,
  ) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final nodePaint = Paint()..style = PaintingStyle.fill;
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    // Define node positions (simple layout for demonstration)
    final positions = {
      'A': Offset(size.width * 0.1, size.height * 0.5),
      'B': Offset(size.width * 0.4, size.height * 0.2),
      'C': Offset(size.width * 0.4, size.height * 0.8),
      'D': Offset(size.width * 0.7, size.height * 0.5),
      'E': Offset(size.width * 0.9, size.height * 0.5),
    };

    // Draw edges
    for (var edge in edges) {
      final start = positions[edge[0]]!;
      final end = positions[edge[1]]!;
      paint.color = Colors.grey.withOpacity(0.5);
      canvas.drawLine(start, end, paint);
    }

    // Draw nodes and traffic density
    for (var node in nodes) {
      final position = positions[node]!;
      final density = trafficDensity[node] ?? 0.0;
      final isLightGreen = trafficLights[node] ?? false;

      // Node background color based on traffic density
      if (density < 0.3) {
        nodePaint.color = Colors.greenAccent.withOpacity(0.7);
      } else if (density < 0.6) {
        nodePaint.color = Colors.orangeAccent.withOpacity(0.7);
      } else {
        nodePaint.color = Colors.redAccent.withOpacity(0.7);
      }

      canvas.drawCircle(position, 20, nodePaint);

      // Draw node text
      textPainter.text = TextSpan(
        text: node,
        style: TextStyle(
          color: selectedNode == node ? Colors.black : Colors.white,
          fontWeight: FontWeight.bold,
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        position - Offset(textPainter.width / 2, textPainter.height / 2),
      );

      // Draw traffic light indicator
      final lightColor = isLightGreen ? Colors.green : Colors.red;
      canvas.drawCircle(position + const Offset(20, -10), 5, Paint()..color = lightColor);

      // Draw weather condition (simplified)
      final weather = weatherConditions[node];
      IconData? weatherIcon;
      switch (weather) {
        case 'Rain':
          weatherIcon = Icons.cloudy_snowing;
          break;
        case 'Snow':
          weatherIcon = Icons.ac_unit;
          break;
        case 'Fog':
          weatherIcon = Icons.cloud;
          break;
        default:
          weatherIcon = Icons.wb_sunny;
          break;
      }

      if (weatherIcon != null) {
        final textSpan = TextSpan(
          text: String.fromCharCode(weatherIcon.codePoint),
          style: TextStyle(
            fontSize: 16,
            fontFamily: weatherIcon.fontFamily,
            color: Colors.yellow,
          ),
        );
        textPainter.text = textSpan;
        textPainter.layout();
        textPainter.paint(
          canvas,
          position + const Offset(20, 10) - Offset(textPainter.width / 2, textPainter.height / 2),
        );
      }
    }

    // Draw animation for selected node (pulse effect)
    if (selectedNode != null && positions.containsKey(selectedNode)) {
      final position = positions[selectedNode]!;
      final radius = 20.0 + (animation.value * 5);
      final opacity = 1.0 - animation.value;
      canvas.drawCircle(
        position,
        radius,
        Paint()..color = Colors.blueAccent.withOpacity(opacity),
      );
    }

    // Draw historical data graph (simplified)
    if (showHistoricalData) {
      final historicalGraphPaint = Paint()
        ..color = Colors.blueAccent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      
      final historicalFillPaint = Paint()..color = Colors.blueAccent.withOpacity(0.2);

      final graphHeight = size.height * 0.2;
      final graphWidth = size.width * 0.8;
      final graphTop = size.height * 0.05;
      final graphLeft = size.width * 0.1;

      // Draw a simplified graph for each node
      for (var node in nodes) {
        final data = historicalTrafficData[node]!;
        final path = Path();
        
        double xStep = graphWidth / (data.length - 1);
        double yFactor = graphHeight;

        if (data.isNotEmpty) {
          path.moveTo(graphLeft, graphTop + graphHeight - (data[0] * yFactor));
          for (int i = 1; i < data.length; i++) {
            path.lineTo(graphLeft + i * xStep, graphTop + graphHeight - (data[i] * yFactor));
          }
          canvas.drawPath(path, historicalGraphPaint);
          
          // Fill the area below the graph
          final fillPath = Path.from(path);
          fillPath.lineTo(graphLeft + graphWidth, graphTop + graphHeight);
          fillPath.lineTo(graphLeft, graphTop + graphHeight);
          fillPath.close();
          canvas.drawPath(fillPath, historicalFillPaint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _GraphPainter oldDelegate) {
    return oldDelegate.selectedNode != selectedNode ||
        oldDelegate.trafficDensity != trafficDensity ||
        oldDelegate.trafficLights != trafficLights ||
        oldDelegate.weatherConditions != weatherConditions ||
        oldDelegate.isEmergencyMode != isEmergencyMode ||
        oldDelegate.showHistoricalData != showHistoricalData ||
        oldDelegate.historicalTrafficData != historicalTrafficData ||
        animation.status != oldDelegate.animation.status;
  }
}
