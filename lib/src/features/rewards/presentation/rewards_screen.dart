import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../widgets/custom_bottom_navigation.dart';
import '../../../../widgets/custom_arrow_icon.dart';
import '../../../../widgets/gradient_button.dart';
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

  List<Map<String, dynamic>> get _categories => [
    {'name': 'All', 'icon': 'assets/images/square.svg'},
    {'name': 'Coffee', 'icon': 'assets/images/teacup.svg'},
    {'name': 'Shop', 'icon': 'assets/images/basket.svg'},
    {'name': 'Food', 'icon': 'assets/images/burger.svg'},
    {'name': 'Gym', 'icon': 'assets/images/gym.svg'},
    {'name': 'Books', 'icon': 'assets/images/books.svg'},
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

  final List<Map<String, dynamic>> _redemptions = [
    {
      'title': 'Nike 20% Discount',
      'date': 'Requested on Oct 9, 2025',
      'points': '2,000 points',
      'status': 'pending',
      'message': 'Your request is being reviewed. You\'ll be notified once approved.',
    },
    {
      'title': 'Starbucks Coffee',
      'date': 'Requested on Oct 5, 2025',
      'points': '500 points',
      'status': 'approved',
      'code': 'STAR-XY89-2024',
    },
    {
      'title': 'Gym Day Pass',
      'date': 'Requested on Sep 28, 2025',
      'points': '1,500 points',
      'status': 'approved',
      'code': 'GYM-AB12-2024',
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
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Column(
                    children: [
                      SizedBox(height: 28.h),
                      _buildHeader(context),
                      SizedBox(height: 20.h),
                      _buildPointsSection(),
                      SizedBox(height: 30.h),
                    ],
                  ),
                ),
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _StickyFiltersDelegate(
                    minHeight: _selectedTabIndex == 0 ? 169.h : 80.h,
                    maxHeight: _selectedTabIndex == 0 ? 170.h : 81.h,
                    child: Container(
                      child: Column(
                        children: [
                          _buildTabs(),
                          if (_selectedTabIndex == 0) ...[
                            SizedBox(height: 20.h),
                            _buildCategories(),
                            SizedBox(height: 15.h),
                          ] else
                            SizedBox(height: 30.h),
                        ],
                      ),
                    ),
                  ),
                ),
                _buildRewardsList(),
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

  int _selectedTabIndex = 0;

  Widget _buildTabs() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 26.w),
      height: 50.h,
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
      padding: EdgeInsets.all(8.w),
      child: Row(
        children: [
          Expanded(
            child: _selectedTabIndex == 0
                ? LayoutBuilder(
                    builder: (context, constraints) {
                      return GradientButton(
                        text: 'Available Rewards',
                        onPressed: () {}, // Already selected
                        width: constraints.maxWidth,
                        height: constraints.maxHeight,
                        showIcon: false,
                        textStyle: GoogleFonts.poppins(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      );
                    },
                  )
                : GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedTabIndex = 0;
                      });
                    },
                    child: Container(
                      color: Colors.transparent,
                      alignment: Alignment.center,
                      child: Text(
                        'Available Rewards',
                        style: GoogleFonts.poppins(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF8B88B5),
                        ),
                      ),
                    ),
                  ),
          ),
          Expanded(
            child: _selectedTabIndex == 1
                ? LayoutBuilder(
                    builder: (context, constraints) {
                      return GradientButton(
                        text: 'My Redemptions',
                        onPressed: () {}, // Already selected
                        width: constraints.maxWidth,
                        height: constraints.maxHeight,
                        showIcon: false,
                        textStyle: GoogleFonts.poppins(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      );
                    },
                  )
                : GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedTabIndex = 1;
                      });
                    },
                    child: Container(
                      color: Colors.transparent,
                      alignment: Alignment.center,
                      child: Text(
                        'My Redemptions',
                        style: GoogleFonts.poppins(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF8B88B5),
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategories() {
    return SizedBox(
      height: 84.h,
      child: ListView.separated(
        padding: EdgeInsets.symmetric(horizontal: 26.w),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
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
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (category['icon'] != null)
                    SvgPicture.asset(
                      category['icon'],
                      width: 28.w,
                      height: 28.w,
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
    final items = _selectedTabIndex == 0 ? _rewards : _redemptions;
    return SliverPadding(
      padding: EdgeInsets.only(left: 20.w, right: 20.w, bottom: 120.h),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            if (index.isOdd) return SizedBox(height: 16.h);
            final itemIndex = index ~/ 2;
            
            if (_selectedTabIndex == 0) {
              return _buildRewardCard(_rewards[itemIndex]);
            } else {
              return _buildRedemptionCard(_redemptions[itemIndex]);
            }
          },
          childCount: items.length * 2 - 1,
        ),
      ),
    );
  }

  Widget _buildRewardCard(Map<String, dynamic> reward) {
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
                SizedBox(
                  width: 160.w,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        reward['title'],
                        style: GoogleFonts.poppins(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w400,
                          color: Colors.black,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        reward['subtitle'],
                        style: GoogleFonts.lexendDeca(
                          fontSize: 11.sp,
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
            child: GestureDetector(
              onTap: () {
                _showConfirmRedemptionDialog(context, reward);
              },
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
                    fontSize: 9.sp,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRedemptionCard(Map<String, dynamic> item) {
    if (item['status'] == 'pending') {
      return Container(
        width: 372.w,
        padding: EdgeInsets.all(22.w),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF7ED),
          border: Border.all(color: const Color(0xFFECB953).withOpacity(0.74)),
          borderRadius: BorderRadius.circular(22.r),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
             Column(
               crossAxisAlignment: CrossAxisAlignment.start,
               children: [
                 Text(
                   item['title'],
                   style: GoogleFonts.lexendDeca(
                     fontSize: 14.sp,
                     fontWeight: FontWeight.w600,
                     color: Colors.black,
                   ),
                 ),
                 SizedBox(height: 4.h),
                 Text(
                   item['date'],
                   style: GoogleFonts.poppins(
                     fontSize: 11.sp,
                     color: const Color(0xFF818181),
                   ),
                 ),
                 SizedBox(height: 4.h),
                 Row(
                   children: [
                     Icon(Icons.star, color: const Color(0xFFFFA500), size: 16.sp),
                     SizedBox(width: 3.w),
                     Text(
                       item['points'],
                       style: GoogleFonts.poppins(
                         fontSize: 13.sp,
                         fontWeight: FontWeight.w500,
                         color: Colors.black,
                       ),
                     ),
                   ],
                 ),
               ],
             ),
             SizedBox(height: 16.h),
             Container(
               padding: EdgeInsets.all(10.w),
               decoration: BoxDecoration(
                 border: Border.all(color: const Color(0xFFECB953).withOpacity(0.9)),
                 borderRadius: BorderRadius.circular(6.r),
               ),
               child: Row(
               crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                   Icon(Icons.access_time, color: const Color(0xFFDC931F), size: 20.sp),
                   SizedBox(width: 8.w),
                   Expanded(
                     child: Text(
                       item['message'],
                       style: GoogleFonts.poppins(
                         fontSize: 12.sp,
                         color: const Color(0xFFDC931F),
                         height: 1.2,
                       ),
                     ),
                   ),
                 ],
               ),
             ),
          ],
        ),
      );
    } else {
      return Container(
        width: 372.w,
        padding: EdgeInsets.all(22.w),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFF5F3F3)),
          borderRadius: BorderRadius.circular(15.r),
          boxShadow: [
             BoxShadow(
               color: Colors.black.withOpacity(0.04),
               blurRadius: 32,
               offset: const Offset(0, 4),
             ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
             Column(
               crossAxisAlignment: CrossAxisAlignment.start,
               children: [
                 Text(
                   item['title'],
                   style: GoogleFonts.lexendDeca(
                     fontSize: 14.sp,
                     fontWeight: FontWeight.w600,
                     color: Colors.black,
                   ),
                 ),
                 SizedBox(height: 4.h),
                 Text(
                   item['date'],
                   style: GoogleFonts.poppins(
                     fontSize: 11.sp,
                     color: const Color(0xFF818181),
                   ),
                 ),
                 SizedBox(height: 4.h),
                 Row(
                   children: [
                     Icon(Icons.star, color: const Color(0xFFFFA500), size: 16.sp),
                     SizedBox(width: 3.w),
                     Text(
                       item['points'],
                       style: GoogleFonts.poppins(
                         fontSize: 13.sp,
                         fontWeight: FontWeight.w500,
                         color: Colors.black,
                       ),
                     ),
                   ],
                 ),
               ],
             ),
             SizedBox(height: 16.h),
             CustomPaint(
               foregroundPainter: DashedRectPainter(
                 color: const Color(0xFFF7A1BA), 
                 strokeWidth: 1.0, 
                 gap: 5.0,
                 borderRadius: 13.r,
               ),
               child: Container(
                 height: 52.h,
                 padding: EdgeInsets.symmetric(horizontal: 16.w),
                 decoration: BoxDecoration(
                   color: Colors.white,
                   borderRadius: BorderRadius.circular(13.r),
                 ),
                 child: Row(
                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                   children: [
                     Column(
                       crossAxisAlignment: CrossAxisAlignment.start,
                       mainAxisAlignment: MainAxisAlignment.center,
                       children: [
                         Text(
                           'Your Coupon Code',
                           style: GoogleFonts.poppins(
                             fontSize: 11.sp,
                             fontWeight: FontWeight.w400,
                             color: const Color(0xFF818181),
                           ),
                         ),
                         Text(
                           item['code'],
                           style: GoogleFonts.lexendDeca(
                             fontSize: 14.sp,
                             fontWeight: FontWeight.w600,
                             color: Colors.black,
                           ),
                         ),
                       ],
                     ),
                     Container(
                       padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                       decoration: BoxDecoration(
                         color: const Color(0xFFF7A1BA).withOpacity(0.15),
                         borderRadius: BorderRadius.circular(6.r),
                       ),
                       child: Text(
                         'Copy',
                         style: GoogleFonts.poppins(
                           fontSize: 11.sp,
                           fontWeight: FontWeight.w600,
                           color: const Color(0xFFF83A71),
                         ),
                       ),
                     ),
                   ],
                 ),
               ),
             ),
          ],
        ),
      );
    }
  }

  void _showConfirmRedemptionDialog(BuildContext context, Map<String, dynamic> reward) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22.r),
          ),
          child: Container(
            width: 330.w,
            padding: EdgeInsets.all(22.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22.r),
              boxShadow: [
                 BoxShadow(
                   color: Colors.black.withOpacity(0.25),
                   blurRadius: 6.2,
                   offset: const Offset(0, 4),
                 ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Confirm Redemption',
                  style: GoogleFonts.poppins(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: 20.h),
                Container(
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAF5FE),
                    border: Border.all(color: const Color(0xFF96AAD2).withOpacity(0.22)),
                    borderRadius: BorderRadius.circular(11.r),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.25),
                        blurRadius: 6.2,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 46.w,
                            height: 46.w,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF97316),
                              borderRadius: BorderRadius.circular(10.r),
                            ),
                            child: Center(
                              child: Icon(Icons.shopping_bag_outlined, color: Colors.white, size: 24.sp),
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  reward['title'],
                                  style: GoogleFonts.poppins(
                                    fontSize: 15.sp,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black,
                                  ),
                                ),
                                Text(
                                  reward['subtitle'],
                                  style: GoogleFonts.poppins(
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.w400,
                                    color: const Color(0xFF8B88B5),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                       SizedBox(height: 12.h),
                       Container(
                         height: 1,
                         color: Colors.black.withOpacity(0.1),
                       ),
                       SizedBox(height: 12.h),
                       Row(
                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
                         children: [
                           Text(
                             'Points Required',
                             style: GoogleFonts.poppins(
                               fontSize: 11.sp,
                               fontWeight: FontWeight.w400,
                               color: const Color(0xFF8B88B5),
                             ),
                           ),
                           Row(
                             children: [
                               Icon(Icons.star, color: const Color(0xFFFFA500), size: 16.sp),
                               SizedBox(width: 4.w),
                               Text(
                                 reward['points'],
                                 style: GoogleFonts.poppins(
                                   fontSize: 16.sp,
                                   fontWeight: FontWeight.w600,
                                   color: Colors.black,
                                 ),
                               ),
                             ],
                           ),
                         ],
                       ),
                    ],
                  ),
                ),
                SizedBox(height: 16.h),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(11.r),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                       Column(
                         crossAxisAlignment: CrossAxisAlignment.start,
                         children: [
                           Text(
                             'Current Balance',
                             style: GoogleFonts.poppins(
                               fontSize: 11.sp,
                               fontWeight: FontWeight.w400,
                               color: Colors.black,
                             ),
                           ),
                           Text(
                             'After Redemption',
                             style: GoogleFonts.poppins(
                               fontSize: 11.sp,
                               fontWeight: FontWeight.w400,
                               color: Colors.black,
                             ),
                           ),
                         ],
                       ),
                       Column(
                         crossAxisAlignment: CrossAxisAlignment.end,
                         children: [
                           Text(
                             '12,450 pts',
                             style: GoogleFonts.poppins(
                               fontSize: 11.sp,
                               fontWeight: FontWeight.w500,
                               color: Colors.black,
                             ),
                           ),
                           Text(
                             '10,450 pts',
                             style: GoogleFonts.poppins(
                               fontSize: 11.sp,
                               fontWeight: FontWeight.w500,
                               color: const Color(0xFFF83A71),
                             ),
                           ),
                         ],
                       ),
                    ],
                  ),
                ),
                SizedBox(height: 24.h),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          height: 37.h,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3F4F6), // Updated bg color
                            borderRadius: BorderRadius.circular(9.r),
                            border: Border.all(color: const Color(0xFF900EBF)),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Cancel',
                            style: GoogleFonts.poppins(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF838383),
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                           // Handle redeem logic
                           Navigator.pop(context);
                        },
                        child: Container(
                          height: 37.h,
                          decoration: BoxDecoration(
                            color: const Color(0xFF900EBF),
                            borderRadius: BorderRadius.circular(9.r),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Confirm Redeem',
                            style: GoogleFonts.poppins(
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _StickyFiltersDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final double minHeight;
  final double maxHeight;

  _StickyFiltersDelegate({
    required this.child,
    required this.minHeight,
    required this.maxHeight,
  });

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: shrinkOffset > 0 ? Colors.white : Colors.transparent,
      child: SizedBox.expand(child: child),
    );
  }

  @override
  double get maxExtent => maxHeight;

  @override
  double get minExtent => minHeight;

  @override
  bool shouldRebuild(_StickyFiltersDelegate oldDelegate) {
    return maxHeight != oldDelegate.maxHeight ||
        minHeight != oldDelegate.minHeight ||
        child != oldDelegate.child;
  }
}

class DashedRectPainter extends CustomPainter {
  final double strokeWidth;
  final Color color;
  final double gap;
  final double dash;
  final double borderRadius;

  DashedRectPainter({
    this.strokeWidth = 1.0, 
    this.color = Colors.black, 
    this.gap = 5.0,
    this.dash = 5.0,
    this.borderRadius = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final RRect rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(borderRadius),
    );

    final Path path = Path()..addRRect(rrect);
    
    Path dashedPath = Path();
    for (ui.PathMetric metric in path.computeMetrics()) {
      double distance = 0.0;
      while (distance < metric.length) {
        dashedPath.addPath(
          metric.extractPath(distance, distance + dash),
          Offset.zero,
        );
        distance += dash + gap;
      }
    }
    canvas.drawPath(dashedPath, paint);
  }

  @override
  bool shouldRepaint(DashedRectPainter oldDelegate) {
    return oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.color != color ||
        oldDelegate.gap != gap ||
        oldDelegate.borderRadius != borderRadius;
  }
}
