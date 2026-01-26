import 'package:flutter/material.dart';

class CustomRefreshIcon extends StatelessWidget {
  final double size;
  final Color color;

  const CustomRefreshIcon({
    super.key,
    this.size = 28.0,
    this.color = const Color(0xFFFEB720),
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _RefreshIconPainter(color: color),
    );
  }
}

class _RefreshIconPainter extends CustomPainter {
  final Color color;

  _RefreshIconPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final scaleX = size.width / 28;
    final scaleY = size.height / 28;

    // Center circle path
    final circlePath = Path();
    circlePath.addOval(Rect.fromCenter(
      center: Offset(14 * scaleX, 15.1667 * scaleY),
      width: 7 * scaleX,
      height: 7 * scaleY,
    ));
    canvas.drawPath(circlePath, paint);

    // Refresh arrow path
    final arrowPath = Path();

    // Start of the path
    arrowPath.moveTo(24.2865 * scaleX, 13.0503 * scaleY);

    arrowPath.cubicTo(
      24.0128 * scaleX, 11.7063 * scaleY,
      23.4755 * scaleX, 10.4299 * scaleY,
      22.7057 * scaleX, 9.29475 * scaleY,
    );

    arrowPath.cubicTo(
      21.9515 * scaleX, 8.17643 * scaleY,
      20.989 * scaleX, 7.21389 * scaleY,
      19.8707 * scaleX, 6.45975 * scaleY,
    );

    arrowPath.cubicTo(
      18.7341 * scaleX, 5.69264 * scaleY,
      17.4582 * scaleX, 5.15558 * scaleY,
      16.1152 * scaleX, 4.87892 * scaleY,
    );

    arrowPath.cubicTo(
      15.4095 * scaleX, 4.73557 * scaleY,
      14.6909 * scaleX, 4.6652 * scaleY,
      13.9708 * scaleX, 4.66892 * scaleY,
    );

    arrowPath.lineTo(13.9708 * scaleX, 2.33325 * scaleY);
    arrowPath.lineTo(9.33333 * scaleX, 5.83325 * scaleY);
    arrowPath.lineTo(13.9708 * scaleX, 9.33325 * scaleY);
    arrowPath.lineTo(13.9708 * scaleX, 7.00225 * scaleY);

    arrowPath.cubicTo(
      14.5355 * scaleX, 6.99992 * scaleY,
      15.1002 * scaleX, 7.05359 * scaleY,
      15.645 * scaleX, 7.16559 * scaleY,
    );

    arrowPath.cubicTo(
      16.6888 * scaleX, 7.38069 * scaleY,
      17.6805 * scaleX, 7.79804 * scaleY,
      18.564 * scaleX, 8.39409 * scaleY,
    );

    arrowPath.cubicTo(
      19.4349 * scaleX, 8.98109 * scaleY,
      20.1843 * scaleX, 9.73055 * scaleY,
      20.7713 * scaleX, 10.6014 * scaleY,
    );

    arrowPath.cubicTo(
      21.6827 * scaleX, 11.9493 * scaleY,
      22.1687 * scaleX, 13.5395 * scaleY,
      22.1667 * scaleX, 15.1666 * scaleY,
    );

    arrowPath.cubicTo(
      22.1675 * scaleX, 16.2585 * scaleY,
      21.9493 * scaleX, 17.3396 * scaleY,
      21.525 * scaleX, 18.3458 * scaleY,
    );

    arrowPath.cubicTo(
      21.3198 * scaleX, 18.8309 * scaleY,
      21.0682 * scaleX, 19.2951 * scaleY,
      20.7737 * scaleX, 19.7318 * scaleY,
    );

    arrowPath.cubicTo(
      20.4798 * scaleX, 20.1671 * scaleY,
      20.1445 * scaleX, 20.573 * scaleY,
      19.7727 * scaleX, 20.9439 * scaleY,
    );

    arrowPath.cubicTo(
      18.6432 * scaleX, 22.071 * scaleY,
      17.2096 * scaleX, 22.8442 * scaleY,
      15.6473 * scaleX, 23.1688 * scaleY,
    );

    arrowPath.cubicTo(
      14.5609 * scaleX, 23.389 * scaleY,
      13.4414 * scaleX, 23.389 * scaleY,
      12.355 * scaleX, 23.1688 * scaleY,
    );

    arrowPath.cubicTo(
      11.3107 * scaleX, 22.9534 * scaleY,
      10.3186 * scaleX, 22.5357 * scaleY,
      9.43483 * scaleX, 21.9391 * scaleY,
    );

    arrowPath.cubicTo(
      8.56503 * scaleX, 21.3525 * scaleY,
      7.81638 * scaleX, 20.6039 * scaleY,
      7.22983 * scaleX, 19.7341 * scaleY,
    );

    arrowPath.cubicTo(
      6.31957 * scaleX, 18.3848 * scaleY,
      5.83327 * scaleX, 16.7942 * scaleY,
      5.83333 * scaleX, 15.1666 * scaleY,
    );

    arrowPath.lineTo(3.5 * scaleX, 15.1666 * scaleY);

    arrowPath.cubicTo(
      3.49982 * scaleX, 17.2594 * scaleY,
      4.12507 * scaleX, 19.3046 * scaleY,
      5.2955 * scaleX, 21.0396 * scaleY,
    );

    arrowPath.cubicTo(
      6.05141 * scaleX, 22.155 * scaleY,
      7.01274 * scaleX, 23.1163 * scaleY,
      8.12817 * scaleX, 23.8723 * scaleY,
    );

    arrowPath.cubicTo(
      9.86139 * scaleX, 25.0453 * scaleY,
      11.9071 * scaleX, 25.6705 * scaleY,
      14 * scaleX, 25.6666 * scaleY,
    );

    arrowPath.cubicTo(
      14.7109 * scaleX, 25.6672 * scaleY,
      15.4199 * scaleX, 25.5957 * scaleY,
      16.1163 * scaleX, 25.4531 * scaleY,
    );

    arrowPath.cubicTo(
      17.459 * scaleX, 25.1763 * scaleY,
      18.7344 * scaleX, 24.6392 * scaleY,
      19.8707 * scaleX, 23.8723 * scaleY,
    );

    arrowPath.cubicTo(
      20.4282 * scaleX, 23.4956 * scaleY,
      20.9482 * scaleX, 23.0662 * scaleY,
      21.4235 * scaleX, 22.5901 * scaleY,
    );

    arrowPath.cubicTo(
      21.9001 * scaleX, 22.1144 * scaleY,
      22.3299 * scaleX, 21.594 * scaleY,
      22.7068 * scaleX, 21.0361 * scaleY,
    );

    arrowPath.cubicTo(
      23.879 * scaleX, 19.3034 * scaleY,
      24.5037 * scaleX, 17.2585 * scaleY,
      24.5 * scaleX, 15.1666 * scaleY,
    );

    arrowPath.cubicTo(
      24.5007 * scaleX, 14.4557 * scaleY,
      24.4291 * scaleX, 13.7466 * scaleY,
      24.2865 * scaleX, 13.0503 * scaleY,
    );

    arrowPath.close();

    canvas.drawPath(arrowPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
