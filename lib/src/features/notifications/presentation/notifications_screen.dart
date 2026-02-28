import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import '../data/notification_repository.dart';
import '../domain/app_notification.dart';
import '../../../../widgets/custom_arrow_icon.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  // Optimistic local state — tracks IDs marked as read this session
  final Set<String> _localReadIds = {};

  @override
  Widget build(BuildContext context) {
    final notificationsAsync = ref.watch(notificationsListProvider);

    // ── Responsive Scale ──────────────────────────────────
    final size = MediaQuery.of(context).size;
    final screenWidth = size.width;
    final screenHeight = size.height;
    final isTablet = screenWidth > 600;

    const double smallScale  = 0.85;
    const double mediumScale = 0.98;
    const double largeScale  = 1.05;
    const double tabletScale = 1.30;

    final double scale = isTablet
        ? tabletScale
        : screenHeight < 680
            ? smallScale
            : screenHeight < 850
                ? mediumScale
                : largeScale;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Background Gradient
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
            child: Column(
              children: [
                _buildAppBar(context, scale),
                Expanded(
                  child: notificationsAsync.when(
                    skipLoadingOnRefresh: true,
                    data: (notifications) {
                      if (notifications.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.notifications_none, size: 60.0 * scale, color: Colors.grey.withOpacity(0.5)),
                              SizedBox(height: 10.0 * scale),
                              Text("No notifications yet", style: GoogleFonts.poppins(color: Colors.grey, fontSize: 14.0 * scale)),
                            ],
                          ),
                        );
                      }

                      return RefreshIndicator(
                        color: const Color(0xFF900EBF),
                        onRefresh: () async {
                          ref.invalidate(notificationsListProvider);
                          ref.invalidate(unreadNotificationCountProvider);
                          _localReadIds.clear();
                          await Future.delayed(const Duration(milliseconds: 500));
                        },
                        child: ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                          padding: EdgeInsets.symmetric(horizontal: 16.0 * scale, vertical: 10.0 * scale),
                          itemCount: notifications.length,
                          separatorBuilder: (context, index) => SizedBox(height: 12.0 * scale),
                          itemBuilder: (context, index) {
                            return _buildNotificationItem(context, notifications[index], scale);
                          },
                        ),
                      );
                    },
                    loading: () => ListView.separated(
                      padding: EdgeInsets.symmetric(horizontal: 16.0 * scale, vertical: 10.0 * scale),
                      itemCount: 8,
                      separatorBuilder: (context, index) => SizedBox(height: 12.0 * scale),
                      itemBuilder: (context, index) => _buildNotificationSkeleton(scale),
                    ),
                    error: (err, stack) => Center(child: Text("Error: $err")),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, double scale) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.0 * scale, vertical: 20.0 * scale),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40.0 * scale,
              height: 40.0 * scale,
              alignment: Alignment.center,
              child: Transform.scale(
                scaleX: -1,
                child: CustomArrowIcon(
                  size: 24.0 * scale,
                  color: const Color(0xFF130F26),
                ),
              ),
            ),
          ),
          Text(
            'Notifications',
            style: GoogleFonts.lexendDeca(
              fontSize: 19.0 * scale,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF24252C),
            ),
          ),
          // Mark all read button
          IconButton(
            icon: Icon(Icons.done_all, color: const Color(0xFF900EBF), size: 22.0 * scale),
            onPressed: () {
              // Optimistic: mark all as read locally
              final notifications = ref.read(notificationsListProvider).value;
              if (notifications != null) {
                setState(() {
                  for (final n in notifications) {
                    _localReadIds.add(n.id);
                  }
                });
              }
              // Fire API in background
              ref.read(notificationRepositoryProvider).markAllAsRead().then((_) {
                ref.invalidate(unreadNotificationCountProvider);
                ref.invalidate(notificationsListProvider);
              });
            },
            tooltip: 'Mark all as read',
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationItem(BuildContext context, AppNotification notification, double scale) {
    // Optimistic: if locally marked as read, treat as read
    final bool isRead = notification.isRead || _localReadIds.contains(notification.id);

    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: 20.0 * scale),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.8),
          borderRadius: BorderRadius.circular(16.0 * scale),
        ),
        child: Icon(Icons.delete, color: Colors.white, size: 28.0 * scale),
      ),
      onDismissed: (_) {
        // Fire API in background — item already removed visually by Dismissible
        ref.read(notificationRepositoryProvider).deleteNotification(notification.id);
        ref.invalidate(unreadNotificationCountProvider);
      },
      child: GestureDetector(
        onTap: () {
          if (!isRead) {
            // Optimistic: mark as read instantly in UI
            setState(() {
              _localReadIds.add(notification.id);
            });
            // Fire API in background — no refetch, no shimmer
            ref.read(notificationRepositoryProvider).markAsRead(notification.id).then((_) {
              ref.invalidate(unreadNotificationCountProvider);
              ref.invalidate(notificationsListProvider);
            });
          }
        },
        child: Container(
          padding: EdgeInsets.all(16.0 * scale),
          decoration: BoxDecoration(
            color: isRead ? Colors.white.withOpacity(0.9) : const Color(0xFFFDF6FF),
            borderRadius: BorderRadius.circular(16.0 * scale),
            border: Border.all(color: Colors.black.withOpacity(0.05)),
            boxShadow: [
              if (!isRead)
                BoxShadow(
                  color: const Color(0xFF900EBF).withOpacity(0.08),
                  blurRadius: 8.0 * scale,
                  offset: Offset(0, 2.0 * scale),
                ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildNotificationIcon(notification.type, scale),
              SizedBox(width: 14.0 * scale),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: GoogleFonts.lexendDeca(
                              fontSize: 15.0 * scale,
                              fontWeight: isRead ? FontWeight.w500 : FontWeight.w700,
                              color: const Color(0xFF24252C),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          _formatTime(notification.createdAt),
                          style: GoogleFonts.poppins(
                            fontSize: 11.0 * scale,
                            color: const Color(0xFF8B88B5),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 6.0 * scale),
                    Text(
                      notification.message,
                      style: GoogleFonts.poppins(
                        fontSize: 13.0 * scale,
                        color: const Color(0xFF24252C).withOpacity(0.7),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationIcon(String type, double scale) {
    IconData icon;
    Color color;

    switch (type) {
      case 'welcome':
        icon = Icons.waving_hand_rounded;
        color = const Color(0xFFFEB720);
        break;
      case 'login_alert':
        icon = Icons.security;
        color = const Color(0xFF5D5FEF);
        break;
      case 'password_changed':
        icon = Icons.lock_reset;
        color = const Color(0xFF5D5FEF);
        break;
      case 'profile_updated':
        icon = Icons.person_outline;
        color = const Color(0xFF24252C);
        break;
      case 'activity_recorded':
        icon = Icons.monitor_heart_outlined;
        color = const Color(0xFFF83A71);
        break;
      case 'workout_recorded':
        icon = Icons.fitness_center;
        color = const Color(0xFFF83A71);
        break;
      case 'goal_achieved':
        icon = Icons.flag_rounded;
        color = const Color(0xFFF83A71);
        break;
      case 'personal_best':
        icon = Icons.emoji_events_outlined;
        color = const Color(0xFFFEB720);
        break;
      case 'challenge_invite':
        icon = Icons.mail_outline;
        color = const Color(0xFF900EBF);
        break;
      case 'challenge_joined':
        icon = Icons.group_add;
        color = const Color(0xFF900EBF);
        break;
      case 'challenge_update':
        icon = Icons.update;
        color = const Color(0xFF900EBF);
        break;
      case 'challenge_progress':
        icon = Icons.trending_up;
        color = const Color(0xFF900EBF);
        break;
      case 'challenge_completed':
        icon = Icons.emoji_events_rounded;
        color = const Color(0xFFFEB720);
        break;
      case 'challenge_leaderboard':
      case 'leaderboard_rank':
        icon = Icons.leaderboard;
        color = const Color(0xFFFEB720);
        break;
      case 'reward_earned':
        icon = Icons.stars_rounded;
        color = const Color(0xFFFEB720);
        break;
      case 'redemption_requested':
        icon = Icons.hourglass_empty;
        color = const Color(0xFF8B88B5);
        break;
      case 'redemption_approved':
        icon = Icons.check_circle_outline;
        color = const Color(0xFF4FFD5B);
        break;
      case 'redemption_rejected':
        icon = Icons.cancel_outlined;
        color = const Color(0xFFFF4B4B);
        break;
      case 'points_earned':
        icon = Icons.add_circle_outline;
        color = const Color(0xFF4FFD5B);
        break;
      case 'points_spent':
        icon = Icons.remove_circle_outline;
        color = const Color(0xFFFF4B4B);
        break;
      case 'friend_request':
        icon = Icons.person_add_alt_1;
        color = const Color(0xFF5D5FEF);
        break;
      case 'reminder_workout':
      case 'reminder_user':
        icon = Icons.alarm;
        color = const Color(0xFFF83A71);
        break;
      case 'reminder_instructor':
        icon = Icons.assignment_ind;
        color = const Color(0xFF900EBF);
        break;
      case 'coupon_received':
        icon = Icons.confirmation_number_outlined;
        color = const Color(0xFF4FFD5B);
        break;
      default:
        icon = Icons.notifications_none_rounded;
        color = const Color(0xFF8B88B5);
    }

    return Container(
      width: 42.0 * scale,
      height: 42.0 * scale,
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: 22.0 * scale),
    );
  }

  Widget _buildNotificationSkeleton(double scale) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[200]!,
      highlightColor: Colors.grey[50]!,
      child: Container(
        padding: EdgeInsets.all(16.0 * scale),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.0 * scale),
          border: Border.all(color: Colors.black.withOpacity(0.05)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42.0 * scale,
              height: 42.0 * scale,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
            SizedBox(width: 14.0 * scale),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        width: 120.0 * scale,
                        height: 14.0 * scale,
                        color: Colors.white,
                      ),
                      Container(
                        width: 40.0 * scale,
                        height: 10.0 * scale,
                        color: Colors.white,
                      ),
                    ],
                  ),
                  SizedBox(height: 10.0 * scale),
                  Container(
                    width: double.infinity,
                    height: 12.0 * scale,
                    color: Colors.white,
                  ),
                  SizedBox(height: 6.0 * scale),
                  Container(
                    width: 200.0 * scale,
                    height: 12.0 * scale,
                    color: Colors.white,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('d MMM').format(date);
    }
  }
}
