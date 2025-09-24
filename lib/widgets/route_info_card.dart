import 'package:flutter/material.dart';

class RouteInfoCard extends StatelessWidget {
  final String duration;
  final String distance;
  final Color? routeColor;
  final int alternativeRoutesCount;
  final Map<String, dynamic>? destinationWeather;
  final String? trafficImpact;

  const RouteInfoCard({
    Key? key,
    required this.duration,
    required this.distance,
    this.routeColor,
    this.alternativeRoutesCount = 0,
    this.destinationWeather,
    this.trafficImpact,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (alternativeRoutesCount > 1)
          Container(
            margin: EdgeInsets.only(bottom: 8),
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 4,
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
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  'Tap route to select',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Route Summary',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (routeColor != null)
                    Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: routeColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
              SizedBox(height: 6),
              Text(
                'Duration: $duration',
                style: TextStyle(fontSize: 13),
              ),
              Text(
                'Distance: $distance',
                style: TextStyle(fontSize: 13),
              ),
              if (trafficImpact != null) ...[
                SizedBox(height: 6),
                Text(
                  'Traffic: $trafficImpact',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: trafficImpact!.contains('Heavy') ? Colors.red : 
                           (trafficImpact!.contains('Moderate') ? Colors.orange : Colors.green)
                  ),
                ),
              ],
              if (destinationWeather != null) ...[
                SizedBox(height: 12),
                Divider(height: 1, thickness: 0.5),
                SizedBox(height: 8),
                Text(
                  'Destination Weather',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 6),
                Row(
                  children: [
                    if (destinationWeather!['icon'] != null)
                      Image.network(
                        'https://openweathermap.org/img/wn/${destinationWeather!['icon']}@2x.png',
                        width: 40,
                        height: 40,
                      ),
                    SizedBox(width: 6),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${destinationWeather!['city']}',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${destinationWeather!['condition']}',
                            style: TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 6),
                Text(
                  'Temp: ${destinationWeather!['temperature'].toStringAsFixed(1)}°C',
                  style: TextStyle(fontSize: 12),
                ),
                Text(
                  'Humidity: ${destinationWeather!['humidity']}%',
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
} 