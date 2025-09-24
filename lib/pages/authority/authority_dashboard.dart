import 'package:flutter/material.dart';
import '../../theme_provider.dart';
import 'pages/home_page.dart';
import 'pages/signal_monitoring_page.dart';
import 'pages/analytics_page.dart';
import 'pages/alerts_page.dart';
import 'pages/simulation_page.dart';
import 'pages/settings_page.dart';

class AuthorityDashboard extends StatefulWidget {
  final ThemeProvider themeProvider;
  const AuthorityDashboard({super.key, required this.themeProvider});

  @override
  State<AuthorityDashboard> createState() => _AuthorityDashboardState();
}

class _AuthorityDashboardState extends State<AuthorityDashboard> {
  int _index = 0;

  final _pages = const [
    AuthorityHomePage(),
    SignalMonitoringPage(),
    AnalyticsPage(),
    AlertsPage(),
    SimulationPage(),
    AuthoritySettingsPage(),
  ];
  
  final _titles = const [
    'Dashboard',
    'Signals',
    'Analytics',
    'Alerts',
    'Simulation',
    'Settings',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_index]),
        actions: [
          IconButton(
            icon: Icon(widget.themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode),
            onPressed: widget.themeProvider.toggleTheme,
          )
        ],
      ),
      body: _pages[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.traffic_outlined), selectedIcon: Icon(Icons.traffic), label: 'Signals'),
          NavigationDestination(icon: Icon(Icons.insights_outlined), selectedIcon: Icon(Icons.insights), label: 'Analytics'),
          NavigationDestination(icon: Icon(Icons.warning_amber_outlined), selectedIcon: Icon(Icons.warning_amber), label: 'Alerts'),
          NavigationDestination(icon: Icon(Icons.computer_outlined), selectedIcon: Icon(Icons.computer), label: 'Simulation'),
          NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: 'Settings'),
        ],
        onDestinationSelected: (i) => setState(() => _index = i),
      ),
    );
  }
}
