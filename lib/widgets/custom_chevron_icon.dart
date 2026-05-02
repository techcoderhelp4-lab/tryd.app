import 'package:flutter/material.dart';

class CustomChevronIcon extends StatelessWidget {
  final double size;
  final Color color;

  const CustomChevronIcon({
    super.key,
    this.size = 12.0,
    this.color = const Color(0xFF24252C),
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size * 1.2),
      painter: _ChevronPainter(color: color),
    );
  }
}

class _ChevronPainter extends CustomPainter {
  final Color color;

  _ChevronPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final scaleX = size.width / 10;
    final scaleY = size.height / 12;

    final path = Path();

    path.moveTo(9.63078 * scaleX, 7.131 * scaleY);
    path.cubicTo(
      9.57428 * scaleX, 7.189 * scaleY,
      9.36094 * scaleX, 7.437 * scaleY,
      9.1622 * scaleX, 7.641 * scaleY,
    );
    path.cubicTo(
      7.99708 * scaleX, 8.924 * scaleY,
      4.95762 * scaleX, 11.024 * scaleY,
      3.36678 * scaleX, 11.665 * scaleY,
    );
    path.cubicTo(
      3.12518 * scaleX, 11.768 * scaleY,
      2.51437 * scaleX, 11.986 * scaleY,
      2.18802 * scaleX, 12 * scaleY,
    );
    path.cubicTo(
      1.8753 * scaleX, 12 * scaleY,
      1.5772 * scaleX, 11.928 * scaleY,
      1.29274 * scaleX, 11.782 * scaleY,
    );
    path.cubicTo(
      0.938139 * scaleX, 11.578 * scaleY,
      0.653678 * scaleX, 11.257 * scaleY,
      0.497808 * scaleX, 10.878 * scaleY,
    );
    path.cubicTo(
      0.397467 * scaleX, 10.615 * scaleY,
      0.241598 * scaleX, 9.828 * scaleY,
      0.241598 * scaleX, 9.814 * scaleY,
    );
    path.cubicTo(
      0.0857281 * scaleX, 8.953 * scaleY,
      0 * scaleX, 7.554 * scaleY,
      0 * scaleX, 6.008 * scaleY,
    );
    path.cubicTo(
      0 * scaleX, 4.535 * scaleY,
      0.0857278 * scaleX, 3.193 * scaleY,
      0.213346 * scaleX, 2.319 * scaleY,
    );
    path.cubicTo(
      0.227959 * scaleX, 2.305 * scaleY,
      0.383828 * scaleX, 1.327 * scaleY,
      0.55431 * scaleX, 0.992 * scaleY,
    );
    path.cubicTo(
      0.867023 * scaleX, 0.379999 * scaleY,
      1.47784 * scaleX, 0 * scaleY,
      2.13151 * scaleX, 0 * scaleY,
    );
    path.lineTo(2.18802 * scaleX, 0 * scaleY);
    path.cubicTo(
      2.61374 * scaleX, 0.015 * scaleY,
      3.50901 * scaleX, 0.395 * scaleY,
      3.50901 * scaleX, 0.409 * scaleY,
    );
    path.cubicTo(
      5.01413 * scaleX, 1.051 * scaleY,
      7.98344 * scaleX, 3.048 * scaleY,
      9.17681 * scaleX, 4.375 * scaleY,
    );
    path.cubicTo(
      9.17681 * scaleX, 4.375 * scaleY,
      9.51291 * scaleX, 4.716 * scaleY,
      9.65904 * scaleX, 4.929 * scaleY,
    );
    path.cubicTo(
      9.88699 * scaleX, 5.235 * scaleY,
      10 * scaleX, 5.614 * scaleY,
      10 * scaleX, 5.993 * scaleY,
    );
    path.cubicTo(
      10 * scaleX, 6.416 * scaleY,
      9.87238 * scaleX, 6.81 * scaleY,
      9.63078 * scaleX, 7.131 * scaleY,
    );
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_ChevronPainter oldDelegate) => oldDelegate.color != color;
}

