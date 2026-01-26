import 'package:flutter/material.dart';

class CustomClockIcon extends StatelessWidget {
  final double size;
  final Color color;

  const CustomClockIcon({
    super.key,
    this.size = 60.0,
    this.color = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _ClockIconPainter(color: color),
    );
  }
}

class _ClockIconPainter extends CustomPainter {
  final Color color;

  _ClockIconPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.14
      ..strokeCap = StrokeCap.square;

    final scale = size.width / 24;
    final centerX = size.width / 2;
    final centerY = size.height / 2;

    // Offset to center the L shape visually
    final offsetX = 2 * scale;
    final offsetY = -2 * scale;

    // Vertical line (hour hand pointing up)
    canvas.drawLine(
      Offset(centerX - offsetX, centerY - offsetY),
      Offset(centerX - offsetX, centerY - offsetY - 8 * scale),
      paint,
    );

    // Horizontal line (minute hand pointing right)
    canvas.drawLine(
      Offset(centerX - offsetX, centerY - offsetY),
      Offset(centerX - offsetX + 8 * scale, centerY - offsetY),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
