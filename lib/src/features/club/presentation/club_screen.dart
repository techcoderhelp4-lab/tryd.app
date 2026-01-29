import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../widgets/gradient_button.dart';
import '../../../../widgets/custom_bottom_navigation.dart';
import '../../challenges/presentation/challenge_detail_screen.dart';
import '../../challenges/presentation/my_challenge_screen.dart';
import '../../home/presentation/home_screen.dart';
import '../../rewards/presentation/rewards_screen.dart';
import '../../activity/presentation/running_screen.dart';
import '../../activity/presentation/workout_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../challenges/data/challenge_repository.dart';
import '../../challenges/domain/challenge.dart';
import 'package:intl/intl.dart';

class ClubScreen extends ConsumerStatefulWidget {
  const ClubScreen({super.key});

  @override
  ConsumerState<ClubScreen> createState() => _ClubScreenState();
}

class _ClubScreenState extends ConsumerState<ClubScreen> {
  String _selectedTab = 'My Challenges';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
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
          child: Stack(
            children: [
              SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 15),
                    // Hero Image
                    Container(
                      width: double.infinity,
                      height: 325,
                      margin: const EdgeInsets.symmetric(horizontal: 0),
                      child: Stack(
                        children: [
                          // Challenges image
                          Positioned.fill(
                            child: Image.asset(
                              'assets/images/challenges.png',
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Container(
                                color: Colors.grey[300],
                                child: const Center(child: Icon(Icons.image, size: 50)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),
                    // Title
                    Text(
                      'Challenges',
                      style: GoogleFonts.lexendDeca(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1B2D51),
                        height: 30 / 24,
                      ),
                    ),
                    const SizedBox(height: 18),
                    // Subtitle
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'Join Challenge and surprise points waiting for you once you finish the challenge.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF1B2D51),
                          height: 21 / 14,
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    // Tab Buttons
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 22),
                      child: _buildTabButtons(),
                    ),
                    const SizedBox(height: 23),
                    // Content based on selected tab
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 22),
                      child: ref.watch(challengesListProvider).when(
                        data: (challenges) {
                          final myChallenges = challenges.where((c) => c.isJoined).toList();
                          final availableChallenges = challenges.where((c) => !c.isJoined).toList();

                          if (_selectedTab == 'My Challenges') {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'My Challenges',
                                  style: GoogleFonts.lexendDeca(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF1B2D51),
                                    height: 22 / 18,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                if (myChallenges.isEmpty)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 20),
                                    child: Center(
                                      child: Text(
                                        'No joined challenges yet.',
                                        style: GoogleFonts.poppins(color: Colors.grey),
                                      ),
                                    ),
                                  )
                                else
                                  ...myChallenges.map((challenge) => Padding(
                                    padding: const EdgeInsets.only(bottom: 23),
                                    child: _buildChallengeCard(
                                      challenge: challenge,
                                      isActive: true,
                                    ),
                                  )),
                                
                                // Previous Challenge Section (Static or mock for now as per design)
                                Text(
                                  'Previous Challenge',
                                  style: GoogleFonts.lexendDeca(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF1B2D51),
                                    height: 22 / 18,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                _buildChallengeCardMock(
                                  title: 'Spring Sprint 100 KM Challenge',
                                  subtitle: 'Ended 30 September 2025',
                                  progress: '39.46/40 km',
                                  kmBadge: '100',
                                  badgeColor: const Color(0xFF96AAD2),
                                  badgeTextColor: Colors.white,
                                  isActive: false,
                                ),
                              ],
                            );
                          } else {
                            return Column(
                              children: [
                                if (availableChallenges.isEmpty)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 20),
                                    child: Center(
                                      child: Text(
                                        'No available challenges to join.',
                                        style: GoogleFonts.poppins(color: Colors.grey),
                                      ),
                                    ),
                                  )
                                else
                                  ...availableChallenges.map((challenge) => Padding(
                                    padding: const EdgeInsets.only(bottom: 17),
                                    child: _buildJoinChallengeCard(challenge),
                                  )),
                              ],
                            );
                          }
                        },
                        loading: () => const Center(
                          child: Padding(
                            padding: EdgeInsets.all(40.0),
                            child: CircularProgressIndicator(),
                          ),
                        ),
                        error: (err, stack) => Center(
                          child: Padding(
                            padding: const EdgeInsets.all(40.0),
                            child: Column(
                              children: [
                                const Icon(Icons.error_outline, color: Colors.red),
                                const SizedBox(height: 8),
                                Text('Failed to load challenges: $err'),
                                TextButton(
                                  onPressed: () => ref.invalidate(challengesListProvider),
                                  child: const Text('Retry'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 140),
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
                    if (index == 4) return;
                    
                    Widget? page;
                    switch (index) {
                      case 0: page = const HomeScreen(); break;
                      case 1: page = const RunningScreen(); break;
                      case 2: page = const RewardsScreen(); break;
                      case 3: page = WorkoutScreen(); break;
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
        ),
      ),
    );
  }

  Widget _buildTabButtons() {
    return Container(
      width: double.infinity,
      height: 57,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFF5F3F3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            offset: const Offset(0, 4),
            blurRadius: 32,
          ),
        ],
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 8.5),
        child: Row(
          children: [
            Expanded(
              child: _selectedTab == 'My Challenges'
                  ? GradientButton(
                      text: 'My Challenges',
                      onPressed: () {},
                      height: 40,
                      showIcon: false,
                      textStyle: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: Colors.white,
                        height: 21 / 14,
                      ),
                    )
                  : GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedTab = 'My Challenges';
                        });
                      },
                      child: Container(
                        height: 40,
                        alignment: Alignment.center,
                        child: Text(
                          'My Challenges',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: Colors.black,
                            height: 21 / 14,
                          ),
                        ),
                      ),
                    ),
            ),
            Expanded(
              child: _selectedTab == 'Join a Challenge'
                  ? GradientButton(
                      text: 'Join a Challenge',
                      onPressed: () {},
                      height: 40,
                      showIcon: false,
                      textStyle: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: Colors.white,
                        height: 21 / 14,
                      ),
                    )
                  : GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedTab = 'Join a Challenge';
                        });
                      },
                      child: Container(
                        height: 40,
                        alignment: Alignment.center,
                        child: Text(
                          'Join a Challenge',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: Colors.black,
                            height: 21 / 14,
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

  Widget _buildChallengeCard({
    required Challenge challenge,
    required bool isActive,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MyChallengeScreen(challenge: challenge),
          ),
        );
      },
      child: Container(
        width: double.infinity,
        height: isActive ? 104 : 102,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFF5F3F3)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              offset: const Offset(0, 4),
              blurRadius: 32,
            ),
          ],
          borderRadius: BorderRadius.circular(15),
        ),
        child: Stack(
          children: [
            // Title
            Positioned(
              left: 16,
              top: isActive ? 21 : 20,
              child: SizedBox(
                width: 220,
                child: Text(
                  challenge.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.lexendDeca(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF24252C),
                    height: 18 / 14,
                  ),
                ),
              ),
            ),
            // Subtitle
            Positioned(
              left: 16,
              top: isActive ? 43 : 42,
              child: SizedBox(
                width: 220,
                child: Text(
                  challenge.description,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.lexendDeca(
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF6E6A7C),
                    height: 14 / 11,
                  ),
                ),
              ),
            ),
            // Location icon
            const Positioned(
              left: 14,
              top: 69,
              child: Icon(
                Icons.location_on,
                color: Color(0xFFAB94FF),
                size: 16,
              ),
            ),
            // Progress text
            Positioned(
              left: 36,
              top: 69,
              child: Text(
                '${challenge.targetKm.toStringAsFixed(0)} KM Challenge',
                style: GoogleFonts.lexendDeca(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF24252C),
                  height: 16 / 13,
                ),
              ),
            ),
            // KM Badge
            Positioned(
              right: 11,
              top: 17,
              child: Container(
                width: 43,
                height: 39,
                decoration: BoxDecoration(
                  color: isActive ? const Color(0xFFFFE4F2) : const Color(0xFF96AAD2),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Stack(
                  children: [
                    // "100" text
                    Positioned(
                      left: 5,
                      top: 1,
                      child: Text(
                        challenge.targetKm.toStringAsFixed(0),
                        style: GoogleFonts.lexendDeca(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: isActive ? const Color(0xFFF83A71) : Colors.white,
                          height: 22 / 18,
                        ),
                      ),
                    ),
                    // "KM" text
                    Positioned(
                      left: 14,
                      top: 24,
                      child: Text(
                        'KM',
                        style: GoogleFonts.roboto(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: isActive ? const Color(0xFFF83A71) : Colors.white,
                          height: 13 / 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // View Icon
            if (isActive)
              Positioned(
                right: 13,
                top: 65,
                child: Container(
                  width: 23,
                  height: 23,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.visibility,
                    color: Color(0xFF9260F4),
                    size: 23,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildChallengeCardMock({
    required String title,
    required String subtitle,
    required String progress,
    required String kmBadge,
    required Color badgeColor,
    required Color badgeTextColor,
    required bool isActive,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MyChallengeScreen(
              challenge: Challenge(
                id: 'mock',
                title: title,
                description: subtitle,
                startDate: DateTime.now(),
                endDate: DateTime.now().add(const Duration(days: 7)),
                targetKm: double.tryParse(kmBadge) ?? 100,
                rewardPoints: 1000,
                isJoined: true,
              ),
            ),
          ),
        );
      },
      child: Container(
        width: double.infinity,
        height: isActive ? 104 : 102,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFF5F3F3)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              offset: const Offset(0, 4),
              blurRadius: 32,
            ),
          ],
          borderRadius: BorderRadius.circular(15),
        ),
        child: Stack(
          children: [
            // Title
            Positioned(
              left: 16,
              top: isActive ? 21 : 20,
              child: SizedBox(
                width: 220,
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.visible,
                  style: GoogleFonts.lexendDeca(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF24252C),
                    height: 18 / 14,
                  ),
                ),
              ),
            ),
            // Subtitle
            Positioned(
              left: 16,
              top: isActive ? 43 : 42,
              child: SizedBox(
                width: 220,
                child: Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.visible,
                  style: GoogleFonts.lexendDeca(
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF6E6A7C),
                    height: 14 / 11,
                  ),
                ),
              ),
            ),
            // Location icon
            const Positioned(
              left: 14,
              top: 69,
              child: Icon(
                Icons.location_on,
                color: Color(0xFFAB94FF),
                size: 16,
              ),
            ),
            // Progress text
            Positioned(
              left: 36,
              top: 69,
              child: Text(
                progress,
                style: GoogleFonts.lexendDeca(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF24252C),
                  height: 16 / 13,
                ),
              ),
            ),
            // KM Badge
            Positioned(
              right: 11,
              top: 17,
              child: Container(
                width: 43,
                height: 39,
                decoration: BoxDecoration(
                  color: badgeColor,
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Stack(
                  children: [
                    // "100" text
                    Positioned(
                      left: 5,
                      top: 1,
                      child: Text(
                        kmBadge,
                        style: GoogleFonts.lexendDeca(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: badgeTextColor,
                          height: 22 / 18,
                        ),
                      ),
                    ),
                    // "KM" text
                    Positioned(
                      left: 14,
                      top: 24,
                      child: Text(
                        'KM',
                        style: GoogleFonts.roboto(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: badgeTextColor,
                          height: 13 / 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJoinChallengeCard(Challenge challenge) {
    final timeLeft = challenge.endDate.difference(DateTime.now()).inDays;
    
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChallengeDetailScreen(challengeId: challenge.id),
          ),
        );
      },
      child: Container(
        width: double.infinity,
        height: 260,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFF5F3F3)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              offset: const Offset(0, 4),
              blurRadius: 32,
            ),
          ],
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image at top
            Padding(
              padding: const EdgeInsets.all(11),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: challenge.imageUrl != null && challenge.imageUrl!.startsWith('http')
                  ? Image.network(
                      challenge.imageUrl!,
                      height: 130,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Image.asset(
                        'assets/images/running.png',
                        height: 130,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    )
                  : Image.asset(
                      challenge.imageUrl ?? 'assets/images/running.png',
                      height: 130,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        height: 130,
                        width: double.infinity,
                        color: Colors.grey[300],
                        child: const Icon(Icons.broken_image),
                      ),
                    ),
              ),
            ),
            const SizedBox(height: 8),
            // Content area
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title and subtitle
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          challenge.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.lexendDeca(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF24252C),
                            height: 18 / 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          challenge.description,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.lexendDeca(
                            fontSize: 11,
                            fontWeight: FontWeight.w400,
                            color: const Color(0xFF6E6A7C),
                            height: 13 / 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // KM Badge
                  Container(
                    width: 45.72,
                    height: 41.47,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFE4F2),
                      borderRadius: BorderRadius.circular(7.44),
                    ),
                    child: Stack(
                      children: [
                        // "100" text
                        Positioned(
                          left: 5.32,
                          top: 2.13,
                          child: Text(
                            challenge.targetKm.toStringAsFixed(0),
                            style: GoogleFonts.lexendDeca(
                              fontSize: 19.14,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFFF83A71),
                              height: 24 / 19.14,
                            ),
                          ),
                        ),
                        // "KM" text
                        Positioned(
                          left: 14.89,
                          top: 24.45,
                          child: Text(
                            'KM',
                            style: GoogleFonts.roboto(
                              fontSize: 11.70,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFFF83A71),
                              height: 14 / 11.70,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Time info with clock icon and eye button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                children: [
                  const Icon(
                    Icons.access_time,
                    color: Color(0xFFAB94FF),
                    size: 14,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '${timeLeft >= 0 ? timeLeft : 0} Days remaining  |  ${NumberFormat.compact().format(challenge.rewardPoints)} pts you will win',
                      style: GoogleFonts.lexendDeca(
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF8B88B5),
                        height: 15 / 11,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(
                      Icons.visibility,
                      color: Color(0xFF9260F4),
                      size: 20,
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
}
