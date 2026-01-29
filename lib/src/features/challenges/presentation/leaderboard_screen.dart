import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../widgets/custom_bottom_navigation.dart';
import '../../home/presentation/home_screen.dart';
import '../../activity/presentation/running_screen.dart';
import '../../rewards/presentation/rewards_screen.dart';
import '../../activity/presentation/workout_screen.dart';
import '../../club/presentation/club_screen.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/challenge_repository.dart';
import '../domain/leaderboard_data.dart';

class LeaderboardScreen extends ConsumerWidget {
  final String challengeId;
  const LeaderboardScreen({super.key, required this.challengeId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leaderboardAsync = ref.watch(challengeLeaderboardProvider(challengeId));
    return Scaffold(
      body: Stack(
        children: [
          // Background Gradient Image
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
          ),
          
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                _buildAppBar(context),
                Expanded(
                  child: leaderboardAsync.when(
                    data: (data) => SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(15, 0, 15, 20),
                      child: Column(
                        children: [
                          _buildActiveChallengeCard(data.challenge),
                          SizedBox(height: 15.h),
                          _buildLeaderboardCard(data),
                          SizedBox(height: 120.h),
                        ],
                      ),
                    ),
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (err, stack) => Center(
                      child: Padding(
                        padding: const EdgeInsets.all(40.0),
                        child: Column(
                          children: [
                            const Icon(Icons.error_outline, color: Colors.red),
                            const SizedBox(height: 8),
                            Text('Failed to load leaderboard: $err'),
                            TextButton(
                              onPressed: () => ref.invalidate(challengeLeaderboardProvider(challengeId)),
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
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
              currentIndex: 4,
              onTap: (index) {
                if (index == 4) {
                   Navigator.pop(context);
                   return;
                }
                
                Widget? page;
                switch (index) {
                  case 0: page = const HomeScreen(); break;
                  case 1: page = const RunningScreen(); break;
                  case 2: page = const RewardsScreen(); break;
                  case 3: page = const WorkoutScreen(); break;
                }
                
                if (page != null) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => page!),
                  );
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
      padding: const EdgeInsets.fromLTRB(26, 28, 26, 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: SvgPicture.asset(
              'assets/images/back_arrow_icon.svg',
              width: 24,
              height: 24,
              colorFilter: const ColorFilter.mode(
                Color(0xFF24252C),
                BlendMode.srcIn,
              ),
            ),
          ),
          Expanded(
            child: Text(
              'Leaderboard',
              textAlign: TextAlign.center,
              style: GoogleFonts.lexendDeca(
                fontSize: 19,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF24252C),
                height: 24 / 19,
              ),
            ),
          ),
          const SizedBox(width: 24), // Spacer for centering
        ],
      ),
    );
  }

  Widget _buildActiveChallengeCard(LeaderboardChallengeInfo challenge) {
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
                    challenge.title,
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      height: 22 / 18,
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
                        '${challenge.endDate != null ? challenge.endDate!.difference(DateTime.now()).inDays.clamp(0, 999) : 0} Days Remaining',
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
            _buildCircularProgress(challenge.userProgress ?? 0.0, challenge.targetKm),
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

  Widget _buildLeaderboardCard(LeaderboardData data) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: const Color(0xFFF5F3F3).withOpacity(0.74),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 32,
          ),
        ],
        borderRadius: BorderRadius.circular(15),
      ),
      padding: const EdgeInsets.fromLTRB(18.5, 23, 18.5, 23),
      child: Column(
        children: [
          // Header with Your Rank and participants
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Your Rank',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF1B2D51),
                  height: 15 / 18,
                ),
              ),
              Row(
                children: [
                  const Icon(
                    Icons.people_outline,
                    size: 15,
                    color: Color(0xFF1B2D51),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${data.leaderboard.length} participants',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF1B2D51),
                      height: 15 / 14,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 15),
          // Your Rank Box
          Container(
            width: double.infinity,
            height: 61,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7ED),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.only(left: 20),
            child: Text(
              '#${data.currentUserRank}',
              style: GoogleFonts.poppins(
                fontSize: 31,
                fontWeight: FontWeight.w700,
                color: const Color(0xFFF83A71),
                height: 15 / 31,
              ),
            ),
          ),
          const SizedBox(height: 17),
          // Top Performers Rank
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Top Performers Rank',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF1B2D51),
                height: 15 / 18,
              ),
            ),
          ),
          const SizedBox(height: 17),
          // Leaderboard List
          _buildLeaderboardList(data.leaderboard),
        ],
      ),
    );
  }

  Widget _buildLeaderboardList(List<LeaderboardEntry> participants) {
    return Column(
      children: participants.map((participant) {
        return _buildParticipantRow(
          rank: '${participant.rank.toString().padLeft(2, '0')}.',
          name: participant.user.name,
          rankLabel: participant.rank <= 3 ? 'Rank #${participant.rank}' : '',
          km: '${participant.completedKm.toStringAsFixed(2)} KM',
          isYou: participant.isCurrentUser,
          profilePicture: participant.user.profilePicture,
        );
      }).toList(),
    );
  }

  Widget _buildParticipantRow({
    required String rank,
    required String name,
    required String rankLabel,
    required String km,
    required bool isYou,
    String? profilePicture,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      padding: isYou
          ? const EdgeInsets.fromLTRB(10, 11, 13, 12)
          : const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isYou ? const Color(0xFF2CFC44).withOpacity(0.13) : Colors.transparent,
        border: isYou
            ? const Border(
                bottom: BorderSide(
                  color: Color(0xFF2CFC44),
                  width: 2,
                ),
              )
            : const Border(
                bottom: BorderSide(
                  color: Color(0xFFE7EAF0),
                  width: 1,
                ),
              ),
        borderRadius: isYou ? BorderRadius.circular(12) : null,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left side: rank + profile + name
          Row(
            children: [
              // Rank number
              SizedBox(
                width: 26,
                child: Text(
                  rank,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF121212).withOpacity(0.5),
                    height: 16 / 14,
                  ),
                ),
              ),
              const SizedBox(width: 26),
              // Profile image
              ClipOval(
                child: profilePicture != null && profilePicture.startsWith('http')
                  ? Image.network(
                      profilePicture,
                      width: 32,
                      height: 32,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Image.asset(
                        'assets/images/profile.png',
                        width: 32,
                        height: 32,
                        fit: BoxFit.cover,
                      ),
                    )
                  : Image.asset(
                      'assets/images/profile.png',
                      width: 32,
                      height: 32,
                      fit: BoxFit.cover,
                    ),
              ),
              const SizedBox(width: 12),
              // Name and rank label
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF121212),
                      height: 16 / 16,
                    ),
                  ),
                  if (rankLabel.isNotEmpty)
                    Text(
                      rankLabel,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF8B88B5).withOpacity(0.7),
                        height: 20 / 13,
                      ),
                    ),
                ],
              ),
            ],
          ),
          // Right side: KM
          Text(
            km,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF121212).withOpacity(0.5),
              height: 16 / 14,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }
}
