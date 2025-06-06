import 'package:flutter/material.dart';
import '../theme_provider.dart';

class TrafficConditionPage extends StatefulWidget {
  final ThemeProvider themeProvider;
  const TrafficConditionPage({super.key, required this.themeProvider});

  @override
  State<TrafficConditionPage> createState() => _TrafficConditionPageState();
}

class _TrafficConditionPageState extends State<TrafficConditionPage> {
  // Simulated traffic data
  final List<Map<String, dynamic>> trafficSegments = [
    {'name': 'Main Street', 'status': 'Heavy', 'color': Colors.redAccent},
    {'name': '2nd Avenue', 'status': 'Moderate', 'color': Colors.amberAccent},
    {'name': 'Park Lane', 'status': 'Clear', 'color': Colors.greenAccent},
    {'name': 'Highway 7', 'status': 'Heavy', 'color': Colors.redAccent},
    {'name': 'River Road', 'status': 'Moderate', 'color': Colors.amberAccent},
    {'name': 'Sunset Blvd', 'status': 'Clear', 'color': Colors.greenAccent},
  ];

  bool isLoading = false;

  void _refreshTraffic() async {
    setState(() => isLoading = true);
    await Future.delayed(const Duration(seconds: 1));
    setState(() => isLoading = false);
    // Here you would fetch new data
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D47A1),
        title: const Text('Real-Time Traffic Conditions'),
        actions: [
          IconButton(
            icon: Icon(
              widget.themeProvider.value == ThemeMode.dark
                  ? Icons.dark_mode
                  : Icons.light_mode,
              color: Theme.of(context).colorScheme.onPrimary,
            ),
            onPressed: () {
              widget.themeProvider.setTheme(
                widget.themeProvider.value == ThemeMode.dark
                    ? ThemeMode.light
                    : ThemeMode.dark,
              );
            },
            tooltip: 'Toggle Theme',
          ),
          IconButton(
            icon: isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Color(0xFF00E5FF),
                      strokeWidth: 3,
                    ),
                  )
                : const Icon(Icons.refresh, color: Color(0xFF00E5FF)),
            onPressed: isLoading ? null : _refreshTraffic,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1A237E),
              Color(0xFF0D47A1),
              Color(0xFF00E5FF),
            ],
          ),
        ),
        child: Column(
          children: [
            // Map placeholder
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                height: 180,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.cyanAccent, width: 2),
                ),
                child: const Center(
                  child: Text(
                    'Map View (Coming Soon)',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
            // Traffic segments
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: trafficSegments.length,
                itemBuilder: (context, index) {
                  final segment = trafficSegments[index];
                  return Card(
                    color: Colors.white.withOpacity(0.08),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 4,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: segment['color'],
                        radius: 16,
                        child: Icon(
                          segment['status'] == 'Heavy'
                              ? Icons.directions_car
                              : segment['status'] == 'Moderate'
                                  ? Icons.traffic
                                  : Icons.check_circle,
                          color: Colors.white,
                        ),
                      ),
                      title: Text(
                        segment['name'],
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        segment['status'],
                        style: TextStyle(
                          color: segment['color'],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            // Legend
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildLegendDot(Colors.redAccent, 'Heavy'),
                  const SizedBox(width: 16),
                  _buildLegendDot(Colors.amberAccent, 'Moderate'),
                  const SizedBox(width: 16),
                  _buildLegendDot(Colors.greenAccent, 'Clear'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendDot(Color color, String label) {
    return Row(
      children: [
        CircleAvatar(radius: 8, backgroundColor: color),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
} 