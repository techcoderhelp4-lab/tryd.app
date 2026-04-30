import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'button_shape_clipper.dart';

class CustomGradientButton extends StatefulWidget {
  final String text;
  final VoidCallback onAction;
  final double? width;
  final double? height;
  final TextStyle? textStyle;

  const CustomGradientButton({
    super.key,
    required this.text,
    required this.onAction,
    this.width,
    this.height,
    this.textStyle,
  });

  @override
  State<CustomGradientButton> createState() => _CustomGradientButtonState();
}

class _CustomGradientButtonState extends State<CustomGradientButton>
    with SingleTickerProviderStateMixin {
  static const _purple = Color(0xFF900EBF);
  static const _defaultHeight = 52.0;

  late AnimationController _ctrl;
  bool _holding = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _ctrl.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        HapticFeedback.vibrate();
        widget.onAction();
        _ctrl.reset();
        if (mounted) setState(() => _holding = false);
      }
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _down(TapDownDetails _) {
    HapticFeedback.lightImpact();
    setState(() => _holding = true);
    _ctrl.forward();
  }

  void _up(TapUpDetails _) {
    if (_ctrl.isAnimating) _ctrl.reverse();
    if (mounted) setState(() => _holding = false);
  }

  void _cancel() {
    if (_ctrl.isAnimating) _ctrl.reverse();
    if (mounted) setState(() => _holding = false);
  }

  @override
  Widget build(BuildContext context) {
    final buttonWidth =
        widget.width ?? MediaQuery.of(context).size.width * 0.823;
    final buttonHeight = widget.height ?? _defaultHeight;

    return GestureDetector(
      onTapDown: _down,
      onTapUp: _up,
      onTapCancel: _cancel,
      child: AnimatedScale(
        scale: _holding ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutBack,
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (_, child) => Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              child!,
              if (_holding)
                Positioned.fill(
                  child: CustomPaint(
                    painter: _ShapeProgressPainter(
                      progress: _ctrl.value,
                      color: const Color(0xFFF83A71),
                      strokeWidth: 4,
                    ),
                  ),
                ),
            ],
          ),
          child: SizedBox(
            width: buttonWidth,
            height: buttonHeight,
            child: Stack(
              children: [
                // Purple shadow underneath (same as GradientButton)
                Positioned(
                  bottom: -3,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 7,
                    decoration: BoxDecoration(
                      color: _purple,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: Container(
                        decoration: const BoxDecoration(color: _purple),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                          child: const SizedBox.expand(),
                        ),
                      ),
                    ),
                  ),
                ),
                // Button body with same clip shape
                ClipPath(
                  clipper: ButtonShapeClipper(),
                  child: Container(
                    width: buttonWidth,
                    height: buttonHeight,
                    color: _purple,
                    child: Center(
                      child: Text(
                        widget.text,
                        style: widget.textStyle ??
                            GoogleFonts.lexendDeca(
                              fontSize: 19,
                              fontWeight: FontWeight.w600,
                              height: 1.26,
                              color: Colors.white,
                            ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ShapeProgressPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double strokeWidth;

  _ShapeProgressPainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;

    // Build the same path as ButtonShapeClipper scaled to this size
    final clipper = ButtonShapeClipper();
    final path = clipper.getClip(size);

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    // Extract a partial path based on progress using PathMetrics
    final metrics = path.computeMetrics();
    for (final metric in metrics) {
      final extractLength = metric.length * progress;
      final extracted = metric.extractPath(0, extractLength);
      canvas.drawPath(extracted, paint);
    }
  }

  @override
  bool shouldRepaint(_ShapeProgressPainter old) =>
      old.progress != progress || old.color != color;
}
