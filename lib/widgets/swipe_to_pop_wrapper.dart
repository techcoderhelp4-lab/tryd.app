import 'package:flutter/material.dart';

// Swipe-back is handled by CupertinoPageTransitionsBuilder set in ThemeData.
// This wrapper is kept so call-sites don't need to be changed.
class SwipeToPopWrapper extends StatefulWidget {
  const SwipeToPopWrapper({super.key, required this.child});
  final Widget child;

  @override
  State<SwipeToPopWrapper> createState() => _SwipeToPopWrapperState();
}

class _SwipeToPopWrapperState extends State<SwipeToPopWrapper> {
  double _dragDistance = 0;

  @override
  Widget build(BuildContext context) {
    if (!Navigator.of(context).canPop()) {
      return widget.child;
    }

    final isRTL = Directionality.of(context) == TextDirection.rtl;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onHorizontalDragStart: (_) {
        _dragDistance = 0;
      },
      onHorizontalDragUpdate: (details) {
        _dragDistance += details.delta.dx;
          
          final screenWidth = MediaQuery.of(context).size.width;
          if (_dragDistance.abs() > screenWidth * 0.25 && Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
            _dragDistance = 0;
          }
      },
      onHorizontalDragEnd: (details) {
        final velocity = details.primaryVelocity ?? 0;
        final screenWidth = MediaQuery.of(context).size.width;
        final distanceThreshold = screenWidth * 0.10; 
        final velocityThreshold = 250.0; 
        
        if ((_dragDistance.abs() > distanceThreshold || velocity.abs() > velocityThreshold) && Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
        
        _dragDistance = 0;
      },
      onHorizontalDragCancel: () {
        _dragDistance = 0;
      },
      child: widget.child,
    );
  }
}
