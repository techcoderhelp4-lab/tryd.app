import 'package:flutter/material.dart';

class CustomCalendarIcon extends StatelessWidget {
  final double size;
  final Color color;

  const CustomCalendarIcon({
    super.key,
    this.size = 24.0,
    this.color = const Color(0xFFF83A71),
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _CalendarIconPainter(color: color),
    );
  }
}

class _CalendarIconPainter extends CustomPainter {
  final Color color;

  _CalendarIconPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0 * (size.width / 24)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final scale = size.width / 24;

    final path = Path();

    // Main calendar rectangle
    path.moveTo(13.5 * scale, 21 * scale);
    path.lineTo(6 * scale, 21 * scale);
    path.cubicTo(5.46957 * scale, 21 * scale, 4.96086 * scale, 20.7893 * scale, 4.58579 * scale, 20.4142 * scale);
    path.cubicTo(4.21071 * scale, 20.0391 * scale, 4 * scale, 19.5304 * scale, 4 * scale, 19 * scale);
    path.lineTo(4 * scale, 7 * scale);
    path.cubicTo(4 * scale, 6.46957 * scale, 4.21071 * scale, 5.96086 * scale, 4.58579 * scale, 5.58579 * scale);
    path.cubicTo(4.96086 * scale, 5.21071 * scale, 5.46957 * scale, 5 * scale, 6 * scale, 5 * scale);
    path.lineTo(18 * scale, 5 * scale);
    path.cubicTo(18.5304 * scale, 5 * scale, 19.0391 * scale, 5.21071 * scale, 19.4142 * scale, 5.58579 * scale);
    path.cubicTo(19.7893 * scale, 5.96086 * scale, 20 * scale, 6.46957 * scale, 20 * scale, 7 * scale);
    path.lineTo(20 * scale, 12 * scale);

    canvas.drawPath(path, paint);

    // Left vertical line (16, 3 to 16, 7)
    final leftLine = Path();
    leftLine.moveTo(16 * scale, 3 * scale);
    leftLine.lineTo(16 * scale, 7 * scale);
    canvas.drawPath(leftLine, paint);

    // Right vertical line (8, 3 to 8, 7)
    final rightLine = Path();
    rightLine.moveTo(8 * scale, 3 * scale);
    rightLine.lineTo(8 * scale, 7 * scale);
    canvas.drawPath(rightLine, paint);

    // Horizontal line (4, 11 to 20, 11)
    final horizontalLine = Path();
    horizontalLine.moveTo(4 * scale, 11 * scale);
    horizontalLine.lineTo(20 * scale, 11 * scale);
    canvas.drawPath(horizontalLine, paint);

    // Lightning bolt (19, 16 -> 17, 19 -> 21, 19 -> 19, 22)
    final bolt = Path();
    bolt.moveTo(19 * scale, 16 * scale);
    bolt.lineTo(17 * scale, 19 * scale);
    bolt.lineTo(21 * scale, 19 * scale);
    bolt.lineTo(19 * scale, 22 * scale);
    canvas.drawPath(bolt, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
