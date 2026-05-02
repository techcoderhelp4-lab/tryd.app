import 'package:flutter/material.dart';

class CustomArrowIcon extends StatelessWidget {
  final double size;
  final Color color;

  const CustomArrowIcon({
    super.key,
    this.size = 24.0,
    this.color = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _ArrowPainter(color: color),
    );
  }
}

class _ArrowPainter extends CustomPainter {
  final Color color;

  _ArrowPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final scaleX = size.width / 24;
    final scaleY = size.height / 24;

    final path = Path();

    path.moveTo(13.0586 * scaleX, 18 * scaleY);
    path.cubicTo(
      12.7412 * scaleX, 18 * scaleY,
      12.4375 * scaleX, 17.9266 * scaleY,
      12.1484 * scaleX, 17.7812 * scaleY,
    );
    path.cubicTo(
      11.7874 * scaleX, 17.5775 * scaleY,
      11.4991 * scaleX, 17.2549 * scaleY,
      11.3398 * scaleX, 16.876 * scaleY,
    );
    path.cubicTo(
      11.2386 * scaleX, 16.6139 * scaleY,
      11.0798 * scaleX, 15.8304 * scaleY,
      11.0791 * scaleX, 15.8125 * scaleY,
    );
    path.cubicTo(
      10.9331 * scaleX, 15.0184 * scaleY,
      10.8491 * scaleX, 13.7648 * scaleY,
      10.8369 * scaleX, 12.3604 * scaleY,
    );
    path.lineTo(10.835 * scaleX, 12.0068 * scaleY);
    path.cubicTo(
      10.835 * scaleX, 10.5352 * scaleY,
      10.921 * scaleX, 9.19297 * scaleY,
      11.0508 * scaleX, 8.31836 * scaleY,
    );
    path.lineTo(11.165 * scaleX, 7.77441 * scaleY);
    path.cubicTo(
      11.2283 * scaleX, 7.48651 * scaleY,
      11.3108 * scaleX, 7.15858 * scaleY,
      11.3975 * scaleX, 6.99121 * scaleY,
    );
    path.cubicTo(
      11.7148 * scaleX, 6.37891 * scaleY,
      12.3358 * scaleX, 6.00018 * scaleY,
      13 * scaleX, 6 * scaleY,
    );
    path.lineTo(13.0586 * scaleX, 6 * scaleY);
    path.cubicTo(
      13.4898 * scaleX, 6.01443 * scaleY,
      14.393 * scaleX, 6.39069 * scaleY,
      14.4014 * scaleX, 6.40723 * scaleY,
    );
    path.cubicTo(
      15.8654 * scaleX, 7.02151 * scaleY,
      18.6897 * scaleX, 8.87561 * scaleY,
      19.9941 * scaleX, 10.1973 * scaleY,
    );
    path.lineTo(20.373 * scaleX, 10.5938 * scaleY);
    path.cubicTo(
      20.4722 * scaleX, 10.7012 * scaleY,
      20.5841 * scaleX, 10.8286 * scaleY,
      20.6533 * scaleX, 10.9277 * scaleY,
    );
    path.cubicTo(
      20.8846 * scaleX, 11.2339 * scaleY,
      21 * scaleX, 11.6133 * scaleY,
      21 * scaleX, 11.9922 * scaleY,
    );
    path.cubicTo(
      21 * scaleX, 12.415 * scaleY,
      20.8703 * scaleX, 12.8083 * scaleY,
      20.625 * scaleX, 13.1299 * scaleY,
    );
    path.lineTo(20.2354 * scaleX, 13.5508 * scaleY);
    path.lineTo(20.1484 * scaleX, 13.6406 * scaleY);
    path.cubicTo(
      18.9648 * scaleX, 14.9239 * scaleY,
      15.8735 * scaleX, 17.0219 * scaleY,
      14.2568 * scaleX, 17.6641 * scaleY,
    );
    path.lineTo(14.0127 * scaleX, 17.7578 * scaleY);
    path.cubicTo(
      13.7191 * scaleX, 17.863 * scaleY,
      13.308 * scaleX, 17.9883 * scaleY,
      13.0586 * scaleX, 18 * scaleY,
    );
    path.close();

    path.moveTo(4.50293 * scaleX, 13.5176 * scaleY);
    path.cubicTo(
      3.67305 * scaleX, 13.5174 * scaleY,
      3.00024 * scaleX, 12.8379 * scaleY,
      3 * scaleX, 12 * scaleY,
    );
    path.cubicTo(
      3 * scaleX, 11.1618 * scaleY,
      3.67291 * scaleX, 10.4816 * scaleY,
      4.50293 * scaleX, 10.4814 * scaleY,
    );
    path.lineTo(8.20215 * scaleX, 10.8086 * scaleY);
    path.cubicTo(
      8.85341 * scaleX, 10.8086 * scaleY,
      9.38184 * scaleX, 11.3424 * scaleY,
      9.38184 * scaleX, 12 * scaleY,
    );
    path.cubicTo(
      9.3816 * scaleX, 12.6585 * scaleY,
      8.85327 * scaleX, 13.1904 * scaleY,
      8.20215 * scaleX, 13.1904 * scaleY,
    );
    path.lineTo(4.50293 * scaleX, 13.5176 * scaleY);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_ArrowPainter oldDelegate) => oldDelegate.color != color;
}

