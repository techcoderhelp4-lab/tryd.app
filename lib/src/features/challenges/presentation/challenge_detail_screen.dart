import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../widgets/gradient_button.dart';
import '../../../../widgets/custom_bottom_navigation.dart';
import '../data/challenge_repository.dart';
import '../domain/challenge.dart';
import 'my_challenge_screen.dart';

class ChallengeDetailScreen extends ConsumerWidget {
  final String challengeId;

  const ChallengeDetailScreen({super.key, required this.challengeId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final challengeAsync = ref.watch(challengeDetailsProvider(challengeId));

    return Scaffold(
      body: Stack(
        children: [
          // Background
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
          
          // Main Content
          SafeArea(
            bottom: false,
            child: challengeAsync.when(
              data: (challenge) => Stack(
                children: [
                   Column(
                    children: [
                      // App bar
                      _buildAppBar(context),
                      
                      // Scrollable Content
                      Expanded(
                        child: SingleChildScrollView(
                          padding: EdgeInsets.symmetric(horizontal: 14.w),
                          child: Column(
                            children: [
                              _buildChallengeHeroCard(challenge),
                              SizedBox(height: 22.h),
                              _buildWinPointsCard(challenge),
                              SizedBox(height: 22.h),
                              _buildDetailsCard(challenge),
                              SizedBox(height: 20.h),
                              _buildJoinButton(context),
                              SizedBox(height: 120.h), // Spacing for bottom nav
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  // Bottom Navigation
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: CustomBottomNavigation(
                      currentIndex: 4,
                      onTap: (index) {
                         if (index != 4) {
                           // Handle navigation or pop
                           Navigator.pop(context);
                         }
                      },
                    ),
                  ),
                ],
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 48),
                    SizedBox(height: 16.h),
                    Text('Error loading challenge', style: GoogleFonts.lexendDeca()),
                    TextButton(
                      onPressed: () => ref.refresh(challengeDetailsProvider(challengeId)),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 26.w, vertical: 28.h),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: SvgPicture.asset(
              'assets/images/back_arrow_icon.svg',
              width: 24.w,
              height: 24.h,
            ),
          ),
          Expanded(
            child: Text(
              'Challenge Detail',
              textAlign: TextAlign.center,
              style: GoogleFonts.lexendDeca(
                fontSize: 19.sp,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF24252C),
                height: 24 / 19,
              ),
            ),
          ),
          SizedBox(width: 24.w), // Balance spacing
        ],
      ),
    );
  }

  Widget _buildChallengeHeroCard(Challenge challenge) {
    final dateFormat = DateFormat('MMM d, yyyy');
    final timeLeft = challenge.endDate.difference(DateTime.now()).inDays;
    
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 20,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15.r),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Challenge image
            Image.asset(
              challenge.imageUrl ?? 'assets/images/running.png',
              width: double.infinity,
              height: 120.h,
              fit: BoxFit.cover,
              errorBuilder: (_,__,___) => Image.asset(
                 'assets/images/running.png',
                 width: double.infinity,
                 height: 120.h,
                 fit: BoxFit.cover,
              ),
            ),
            // Gradient section
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [Color(0xFF910EBF), Color(0xFFFD3B6E)],
                ),
              ),
              padding: EdgeInsets.all(20.w),
              child: Row(
                children: [
                  // Left content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title
                        Text(
                          challenge.title,
                          style: GoogleFonts.lexendDeca(
                            fontSize: 22.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            height: 1.2,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        // Badge
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF83A71).withOpacity(0.73),
                            borderRadius: BorderRadius.circular(222.r),
                          ),
                          child: Text(
                            'You will win ${NumberFormat.compact().format(challenge.rewardPoints)} points',
                            style: GoogleFonts.poppins(
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        SizedBox(height: 12.h),
                        // Date and Time
                        Row(
                          children: [
                            Icon(Icons.calendar_today_rounded, color: Colors.white, size: 14.sp),
                            SizedBox(width: 6.w),
                            Text(
                              dateFormat.format(challenge.startDate),
                              style: GoogleFonts.poppins(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w400,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(width: 16.w),
                            Icon(Icons.access_time_filled, color: Colors.white, size: 14.sp),
                            SizedBox(width: 6.w),
                            Text(
                              '$timeLeft Days Left',
                              style: GoogleFonts.poppins(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w400,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 16.w),
                  // KM Badge (Right side)
                  Container(
                    width: 68.w,
                    height: 93.h,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF5392),
                      borderRadius: BorderRadius.circular(19.43.r),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          challenge.targetKm.toStringAsFixed(0),
                          style: GoogleFonts.poppins(
                            fontSize: 22.96.sp,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            height: 1,
                          ),
                        ),
                        Text(
                          'KM',
                          style: GoogleFonts.poppins(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w400,
                            color: Colors.white,
                          ),
                        ),
                      ],
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

  Widget _buildWinPointsCard(Challenge challenge) {
    final dateFormat = DateFormat('d MMM');
    return Container(
      width: double.infinity,
      height: 73.h,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFF5F3F3).withOpacity(0.55)),
        borderRadius: BorderRadius.circular(15.r),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 23.w, vertical: 15.h),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Win ${NumberFormat.compact().format(challenge.rewardPoints)} points',
                    style: GoogleFonts.lexendDeca(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                      height: 22 / 18,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    'Complete ${challenge.targetKm.toStringAsFixed(0)} km by ${dateFormat.format(challenge.endDate)}',
                    style: GoogleFonts.lexendDeca(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF6E6A7C),
                      height: 14 / 11,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 41.w,
              height: 41.h,
              decoration: BoxDecoration(
                color: const Color(0xFF900EBF).withOpacity(0.15),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Center(
                child: SvgPicture.asset(
                  'assets/images/crown_icon.svg',
                  width: 24.w,
                  height: 24.h,
                  colorFilter: const ColorFilter.mode(
                    Color(0xFF900EBF),
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsCard(Challenge challenge) {
    final dateFormat = DateFormat('d MMM');
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(22.w),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFF5F3F3).withOpacity(0.62)),
        borderRadius: BorderRadius.circular(15.r),
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
          _buildDetailRow('Total Distance', '${challenge.targetKm.toStringAsFixed(0)} Km'),
          SizedBox(height: 7.h),
          _buildDetailRow('Duration', '${dateFormat.format(challenge.startDate)}-${dateFormat.format(challenge.endDate)}'),
          SizedBox(height: 7.h),
          _buildDetailRow('Participants', '19,543 Runners'), // Mock data as it's not in the model
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
          style: GoogleFonts.poppins(
            fontSize: 12.sp,
            color: const Color(0xFF8B88B5),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.lexendDeca(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF24252C),
          ),
        ),
      ],
    );
  }

  Widget _buildJoinButton(BuildContext context) {
    return GradientButton(
      text: 'Join Challenge',
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const MyChallengeScreen()),
        );
      },
      height: 58.h,
    );
  }
}
