import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class HoldProgressButton extends StatefulWidget {
  final double scale;
  final double size;
  final bool isRunning;
  final VoidCallback onAction;
  final VoidCallback onTap;
  final bool requireHold;

  const HoldProgressButton({
    super.key,
    required this.scale,
    required this.size,
    required this.isRunning,
    required this.onAction,
    required this.onTap,
    this.requireHold = true,
  });

  @override
  State<HoldProgressButton> createState() => _HoldProgressButtonState();
}

class _HoldProgressButtonState extends State<HoldProgressButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isHolding = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700), // Slightly faster for responsiveness
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        HapticFeedback.vibrate(); // Success haptic
        widget.onAction();
        _controller.reset();
        if (mounted) setState(() => _isHolding = false);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    HapticFeedback.lightImpact(); // Initial touch haptic
    setState(() => _isHolding = true);
    _controller.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    if (_controller.isAnimating) {
      if (!_controller.isCompleted) {
        // If it was a short tap, trigger the hint
        widget.onTap();
      }
      _controller.reverse(); // Smooth return instead of reset
      setState(() => _isHolding = false);
    }
  }

  void _handleTapCancel() {
    if (_controller.isAnimating) {
      _controller.reverse();
      setState(() => _isHolding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.requireHold ? _handleTapDown : null,
      onTapUp: widget.requireHold ? _handleTapUp : null,
      onTapCancel: widget.requireHold ? _handleTapCancel : null,
      onTap: widget.requireHold ? null : () {
        HapticFeedback.mediumImpact();
        widget.onAction();
      },
      child: AnimatedScale(
        scale: _isHolding ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutBack,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Stack(
              alignment: Alignment.center,
              children: [
                // Inner Shadow/Glow effect during hold
                if (_isHolding)
                  Container(
                    width: widget.size + 10,
                    height: widget.size + 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFF83A71).withOpacity(0.2 * _controller.value),
                          blurRadius: 15,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                  ),
                
                // Main Button Container
                Container(
                  width: widget.size,
                  height: widget.size,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.12),
                        offset: const Offset(0, 10),
                        blurRadius: 20,
                      ),
                    ],
                  ),
                  child: Icon(
                    widget.isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    size: 38.0 * widget.scale,
                    color: const Color(0xFFF83A71),
                  ),
                ),
                
                // Progress Indicator
                SizedBox(
                  width: widget.size + 4, // Slightly larger than button
                  height: widget.size + 4,
                  child: CircularProgressIndicator(
                    value: _controller.value,
                    strokeWidth: 4,
                    strokeCap: StrokeCap.round,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      const Color(0xFFF83A71).withOpacity(_isHolding ? 1.0 : 0.0),
                    ),
                    backgroundColor: Colors.transparent,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

