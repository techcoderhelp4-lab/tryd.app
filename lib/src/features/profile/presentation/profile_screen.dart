import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../widgets/custom_bottom_navigation.dart';
import '../../../../widgets/custom_arrow_icon.dart';
import '../../../../widgets/custom_chevron_icon.dart';
import '../../activity/presentation/activity_screen.dart';
import '../../rewards/presentation/rewards_screen.dart';
import '../../activity/presentation/workout_screen.dart';
import '../data/user_repository.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  int _selectedIndex = 4; // Profile is at index 4
  bool _showAvatar = true;
  double _topPadding = 130.0;

  void _onSheetDrag(double extent) {
    // extent ranges from minChildSize (0.72) to maxChildSize (0.87 in this case)
    const minSize = 0.72;
    const maxSize = 0.87;
    const threshold = 0.80; 

    // Calculate progress (0.0 to 1.0)
    final progress = ((extent - minSize) / (maxSize - minSize)).clamp(0.0, 1.0);
    
    // Calculate top padding: 130 when closed (0.72), 30 when open (0.87)
    final padding = 130.0 - (100.0 * progress);

    setState(() {
      _showAvatar = extent < threshold;
      _topPadding = padding;
    });
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(userProfileProvider);
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    final horizontalPadding = 14.w; // Based on 0.037 * screenWidth roughly
    final avatarSize = screenWidth * 0.55;
    final headerHeight = screenHeight * 0.32;

    return Scaffold(
      backgroundColor: Colors.white,
      body: userAsync.when(
        data: (user) => Stack(
          children: [
            // Background color
            Container(color: const Color(0xFFF7F7FF)),

            // Pink header background
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: headerHeight,
              child: Container(
                color: const Color(0xFFF7E6EB),
              ),
            ),

            // Navigation buttons in the header
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(top: 28),
                child: _buildHeader(context),
              ),
            ),

            // Draggable Bottom Sheet
            NotificationListener<DraggableScrollableNotification>(
              onNotification: (notification) {
                _onSheetDrag(notification.extent);
                return true;
              },
              child: DraggableScrollableSheet(
                initialChildSize: 0.72,
                minChildSize: 0.72,
                maxChildSize: 0.87,
                snap: true,
                snapSizes: const [0.72, 0.87],
                builder: (BuildContext context, ScrollController scrollController) {
                  final avatarOffset = -(avatarSize / 2);
                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // White Sheet Container
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(33),
                            topRight: Radius.circular(33),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              offset: const Offset(0, -4),
                              blurRadius: 20,
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(33),
                            topRight: Radius.circular(33),
                          ),
                          child: ListView(
                            controller: scrollController,
                            padding: EdgeInsets.only(top: _topPadding),
                            children: [
                              // User Name
                              Center(
                                child: Text(
                                  user.name,
                                  style: GoogleFonts.lexendDeca(
                                    fontSize: 19.sp,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF24252C),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              
                              // Menu items
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                                child: Column(
                                  children: [
                                    _buildMenuItem(
                                      icon: Icons.emoji_events,
                                      title: 'Achievements',
                                      iconColor: const Color(0xFFF83A71),
                                      onTap: () => Navigator.push(
                                        context,
                                        MaterialPageRoute(builder: (context) => const RewardsScreen()),
                                      ),
                                    ),
                                    const SizedBox(height: 7),
                                    _buildMenuItem(
                                      icon: Icons.history,
                                      title: 'Activity',
                                      iconColor: const Color(0xFFF83A71),
                                      onTap: () => Navigator.push(
                                        context,
                                        MaterialPageRoute(builder: (context) => const ActivityScreen()),
                                      ),
                                    ),
                                    const SizedBox(height: 7),
                                    _buildMenuItem(
                                      icon: Icons.fitness_center,
                                      title: 'My Workouts',
                                      iconColor: const Color(0xFFF83A71),
                                      onTap: () => Navigator.push(
                                        context,
                                        MaterialPageRoute(builder: (context) => const WorkoutScreen()),
                                      ),
                                    ),
                                    const SizedBox(height: 7),
                                    _buildMenuItem(
                                      icon: Icons.settings,
                                      title: 'Settings',
                                      iconColor: const Color(0xFFF83A71),
                                      onTap: () {},
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 17),
                              
                              // Plan cards
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                                child: Column(
                                  children: [
                                    _buildFreePlanCard(),
                                    const SizedBox(height: 17),
                                    _buildPremiumPlanCard(),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 140), // Padding for bottom nav
                            ],
                          ),
                        ),
                      ),
                      
                      // Avatar positioned at the top edge of the sheet
                      if (_showAvatar)
                        Positioned(
                          top: avatarOffset,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: _buildAvatar(avatarSize, user.profilePicture),
                          ),
                        ),
                    ],
                  );
                },
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
                  if (index == 4) return; // Already on profile
                  setState(() => _selectedIndex = index);
                  // Add actual navigation logic here if needed
                },
              ),
            ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => _buildErrorView(err.toString()),
      ),
    );
  }

  Widget _buildErrorView(String message) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24.w),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline_rounded, color: const Color(0xFFFD3C6F), size: 64.sp),
          SizedBox(height: 16.h),
          Text(
            'Something went wrong',
            style: GoogleFonts.lexendDeca(
              fontSize: 20.sp,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF24252C),
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            message,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 14.sp,
              color: const Color(0xFF8B88B5),
            ),
          ),
          SizedBox(height: 24.h),
          ElevatedButton(
            onPressed: () => ref.invalidate(userProfileProvider),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF900EBF),
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 12.h),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
            ),
            child: const Text('Retry'),
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
                  size: 30,
                  color: Color(0xFF130F26),
                ),
              ),
            ),
          ),
          Text(
            'Profile',
            style: GoogleFonts.lexendDeca(
              fontSize: 19.sp,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF24252C),
            ),
          ),
          GestureDetector(
            onTap: () {
              // Logout action
            },
            child: const Icon(
              Icons.logout,
              size: 27,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(double size, String? imageUrl) {
    final innerSize = size * 0.85;
    final borderWidth = size * 0.075;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white,
                width: borderWidth,
              ),
            ),
          ),
          Container(
            width: innerSize,
            height: innerSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFCCCCCC),
              image: DecorationImage(
                image: imageUrl != null
                    ? NetworkImage(imageUrl)
                    : const AssetImage('assets/images/profile.png') as ImageProvider,
                fit: BoxFit.cover,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required Color iconColor,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 72,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(
            color: const Color(0xFFF5F3F3).withOpacity(0.62),
          ),
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              offset: const Offset(0, 4),
              blurRadius: 32,
              color: Colors.black.withOpacity(0.04),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  size: 28,
                  color: iconColor,
                ),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF1B2D51),
                  ),
                ),
              ],
            ),
            const CustomChevronIcon(
              size: 10,
              color: Color(0xFF24252C),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFreePlanCard() {
    return Container(
      height: 96,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: const Color(0xFFF5F3F3).withOpacity(0.62),
        ),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            offset: const Offset(0, 4),
            blurRadius: 32,
            color: Colors.black.withOpacity(0.04),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Free Plan',
                style: GoogleFonts.poppins(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w600,
                  height: 1.1,
                  color: const Color(0xFF1B2D51),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'Basic tracking & community access',
                style: GoogleFonts.poppins(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w400,
                  height: 1.67,
                  color: const Color(0xFF96AAD2),
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: const Color(0xFF22D198),
              borderRadius: BorderRadius.circular(222),
            ),
            child: Text(
              'Current',
              style: GoogleFonts.poppins(
                fontSize: 12.sp,
                fontWeight: FontWeight.w400,
                height: 1.25,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumPlanCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment(-1.0, 0.07),
          end: Alignment(1.0, -0.07),
          colors: [Color(0xFF910EBF), Color(0xFFFD3C6F)],
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 21, vertical: 21),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Premium Plan',
                style: GoogleFonts.poppins(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w600,
                  height: 1.1,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Advanced features & exclusive rewards',
                style: GoogleFonts.poppins(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w400,
                  height: 1.67,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              Container(
                width: 145,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.46),
                  borderRadius: BorderRadius.circular(15),
                ),
                alignment: Alignment.center,
                child: Text(
                  'Upgrade Now',
                  style: GoogleFonts.poppins(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                    height: 1.43,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            right: -10,
            bottom: -10,
            child: SvgPicture.asset(
              'assets/images/cup.svg',
              width: 70,
              height: 70,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Icon(Icons.emoji_events, color: Colors.white, size: 50),
            ),
          ),
        ],
      ),
    );
  }
}
