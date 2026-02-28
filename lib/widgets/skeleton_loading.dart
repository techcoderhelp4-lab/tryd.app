import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// A reusable shimmer skeleton box
class SkeletonBox extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const SkeletonBox({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFF2F2F7),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

/// Skeleton loading screen that matches the Home Screen layout
class HomeSkeletonLoading extends StatelessWidget {
  final double scale;
  final bool isTablet;

  const HomeSkeletonLoading({
    super.key,
    required this.scale,
    required this.isTablet,
  });

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = (isTablet ? 16.0 : 15.0) * scale;

    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
          children: [
            // Header skeleton
            _buildHeaderSkeleton(horizontalPadding),
            SizedBox(height: (isTablet ? 12.0 : 14.0) * scale),
            // Divider
            Container(
              height: 1,
              color: Colors.black.withOpacity(0.05),
            ),
            SizedBox(height: 8.0 * scale),
            // Points card skeleton
            Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: _buildPointsCardSkeleton(),
            ),
            SizedBox(height: 8.0 * scale),
            // Banner skeleton
            Padding(
              padding: EdgeInsets.only(left: horizontalPadding, right: horizontalPadding),
              child: _buildBannerSkeleton(),
            ),
            SizedBox(height: 8.0 * scale),
            // Current month card skeleton
            Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: _buildCurrentMonthSkeleton(),
            ),
            SizedBox(height: (isTablet ? 12.0 : 16.0) * scale),
            // Stats grid skeleton
            Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: _buildStatsGridSkeleton(),
            ),
          ],
        ),
    );
  }

  Widget _buildHeaderSkeleton(double horizontalPadding) {
    final avatarSize = (isTablet ? 45.0 : 50.0) * scale;
    final topPadding = (isTablet ? 20.0 : 32.0) * scale;
    final bottomPadding = (isTablet ? 15.0 : 20.0) * scale;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        horizontalPadding, topPadding, horizontalPadding, bottomPadding,
      ),
      child: Row(
        children: [
          // Avatar circle
          Container(
            width: avatarSize,
            height: avatarSize,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: (isTablet ? 12.0 : 16.0) * scale),
          // Name lines
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBox(
                  width: 60.0 * scale,
                  height: 14.0 * scale,
                  borderRadius: 6.0,
                ),
                SizedBox(height: 6.0 * scale),
                SkeletonBox(
                  width: 140.0 * scale,
                  height: 20.0 * scale,
                  borderRadius: 6.0,
                ),
              ],
            ),
          ),
          // Bell icon
          SkeletonBox(
            width: 36.0 * scale,
            height: 36.0 * scale,
            borderRadius: 18.0 * scale,
          ),
        ],
      ),
    );
  }

  Widget _buildPointsCardSkeleton() {
    final cardHeight = (isTablet ? 60.0 : 66.0) * scale;
    final iconSize = (isTablet ? 38.0 : 44.0) * scale;

    return SizedBox(
      height: cardHeight,
      child: Row(
        children: [
          SkeletonBox(
            width: iconSize,
            height: iconSize,
            borderRadius: (isTablet ? 14.0 : 16.0) * scale,
          ),
          SizedBox(width: (isTablet ? 12.0 : 14.0) * scale),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SkeletonBox(
                width: 80.0 * scale,
                height: 22.0 * scale,
                borderRadius: 6.0,
              ),
              SizedBox(height: 6.0 * scale),
              SkeletonBox(
                width: 140.0 * scale,
                height: 14.0 * scale,
                borderRadius: 6.0,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBannerSkeleton() {
    return AspectRatio(
      aspectRatio: isTablet ? (334 / 140) : (334 / 160),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular((isTablet ? 18.0 : 22.0) * scale),
        ),
      ),
    );
  }

  Widget _buildCurrentMonthSkeleton() {
    final cardHeight = (isTablet ? 70.0 : 80.0) * scale;
    final iconSize = (isTablet ? 38.0 : 43.0) * scale;

    return Container(
      height: cardHeight,
      padding: EdgeInsets.symmetric(
        horizontal: (isTablet ? 14.0 : 19.0) * scale,
        vertical: (isTablet ? 10.0 : 14.0) * scale,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular((isTablet ? 12.0 : 15.0) * scale),
      ),
      child: Row(
        children: [
          SkeletonBox(
            width: iconSize,
            height: iconSize,
            borderRadius: iconSize / 2,
          ),
          SizedBox(width: (isTablet ? 12.0 : 14.0) * scale),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SkeletonBox(
                width: 100.0 * scale,
                height: 13.0 * scale,
                borderRadius: 6.0,
              ),
              SizedBox(height: 6.0 * scale),
              SkeletonBox(
                width: 70.0 * scale,
                height: 18.0 * scale,
                borderRadius: 6.0,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGridSkeleton() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            children: [
              SkeletonBox(
                width: double.infinity,
                height: 152.0 * scale,
                borderRadius: 15.0 * scale,
              ),
              SizedBox(height: 12.0 * scale),
              SkeletonBox(
                width: double.infinity,
                height: 130.0 * scale,
                borderRadius: 15.0 * scale,
              ),
            ],
          ),
        ),
        SizedBox(width: 10.0 * scale),
        Expanded(
          child: Column(
            children: [
              SkeletonBox(
                width: double.infinity,
                height: 130.0 * scale,
                borderRadius: 15.0 * scale,
              ),
              SizedBox(height: 12.0 * scale),
              SkeletonBox(
                width: double.infinity,
                height: 152.0 * scale,
                borderRadius: 15.0 * scale,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Skeleton loading screen that matches the Club Screen layout
class ClubSkeletonLoading extends StatelessWidget {
  final double scale;
  final bool isTablet;

  const ClubSkeletonLoading({
    super.key,
    required this.scale,
    required this.isTablet,
  });

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = 16.0 * scale;

    return Shimmer.fromColors(
      baseColor: const Color(0xFFEEECF5),
      highlightColor: const Color(0xFFF8F6FF),
      period: const Duration(milliseconds: 1200),
      child: Column(
        children: [
          // Section title skeleton
          Padding(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            child: Align(
              alignment: Alignment.centerLeft,
              child: SkeletonBox(
                width: 140.0 * scale,
                height: 20.0 * scale,
                borderRadius: 6.0,
              ),
            ),
          ),
          SizedBox(height: 14.0 * scale),
          // Challenge cards skeleton (My Challenges)
          ...List.generate(2, (index) => Padding(
            padding: EdgeInsets.only(
              left: horizontalPadding,
              right: horizontalPadding,
              bottom: 23.0 * scale,
            ),
            child: _buildChallengeCardSkeleton(),
          )),
          SizedBox(height: 10.0 * scale),
          // Previous challenge section title
          Padding(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            child: Align(
              alignment: Alignment.centerLeft,
              child: SkeletonBox(
                width: 170.0 * scale,
                height: 20.0 * scale,
                borderRadius: 6.0,
              ),
            ),
          ),
          SizedBox(height: 14.0 * scale),
          // Previous challenge card
          Padding(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            child: _buildChallengeCardSkeleton(),
          ),
        ],
      ),
    );
  }

  Widget _buildChallengeCardSkeleton() {
    final cardHeight = (isTablet ? 98.0 : 104.0) * scale;
    final borderRadius = 12.0 * scale;
    final badgeHeight = (isTablet ? 40.0 : 45.0) * scale;
    final badgeWidth = 42.0 * scale;

    return Container(
      width: double.infinity,
      constraints: BoxConstraints(minHeight: cardHeight),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.0 * scale, vertical: 12.0 * scale),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Title
                  SkeletonBox(
                    width: 180.0 * scale,
                    height: 14.0 * scale,
                    borderRadius: 6.0,
                  ),
                  SizedBox(height: 6.0 * scale),
                  // Description
                  SkeletonBox(
                    width: 140.0 * scale,
                    height: 11.0 * scale,
                    borderRadius: 6.0,
                  ),
                  SizedBox(height: 12.0 * scale),
                  // Progress row
                  Row(
                    children: [
                      SkeletonBox(
                        width: 16.0 * scale,
                        height: 16.0 * scale,
                        borderRadius: 8.0 * scale,
                      ),
                      SizedBox(width: 6.0 * scale),
                      SkeletonBox(
                        width: 120.0 * scale,
                        height: 12.0 * scale,
                        borderRadius: 6.0,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(width: 8.0 * scale),
            // KM badge
            SkeletonBox(
              width: badgeWidth,
              height: badgeHeight,
              borderRadius: 7.0 * scale,
            ),
          ],
        ),
      ),
    );
  }
}

/// Skeleton loading screen that matches the Workout History Screen layout
class HistorySkeletonLoading extends StatelessWidget {
  final double scale;
  final bool isTablet;

  const HistorySkeletonLoading({
    super.key,
    required this.scale,
    required this.isTablet,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFEEECF5),
      highlightColor: const Color(0xFFF8F6FF),
      period: const Duration(milliseconds: 1200),
      child: ListView.separated(
        padding: EdgeInsets.symmetric(horizontal: 20.0 * scale),
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 4,
        separatorBuilder: (_, __) => SizedBox(height: 15.0 * scale),
        itemBuilder: (context, index) => _buildHistoryCardSkeleton(),
      ),
    );
  }

  Widget _buildHistoryCardSkeleton() {
    final padding = 18.0 * scale;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22.0 * scale),
      ),
      child: Padding(
        padding: EdgeInsets.all(padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date row (calendar icon + date text)
            Row(
              children: [
                SkeletonBox(
                  width: 24.0 * scale,
                  height: 24.0 * scale,
                  borderRadius: 6.0,
                ),
                SizedBox(width: 7.0 * scale),
                SkeletonBox(
                  width: 140.0 * scale,
                  height: 20.0 * scale,
                  borderRadius: 6.0,
                ),
              ],
            ),
            SizedBox(height: 18.0 * scale),
            // Stats row (Work, Rest, Ex, Rounds)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(4, (_) => Column(
                children: [
                  SkeletonBox(
                    width: 40.0 * scale,
                    height: 14.0 * scale,
                    borderRadius: 4.0,
                  ),
                  SizedBox(height: 8.0 * scale),
                  SkeletonBox(
                    width: 50.0 * scale,
                    height: 26.0 * scale,
                    borderRadius: 6.0,
                  ),
                ],
              )),
            ),
          ],
        ),
      ),
    );
  }
}

