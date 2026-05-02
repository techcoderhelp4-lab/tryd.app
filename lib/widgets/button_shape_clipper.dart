import 'package:flutter/material.dart';

class ButtonShapeClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    final scaleX = size.width / 331;
    final scaleY = size.height / 52;

    path.moveTo(0, 15.724 * scaleY);

    path.cubicTo(
      0, 8.10067 * scaleY,
      6.07038 * scaleX, 1.88084 * scaleY,
      13.6925 * scaleX, 1.74209 * scaleY,
    );

    path.cubicTo(
      43.5022 * scaleX, 1.19944 * scaleY,
      115.638 * scaleX, -0.00982954 * scaleY,
      166 * scaleX, 6.10352e-05 * scaleY,
    );

    path.cubicTo(
      215.917 * scaleX, 0.00986421 * scaleY,
      287.606 * scaleX, 1.20648 * scaleY,
      317.308 * scaleX, 1.74385 * scaleY,
    );

    path.cubicTo(
      324.931 * scaleX, 1.88176 * scaleY,
      331 * scaleX, 8.10198 * scaleY,
      331 * scaleX, 15.7262 * scaleY,
    );

    path.lineTo(331 * scaleX, 36.2738 * scaleY);

    path.cubicTo(
      331 * scaleX, 43.898 * scaleY,
      324.931 * scaleX, 50.1183 * scaleY,
      317.308 * scaleX, 50.2562 * scaleY,
    );

    path.cubicTo(
      287.606 * scaleX, 50.7936 * scaleY,
      215.917 * scaleX, 51.9902 * scaleY,
      166 * scaleX, 52 * scaleY,
    );

    path.cubicTo(
      115.638 * scaleX, 52.0099 * scaleY,
      43.5022 * scaleX, 50.8006 * scaleY,
      13.6925 * scaleX, 50.2579 * scaleY,
    );

    path.cubicTo(
      6.07037 * scaleX, 50.1192 * scaleY,
      0, 43.8994 * scaleY,
      0, 36.276 * scaleY,
    );

    path.lineTo(0, 15.724 * scaleY);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

