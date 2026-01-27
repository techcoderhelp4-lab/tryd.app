import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../widgets/custom_bottom_navigation.dart';
import '../../../../widgets/custom_arrow_icon.dart';
import '../../home/presentation/home_screen.dart';
import '../../activity/presentation/running_screen.dart';
import '../../activity/presentation/workout_screen.dart';
import '../../club/presentation/club_screen.dart';

class RewardsScreen extends ConsumerStatefulWidget {
  const RewardsScreen({super.key});

  @override
  ConsumerState<RewardsScreen> createState() => _RewardsScreenState();
}

class _RewardsScreenState extends ConsumerState<RewardsScreen> {
  final int _selectedIndex = 2; // Rewards tab
  String _selectedCategory = 'All';

  final List<Map<String, dynamic>> _categories = [
    {'name': 'All', 'icon': null},
    {'name': 'Cofee', 'icon': 'assets/images/cup.svg'},
    {'name': 'Shop', 'icon': 'assets/images/basket.svg'},
    {'name': 'Food', 'icon': 'assets/images/burger.svg'},
    {'name': 'Gym', 'icon': 'assets/images/gym.svg'},
  ];

  final List<Map<String, dynamic>> _rewards = [
    {
      'title': 'Nike 20% Discount',
      'subtitle': 'Valid on all products',
      'points': '2,000',
      'image': 'assets/images/nike.png',
      'manual': false,
    },
    {
      'title': 'Adidas Gift Voucher',
      'subtitle': 'KD 200 off on purchase',
      'points': '3,000',
      'image': 'assets/images/adidas.png',
      'manual': false,
    },
    {
      'title': 'Monthly Gym Pass',
      'subtitle': '1 month premium access',
      'points': '8,000',
      'image': 'assets/images/gym.png',
      'manual': true,
    },
    {
      'title': 'Starbucks Coffee',
      'subtitle': 'Any grande beverage',
      'points': '500',
      'image': 'assets/images/starbucks.png',
      'manual': false,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Background
          Positioned.fill(
            child: Opacity(
              opacity: 0.8,
              child: Image.asset(
                'assets/images/bg-gradient.png',
                fit: BoxFit.cover,
              ),
            ),
          ),
          
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                SizedBox(height: 28.h),
                _buildHeader(context),
                SizedBox(height: 20.h),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.only(bottom: 120.h),
                    child: Column(
                      children: [
                        _buildPointsSection(),
                        SizedBox(height: 30.h),
                        _buildTabs(),
                        SizedBox(height: 30.h),
                        _buildCategories(),
                        SizedBox(height: 30.h),
                        _buildRewardsList(),
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
                if (index == 2) return;
                
                Widget? page;
                if (index == 0) page = const HomeScreen();
                if (index == 1) page = const RunningScreen();
                if (index == 3) page = const WorkoutScreen();
                if (index == 4) page = const ClubScreen();
                
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

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 26.w),
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
            'Rewards',
            style: GoogleFonts.lexendDeca(
              fontSize: 19.sp,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF24252C),
            ),
          ),
          SizedBox(width: 40.w), // Spacer
        ],
      ),
    );
  }

  Widget _buildPointsSection() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 26.w),
      child: Row(
        children: [
          Container(
            width: 44.w,
            height: 44.w,
            decoration: BoxDecoration(
              color: const Color(0xFFFFD66B),
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: Center(
              child: SvgPicture.asset(
                'assets/images/crown_icon.svg',
                width: 24.w,
                colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
              ),
            ),
          ),
          SizedBox(width: 16.w),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '12,450',
                style: GoogleFonts.poppins(
                  fontSize: 24.sp,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF221F48),
                  height: 1.0,
                ),
              ),
              Text(
                'Your Available Points',
                style: GoogleFonts.lexendDeca(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF221F48),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 26.w),
      height: 57.h,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15.r),
        border: Border.all(color: const Color(0xFFF5F3F3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 32,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(8.w),
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF910EBF), Color(0xFFFD3B6E)],
                  ),
                  borderRadius: BorderRadius.circular(9.r),
                ),
                alignment: Alignment.center,
                child: Text(
                  'Available Rewards',
                  style: GoogleFonts.poppins(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w400,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            Expanded(
              child: Container(
                alignment: Alignment.center,
                child: Text(
                  'My Redemptions',
                  style: GoogleFonts.poppins(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w400,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategories() {
    return SizedBox(
      height: 84.h,
      child: ListView.separated(
        padding: EdgeInsets.symmetric(horizontal: 26.w),
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        separatorBuilder: (_, __) => SizedBox(width: 12.w),
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isAll = category['name'] == 'All';
          final isSelected = _selectedCategory == category['name'];
          
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedCategory = category['name'];
              });
            },
            child: Container(
              width: 64.w,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15.r),
                border: isSelected ? Border.all(color: const Color(0xFF900EBF)) : null,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 32,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (category['icon'] != null)
                    SvgPicture.asset(
                      category['icon'],
                      width: 28.w,
                      height: 28.w,
                      colorFilter: ColorFilter.mode(
                        isSelected ? const Color(0xFF900EBF) : const Color(0xFFFFD66B),
                        BlendMode.srcIn,
                      ),
                    )
                  else
                    Padding(
                      padding: EdgeInsets.all(4.w),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Icon(Icons.grid_view, color: isSelected ? const Color(0xFF900EBF) : const Color(0xFFFFD66B), size: 28.sp),
                        ],
                      ),
                    ),
                  SizedBox(height: 8.h),
                  Text(
                    category['name'],
                    style: GoogleFonts.lexendDeca(
                      fontSize: 11.sp,
                      color: const Color(0xFF1B2D51),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRewardsList() {
    return ListView.separated(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 0),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _rewards.length,
      separatorBuilder: (_, __) => SizedBox(height: 16.h),
      itemBuilder: (context, index) {
        final reward = _rewards[index];
        return Container(
          height: 109.h,
          width: 369.w,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15.r),
            border: Border.all(color: const Color(0xFFF5F3F3)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 32,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            children: [
              Padding(
                padding: EdgeInsets.all(12.w),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 68.w,
                      height: 68.w,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(17.r),
                        image: DecorationImage(
                          image: AssetImage(reward['image']),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    SizedBox(width: 16.w),
                    Container(
                      width: 160.w, // Reduced width to avoid overlap
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            reward['title'],
                            style: GoogleFonts.poppins(
                              fontSize: 12.sp, // Smaller font
                              fontWeight: FontWeight.w400,
                              color: Colors.black,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            reward['subtitle'],
                            style: GoogleFonts.lexendDeca(
                              fontSize: 11.sp, // Smaller subtitle
                              color: const Color(0xFF8B88B5),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 8.h),
                          Row(
                            children: [
                              Icon(Icons.star, color: const Color(0xFFFFA500), size: 16.sp),
                              SizedBox(width: 4.w),
                              Text(
                                reward['points'],
                                style: GoogleFonts.lexendDeca(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black,
                                ),
                              ),
                              SizedBox(width: 4.w),
                              Text(
                                'points',
                                style: GoogleFonts.poppins(
                                  fontSize: 12.sp,
                                  color: const Color(0xFF8B88B5),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                right: 15.w,
                bottom: 11.h,
                child: Container(
                  width: 90.w,
                  height: 37.h,
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFF900EBF)),
                    borderRadius: BorderRadius.circular(9.r),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'Redeem',
                    style: GoogleFonts.poppins(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF900EBF),
                    ),
                  ),
                ),
              ),
              if (reward['manual'] == true)
                Positioned(
                  right: 9.w,
                  top: 9.h,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8337F).withOpacity(0.08),
                      border: Border.all(color: const Color(0xFFE8337F).withOpacity(0.22)),
                      borderRadius: BorderRadius.circular(22.r),
                    ),
                    child: Text(
                      'Manual Approval',
                      style: GoogleFonts.poppins(
                        fontSize: 9.sp, // Smaller font
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