/// Skeleton loading screen for the Leaderboard
class LeaderboardSkeletonLoading extends StatelessWidget {
  final double scale;
  final bool isTablet;

  const LeaderboardSkeletonLoading({
    super.key,
    required this.scale,
    required this.isTablet,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFEEECF5),
      highlightColor: const Color(0xFFF8F6FF),
      period: const Duration(milliseconds: 1200),
      child: Column(
        children: [
          // Active Challenge Card skeleton
          _buildActiveCardSkeleton(),
          SizedBox(height: 15.0 * scale),
          // Your Rank section skeleton
          _buildRankHeaderSkeleton(),
          // Table header skeleton
          _buildTableHeaderSkeleton(),
          // List of participants skeleton
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.zero,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 6,
              itemBuilder: (context, index) => _buildUserRowSkeleton(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveCardSkeleton() {
    return Container(
      width: double.infinity,
      height: (isTablet ? 120.0 : 138.0) * scale,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22.0 * scale),
      ),
    );
  }

  Widget _buildRankHeaderSkeleton() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(18.0 * scale, 23.0 * scale, 18.0 * scale, 15.0 * scale),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(15.0 * scale),
          topRight: Radius.circular(15.0 * scale),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SkeletonBox(width: 100.0 * scale, height: 20.0 * scale),
              SkeletonBox(width: 80.0 * scale, height: 16.0 * scale),
            ],
          ),
          SizedBox(height: 15.0 * scale),
          SkeletonBox(width: double.infinity, height: 60.0 * scale, borderRadius: 12.0 * scale),
          SizedBox(height: 17.0 * scale),
          SkeletonBox(width: 150.0 * scale, height: 20.0 * scale),
        ],
      ),
    );
  }

  Widget _buildTableHeaderSkeleton() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 18.0 * scale, vertical: 12.0 * scale),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFF5F3F3))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          SkeletonBox(width: 30.0 * scale, height: 10.0 * scale),
          SkeletonBox(width: 140.0 * scale, height: 10.0 * scale),
          SkeletonBox(width: 60.0 * scale, height: 10.0 * scale),
        ],
      ),
    );
  }

  Widget _buildUserRowSkeleton() {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.symmetric(horizontal: 18.0 * scale, vertical: 12.0 * scale),
      child: Row(
        children: [
          SkeletonBox(width: 25.0 * scale, height: 14.0 * scale),
          SizedBox(width: 8.0 * scale),
          Container(
            width: 32.0 * scale,
            height: 32.0 * scale,
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
          ),
          SizedBox(width: 8.0 * scale),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SkeletonBox(width: 120.0 * scale, height: 14.0 * scale),
              SizedBox(height: 4.0 * scale),
              SkeletonBox(width: 60.0 * scale, height: 10.0 * scale),
            ],
          ),
          const Spacer(),
          SkeletonBox(width: 50.0 * scale, height: 14.0 * scale),
        ],
      ),
    );
  }
}
