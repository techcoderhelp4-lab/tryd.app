import 'package:flutter/material.dart';

class CustomWorkIcon extends StatelessWidget {
  final double size;
  final Color color;

  const CustomWorkIcon({
    super.key,
    this.size = 28.0,
    this.color = const Color(0xFF34CDFD),
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size * 22 / 21),
      painter: _WorkIconPainter(color: color),
    );
  }
}

class _WorkIconPainter extends CustomPainter {
  final Color color;

  _WorkIconPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final scaleX = size.width / 21;
    final scaleY = size.height / 22;

    final path = Path();

    // First path - head
    path.moveTo(16.6253 * scaleX, 0.114301 * scaleY);
    path.cubicTo(14.9107 * scaleX, 0.711208 * scaleY, 14.3646 * scaleX, 2.87023 * scaleY, 15.6092 * scaleX, 4.17834 * scaleY);
    path.cubicTo(16.8412 * scaleX, 5.47376 * scaleY, 18.9113 * scaleX, 5.14355 * scaleY, 19.686 * scaleX, 3.51794 * scaleY);
    path.cubicTo(20.0035 * scaleX, 2.83213 * scaleY, 19.9654 * scaleX, 1.86692 * scaleY, 19.5844 * scaleX, 1.23191 * scaleY);
    path.cubicTo(19.1145 * scaleX, 0.444505 * scaleY, 18.3144 * scaleX, 0, 17.4 * scaleX, 0);
    path.cubicTo(17.1079 * scaleX, 0.0127001 * scaleY, 16.8158 * scaleX, 0.0508007 * scaleY, 16.6253 * scaleX, 0.114301 * scaleY);
    path.close();

    // Second path - upper body
    path.moveTo(11.2909 * scaleX, 2.23526 * scaleY);
    path.cubicTo(11.0877 * scaleX, 2.31146 * scaleY, 6.29972 * scaleX, 5.56269 * scaleY, 6.05841 * scaleX, 5.79129 * scaleY);
    path.cubicTo(5.43611 * scaleX, 6.3501 * scaleY, 5.56311 * scaleX, 7.39151 * scaleY, 6.29972 * scaleX, 7.77251 * scaleY);
    path.cubicTo(6.60452 * scaleX, 7.92492 * scaleY, 7.07442 * scaleX, 7.95032 * scaleY, 7.37923 * scaleX, 7.82332 * scaleY);
    path.cubicTo(7.48083 * scaleX, 7.78521 * scaleY, 8.44604 * scaleX, 7.15021 * scaleY, 9.51285 * scaleX, 6.4136 * scaleY);
    path.cubicTo(10.5924 * scaleX, 5.68969 * scaleY, 11.4814 * scaleX, 5.09279 * scaleY, 11.5068 * scaleX, 5.09279 * scaleY);
    path.cubicTo(11.5322 * scaleX, 5.09279 * scaleY, 12.3831 * scaleX, 6.0834 * scaleY, 13.3991 * scaleX, 7.27721 * scaleY);
    path.cubicTo(15.9518 * scaleX, 10.2998 * scaleY, 16.0026 * scaleX, 10.3633 * scaleY, 16.3074 * scaleX, 10.503 * scaleY);
    path.cubicTo(16.536 * scaleX, 10.6046 * scaleY, 16.6884 * scaleX, 10.6173 * scaleY, 18.1362 * scaleX, 10.5919 * scaleY);
    path.lineTo(19.7111 * scaleX, 10.5792 * scaleY);
    path.lineTo(19.9524 * scaleX, 10.4141 * scaleY);
    path.cubicTo(20.308 * scaleX, 10.1855 * scaleY, 20.4985 * scaleX, 9.86804 * scaleY, 20.5366 * scaleX, 9.44893 * scaleY);
    path.cubicTo(20.5747 * scaleX, 8.97903 * scaleY, 20.3588 * scaleX, 8.54722 * scaleY, 19.9397 * scaleX, 8.29322 * scaleY);
    path.lineTo(19.6603 * scaleX, 8.11542 * scaleY);
    path.lineTo(18.5045 * scaleX, 8.09002 * scaleY);
    path.lineTo(17.3488 * scaleX, 8.06462 * scaleY);
    path.lineTo(14.9739 * scaleX, 5.25789 * scaleY);
    path.cubicTo(12.3704 * scaleX, 2.17176 * scaleY, 12.3704 * scaleX, 2.17176 * scaleY, 11.7735 * scaleX, 2.18446 * scaleY);
    path.cubicTo(11.5703 * scaleX, 2.17176 * scaleY, 11.3671 * scaleX, 2.19716 * scaleY, 11.2909 * scaleX, 2.23526 * scaleY);
    path.close();

