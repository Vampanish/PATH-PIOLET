import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'dart:math' as math;

class CompassWidget extends StatelessWidget {
  final double heading;
  final String languageCode;

  const CompassWidget({
    Key? key,
    required this.heading,
    required this.languageCode,
  }) : super(key: key);

  String _getDirection(double heading) {
    const directions = ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW'];
    final index = ((heading + 22.5) % 360 / 45).floor();
    return directions[index];
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'Compass',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Transform.rotate(
                    angle: (heading * (math.pi / 180) * -1),
                    child: CustomPaint(
                      size: const Size(180, 180),
                      painter: CompassPainter(),
                    ),
                  ),
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white,
                        width: 2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _getDirection(heading),
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '${heading.toStringAsFixed(1)}°',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CompassPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Draw outer circle
    final outerCirclePaint = Paint()
      ..color = Colors.blue.shade100
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, outerCirclePaint);

    // Draw inner circle
    final innerCirclePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius * 0.9, innerCirclePaint);

    // Draw cardinal directions
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    const directions = ['N', 'E', 'S', 'W'];
    const angles = [0.0, 90.0, 180.0, 270.0];

    for (int i = 0; i < directions.length; i++) {
      final angle = angles[i] * (math.pi / 180);
      final x = center.dx + (radius * 0.7) * math.sin(angle);
      final y = center.dy - (radius * 0.7) * math.cos(angle);

      textPainter.text = TextSpan(
        text: directions[i],
        style: TextStyle(
          color: directions[i] == 'N' ? Colors.red : Colors.black,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      );

      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(x - textPainter.width / 2, y - textPainter.height / 2),
      );
    }

    // Draw tick marks
    final tickPaint = Paint()
      ..color = Colors.black
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < 360; i += 30) {
      final angle = i * (math.pi / 180);
      final startRadius = i % 90 == 0 ? radius * 0.7 : radius * 0.8;
      final endRadius = radius * 0.9;

      final startX = center.dx + startRadius * math.sin(angle);
      final startY = center.dy - startRadius * math.cos(angle);
      final endX = center.dx + endRadius * math.sin(angle);
      final endY = center.dy - endRadius * math.cos(angle);

      canvas.drawLine(
        Offset(startX, startY),
        Offset(endX, endY),
        tickPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
} 