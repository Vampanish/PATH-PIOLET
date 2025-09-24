import 'package:flutter/material.dart';
import '../../../services/matlab_simulation_service.dart';
import '../../../widgets/simulation_viewer_3d.dart';
import '../../../widgets/vehicle_count_display.dart';

class SimulationPage extends StatefulWidget {
  const SimulationPage({super.key});

  @override
  State<SimulationPage> createState() => _SimulationPageState();
}

class _SimulationPageState extends State<SimulationPage> {
  final MatlabSimulationService _simulationService = MatlabSimulationService();

  @override
  void initState() {
    super.initState();
    // Service is a singleton, no initialization needed
  }

  @override
  void dispose() {
    _simulationService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Page Header
          Row(
            children: [
              Icon(
                Icons.computer,
                size: 32,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'MATLAB LIDAR Simulation',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Real-time vehicle detection and 3D visualization',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Simulation Status Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: StreamBuilder<bool>(
                stream: _simulationService.simulationStatusStream,
                builder: (context, snapshot) {
                  final isRunning = snapshot.data ?? false;
                  return Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isRunning ? Colors.green : Colors.grey,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        isRunning ? 'Simulation Running' : 'Simulation Stopped',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const Spacer(),
                      if (isRunning)
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                    ],
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Main Simulation Content
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Use column layout for smaller screens, row for larger
                if (constraints.maxWidth < 800) {
                  return Column(
                    children: [
                      // Vehicle Count Display (top)
                      SizedBox(
                        height: 200,
                        child: VehicleCountDisplay(),
                      ),
                      const SizedBox(height: 16),
                      // 3D Simulation Viewer (bottom)
                      Expanded(
                        child: _SimulationViewer3D(),
                      ),
                    ],
                  );
                } else {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 3D Simulation Viewer (left side)
                      Expanded(
                        flex: 2,
                        child: _SimulationViewer3D(),
                      ),
                      const SizedBox(width: 16),
                      // Vehicle Count Display (right side)
                      SizedBox(
                        width: 320,
                        child: VehicleCountDisplay(),
                      ),
                    ],
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SimulationViewer3D extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.view_in_ar,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  '3D LIDAR Visualization',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    'LIVE',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              color: Colors.black87,
              child: const SimulationViewer3D(),
            ),
          ),
        ],
      ),
    );
  }
}