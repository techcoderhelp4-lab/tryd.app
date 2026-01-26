import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../widgets/custom_bottom_navigation.dart';
import 'leaderboard_screen.dart';

class MyChallengeScreen extends StatelessWidget {
  const MyChallengeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Background with bg-gradient.png
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/bg-gradient.png'),
                fit: BoxFit.cover,
                opacity: 0.8,
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // App bar
                    _buildAppBar(context),
                    const SizedBox(height: 30),
                    // Content
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 15),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Active challenge card
                          _buildActiveChallengeCard(),
                          const SizedBox(height: 15),
                          // Details card
                          _buildDetailsCard(),
                          const SizedBox(height: 15),
                          // Leaderboard button
                          _buildLeaderboardButton(context),
                          const SizedBox(height: 15),
                          // Unlock Rewards heading
                          Text(
                            'Unlock Rewards',
                            style: GoogleFonts.lexendDeca(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF221F48),
                              height: 22 / 18,
                            ),
                          ),
                          const SizedBox(height: 15),
                          // Reward card
                          _buildRewardCard(),
                          const SizedBox(height: 120),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Bottom navigation
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: CustomBottomNavigation(
              currentIndex: 4,
              onTap: (index) {
                if (index != 4) {
                  Navigator.pop(context);
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 28),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: SvgPicture.asset(
              'assets/images/back_arrow_icon.svg',
              width: 24,
              height: 24,
            ),
          ),
          Expanded(
            child: Text(
              'My Challenge',
              textAlign: TextAlign.center,
              style: GoogleFonts.lexendDeca(
                fontSize: 19,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF24252C),
                height: 24 / 19,
              ),
            ),
          ),
          const SizedBox(width: 24),
        ],
      ),
    );
  }

  Widget _buildActiveChallengeCard() {
    return Container(
      width: double.infinity,
      height: 146,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [Color(0xFF910EBF), Color(0xFFFD3B6E)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 20,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 22, 29, 22),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Active Challenge badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4FFD5B).withOpacity(0.67),
                      borderRadius: BorderRadius.circular(185),
                    ),
                    child: Text(
                      'Active Challenge',
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                        height: 15 / 10,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Title
                  Text(
                    'End March 160 KM\nChallenge',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      height: 22 / 20,
                    ),
                  ),
                  const Spacer(),
                  // Days Remaining
                  Row(
                    children: [
                      const Icon(
                        Icons.access_time_filled,
                        color: Colors.white,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '2 Days Remaining',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: Colors.white,
                          height: 21 / 14,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Circular progress indicator
            _buildCircularProgress(67.1, 100),
          ],
        ),
      ),
    );
  }

  Widget _buildCircularProgress(double current, double total) {
    final progress = current / total;
    return Center(
      child: SizedBox(
        width: 82,
        height: 82,
        child: Stack(
          children: [
            // Progress indicator with background stroke
            Transform.rotate(
              angle: -1.5708, // -90 degrees to start from top (12 o'clock)
              child: SizedBox(
                width: 82,
                height: 82,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 10,
                  strokeCap: StrokeCap.round,
                  backgroundColor: const Color(0xFFEF60A3),
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFE8DEFF)),
                ),
              ),
            ),
            // Center text
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    current.toString(),
                    style: GoogleFonts.lexendDeca(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${total.toInt()}KM',
                    style: GoogleFonts.lexendDeca(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      height: 1,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFF5F3F3).withOpacity(0.62)),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            offset: const Offset(0, 4),
            blurRadius: 32,
          ),
        ],
      ),
      child: Column(
        children: [
          _buildDetailRow('Total Distance', '100 Km'),
          const SizedBox(height: 7),
          _buildDetailRow('Duration', '6-12 Oct'),
          const SizedBox(height: 7),
          _buildDetailRow('Participants', '19,543 Runners'),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.lexendDeca(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF1B2D51),
            height: 18 / 14,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: const Color(0xFF8B88B5).withOpacity(0.7),
            height: 21 / 14,
          ),
        ),
      ],
    );
  }

  Widget _buildLeaderboardButton(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const LeaderboardScreen(),
          ),
        );
      },
      child: Container(
        width: double.infinity,
        height: 58,
        decoration: BoxDecoration(
          color: const Color(0xFF900EBF),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Leaderboard',
              style: GoogleFonts.lexendDeca(
                fontSize: 19,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                height: 24 / 19,
              ),
            ),
            const SizedBox(width: 12),
            Transform.rotate(
              angle: 3.14159, // 180 degrees
              child: SvgPicture.asset(
                'assets/images/back_arrow_icon.svg',
                width: 24,
                height: 24,
                colorFilter: const ColorFilter.mode(
                  Colors.white,
                  BlendMode.srcIn,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRewardCard() {
    return Container(
      width: double.infinity,
      height: 73,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFF5F3F3).withOpacity(0.62)),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            offset: const Offset(0, 4),
            blurRadius: 32,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 23, vertical: 15),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Run 100 km',
                    style: GoogleFonts.lexendDeca(
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF6E6A7C),
                      height: 14 / 11,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'win 10k points',
                    style: GoogleFonts.lexendDeca(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: Colors.black,
                      height: 18 / 14,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 41,
              height: 41,
              decoration: BoxDecoration(
                color: const Color(0xFFFFE4F2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: SvgPicture.asset(
                  'assets/images/cup.svg',
                  width: 26,
                  height: 26,
                  colorFilter: const ColorFilter.mode(
                    Color(0xFFF83A71),
                    BlendMode.srcIn,
                  ),
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.emoji_events,
                    color: Color(0xFFF83A71),
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
