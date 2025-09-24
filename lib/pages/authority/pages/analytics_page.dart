import 'package:flutter/material.dart';
import '../services/authority_data_service.dart';
import '../../../services/ai_traffic_monitoring_service.dart';
import '../../../services/iot_sensor_manager.dart';
import '../../../services/computer_vision_engine.dart';

class AnalyticsPage extends StatelessWidget {
  const AnalyticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final service = AuthorityDataService.instance;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text('AI Traffic Analytics', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('POWERED BY AI', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // AI Performance Metrics
            _AIPerformanceOverview(),
            const SizedBox(height: 16),
            
            // Traditional Analytics with AI Enhancement
            _ChartCard(
              title: 'Average Commute Time Trend (AI Optimized)',
              stream: service.avgCommuteTimeStream,
              color: Colors.blue,
              aiEnhanced: true,
            ),
            _ChartCard(
              title: 'Vehicle Count Trend (CV Detected)',
              stream: service.vehiclesOnRoadStream,
              color: Colors.green,
              aiEnhanced: true,
            ),
            
            // New AI-specific analytics
            _AIDetectionAnalytics(),
            _SensorNetworkAnalytics(),
          ],
        ),
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  final String title;
  final Stream<num> stream;
  final Color color;
  final bool aiEnhanced;
  const _ChartCard({required this.title, required this.stream, required this.color, this.aiEnhanced = false});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                const SizedBox(width: 8),
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                if (aiEnhanced) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.psychology, size: 10),
                        SizedBox(width: 2),
                        Text('AI', style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            Container(
              height: 160,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  colors: [color.withOpacity(0.15), color.withOpacity(0.05)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(color: color.withOpacity(0.3)),
              ),
              child: StreamBuilder<num>(
                stream: stream,
                builder: (context, snapshot) {
                  final v = snapshot.data?.toDouble() ?? 0;
                  return CustomPaint(
                    painter: _MiniLinePainter(value: v, color: color),
                    child: Center(
                      child: Text(
                        'Live Value: ${v.toStringAsFixed(1)}\n(Integrate charts lib later)',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  );
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}

class _MiniLinePainter extends CustomPainter {
  final double value;
  final Color color;
  _MiniLinePainter({required this.value, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    final path = Path();
    path.moveTo(0, size.height * 0.8);
    for (int i = 0; i < 20; i++) {
      final x = size.width * (i / 19);
      final y = size.height * (0.5 + 0.3 * (value % 10) / 10 * (i % 2 == 0 ? -1 : 1));
      path.lineTo(x, y.clamp(0, size.height));
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _MiniLinePainter oldDelegate) => oldDelegate.value != value;
}

// AI Performance Overview
class _AIPerformanceOverview extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.psychology, color: Colors.blue),
                const SizedBox(width: 8),
                Text('AI System Performance', style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                // Use different layout for smaller screens
                if (constraints.maxWidth < 600) {
                  return Column(
                    children: [
                      Row(
                        children: [
                          Expanded(child: _PerformanceMetric('CV Accuracy', '94.2%', Colors.green, Icons.camera_alt)),
                          Expanded(child: _PerformanceMetric('Alert Response', '1.3s', Colors.blue, Icons.speed)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(child: _PerformanceMetric('System Uptime', '99.8%', Colors.teal, Icons.check_circle)),
                          Expanded(child: _PerformanceMetric('Processing Rate', '24 FPS', Colors.purple, Icons.memory)),
                        ],
                      ),
                    ],
                  );
                } else {
                  return Row(
                    children: [
                      Expanded(child: _PerformanceMetric('CV Accuracy', '94.2%', Colors.green, Icons.camera_alt)),
                      Expanded(child: _PerformanceMetric('Alert Response', '1.3s', Colors.blue, Icons.speed)),
                      Expanded(child: _PerformanceMetric('System Uptime', '99.8%', Colors.teal, Icons.check_circle)),
                      Expanded(child: _PerformanceMetric('Processing Rate', '24 FPS', Colors.purple, Icons.memory)),
                    ],
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _PerformanceMetric extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;
  
  const _PerformanceMetric(this.label, this.value, this.color, this.icon);
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: color.withOpacity(0.1),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
          ),
          Text(
            label, 
            style: const TextStyle(fontSize: 10), 
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          ),
        ],
      ),
    );
  }
}

// AI Detection Analytics
class _AIDetectionAnalytics extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.analytics, color: Colors.orange),
                const SizedBox(width: 8),
                Text('AI Detection Analytics (Last 24h)', style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              height: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  colors: [Colors.orange.withOpacity(0.1), Colors.red.withOpacity(0.1)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _DetectionStat('Accidents', '3', Icons.car_crash, Colors.red),
                      _DetectionStat('Stalled Vehicles', '12', Icons.directions_car, Colors.orange),
                      _DetectionStat('Congestion Events', '28', Icons.traffic, Colors.yellow[700]!),
                      _DetectionStat('Sensor Failures', '2', Icons.sensors_off, Colors.grey),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.trending_up, color: Colors.green, size: 16),
                      const SizedBox(width: 4),
                      const Text('Detection accuracy improved by 12% this week', 
                           style: TextStyle(fontSize: 12, color: Colors.green)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.speed, color: Colors.blue, size: 16),
                      const SizedBox(width: 4),
                      const Text('Average response time: 1.3 seconds', 
                           style: TextStyle(fontSize: 12, color: Colors.blue)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetectionStat extends StatelessWidget {
  final String label;
  final String count;
  final IconData icon;
  final Color color;
  
  const _DetectionStat(this.label, this.count, this.icon, this.color);
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 4),
        Text(count, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: color)),
        Text(label, style: const TextStyle(fontSize: 10), textAlign: TextAlign.center),
      ],
    );
  }
}

