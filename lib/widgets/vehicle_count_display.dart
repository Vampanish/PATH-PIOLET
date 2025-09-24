import 'package:flutter/material.dart';
import '../services/matlab_simulation_service.dart';

class VehicleCountDisplay extends StatefulWidget {
  const VehicleCountDisplay({Key? key}) : super(key: key);

  @override
  State<VehicleCountDisplay> createState() => _VehicleCountDisplayState();
}

class _VehicleCountDisplayState extends State<VehicleCountDisplay>
    with SingleTickerProviderStateMixin {
  final MatlabSimulationService _simulationService = MatlabSimulationService();
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  
  int _vehicleCount = 0;
  bool _isSimulationRunning = false;
  Map<String, dynamic>? _simulationData;

  @override
  void initState() {
    super.initState();
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    // Listen to vehicle count updates
    _simulationService.vehicleCountStream.listen((count) {
      if (mounted) {
        setState(() {
          _vehicleCount = count;
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

    // Listen to simulation data for additional info
    _simulationService.simulationDataStream.listen((data) {
      if (mounted) {
        setState(() {
          _simulationData = data;
        });
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            _isSimulationRunning ? Colors.green.withOpacity(0.8) : Colors.grey.withOpacity(0.8),
            _isSimulationRunning ? Colors.teal.withOpacity(0.8) : Colors.grey.withOpacity(0.6),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: _isSimulationRunning ? Colors.green : Colors.grey,
          width: 2,
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // LIDAR Status Icon
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _isSimulationRunning ? _pulseAnimation.value : 1.0,
                child: Icon(
                  Icons.radar,
                  size: 48,
                  color: _isSimulationRunning ? Colors.white : Colors.grey[400],
                ),
              );
            },
          ),

          const SizedBox(height: 16),

          // Title
          Text(
            'LIDAR Vehicle Detection',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 20),

          // Vehicle Count Display
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 500),
            child: Container(
              key: ValueKey(_vehicleCount),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.directions_car,
                    color: Colors.white,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$_vehicleCount',
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Vehicles text
          Text(
            _vehicleCount == 1 ? 'Vehicle Detected' : 'Vehicles Detected',
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(height: 20),

          // Additional Info
          if (_simulationData != null) ...[
            _buildInfoRow('Accuracy', '${(_simulationData!['accuracy'] * 100).toStringAsFixed(1)}%'),
            const SizedBox(height: 8),
            _buildInfoRow('Status', _simulationData!['sensorStatus']),
            const SizedBox(height: 8),
            _buildInfoRow('Last Update', _formatTime(_simulationData!['timestamp'])),
          ],

          const SizedBox(height: 20),

          // Control Buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isSimulationRunning ? null : _startSimulation,
                  icon: const Icon(Icons.play_arrow, size: 18),
                  label: const Text('Start'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isSimulationRunning ? _stopSimulation : null,
                  icon: const Icon(Icons.stop, size: 18),
                  label: const Text('Stop'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '$label:',
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  String _formatTime(String timestamp) {
    try {
      final dateTime = DateTime.parse(timestamp);
      final now = DateTime.now();
      final difference = now.difference(dateTime).inSeconds;
      
      if (difference < 60) {
        return '${difference}s ago';
      } else {
        return '${difference ~/ 60}m ago';
      }
    } catch (e) {
      return 'Unknown';
    }
  }

  void _startSimulation() async {
    final success = await _simulationService.startSimulation();
    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to start MATLAB simulation. Running in demo mode.'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  void _stopSimulation() async {
    await _simulationService.stopSimulation();
  }
}