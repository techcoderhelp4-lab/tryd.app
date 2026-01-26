import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:math' as math;
import '../widgets/gradient_button.dart';

class AddTimeScreen extends StatefulWidget {
  const AddTimeScreen({super.key});

  @override
  State<AddTimeScreen> createState() => _AddTimeScreenState();
}

class _AddTimeScreenState extends State<AddTimeScreen> {
  // Total duration in minutes
  int _totalMinutes = 30;
  final int _maxMinutes = 300; // 5 hours max

  @override
  Widget build(BuildContext context) {
    int hours = _totalMinutes ~/ 60;
    int minutes = _totalMinutes % 60;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Set Goal',
          style: GoogleFonts.lexendDeca(
            fontSize: 20.sp,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF24252C),
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF24252C)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Target Duration',
            style: GoogleFonts.poppins(
              fontSize: 16.sp,
              color: const Color(0xFF8B88B5),
            ),
          ),
          SizedBox(height: 30.h),
          
          // Time Display
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              _buildTimeUnit(hours.toString().padLeft(2, '0'), 'HOURS'),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: Text(
                  ':',
                  style: GoogleFonts.lexendDeca(
                    fontSize: 40.sp,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF24252C),
                  ),
                ),
              ),
              _buildTimeUnit(minutes.toString().padLeft(2, '0'), 'MINUTES'),
            ],
          ),
          
          SizedBox(height: 50.h),

          // Waveform Slider
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: _WaveformSlider(
              value: _totalMinutes / _maxMinutes,
              onChanged: (val) {
                setState(() {
                  _totalMinutes = (val * _maxMinutes).round();
                });
              },
            ),
          ),
          
          SizedBox(height: 60.h),

          // Continue Button
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: GradientButton(
              text: 'Set Goal',
              onPressed: () {
                Navigator.pop(context, Duration(minutes: _totalMinutes));
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeUnit(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.lexendDeca(
            fontSize: 64.sp,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF24252C),
            height: 1.0,
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12.sp,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF8B88B5),
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }
}

class _WaveformSlider extends StatelessWidget {
  final double value; // 0.0 to 1.0
  final ValueChanged<double> onChanged;

  const _WaveformSlider({
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragUpdate: (details) {
        final box = context.findRenderObject() as RenderBox;
        final double localDx = details.localPosition.dx;
        final double width = box.size.width;
        
        // Calculate new value based on drag position
        double newValue = localDx / width;
        newValue = newValue.clamp(0.0, 1.0);
        
        onChanged(newValue);
      },
      onTapUp: (details) {
         final box = context.findRenderObject() as RenderBox;
        final double localDx = details.localPosition.dx;
        final double width = box.size.width;
        
        // Calculate new value based on tap position
        double newValue = localDx / width;
        newValue = newValue.clamp(0.0, 1.0);
        
        onChanged(newValue);
      },
      child: SizedBox(
        height: 80.h,
        width: double.infinity,
        child: CustomPaint(
          painter: _WaveformPainter(
            progress: value,
            activeColor: const Color(0xFF900EBF),
            inactiveColor: const Color(0xFFE0E0E0),
          ),
          child: Stack(
            alignment: Alignment.bottomLeft,
            children: [
               // Triangle Indicator
               Positioned(
                 left: 0,
                 right: 0,
                 bottom: 0,
                 child: LayoutBuilder(
                   builder: (context, constraints) {
                     return Align(
                       alignment: Alignment(-1.0 + (value * 2.0), 1.0),
                       child: CustomPaint(
                         size: Size(20.w, 10.h),
                         painter: _TrianglePainter(color: const Color(0xFF900EBF)),
                       ),
                     );
                   }
                 ),
               ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WaveformPainter extends CustomPainter {
  final double progress;
  final Color activeColor;
  final Color inactiveColor;

  _WaveformPainter({
    required this.progress,
    required this.activeColor,
    required this.inactiveColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    
    final int barCount = 40;
    final double barWidth = (size.width / barCount) * 0.6;
    final double spacing = (size.width / barCount) * 0.4;
    
    final random = math.Random(42); // Seeded for consistency

    for (int i = 0; i < barCount; i++) {
      // Determine height
      // Mix of sine wave + random for a nice "audio" look
      double normalizedPos = i / barCount;
      double wave = math.sin(normalizedPos * math.pi * 2) * 0.3 + 0.5;
      double noise = random.nextDouble() * 0.4;
      double heightFactor = (wave + noise).clamp(0.1, 1.0);
      
      double barHeight = size.height * 0.8 * heightFactor;
      
      // Determine color
      if (normalizedPos <= progress) {
        paint.color = activeColor;
      } else {
        paint.color = inactiveColor;
      }

      double left = i * (barWidth + spacing);
      double top = (size.height * 0.8 - barHeight) / 2; // Center vertically in upper area
      
      // Draw rounded rect
      RRect rrect = RRect.fromRectAndRadius(
        Rect.fromLTWH(left, top, barWidth, barHeight),
        Radius.circular(barWidth / 2),
      );
      
      canvas.drawRRect(rrect, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _WaveformPainter oldDelegate) {
    return oldDelegate.progress != progress ||
           oldDelegate.activeColor != activeColor ||
           oldDelegate.inactiveColor != inactiveColor;
  }
}

class _TrianglePainter extends CustomPainter {
  final Color color;

  _TrianglePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, size.height);
    path.lineTo(size.width / 2, 0);
    path.lineTo(size.width, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _TrianglePainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
