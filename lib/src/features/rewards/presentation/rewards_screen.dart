import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../widgets/custom_arrow_icon.dart';
import '../../../../widgets/skeleton_loading.dart';
import '../../../../widgets/swipe_to_pop_wrapper.dart';
import '../../../shell/main_shell.dart' show mainNavTapProvider;
import '../../home/presentation/home_screen.dart';
import '../../activity/presentation/running_screen.dart';
import '../../activity/presentation/workout_screen.dart';
import '../../club/presentation/club_screen.dart';
import '../../../../widgets/gradient_button.dart';
import '../../profile/data/user_repository.dart';
import '../data/reward_repository.dart';
import '../../notifications/data/real_time_notification_service.dart';
import '../../../../widgets/custom_bottom_navigation.dart';
import '../domain/reward.dart';
import '../domain/redemption.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import '../../../generated/l10n/app_localizations.dart';

class RewardsScreen extends ConsumerStatefulWidget {
  final bool showSwipeBack;
  const RewardsScreen({super.key, this.showSwipeBack = false});

  @override
  ConsumerState<RewardsScreen> createState() => _RewardsScreenState();
}

class _RewardsScreenState extends ConsumerState<RewardsScreen> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  String _selectedCategory = 'All';
  final ScrollController _scrollController = ScrollController();
  bool _isRedeeming = false;

  List<Map<String, dynamic>> get _categories => [
    {'name': 'All', 'icon': 'assets/images/square.svg'},
    {'name': 'Coffee', 'icon': 'assets/images/teacup.svg'},
    {'name': 'Shop', 'icon': 'assets/images/basket.svg'},
    {'name': 'Food', 'icon': 'assets/images/burger.svg'},
    {'name': 'Gym', 'icon': 'assets/images/gym.svg'},
    {'name': 'Books', 'icon': 'assets/images/books.svg'},
  ];

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final userAsync = ref.watch(userProfileProvider);
    final rewardsAsync = ref.watch(filteredRewardsProvider(_selectedCategory == 'All' ? null : _selectedCategory)) as AsyncValue<List<Reward>>;
    final redemptionsAsync = ref.watch(myRedemptionsProvider);
    
    // ── Responsive Scale ──────────────────────────────────
    final size = MediaQuery.of(context).size;
    final screenWidth = size.width;
    final screenHeight = size.height;
    final isTablet = screenWidth > 600;

    const double smallScale  = 0.85;
    const double mediumScale = 0.98;
    const double largeScale  = 1.05;
    const double tabletScale = 1.25;

    final double scale = isTablet
        ? tabletScale
        : screenHeight < 680
            ? smallScale
            : screenHeight < 850
                ? mediumScale
                : largeScale;

    final double tabHeightValue = 50.0 * scale;
    final double tabSpacing0 = 14.0 * scale;
    final double categoryHeightValue = 88.0 * scale;
    final double categoryBottomSpacing = 10.0 * scale;
    final double tabSpacing1 = 20.0 * scale;

    final headerHeightTabIndex0 = tabHeightValue + tabSpacing0 + categoryHeightValue + categoryBottomSpacing;
    final headerHeightTabIndex1 = tabHeightValue + tabSpacing1;

    final l10n = AppLocalizations.of(context)!;
    final isRTL = Localizations.localeOf(context).languageCode == 'ar';
    final fontScale = isRTL ? 1.2 : 1.0;

    final content = Scaffold(
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
              child: RefreshIndicator(
                color: const Color(0xFF900EBF),
                onRefresh: () async {
                  ref.invalidate(userProfileProvider);
                  ref.invalidate(rewardsListProvider);
                  ref.invalidate(myRedemptionsProvider);
                  await Future.delayed(const Duration(seconds: 1));
                },
                child: CustomScrollView(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                  slivers: [
                    SliverToBoxAdapter(
                      child: Column(
                        children: [
                          SizedBox(height: 24.0 * scale),
                          _buildHeader(context, isTablet, scale, l10n, isRTL, fontScale),
                          SizedBox(height: 16.0 * scale),
                          userAsync.when(
                            data: (user) => _buildPointsSection(user.points ?? 0, isTablet, scale, l10n, isRTL, fontScale),
                            loading: () => _buildPointsSection(null, isTablet, scale, l10n, isRTL, fontScale),
                            error: (_, __) => _buildPointsSection(0, isTablet, scale, l10n, isRTL, fontScale),
                          ),
                          SizedBox(height: 24.0 * scale),
                        ],
                      ),
                    ),
                    SliverPersistentHeader(
                      pinned: true,
                      delegate: _StickyFiltersDelegate(
                        minHeight: _selectedTabIndex == 0 ? headerHeightTabIndex0 : headerHeightTabIndex1,
                        maxHeight: (_selectedTabIndex == 0 ? headerHeightTabIndex0 : headerHeightTabIndex1) + 1.0,
                        child: Container(
                          child: Column(
                            children: [
                              _buildTabs(isTablet, scale, l10n, isRTL, fontScale),
                              if (_selectedTabIndex == 0) ...[
                                SizedBox(height: tabSpacing0),
                                _buildCategories(isTablet, scale, l10n, isRTL),
                                SizedBox(height: categoryBottomSpacing),
                              ] else
                                SizedBox(height: tabSpacing1),
                            ],
                          ),
                        ),
                      ),
                    ),
                    _buildRewardsList(rewardsAsync, redemptionsAsync, isTablet, headerHeightTabIndex0, scale, l10n, isRTL, fontScale),
                  ],
                ),
              ),
            ),
  
            if (Navigator.of(context).canPop())
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: CustomBottomNavigation(
                  currentIndex: 2,
                  onTap: (index) {
                    if (index == 2) return;
                    Navigator.of(context).popUntil((route) => route.isFirst);
                    ref.read(mainNavTapProvider)?.call(index);
                  },
                ),
              ),
          ],
        ),
    );

    if (widget.showSwipeBack) {
      return SwipeToPopWrapper(child: content);
    }
    return content;
  }

  Widget _buildHeader(BuildContext context, bool isTablet, double scale, AppLocalizations l10n, bool isRTL, double fontScale) {
    final horizontalPadding = 26.0 * scale;
    final buttonSize = 40.0 * scale;
    final titleSize = 19.0 * scale;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              } else {
                ref.read(mainNavTapProvider)?.call(0);
              }
            },
            behavior: HitTestBehavior.opaque,
            child: SizedBox(
              width: 32.0 * scale,
              height: 32.0 * scale,
              child: SvgPicture.asset(
                'assets/images/back_arrow_icon.svg',
                width: 32.0 * scale,
                height: 32.0 * scale,
                matchTextDirection: true,
              ),
            ),
          ),
          Text(
            l10n.rewardsTitle,
            style: (isRTL ? GoogleFonts.tajawal : GoogleFonts.tajawal)(
              fontSize: titleSize * fontScale,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF24252C),
            ),
          ),
          SizedBox(width: buttonSize),
        ],
      ),
    );
  }

  Widget _buildPointsSection(int? points, bool isTablet, double scale, AppLocalizations l10n, bool isRTL, double fontScale) {
    final horizontalPadding = 26.0 * scale;
    final iconBoxSize = 44.0 * scale;
    final crownSize = 24.0 * scale;
    final pointsFontSize = 24.0 * scale;
    final labelFontSize = 14.0 * scale;
    final gap = 16.0 * scale;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: Row(
        children: [
          Container(
            width: iconBoxSize,
            height: iconBoxSize,
            decoration: BoxDecoration(
              color: const Color(0xFFFFD66B),
              borderRadius: BorderRadius.circular(16.0 * scale),
            ),
            child: Center(
              child: SvgPicture.asset(
                'assets/images/crown_icon.svg',
                width: crownSize,
                colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
              ),
            ),
          ),
          SizedBox(width: gap),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                points != null ? NumberFormat('#,###').format(points) : '--',
                style: GoogleFonts.tajawal(
                  fontSize: pointsFontSize,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF221F48),
                  height: 1.0,
                ),
              ),
              Text(
                l10n.availablePointsLabel,
                style: (isRTL ? GoogleFonts.tajawal : GoogleFonts.tajawal)(
                  fontSize: labelFontSize * fontScale,
                  fontWeight: FontWeight.w600,
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

  Widget _buildTabs(bool isTablet, double scale, AppLocalizations l10n, bool isRTL, double fontScale) {
    final horizontalMargin = 26.0 * scale;
    final tabHeight = 50.0 * scale;
    final tabRadius = 15.0 * scale;
    final innerPadding = 8.0 * scale;
    final tabFontSize = 13.0 * scale;
    
    return Container(
      margin: EdgeInsets.symmetric(horizontal: horizontalMargin),
      height: tabHeight,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(tabRadius),
        border: Border.all(color: const Color(0xFFF5F3F3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 24,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: EdgeInsets.all(innerPadding),
      child: Row(
        children: [
          Expanded(
            child: _selectedTabIndex == 0
                ? LayoutBuilder(
                    builder: (context, constraints) {
                      return GradientButton(
                        text: l10n.availableRewardsTab,
                        onPressed: () {}, // Already selected
                        width: constraints.maxWidth,
                        height: constraints.maxHeight,
                        showIcon: false,
                        textStyle: (isRTL ? GoogleFonts.tajawal : GoogleFonts.tajawal)(
                          fontSize: tabFontSize * fontScale,
                          fontWeight: FontWeight.w700,
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
                        l10n.availableRewardsTab,
                        style: (isRTL ? GoogleFonts.tajawal : GoogleFonts.tajawal)(
                          fontSize: tabFontSize * fontScale,
                          fontWeight: FontWeight.w600,
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
                        text: l10n.myRedemptionsTab,
                        onPressed: () {}, // Already selected
                        width: constraints.maxWidth,
                        height: constraints.maxHeight,
                        showIcon: false,
                        textStyle: (isRTL ? GoogleFonts.tajawal : GoogleFonts.tajawal)(
                          fontSize: tabFontSize * fontScale,
                          fontWeight: FontWeight.w700,
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
                        l10n.myRedemptionsTab,
                        style: (isRTL ? GoogleFonts.tajawal : GoogleFonts.tajawal)(
                          fontSize: tabFontSize * fontScale,
                          fontWeight: FontWeight.w600,
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

  Widget _buildCategories(bool isTablet, double scale, AppLocalizations l10n, bool isRTL) {
    final categoryHeight = 88.0 * scale;
    final categoryWidth = 64.0 * scale;
    final iconSize = 28.0 * scale;
    final labelSize = 11.0 * scale;
    final horizontalPadding = 26.0 * scale;
    final gap = 12.0 * scale;
    final borderRadius = 15.0 * scale;
    final fontScale = isRTL ? 1.2 : 1.0;
    final Map<String, String> categoryLabels = {
      'All': l10n.categoryAll,
      'Coffee': l10n.categoryCoffee,
      'Shop': l10n.categoryShop,
      'Food': l10n.categoryFood,
      'Gym': l10n.categoryGym,
      'Books': l10n.categoryBooks,
    };
    
    return SizedBox(
      height: categoryHeight,
      child: ListView.separated(
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _categories.length,
        separatorBuilder: (_, __) => SizedBox(width: gap),
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
              width: categoryWidth,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(borderRadius),
                border: isSelected ? Border.all(color: const Color(0xFF900EBF)) : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (category['icon'] != null)
                    SvgPicture.asset(
                      category['icon'],
                      width: iconSize,
                      height: iconSize,
                    )
                  else
                    Padding(
                      padding: EdgeInsets.all(3.0 * scale),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Icon(Icons.grid_view, color: isSelected ? const Color(0xFF900EBF) : const Color(0xFFFFD66B), size: iconSize),
                        ],
                      ),
                    ),
                  SizedBox(height: 6.0 * scale),
                  Text(
                    categoryLabels[category['name']] ?? category['name'],
                    style: (isRTL ? GoogleFonts.tajawal : GoogleFonts.tajawal)(
                      fontSize: labelSize * fontScale,
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

  Widget _buildRewardsList(AsyncValue<List<Reward>> rewardsAsync, AsyncValue<List<Redemption>> redemptionsAsync, bool isTablet, double headerHeightTabIndex0, double scale, AppLocalizations l10n, bool isRTL, double fontScale) {
    final horizontalPadding = 20.0 * scale;
    final bottomPadding = 120.0 * scale;
    final itemSpacing = 16.0 * scale;
    
    // Approximate height of the header sections to center empty state visually
    final totalHeaderHeight = (70.0 * scale) + (90.0 * scale) + headerHeightTabIndex0;

    if (_selectedTabIndex == 0) {
      return rewardsAsync.when(
        data: (rewards) => rewards.isEmpty 
          ? SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: EdgeInsets.only(bottom: totalHeaderHeight / 2),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.redeem_outlined, size: 48.0 * scale, color: const Color(0xFF8B88B5).withOpacity(0.3)),
                      SizedBox(height: 12.0 * scale),
                      Text(
                        l10n.noRewardsAvailable,
                        style: (isRTL ? GoogleFonts.tajawal : GoogleFonts.tajawal)(
                          fontSize: 16.0 * scale * fontScale,
                          color: const Color(0xFF8B88B5),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          : Builder(
              builder: (context) {
                final redemptions = redemptionsAsync.value ?? [];
                // Count approved & pending per reward (rejected don't count — user can redeem again)
                final Map<String, int> approvedCount = {};
                final Map<String, int> pendingCount = {};
                for (final r in redemptions) {
                  if (r.status == 'approved') {
                    approvedCount[r.reward.id] = (approvedCount[r.reward.id] ?? 0) + 1;
                  } else if (r.status == 'pending') {
                    pendingCount[r.reward.id] = (pendingCount[r.reward.id] ?? 0) + 1;
                  }
                }

                return SliverPadding(
                  padding: EdgeInsets.only(left: horizontalPadding, right: horizontalPadding, bottom: bottomPadding),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        if (index.isOdd) return SizedBox(height: itemSpacing);
                        final itemIndex = index ~/ 2;
                        final reward = rewards[itemIndex];
                        final approved = approvedCount[reward.id] ?? 0;
                        final pending = pendingCount[reward.id] ?? 0;
                        final limit = reward.maxPerUser;
                        // Fully claimed = approved count hit the limit
                        final isClaimed = limit != null && approved >= limit;
                        // For manual approval: block redeem while any is still pending
                        final isPending = !isClaimed && pending > 0 && reward.requiresApproval == true;
                        return _buildRewardCard(reward, isTablet, scale, l10n, isRTL, fontScale, isClaimed: isClaimed, isPending: isPending);
                      },
                      childCount: rewards.length * 2 - 1,
                    ),
                  ),
                );
              },
            ),
        loading: () => _buildSkeletonList(horizontalPadding, itemSpacing, scale),
        error: (err, _) => SliverFillRemaining(child: Center(child: Text('Error: $err'))),
      );
    } else {
      return redemptionsAsync.when(
        data: (redemptions) => redemptions.isEmpty
          ? SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: EdgeInsets.only(bottom: totalHeaderHeight / 2),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.history_outlined, size: 48.0 * scale, color: const Color(0xFF8B88B5).withOpacity(0.3)),
                      SizedBox(height: 12.0 * scale),
                      Text(
                        l10n.noRedemptionsYet,
                        style: (isRTL ? GoogleFonts.tajawal : GoogleFonts.tajawal)(
                          fontSize: 16.0 * scale * fontScale,
                          color: const Color(0xFF8B88B5),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          : SliverPadding(
              padding: EdgeInsets.only(left: horizontalPadding, right: horizontalPadding, bottom: bottomPadding),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    if (index.isOdd) return SizedBox(height: itemSpacing);
                    final itemIndex = index ~/ 2;
                    return _buildRedemptionCard(redemptions[itemIndex], isTablet, scale, l10n, isRTL, fontScale);
                  },
                  childCount: redemptions.length * 2 - 1,
                ),
              ),
            ),
        loading: () => _buildSkeletonList(horizontalPadding, itemSpacing, scale),
        error: (err, _) => SliverFillRemaining(child: Center(child: Text('Error: $err'))),
      );
    }
  }

  Widget _buildSkeletonList(double horizontalPadding, double itemSpacing, double scale) {
    return SliverPadding(
      padding: EdgeInsets.only(left: horizontalPadding, right: horizontalPadding, bottom: 120.0 * scale),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            if (index.isOdd) return SizedBox(height: itemSpacing);
            return _buildRewardSkeleton(scale);
          },
          childCount: 10,
        ),
      ),
    );
  }

  Widget _buildRewardSkeleton(double scale) {
    final cardHeight = 109.0 * scale;
    final borderRadius = 15.0 * scale;
    final innerPadding = 12.0 * scale;
    final imageSize = 68.0 * scale;
    final imageRadius = 17.0 * scale;

    return Shimmer.fromColors(
      baseColor: Colors.grey[200]!,
      highlightColor: Colors.grey[50]!,
      child: Container(
        height: cardHeight,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(color: const Color(0xFFF5F3F3)),
        ),
        padding: EdgeInsets.all(innerPadding),
        child: Row(
          children: [
            Container(
              width: imageSize,
              height: imageSize,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(imageRadius),
                color: Colors.white,
              ),
            ),
            SizedBox(width: 12.0 * scale),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 120.0 * scale,
                    height: 12.0 * scale,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  SizedBox(height: 8.0 * scale),
                  Container(
                    width: 80.0 * scale,
                    height: 10.0 * scale,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  SizedBox(height: 10.0 * scale),
                  Container(
                    width: 60.0 * scale,
                    height: 14.0 * scale,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
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

  Widget _buildRewardCard(Reward reward, bool isTablet, double scale, AppLocalizations l10n, bool isRTL, double fontScale, {bool isClaimed = false, bool isPending = false}) {
    final cardHeight = 109.0 * scale;
    final borderRadius = 15.0 * scale;
    final innerPadding = 12.0 * scale;
    final imageSize = 68.0 * scale;
    final imageRadius = 17.0 * scale;
    final titleFontSize = 12.0 * scale;
    final partnerFontSize = 11.0 * scale;
    final pointsFontSize = 14.0 * scale;
    final starSize = 16.0 * scale;
    final buttonWidth = 90.0 * scale;
    final buttonHeight = 37.0 * scale;
    final buttonFontSize = 13.0 * scale;
    final badgeFontSize = 9.0 * scale;

    return Container(
      height: cardHeight,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: const Color(0xFFF5F3F3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 24,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(innerPadding),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: imageSize,
              height: imageSize,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(imageRadius),
                color: const Color(0xFFF5F3F3),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(imageRadius),
                child: Image.network(
                  reward.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: const Color(0xFFF5F3F3),
                      child: Icon(
                        Icons.broken_image_outlined,
                        color: const Color(0xFF8B88B5),
                        size: 24.0 * scale,
                      ),
                    );
                  },
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                            : null,
                      ),
                    );
                  },
                ),
              ),
            ),
            SizedBox(width: 12.0 * scale),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    reward.title,
                    style: (isRTL ? GoogleFonts.tajawal : GoogleFonts.tajawal)(
                      fontSize: titleFontSize * fontScale,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    reward.partner,
                    style: (isRTL ? GoogleFonts.tajawal : GoogleFonts.tajawal)(
                      fontSize: partnerFontSize * fontScale,
                      color: const Color(0xFF8B88B5),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 6.0 * scale),
                  Row(
                    children: [
                      Icon(Icons.star, color: const Color(0xFFFFA500), size: starSize),
                      SizedBox(width: 4.0 * scale),
                      Text(
                        reward.requiredPoints.toString(),
                        style: GoogleFonts.tajawal(
                          fontSize: pointsFontSize * fontScale,
                          fontWeight: FontWeight.w800,
                          color: Colors.black,
                        ),
                      ),
                      SizedBox(width: 4.0 * scale),
                      Text(
                        l10n.pointsLabel,
                        style: (isRTL ? GoogleFonts.tajawal : GoogleFonts.tajawal)(
                          fontSize: partnerFontSize * fontScale,
                          color: const Color(0xFF8B88B5),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(width: 8.0 * scale),
            SizedBox(
              height: cardHeight - 2 * innerPadding,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (reward.requiresApproval == true)
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 6.0 * scale,
                        vertical: 2.0 * scale,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8337F).withOpacity(0.08),
                        border: Border.all(color: const Color(0xFFE8337F).withOpacity(0.22)),
                        borderRadius: BorderRadius.circular(18.0 * scale),
                      ),
                      child: Text(
                        l10n.manualApprovalBadge,
                        style: (isRTL ? GoogleFonts.tajawal : GoogleFonts.tajawal)(
                          fontSize: badgeFontSize * fontScale,
                          color: Colors.black,
                        ),
                      ),
                    )
                  else
                    const SizedBox.shrink(),
                  if (isClaimed)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle, color: const Color(0xFF22D198), size: 16.0 * scale),
                        SizedBox(width: 4.0 * scale),
                        Text(
                          l10n.claimedLabel,
                          style: (isRTL ? GoogleFonts.tajawal : GoogleFonts.tajawal)(
                            fontSize: 12.0 * scale * fontScale,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF22D198),
                          ),
                        ),
                      ],
                    )
                  else if (isPending)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.access_time, color: const Color(0xFFDC931F), size: 16.0 * scale),
                        SizedBox(width: 4.0 * scale),
                        Text(
                          l10n.pendingLabel,
                          style: (isRTL ? GoogleFonts.tajawal : GoogleFonts.tajawal)(
                            fontSize: 12.0 * scale * fontScale,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFFDC931F),
                          ),
                        ),
                      ],
                    )
                  else
                    GestureDetector(
                      onTap: () {
                        _showConfirmRedemptionDialog(context, reward);
                      },
                      child: Container(
                        width: buttonWidth,
                        height: buttonHeight,
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFF900EBF)),
                          borderRadius: BorderRadius.circular(8.0 * scale),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          l10n.redeemButton,
                          style: (isRTL ? GoogleFonts.tajawal : GoogleFonts.tajawal)(
                            fontSize: buttonFontSize * fontScale,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF900EBF),
                          ),
                        ),
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

  Widget _buildRedemptionCard(Redemption redemption, bool isTablet, double scale, AppLocalizations l10n, bool isRTL, double fontScale) {
    final horizontalPadding = 22.0 * scale;
    final borderRadius = 15.0 * scale;
    final titleFontSize = 14.0 * scale;
    final dateFontSize = 11.0 * scale;
    final pointsFontSize = 13.0 * scale;
    final starSize = 16.0 * scale;
    final messageBoxPadding = 10.0 * scale;
    final messageFontSize = 12.0 * scale;
    final couponHeight = 52.0 * scale;

    final dateLocale = isRTL ? 'ar' : 'en';

    if (redemption.status == 'rejected') {
      // ── Rejected Card ──
      return Container(
        padding: EdgeInsets.all(horizontalPadding),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF5F5),
          border: Border.all(color: const Color(0xFFE53E3E).withOpacity(0.3)),
          borderRadius: BorderRadius.circular(18.0 * scale),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  redemption.reward.title,
                  style: (isRTL ? GoogleFonts.tajawal : GoogleFonts.tajawal)(
                    fontSize: titleFontSize * fontScale,
                    fontWeight: FontWeight.w800,
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: 4.0 * scale),
                Text(
                  l10n.requestedOnDate(DateFormat('dd MMM yyyy', dateLocale).format(redemption.createdAt)),
                  style: (isRTL ? GoogleFonts.tajawal : GoogleFonts.tajawal)(
                    fontSize: dateFontSize * fontScale,
                    color: const Color(0xFF818181),
                  ),
                ),
                SizedBox(height: 4.0 * scale),
                Row(
                  children: [
                    Icon(Icons.star, color: const Color(0xFFFFA500), size: starSize),
                    SizedBox(width: 3.0 * scale),
                    Text(
                      '${redemption.pointsDeducted} ${l10n.pointsLabel}',
                      style: (isRTL ? GoogleFonts.tajawal : GoogleFonts.tajawal)(
                        fontSize: pointsFontSize * fontScale,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(width: 8.0 * scale),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 6.0 * scale, vertical: 2.0 * scale),
                      decoration: BoxDecoration(
                        color: const Color(0xFF22D198).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4.0 * scale),
                      ),
                      child: Text(
                        l10n.refundedLabel,
                        style: (isRTL ? GoogleFonts.tajawal : GoogleFonts.tajawal)(
                          fontSize: 10.0 * scale * fontScale,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF22D198),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 16.0 * scale),
            Container(
              padding: EdgeInsets.all(messageBoxPadding),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFE53E3E).withOpacity(0.3)),
                borderRadius: BorderRadius.circular(6.0 * scale),
                color: const Color(0xFFE53E3E).withOpacity(0.05),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.cancel_outlined, color: const Color(0xFFE53E3E), size: 18.0 * scale),
                  SizedBox(width: 8.0 * scale),
                  Expanded(
                    child: Text(
                      redemption.adminNote != null && redemption.adminNote!.isNotEmpty
                          ? l10n.rejectedWithNote(redemption.adminNote!)
                          : l10n.requestRejectedDefault,
                      style: (isRTL ? GoogleFonts.tajawal : GoogleFonts.tajawal)(
                        fontSize: messageFontSize * fontScale,
                        color: const Color(0xFFE53E3E),
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
    } else if (redemption.status == 'pending') {
      // ── Pending Card ──
      return Container(
        padding: EdgeInsets.all(horizontalPadding),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF7ED),
          border: Border.all(color: const Color(0xFFECB953).withOpacity(0.74)),
          borderRadius: BorderRadius.circular(18.0 * scale),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  redemption.reward.title,
                  style: (isRTL ? GoogleFonts.tajawal : GoogleFonts.tajawal)(
                    fontSize: titleFontSize * fontScale,
                    fontWeight: FontWeight.w800,
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: 4.0 * scale),
                Text(
                  l10n.requestedOnDate(DateFormat('dd MMM yyyy', dateLocale).format(redemption.createdAt)),
                  style: (isRTL ? GoogleFonts.tajawal : GoogleFonts.tajawal)(
                    fontSize: dateFontSize * fontScale,
                    color: const Color(0xFF818181),
                  ),
                ),
                SizedBox(height: 4.0 * scale),
                Row(
                  children: [
                    Icon(Icons.star, color: const Color(0xFFFFA500), size: starSize),
                    SizedBox(width: 3.0 * scale),
                    Text(
                      '${redemption.pointsDeducted} ${l10n.pointsLabel}',
                      style: (isRTL ? GoogleFonts.tajawal : GoogleFonts.tajawal)(
                        fontSize: pointsFontSize * fontScale,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 16.0 * scale),
            Container(
              padding: EdgeInsets.all(messageBoxPadding),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFECB953).withOpacity(0.9)),
                borderRadius: BorderRadius.circular(6.0 * scale),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.access_time, color: const Color(0xFFDC931F), size: 18.0 * scale),
                  SizedBox(width: 8.0 * scale),
                  Expanded(
                    child: Text(
                      l10n.requestPendingMessage,
                      style: (isRTL ? GoogleFonts.tajawal : GoogleFonts.tajawal)(
                        fontSize: messageFontSize * fontScale,
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
      // ── Approved Card ──
      return Container(
        padding: EdgeInsets.all(horizontalPadding),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFF5F3F3)),
          borderRadius: BorderRadius.circular(borderRadius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 24,
              offset: const Offset(0, 3),
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
                  redemption.reward.title,
                  style: (isRTL ? GoogleFonts.tajawal : GoogleFonts.tajawal)(
                    fontSize: titleFontSize * fontScale,
                    fontWeight: FontWeight.w800,
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: 4.0 * scale),
                Text(
                  l10n.redeemedOnDate(DateFormat('dd MMM yyyy', dateLocale).format(redemption.createdAt)),
                  style: (isRTL ? GoogleFonts.tajawal : GoogleFonts.tajawal)(
                    fontSize: dateFontSize * fontScale,
                    color: const Color(0xFF818181),
                  ),
                ),
                SizedBox(height: 4.0 * scale),
                Row(
                  children: [
                    Icon(Icons.star, color: const Color(0xFFFFA500), size: starSize),
                    SizedBox(width: 4.0 * scale),
                    Text(
                      '${redemption.pointsDeducted} ${l10n.pointsLabel}',
                      style: (isRTL ? GoogleFonts.tajawal : GoogleFonts.tajawal)(
                        fontSize: pointsFontSize * fontScale,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (redemption.couponCode != null) ...[
              SizedBox(height: 16.0 * scale),
              CustomPaint(
                foregroundPainter: DashedRectPainter(
                  color: const Color(0xFFF7A1BA),
                  strokeWidth: 1.0,
                  gap: 5.0,
                  borderRadius: 13.0 * scale,
                ),
                child: Container(
                  height: couponHeight,
                  padding: EdgeInsets.symmetric(horizontal: 16.0 * scale),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(13.0 * scale),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            l10n.yourCouponCode,
                            style: (isRTL ? GoogleFonts.tajawal : GoogleFonts.tajawal)(
                              fontSize: dateFontSize * fontScale,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF818181),
                            ),
                          ),
                          Text(
                            redemption.couponCode!,
                            style: GoogleFonts.tajawal(
                              fontSize: titleFontSize,
                              fontWeight: FontWeight.w800,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: redemption.couponCode!));
                          ref.read(realTimeNotificationServiceProvider).showInAppBanner(
                            l10n.codeCopiedTitle,
                            l10n.codeCopiedMessage,
                          );
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12.0 * scale,
                            vertical: 6.0 * scale,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF7A1BA).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6.0 * scale),
                          ),
                          child: Text(
                            l10n.copyButton,
                            style: (isRTL ? GoogleFonts.tajawal : GoogleFonts.tajawal)(
                              fontSize: dateFontSize * fontScale,
                              fontWeight: FontWeight.w800,
                               color: const Color(0xFFF83A71),
                             ),
                           ),
                         ),
                       ),
                     ],
                   ),
                 ),
               ),
             ],
          ],
        ),
      );
    }
  }

  Future<void> _showConfirmRedemptionDialog(BuildContext parentContext, Reward reward) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        final size = MediaQuery.of(context).size;
        final screenWidth = size.width;
        final screenHeight = size.height;
        final isTablet = screenWidth > 600;

        const double smallScale  = 0.85;
        const double mediumScale = 0.98;
        const double largeScale  = 1.05;
        const double tabletScale = 1.25;

        final double scale = isTablet
            ? tabletScale
            : screenHeight < 680
                ? smallScale
                : screenHeight < 850
                    ? mediumScale
                    : largeScale;

        final horizontalPadding = 21.0 * scale;
        final borderRadius = 22.0 * scale;
        final titleFontSize = 13.0 * scale;
        final cardTitleSize = 15.0 * scale;
        final cardLabelSize = 12.0 * scale;
        final ptsSize = 16.0 * scale;
        final balanceLabelSize = 11.0 * scale;
        final balanceValueSize = 11.0 * scale;
        final buttonHeight = 37.0 * scale;
        final buttonFontSize = 13.0 * scale;
        
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.symmetric(horizontal: 21.0 * scale),
          child: Container(
            width: isTablet ? 400.0 : double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(borderRadius),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 20.0 * scale,
                  offset: Offset(0, 4.0 * scale),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.only(left: horizontalPadding, top: horizontalPadding),
                  child: Text(
                    AppLocalizations.of(context)!.confirmRedemptionTitle,
                    style: GoogleFonts.tajawal(
                      fontSize: titleFontSize,
                      fontWeight: FontWeight.w800,
                      color: Colors.black,
                    ),
                  ),
                ),
                SizedBox(height: 16.0 * scale),
                Container(
                  margin: EdgeInsets.symmetric(horizontal: horizontalPadding),
                  padding: EdgeInsets.all(16.0 * scale),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAF5FE),
                    border: Border.all(color: const Color(0xFF96AAD2).withOpacity(0.22)),
                    borderRadius: BorderRadius.circular(11.0 * scale),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10.0 * scale,
                        offset: Offset(0, 2.0 * scale),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 46.0 * scale,
                            height: 46.0 * scale,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF97316),
                              borderRadius: BorderRadius.circular(10.0 * scale),
                            ),
                            child: Center(
                              child: Icon(Icons.shopping_bag_outlined, color: Colors.white, size: 24.0 * scale),
                            ),
                          ),
                          SizedBox(width: 12.0 * scale),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  reward.title,
                                  style: GoogleFonts.tajawal(
                                    fontSize: cardTitleSize,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.black,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  reward.partner,
                                  style: GoogleFonts.tajawal(
                                    fontSize: cardLabelSize,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF8B88B5),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12.0 * scale),
                      Container(
                        height: 1,
                        color: Colors.black.withOpacity(0.05),
                      ),
                      SizedBox(height: 12.0 * scale),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            AppLocalizations.of(context)!.pointsRequired,
                            style: GoogleFonts.tajawal(
                              fontSize: balanceLabelSize,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF8B88B5),
                            ),
                          ),
                          Row(
                            children: [
                              Icon(Icons.star, color: const Color(0xFFFFA500), size: 16.0 * scale),
                              SizedBox(width: 4.0 * scale),
                              Text(
                                reward.requiredPoints.toString(),
                                style: GoogleFonts.tajawal(
                                  fontSize: ptsSize,
                                  fontWeight: FontWeight.w800,
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
                SizedBox(height: 20.0 * scale),
                Container(
                  margin: EdgeInsets.symmetric(horizontal: horizontalPadding),
                  padding: EdgeInsets.symmetric(horizontal: 16.0 * scale, vertical: 12.0 * scale),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(11.0 * scale),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppLocalizations.of(context)!.currentBalance,
                            style: GoogleFonts.tajawal(
                              fontSize: balanceLabelSize,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                          ),
                          Text(
                            AppLocalizations.of(context)!.afterRedemption,
                            style: GoogleFonts.tajawal(
                              fontSize: balanceLabelSize,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                      Consumer(
                        builder: (context, ref, _) {
                          final user = ref.read(userProfileProvider).value;
                          final points = user?.points ?? 0;
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${NumberFormat('#,###').format(points)} ${AppLocalizations.of(context)!.ptsSuffix}',
                                style: GoogleFonts.tajawal(
                                  fontSize: balanceValueSize,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black,
                                ),
                              ),
                              Text(
                                '${NumberFormat('#,###').format(math.max(0, points - reward.requiredPoints))} ${AppLocalizations.of(context)!.ptsSuffix}',
                                style: GoogleFonts.tajawal(
                                  fontSize: balanceValueSize,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFFF83A71),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 24.0 * scale),
                Padding(
                  padding: EdgeInsets.fromLTRB(horizontalPadding, 0, horizontalPadding, horizontalPadding),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            height: buttonHeight,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF3F4F6),
                              borderRadius: BorderRadius.circular(9.0 * scale),
                              border: Border.all(color: const Color(0xFF900EBF).withOpacity(0.5)),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              AppLocalizations.of(context)!.cancelButton,
                              style: GoogleFonts.tajawal(
                                fontSize: buttonFontSize,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF838383),
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 12.0 * scale),
                      Consumer(
                        builder: (context, ref, _) {
                          final user = ref.watch(userProfileProvider).value;
                          final points = user?.points ?? 0;
                          final canRedeem = points >= reward.requiredPoints;

                          return Expanded(
                            child: GestureDetector(
                              onTap: canRedeem ? () {
                                Navigator.pop(context, true); // Close dialog, return true to confirm
                              } : null,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                height: buttonHeight,
                                decoration: BoxDecoration(
                                  color: canRedeem ? const Color(0xFF900EBF) : Colors.grey.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(9.0 * scale),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  AppLocalizations.of(context)!.confirmRedeemButton,
                                  style: GoogleFonts.tajawal(
                                    fontSize: buttonFontSize,
                                    fontWeight: FontWeight.w800,
                                    color: canRedeem ? Colors.white : Colors.white.withOpacity(0.6),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (confirmed == true && parentContext.mounted && !_isRedeeming) {
      _isRedeeming = true;

      // INSTANT: switch tab + scroll to top immediately
      setState(() {
        _selectedTabIndex = 1;
      });
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );

      // Fire API in background — don't block UI
      ref.read(rewardRepositoryProvider).redeemReward(reward.id).then((_) {
        // Refresh data silently
        ref.invalidate(userProfileProvider);
        ref.invalidate(myRedemptionsProvider);
        ref.invalidate(rewardsListProvider);

        if (parentContext.mounted) {
          final l10n = AppLocalizations.of(parentContext)!;
          ref.read(realTimeNotificationServiceProvider).showInAppBanner(
            l10n.rewardRedeemedTitle,
            l10n.rewardRedeemedMessage(reward.title),
          );
        }
        _isRedeeming = false;
      }).catchError((e) {
        // Revert to available rewards tab on failure
        if (parentContext.mounted) {
          setState(() {
            _selectedTabIndex = 0;
          });
          ScaffoldMessenger.of(parentContext).showSnackBar(
            SnackBar(
              content: Text(e.toString().replaceAll('Exception: ', '')),
              backgroundColor: Colors.red,
            ),
          );
        }
        _isRedeeming = false;
      });
    }
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

