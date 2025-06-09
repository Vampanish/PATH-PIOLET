import 'package:flutter/material.dart';

class RouteInfoCard extends StatelessWidget {
  final String duration;
  final String distance;
  final Color? routeColor;
  final int alternativeRoutesCount;

  const RouteInfoCard({
    Key? key,
    required this.duration,
    required this.distance,
    this.routeColor,
    this.alternativeRoutesCount = 0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (alternativeRoutesCount > 1)
          Container(
            margin: EdgeInsets.only(bottom: 8),
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$alternativeRoutesCount routes available',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  'Tap route to select',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 6,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(
                children: [
                  Icon(Icons.access_time, color: routeColor ?? Colors.cyanAccent[700]),
                  SizedBox(height: 4),
                  Text(
                    duration,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: routeColor ?? Colors.cyanAccent[700],
                    ),
                  ),
                  Text(
                    'Duration',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              Container(
                height: 40,
                width: 1,
                color: Colors.grey[300],
              ),
              Column(
                children: [
                  Icon(Icons.route, color: routeColor ?? Colors.cyanAccent[700]),
                  SizedBox(height: 4),
                  Text(
                    distance,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: routeColor ?? Colors.cyanAccent[700],
                    ),
                  ),
                  Text(
                    'Distance',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
} 