import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../theme_provider.dart';

class RewardPage extends StatefulWidget {
  final int points;
  final int trafficAvoided;
  final int alternateRoutes;
  final String userName;
  final ThemeProvider themeProvider;

  const RewardPage({
    super.key,
    this.points = 500,
    this.trafficAvoided = 25,
    this.alternateRoutes = 32,
    this.userName = 'Martin.P',
    required this.themeProvider,
  });

  @override
  State<RewardPage> createState() => _RewardPageState();
}

class _RewardPageState extends State<RewardPage> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<Candy> _candies = [];
  final math.Random _random = math.Random();
  bool _candiesInitialized = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  Color _getRandomColor() {
    final colors = [
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.yellow,
      Colors.purple,
      Colors.orange,
      Colors.pink,
    ];
    return colors[_random.nextInt(colors.length)];
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _initializeCandies(BuildContext context) {
    if (!_candiesInitialized) {
      _candies.clear();
      final width = MediaQuery.of(context).size.width;
      for (int i = 0; i < 30; i++) {
        _candies.add(Candy(
          x: _random.nextDouble() * width,
          y: -_random.nextDouble() * 100,
          color: _getRandomColor(),
          size: _random.nextDouble() * 8 + 4,
        ));
      }
      _candiesInitialized = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    _initializeCandies(context);
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      body: Stack(
        children: [
          // Candy shower animation
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return CustomPaint(
                painter: CandyPainter(_candies),
                size: Size.infinite,
              );
            },
          ),
          SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Theme toggle button
                    Align(
                      alignment: Alignment.topRight,
                      child: IconButton(
                        icon: Icon(
                          theme.brightness == Brightness.dark
                              ? Icons.light_mode
                              : Icons.dark_mode,
                          color: theme.colorScheme.primary,
                        ),
                        onPressed: () {
                          widget.themeProvider.toggleTheme();
                        },
                      ),
                    ),
                    // User Profile Section
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            theme.colorScheme.primary.withOpacity(0.1),
                            theme.colorScheme.primary.withOpacity(0.05),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 45,
                            backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                            child: Icon(
                              Icons.person,
                              size: 50,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 15),
                          Text(
                            widget.userName,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Stats 2x2 Grid
                    Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildStatCard(
                              context,
                              'Points',
                              widget.points.toString(),
                              Icons.stars_rounded,
                              Colors.amber,
                            ),
                            _buildStatCard(
                              context,
                              'Traffic Avoided',
                              '${widget.trafficAvoided} mins',
                              Icons.traffic_rounded,
                              Colors.green,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildStatCard(
                              context,
                              'Alternate Routes',
                              widget.alternateRoutes.toString(),
                              Icons.alt_route_rounded,
                              Colors.blue,
                            ),
                            _buildStatCard(
                              context,
                              'Total Savings',
                              '₹${widget.points * 2}',
                              Icons.savings_rounded,
                              Colors.purple,
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),

                    // Redeem Button
                    Container(
                      width: 200,
                      height: 45,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            theme.colorScheme.primary,
                            theme.colorScheme.primary.withOpacity(0.8),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: theme.colorScheme.primary.withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: () {
                          // TODO: Implement redeem functionality
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        child: const Text(
                          'Redeem Now',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 15),
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              size: 24,
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class Candy {
  double x;
  double y;
  final Color color;
  final double size;

  Candy({
    required this.x,
    required this.y,
    required this.color,
    required this.size,
  });
}

class CandyPainter extends CustomPainter {
  final List<Candy> candies;

  CandyPainter(this.candies);

  @override
  void paint(Canvas canvas, Size size) {
    for (var candy in candies) {
      final paint = Paint()
        ..color = candy.color
        ..style = PaintingStyle.fill;

      // Draw candy shape
      final path = Path()
        ..moveTo(candy.x, candy.y)
        ..lineTo(candy.x + candy.size, candy.y + candy.size)
        ..lineTo(candy.x, candy.y + candy.size * 2)
        ..lineTo(candy.x - candy.size, candy.y + candy.size)
        ..close();

      canvas.drawPath(path, paint);

      // Update candy position
      candy.y += 6;
      if (candy.y > size.height) {
        candy.y = -candy.size * 2;
        candy.x = math.Random().nextDouble() * size.width;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
} 