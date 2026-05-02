import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'button_shape_clipper.dart';
import 'custom_arrow_icon.dart';

class GradientButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final double? width;
  final double? height;
  final bool showIcon;
  final TextStyle? textStyle;
  final bool enabled;
  final Color? disabledColor;
  final Color? primaryColor;
  final Color? textColor;
  final bool showShadow;

  const GradientButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.width,
    this.height,
    this.showIcon = true,
    this.textStyle,
    this.enabled = true,
    this.disabledColor,
    this.primaryColor,
    this.textColor,
    this.showShadow = true,
  });

  static const Color _primaryColor = Color(0xFF900EBF);
  static const double _defaultHeight = 52.0;

  @override
  Widget build(BuildContext context) {
    final buttonWidth = width ?? MediaQuery.of(context).size.width * 0.823;

    final bgColor = enabled ? (primaryColor ?? _primaryColor) : (disabledColor ?? const Color(0xFF96AAD2));
    final effectiveTextColor = textColor ?? Colors.white;

    return Opacity(
      opacity: enabled ? 1.0 : 0.85,
      child: Container(
        width: buttonWidth,
        height: height ?? _defaultHeight,
        child: Stack(
          children: [
            if (enabled && showShadow)
              Positioned(
                bottom: -3,
                left: 0,
                right: 0,
                child: Container(
                  height: 7,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [Color(0xFF910EBF), Color(0xFFFD3B6E)],
                      stops: [0.2019, 1.0],
                    ),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [Color(0xFF910EBF), Color(0xFFFD3B6E)],
                          stops: [0.2019, 1.0],
                        ),
                      ),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                        child: Container(
                          color: Colors.transparent,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ClipPath(
              clipper: ButtonShapeClipper(),
              child: Container(
                width: buttonWidth,
                height: height ?? _defaultHeight,
                color: bgColor,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: enabled ? onPressed : null,
                    child: SizedBox(
                      height: height ?? _defaultHeight,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.only(top: 2.0),
                              child: Text(
                                text,
                                textAlign: TextAlign.center,
                                style: textStyle ?? GoogleFonts.tajawal(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  height: 1.0,
                                  color: effectiveTextColor,
                                ),
                              ),
                            ),
                          ),
                          if (showIcon)
                            Positioned(
                              right: 20,
                              child: CustomArrowIcon(
                                size: 24,
                                color: effectiveTextColor,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

