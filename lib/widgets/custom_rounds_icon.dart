import 'package:flutter/material.dart';

class CustomRoundsIcon extends StatelessWidget {
  final double size;
  final Color color;

  const CustomRoundsIcon({
    super.key,
    this.size = 28.0,
    this.color = const Color(0xFFF83A71),
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _RoundsIconPainter(color: color),
    );
  }
}

class _RoundsIconPainter extends CustomPainter {
  final Color color;

  _RoundsIconPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2 * (size.width / 20)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final scaleX = size.width / 20;
    final scaleY = size.height / 20;

    // First path - top arrow
    final path1 = Path();
    path1.moveTo(18.1001 * scaleX, 8.53561 * scaleY);
    path1.cubicTo(17.8403 * scaleX, 6.66234 * scaleY, 16.9729 * scaleX, 4.92663 * scaleY, 15.6315 * scaleX, 3.59585 * scaleY);
    path1.cubicTo(14.2902 * scaleX, 2.26506 * scaleY, 12.5493 * scaleX, 1.41303 * scaleY, 10.6771 * scaleX, 1.171 * scaleY);
    path1.cubicTo(8.80491 * scaleX, 0.928975 * scaleY, 6.9052 * scaleX, 1.31038 * scaleY, 5.27062 * scaleX, 2.25645 * scaleY);
    path1.cubicTo(3.63605 * scaleX, 3.20253 * scaleY, 2.3573 * scaleX, 4.6608 * scaleY, 1.63135 * scaleX, 6.40663 * scaleY);
    canvas.drawPath(path1, paint);

    // Arrow head 1
    final path2 = Path();
    path2.moveTo(1.1001 * scaleX, 2.14868 * scaleY);
    path2.lineTo(1.1001 * scaleX, 6.40663 * scaleY);
    path2.lineTo(5.3501 * scaleX, 6.40663 * scaleY);
    canvas.drawPath(path2, paint);

    // Second path - bottom arrow
    final path3 = Path();
    path3.moveTo(1.1001 * scaleX, 10.6646 * scaleY);
    path3.cubicTo(1.35994 * scaleX, 12.5379 * scaleY, 2.22734 * scaleX, 14.2736 * scaleY, 3.56867 * scaleX, 15.6043 * scaleY);
    path3.cubicTo(4.91 * scaleX, 16.9351 * scaleY, 6.65086 * scaleX, 17.7872 * scaleY, 8.52307 * scaleX, 18.0292 * scaleY);
    path3.cubicTo(10.3953 * scaleX, 18.2712 * scaleY, 12.295 * scaleX, 17.8898 * scaleY, 13.9296 * scaleX, 16.9437 * scaleY);
    path3.cubicTo(15.5641 * scaleX, 15.9977 * scaleY, 16.8429 * scaleX, 14.5394 * scaleY, 17.5688 * scaleX, 12.7936 * scaleY);
    canvas.drawPath(path3, paint);

    // Arrow head 2
    final path4 = Path();
    path4.moveTo(18.1001 * scaleX, 17.0515 * scaleY);
    path4.lineTo(18.1001 * scaleX, 12.7936 * scaleY);
    path4.lineTo(13.8501 * scaleX, 12.7936 * scaleY);
    canvas.drawPath(path4, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
