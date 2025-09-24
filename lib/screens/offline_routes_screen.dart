import 'package:flutter/material.dart';
import '../services/offline_route_service.dart';
import '../models/offline_route.dart';
import 'offline_route_map_screen.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class OfflineRoutesScreen extends StatefulWidget {
  const OfflineRoutesScreen({super.key});

  @override
  State<OfflineRoutesScreen> createState() => _OfflineRoutesScreenState();
}

class _OfflineRoutesScreenState extends State<OfflineRoutesScreen> {
  final OfflineRouteService _routeService = OfflineRouteService();
  List<OfflineRoute> _routes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRoutes();
  }

  Future<void> _loadRoutes() async {
    setState(() => _isLoading = true);
    try {
      final routes = await _routeService.getOfflineRoutes();
      setState(() {
        _routes = routes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading routes: $e')),
      );
    }
  }

  Future<void> _deleteRoute(OfflineRoute route) async {
    try {
      await _routeService.deleteRoute(route.id);
      await _loadRoutes();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Route deleted successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting route: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Offline Routes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadRoutes,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _routes.isEmpty
              ? const Center(
                  child: Text(
                    'No offline routes available.\nDownload routes to view them here.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16),
                  ),
                )
              : ListView.builder(
                  itemCount: _routes.length,
                  itemBuilder: (context, index) {
                    final route = _routes[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: ListTile(
                        title: Text(route.name),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('From: ${route.sourceAddress}'),
                            Text('To: ${route.destinationAddress}'),
                            Text(
                              'Downloaded: ${route.downloadDate.toString().split('.')[0]}',
                            ),
                            Text(
                              'Distance: ${route.distance} • Duration: ${route.duration}',
                            ),
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () => _deleteRoute(route),
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => OfflineRouteMapScreen(
                                route: route,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
    );
  }
} 