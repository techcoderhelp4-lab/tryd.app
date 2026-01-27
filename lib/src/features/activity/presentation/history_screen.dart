import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../widgets/custom_bottom_navigation.dart';
import '../../../../widgets/custom_arrow_icon.dart';
import '../../../../widgets/custom_calendar_icon.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  int _selectedIndex = 3; // History/Workout tab

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Background gradient image
          Positioned.fill(
            child: Opacity(
              opacity: 0.8,
              child: Image.asset(
                'assets/images/bg-gradient.png',
                fit: BoxFit.cover,
              ),
            ),
          ),
          
          // Main content
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 28),
                _buildHeader(context),
                const SizedBox(height: 52),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        // History card example
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 15),
                          child: _buildHistoryCard(),
                        ),
                        // Add more history cards here if needed via ListView.builder naturally
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                          child: _buildHistoryCard(),
                        ),
                        const SizedBox(height: 140),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Bottom Navigation
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: CustomBottomNavigation(
              currentIndex: _selectedIndex,
              onTap: (index) {
                if (index == 0) {
                  Navigator.pop(context);
                } else {
                  setState(() {
                    _selectedIndex = index;
                  });
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 26),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              child: Transform.scale(
                scaleX: -1,
                child: const CustomArrowIcon(
                  size: 24,
                  color: Color(0xFF130F26),
                ),
              ),
            ),
          ),
          Text(
            'History',
            style: GoogleFonts.lexendDeca(
              fontSize: 19,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF24252C),
            ),
          ),
          const SizedBox(width: 40), // Spacer for alignment
        ],
      ),
    );
  }

  Widget _buildHistoryCard() {
    return Container(
      width: double.infinity,
      height: 159,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: const Color(0xFFE8ECF4).withOpacity(0.49),
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CustomCalendarIcon(
                  size: 24,
                  color: Color(0xFFF83A71),
                ),
                const SizedBox(width: 7),
                Text(
                  '20 Sep 2025',
                  style: GoogleFonts.poppins(
                    fontSize: 19,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF221F48),
                    height: 22 / 19,
                  ),
                ),
                const Spacer(),
                const SizedBox(width: 7),
              ],
            ),
            const SizedBox(height: 18),
            _buildStatsRow(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _buildStatItem('Work', '5'),
          _buildStatItem('Rest', '3'),
          _buildStatItem('Exercises', '7'),
          _buildStatItem('Rounds', '2'),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.roboto(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: const Color(0xFF221F48),
            height: 31 / 14,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.roboto(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF221F48),
            height: 31 / 24,
          ),
        ),
      ],
    );
  }
}
