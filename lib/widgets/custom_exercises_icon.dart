import 'package:flutter/material.dart';

class CustomExercisesIcon extends StatelessWidget {
  final double size;
  final Color color;

  const CustomExercisesIcon({
    super.key,
    this.size = 28.0,
    this.color = const Color(0xFF5D37E5),
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size * 13 / 22, size),
      painter: _ExercisesIconPainter(color: color),
    );
  }
}

class _ExercisesIconPainter extends CustomPainter {
  final Color color;

  _ExercisesIconPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final scaleX = size.width / 13;
    final scaleY = size.height / 22;

    final path = Path();

    path.moveTo(11.5687 * scaleX, 0.141976 * scaleY);
    path.lineTo(0.201648 * scaleX, 9.03241 * scaleY);
    path.cubicTo(-0.101781 * scaleX, 9.26877 * scaleY, -0.054024 * scaleX, 9.67349 * scaleY, 0.285205 * scaleX, 9.78832 * scaleY);
    path.lineTo(3.36911 * scaleX, 10.8322 * scaleY);
    path.cubicTo(3.63895 * scaleX, 10.9235 * scaleY, 3.71563 * scaleX, 11.0778 * scaleY, 3.61544 * scaleX, 11.3738 * scaleY);
    path.lineTo(0.619991 * scaleX, 20.2232 * scaleY);
    path.cubicTo(0.422391 * scaleX, 20.8069 * scaleY, 0.999155 * scaleX, 21.2862 * scaleY, 1.47389 * scaleX, 20.9246 * scaleY);
    path.lineTo(12.4593 * scaleX, 12.8874 * scaleY);
    path.cubicTo(12.7704 * scaleX, 12.6536 * scaleY, 12.7457 * scaleX, 12.1733 * scaleY, 12.4065 * scaleX, 12.0585 * scaleY);
    path.lineTo(9.70805 * scaleX, 11.1451 * scaleY);
    path.cubicTo(9.32256 * scaleX, 11.0146 * scaleY, 9.07622 * scaleX, 10.473 * scaleY, 9.21538 * scaleX, 10.0619 * scaleY);
    path.lineTo(12.4159 * scaleX, 0.606557 * scaleY);
    path.cubicTo(12.5551 * scaleX, 0.195455 * scaleY, 12.0454 * scaleX, -0.228166 * scaleY, 11.5687 * scaleX, 0.141976 * scaleY);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
