import 'package:flutter/material.dart';

class BatteryIndicator extends StatelessWidget {
  final double percentage;
  final double voltage;

  const BatteryIndicator({
    super.key,
    required this.percentage,
    required this.voltage,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF1A1A1A),
            Color(0xFF2A2A2A),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: _getBatteryColor(percentage).withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
          const BoxShadow(
            color: Colors.black26,
            blurRadius: 12,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Card(
        elevation: 0,
        color: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  // Battery outline
                  Container(
                    width: 60,
                    height: 100,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: const Color(0xFF555555),
                        width: 3,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  // Battery tip
                  Positioned(
                    top: -8,
                    child: Container(
                      width: 20,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFF555555),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(4),
                          topRight: Radius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  // Battery fill with gradient and glow
                  Positioned(
                    bottom: 3,
                    child: Container(
                      width: 54,
                      height: (94 * percentage / 100).clamp(0, 94),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            _getBatteryColor(percentage).withOpacity(0.7),
                            _getBatteryColor(percentage),
                          ],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                        ),
                        borderRadius: BorderRadius.circular(4),
                        boxShadow: [
                          BoxShadow(
                            color: _getBatteryColor(percentage).withOpacity(0.6),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Percentage text
                  Text(
                    '${percentage.toInt()}%',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: percentage > 50 
                          ? Colors.white 
                          : const Color(0xFFE0E0E0),
                      shadows: [
                        Shadow(
                          color: _getBatteryColor(percentage).withOpacity(0.5),
                          blurRadius: 2,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                '${voltage.toStringAsFixed(1)}V',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: _getBatteryColor(percentage),
                  shadows: [
                    Shadow(
                      color: _getBatteryColor(percentage).withOpacity(0.5),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
              const Text(
                'Battery',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFFB0B0B0),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getBatteryColor(double percentage) {
    if (percentage > 60) return const Color(0xFF00FF88); // Bright green
    if (percentage > 30) return const Color(0xFFFF9500); // Electric orange
    if (percentage > 15) return const Color(0xFFFF3366); // Electric red
    return const Color(0xFFCC0000); // Deep red
  }
}