    // Third path - lower body and legs
    path.moveTo(11.2529 * scaleX, 7.88671 * scaleY);
    path.cubicTo(11.164 * scaleX, 7.93751 * scaleY, 11.0243 * scaleX, 8.02641 * scaleY, 10.9481 * scaleX, 8.07721 * scaleY);
    path.cubicTo(10.6433 * scaleX, 8.30581 * scaleY, 0.203791 * scaleX, 19.266 * scaleY, 0.10219 * scaleX, 19.4565 * scaleY);
    path.cubicTo(-0.113712 * scaleX, 19.901 * scaleY, 0.0259899 * scaleX, 20.5614 * scaleY, 0.394294 * scaleX, 20.9043 * scaleY);
    path.cubicTo(0.711797 * scaleX, 21.2092 * scaleY, 1.2833 * scaleX, 21.2981 * scaleY, 1.72781 * scaleX, 21.1202 * scaleY);
    path.cubicTo(1.91831 * scaleX, 21.044 * scaleY, 2.92162 * scaleX, 20.028 * scaleY, 6.57926 * scaleX, 16.2053 * scaleY);
    path.cubicTo(9.10659 * scaleX, 13.5637 * scaleY, 11.3164 * scaleX, 11.2522 * scaleY, 11.4815 * scaleX, 11.0871 * scaleY);
    path.lineTo(11.7736 * scaleX, 10.7823 * scaleY);
    path.lineTo(13.6405 * scaleX, 12.5604 * scaleY);
    path.lineTo(15.5075 * scaleX, 14.3384 * scaleY);
    path.lineTo(12.815 * scaleX, 14.3638 * scaleY);
    path.lineTo(10.1226 * scaleX, 14.3892 * scaleY);
    path.lineTo(9.8813 * scaleX, 14.5543 * scaleY);
    path.cubicTo(9.74159 * scaleX, 14.6432 * scaleY, 9.56379 * scaleX, 14.821 * scaleY, 9.47489 * scaleX, 14.9607 * scaleY);
    path.cubicTo(9.33519 * scaleX, 15.1639 * scaleY, 9.30979 * scaleX, 15.2655 * scaleY, 9.30979 * scaleX, 15.5957 * scaleY);
    path.cubicTo(9.30979 * scaleX, 16.1164 * scaleY, 9.52569 * scaleX, 16.4847 * scaleY, 9.9575 * scaleX, 16.7006 * scaleY);
    path.lineTo(10.2496 * scaleX, 16.853 * scaleY);
    path.lineTo(14.6184 * scaleX, 16.853 * scaleY);
    path.lineTo(18.9873 * scaleX, 16.853 * scaleY);
    path.lineTo(19.254 * scaleX, 16.7006 * scaleY);
    path.cubicTo(19.6477 * scaleX, 16.472 * scaleY, 19.8636 * scaleX, 16.1418 * scaleY, 19.889 * scaleX, 15.6846 * scaleY);
    path.cubicTo(19.9017 * scaleX, 15.3925 * scaleY, 19.889 * scaleX, 15.2655 * scaleY, 19.7874 * scaleX, 15.075 * scaleY);
    path.cubicTo(19.6985 * scaleX, 14.9099 * scaleY, 18.5809 * scaleX, 13.7923 * scaleY, 16.1552 * scaleX, 11.4808 * scaleY);
    path.cubicTo(14.212 * scaleX, 9.63933 * scaleY, 12.5356 * scaleX, 8.06451 * scaleY, 12.4213 * scaleX, 7.98831 * scaleY);
    path.cubicTo(12.1292 * scaleX, 7.78511 * scaleY, 11.5196 * scaleX, 7.73431 * scaleY, 11.2529 * scaleX, 7.88671 * scaleY);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
