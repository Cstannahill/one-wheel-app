import 'package:flutter/material.dart';
import 'dart:math' as math;

class SpeedGauge extends StatelessWidget {
  final double speed;
  final double maxSpeed;

  const SpeedGauge({
    super.key,
    required this.speed,
    required this.maxSpeed,
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
            color: const Color(0xFF00D4FF).withOpacity(0.3),
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
              SizedBox(
                width: 120,
                height: 120,
                child: CustomPaint(
                  painter: SpeedGaugePainter(
                    speed: speed,
                    maxSpeed: maxSpeed,
                    color: const Color(0xFF00D4FF),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          speed.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF00D4FF),
                            shadows: [
                              Shadow(
                                color: Color(0xFF00D4FF),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                        ),
                        const Text(
                          'mph',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFFB0B0B0),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Speed',
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
}

class SpeedGaugePainter extends CustomPainter {
  final double speed;
  final double maxSpeed;
  final Color color;

  SpeedGaugePainter({
    required this.speed,
    required this.maxSpeed,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;
    
    // Background arc
    final backgroundPaint = Paint()
      ..color = const Color(0xFF2A2A2A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;
    
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi * 0.8,
      math.pi * 1.6,
      false,
      backgroundPaint,
    );
    
    // Progress arc with gradient
    final progressPaint = Paint()
      ..shader = SweepGradient(
        startAngle: -math.pi * 0.8,
        endAngle: -math.pi * 0.8 + (speed / maxSpeed) * math.pi * 1.6,
        colors: [
          _getSpeedColor(speed, maxSpeed).withOpacity(0.6),
          _getSpeedColor(speed, maxSpeed),
          _getSpeedColor(speed, maxSpeed).withOpacity(0.8),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;
    
    final sweepAngle = (speed / maxSpeed) * math.pi * 1.6;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi * 0.8,
      sweepAngle,
      false,
      progressPaint,
    );
    
    // Glow effect at current position
    if (speed > 0) {
      final glowPaint = Paint()
        ..color = _getSpeedColor(speed, maxSpeed).withOpacity(0.8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi * 0.8 + sweepAngle - 0.05,
        0.1,
        false,
        glowPaint,
      );
    }
    
    // Speed marks
    final markPaint = Paint()
      ..color = const Color(0xFF666666)
      ..strokeWidth = 2;
    
    for (int i = 0; i <= 10; i++) {
      final angle = -math.pi * 0.8 + (i / 10) * math.pi * 1.6;
      final startX = center.dx + (radius - 15) * math.cos(angle);
      final startY = center.dy + (radius - 15) * math.sin(angle);
      final endX = center.dx + (radius - 5) * math.cos(angle);
      final endY = center.dy + (radius - 5) * math.sin(angle);
      
      canvas.drawLine(
        Offset(startX, startY),
        Offset(endX, endY),
        markPaint,
      );
    }
  }

  Color _getSpeedColor(double speed, double maxSpeed) {
    final ratio = speed / maxSpeed;
    if (ratio < 0.5) return const Color(0xFF00FF88); // Bright green
    if (ratio < 0.8) return const Color(0xFFFF9500); // Electric orange
    return const Color(0xFFFF3366); // Electric red
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
