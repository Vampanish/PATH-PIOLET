import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'services/maps_service.dart';

class GNNPage extends StatefulWidget {
  final String origin;
  final String destination;

  const GNNPage({Key? key, required this.origin, required this.destination}) : super(key: key);

  @override
  State<GNNPage> createState() => _GNNPageState();
}

class _GNNPageState extends State<GNNPage> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final MapsService _mapsService = MapsService();
  Map<String, dynamic> graphData = {'nodes': [], 'edges': []};
  bool isLoading = true;
  String? errorMessage;
  String? selectedNode;
  
  // Color constants
  static const Color primaryColor = Color(0xFF0D47A1); // Deep Blue
  static const Color secondaryColor = Color(0xFF1976D2); // Medium Blue
  static const Color accentColor = Color(0xFF00E5FF); // Cyan/Neon Blue
  static const Color backgroundColor = Color(0xFF1A237E); // Blue-Gray
  static const Color surfaceColor = Color(0xFF212B50); // Dark Blue-Gray

  // Simulation state
  Map<String, double> trafficDensity = {};
  Map<String, bool> trafficLights = {};
  Map<String, String> weatherConditions = {};
  Map<String, double> weatherImpact = {};
  Map<String, List<double>> historicalTrafficData = {};
  Map<String, Map<String, dynamic>> nodeStatistics = {};
  List<Map<String, dynamic>> routeOptions = [];
  bool isSimulating = false;
  bool isTrafficControlEnabled = false;
  String selectedWeather = 'Clear';
  bool isEmergencyMode = false;
  int currentHour = 8;
  bool showHistoricalData = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _fetchRouteGraph();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _fetchRouteGraph() async {
    try {
      final data = await _mapsService.getRouteAsGraph(widget.origin, widget.destination);
      setState(() {
        graphData = data;
        isLoading = false;
      });
      _initializeSimulationState();
    } catch (e) {
      setState(() {
        errorMessage = "Failed to load route graph: $e";
        isLoading = false;
      });
    }
  }

  void _initializeSimulationState() {
    final nodes = (graphData['nodes'] as List).cast<Map<String, String>>();
    trafficDensity = {};
    trafficLights = {};
    weatherConditions = {};
    weatherImpact = {};
    historicalTrafficData = {};
    nodeStatistics = {};
    for (var node in nodes) {
      final id = node['id']!;
      trafficDensity[id] = 0.0;
      trafficLights[id] = false;
      weatherConditions[id] = 'Clear';
      weatherImpact[id] = 0.0;
      historicalTrafficData[id] = List.generate(24, (index) => 0.0);
      nodeStatistics[id] = {
        'peakHour': 8,
        'averageTraffic': 0.0,
        'emergencyRoutes': 0,
        'weatherImpact': 0.0,
      };
    }
    _calculateRouteOptions();
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
        double baseDensity = _getTimeBasedDensity(currentHour);
        double weatherFactor = weatherImpact[node] ?? 0.0;
        double randomFactor = math.Random().nextDouble() * 0.2;
        trafficDensity[node] = (baseDensity + weatherFactor + randomFactor).clamp(0.0, 1.0);
        historicalTrafficData[node]![currentHour] = trafficDensity[node]!;
        _updateNodeStatistics(node);
        if (isTrafficControlEnabled) {
          final density = trafficDensity[node] ?? 0.0;
          trafficLights[node] = density > 0.7;
        }
      }
      _calculateRouteOptions();
      currentHour = (currentHour + 1) % 24;
    });
    Future.delayed(const Duration(seconds: 2), _updateTrafficDensity);
  }

  double _getTimeBasedDensity(int hour) {
    if (hour >= 7 && hour <= 9) return 0.7;
    if (hour >= 16 && hour <= 18) return 0.8;
    if (hour >= 12 && hour <= 14) return 0.5;
    return 0.3;
  }

  void _updateNodeStatistics(String node) {
    final stats = nodeStatistics[node]!;
    final historicalData = historicalTrafficData[node]!;
    double sum = historicalData.reduce((a, b) => a + b);
    stats['averageTraffic'] = sum / historicalData.length;
    int peakHour = 0;
    double maxDensity = 0.0;
    for (int i = 0; i < historicalData.length; i++) {
      if (historicalData[i] > maxDensity) {
        maxDensity = historicalData[i];
        peakHour = i;
      }
    }
    stats['peakHour'] = peakHour;
    stats['weatherImpact'] = weatherImpact[node] ?? 0.0;
  }

  void _updateWeather(String node, String condition) {
    setState(() {
      weatherConditions[node] = condition;
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
    // For now, just create a single route option using the node order
    final nodes = (graphData['nodes'] as List).cast<Map<String, String>>();
    if (nodes.length < 2) {
      routeOptions = [];
      return;
    }
    List<String> path = nodes.map((n) => n['label']!).toList();
    routeOptions = [
      {
        'path': path,
        'distance': (nodes.length - 1) * 10.0, // Dummy distance
        'time': (nodes.length - 1) * 15, // Dummy time
        'traffic': trafficDensity[path[0]] ?? 0.0,
        'weather': weatherConditions[path[0]] ?? 'Clear',
        'trafficLights': trafficLights[path[0]] ?? false,
        'emergency': isEmergencyMode ? 0.8 : 0.0,
      },
    ];
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
              node,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text(
              'Traffic: ${(density * 100).toStringAsFixed(1)}%',
              style: TextStyle(color: densityColor, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Light: ${isLightGreen ? 'Red' : 'Green'}',
              style: TextStyle(color: isLightGreen ? Colors.redAccent : Colors.greenAccent, fontWeight: FontWeight.bold),
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

  @override
  Widget build(BuildContext context) {
    final nodes = (graphData['nodes'] as List).cast<Map<String, String>>();
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text(
          'GNN for Route Optimization',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: primaryColor,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
              ? Center(child: Text(errorMessage!, style: const TextStyle(color: Colors.red)))
              : SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Graph Neural Networks (GNNs) model traffic as a graph, where intersections are nodes and roads are edges.\nGNNs can learn to predict the optimal route by considering real-time traffic, closures and user preferences.',
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
                          height: 400,
                          decoration: BoxDecoration(
                            color: surfaceColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: primaryColor, width: 2),
                          ),
                          child: GraphWidget(
                            nodes: nodes,
                            edges: (graphData['edges'] as List).cast<List<String>>(),
                            controller: _controller,
                            trafficDensity: trafficDensity,
                            trafficLights: trafficLights,
                            selectedNode: selectedNode,
                            onNodeTap: (nodeId) {
                              setState(() {
                                selectedNode = nodeId;
                              });
                            },
                          ),
                        ),
                        const SizedBox(height: 24),
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
                            final node = nodes[index]['id']!;
                            final density = trafficDensity[node] ?? 0.0;
                            final isLightGreen = trafficLights[node] ?? false;
                            return _buildNodeCard(node, density, isLightGreen);
                          },
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
                              final stats = nodeStatistics[node['id']!]!;
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
                                        'Node: ${node['label']}',
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
                                  final data = historicalTrafficData[node['id']!]!;
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
                                            'Node ${node['label']}',
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
                        const SizedBox(height: 20),
                        if (selectedNode != null)
                          Card(
                            color: surfaceColor,
                            child: ListTile(
                              leading: const Icon(Icons.location_on, color: accentColor),
                              title: Text('Selected: $selectedNode', style: const TextStyle(color: Colors.white)),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
    );
  }
}

class GraphWidget extends StatelessWidget {
  final List<Map<String, String>> nodes;
  final List<List<String>> edges;
  final AnimationController controller;
  final Map<String, double> trafficDensity;
  final Map<String, bool> trafficLights;
  final String? selectedNode;
  final Function(String) onNodeTap;

  const GraphWidget({
    Key? key,
    required this.nodes,
    required this.edges,
    required this.controller,
    required this.trafficDensity,
    required this.trafficLights,
    required this.selectedNode,
    required this.onNodeTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        final center = Offset(width / 2, height / 2);
        final radius = math.min(width, height) / 2.5;

        final nodePositions = <String, Offset>{};
        if (nodes.isNotEmpty) {
          for (int i = 0; i < nodes.length; i++) {
            final angle = (2 * math.pi * i) / nodes.length;
            nodePositions[nodes[i]['id']!] = center + Offset(radius * math.cos(angle), radius * math.sin(angle));
          }
        }

        return CustomPaint(
          painter: GraphPainter(
            nodes: nodes,
            edges: edges,
            nodePositions: nodePositions,
            animation: controller,
            trafficDensity: trafficDensity,
            trafficLights: trafficLights,
            selectedNode: selectedNode,
          ),
          child: GestureDetector(
            onTapDown: (details) {
              for (var node in nodes) {
                final pos = nodePositions[node['id']!];
                if (pos != null && (details.localPosition - pos).distance < 20) {
                  onNodeTap(node['label']!);
                  break;
                }
              }
            },
          ),
        );
      },
    );
  }
}

class GraphPainter extends CustomPainter {
  final List<Map<String, String>> nodes;
  final List<List<String>> edges;
  final Map<String, Offset> nodePositions;
  final Animation<double> animation;
  final Map<String, double> trafficDensity;
  final Map<String, bool> trafficLights;
  final String? selectedNode;

  GraphPainter({
    required this.nodes,
    required this.edges,
    required this.nodePositions,
    required this.animation,
    required this.trafficDensity,
    required this.trafficLights,
    required this.selectedNode,
  }) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final edgePaint = Paint()
      ..color = Colors.white.withOpacity(0.7)
      ..strokeWidth = 2;

    for (var edge in edges) {
      final startNode = nodePositions[edge[0]];
      final endNode = nodePositions[edge[1]];
      if (startNode != null && endNode != null) {
        canvas.drawLine(startNode, endNode, edgePaint);
      }
    }

    for (var node in nodes) {
      final pos = nodePositions[node['id']!];
      if (pos != null) {
        final density = trafficDensity[node['id']!] ?? 0.0;
        Color nodeColor;
        if (density < 0.3) {
          nodeColor = Colors.greenAccent.withOpacity(0.7);
        } else if (density < 0.6) {
          nodeColor = Colors.orangeAccent.withOpacity(0.7);
        } else {
          nodeColor = Colors.redAccent.withOpacity(0.7);
        }
        canvas.drawCircle(pos, 20, Paint()..color = nodeColor);
        final textSpan = TextSpan(text: node['label'], style: const TextStyle(color: Colors.white, fontSize: 12));
        final textPainter = TextPainter(text: textSpan, textAlign: TextAlign.center, textDirection: TextDirection.ltr);
        textPainter.layout(minWidth: 0, maxWidth: 80);
        textPainter.paint(canvas, pos - Offset(textPainter.width / 2, textPainter.height / 2));
        // Draw traffic light indicator
        final isLightRed = trafficLights[node['id']!] ?? false;
        final lightColor = isLightRed ? Colors.red : Colors.green;
        canvas.drawCircle(pos + const Offset(20, -10), 5, Paint()..color = lightColor);
        // Pulse effect for selected node
        if (selectedNode == node['label']) {
          final radius = 20.0 + (animation.value * 5);
          final opacity = 1.0 - animation.value;
          canvas.drawCircle(
            pos,
            radius,
            Paint()..color = Colors.blueAccent.withOpacity(opacity),
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