// Sensor Network Analytics
class _SensorNetworkAnalytics extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.sensors, color: Colors.teal),
                const SizedBox(width: 8),
                Text('IoT Sensor Network Health', style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 16),
            StreamBuilder<IoTSensorData>(
              stream: IoTSensorManager.instance.sensorDataStream,
              builder: (context, snapshot) {
                final stats = IoTSensorManager.instance.getNetworkStatistics();
                return Container(
                  height: 180,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: LinearGradient(
                      colors: [Colors.teal.withOpacity(0.1), Colors.blue.withOpacity(0.1)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: Border.all(color: Colors.teal.withOpacity(0.3)),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _SensorMetric(
                              'Total Sensors',
                              '${stats.totalSensors}',
                              Colors.teal,
                              Icons.sensors,
                            ),
                          ),
                          Expanded(
                            child: _SensorMetric(
                              'Active',
                              '${stats.activeSensors}',
                              Colors.green,
                              Icons.check_circle,
                            ),
                          ),
                          Expanded(
                            child: _SensorMetric(
                              'Health',
                              '${stats.healthPercentage.isNaN ? 0 : stats.healthPercentage.toInt()}%',
                              (stats.healthPercentage.isNaN ? 0 : stats.healthPercentage) > 90 ? Colors.green : Colors.orange,
                              Icons.favorite,
                            ),
                          ),
                          Expanded(
                            child: _SensorMetric(
                              'Avg Battery',
                              '${stats.averageBatteryLevel.isNaN ? 0 : stats.averageBatteryLevel.toInt()}%',
                              (stats.averageBatteryLevel.isNaN ? 0 : stats.averageBatteryLevel) > 70 ? Colors.green : Colors.orange,
                              Icons.battery_std,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Divider(),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _SensorTypeCount('Vehicle Counters', '8', Colors.blue),
                          ),
                          Expanded(
                            child: _SensorTypeCount('Speed Sensors', '6', Colors.green),
                          ),
                          Expanded(
                            child: _SensorTypeCount('Pollution', '4', Colors.orange),
                          ),
                          Expanded(
                            child: _SensorTypeCount('Accident Det.', '10', Colors.red),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _SensorMetric extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;
  
  const _SensorMetric(this.label, this.value, this.color, this.icon);
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
        Text(label, style: const TextStyle(fontSize: 9), textAlign: TextAlign.center),
      ],
    );
  }
}

class _SensorTypeCount extends StatelessWidget {
  final String label;
  final String count;
  final Color color;
  
  const _SensorTypeCount(this.label, this.count, this.color);
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      child: Column(
        children: [
          Text(count, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: color)),
          Text(label, style: const TextStyle(fontSize: 8), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
