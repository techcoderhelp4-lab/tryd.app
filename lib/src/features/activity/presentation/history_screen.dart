import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'History',
          style: GoogleFonts.lexendDeca(
            fontSize: 20.sp,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF24252C),
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView.builder(
        padding: EdgeInsets.all(20.w),
        itemCount: 10,
        itemBuilder: (context, index) {
          return Padding(
            padding: EdgeInsets.only(bottom: 16.h),
            child: Row(
              children: [
                Container(
                  width: 50.w,
                  height: 50.h,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Center(
                     child: Text(
                       '${20 - index}\nOCT',
                       textAlign: TextAlign.center,
                       style: GoogleFonts.lexendDeca(
                         fontSize: 12.sp,
                         fontWeight: FontWeight.bold,
                         color: const Color(0xFF8B88B5),
                       ),
                     ),
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Morning Run',
                        style: GoogleFonts.lexendDeca(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF24252C),
                        ),
                      ),
                      Text(
                        '5.24 km • 32:10 min',
                        style: GoogleFonts.poppins(
                          fontSize: 14.sp,
                          color: const Color(0xFF8B88B5),
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '320 kcal',
                  style: GoogleFonts.lexendDeca(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFFD3C6F),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
