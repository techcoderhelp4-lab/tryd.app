import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../data/notification_repository.dart';
import '../domain/app_notification.dart';
import '../../../../widgets/custom_arrow_icon.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsListProvider);

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
                _buildAppBar(context, ref),
                Expanded(
                  child: notificationsAsync.when(
                    data: (notifications) {
                      if (notifications.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.notifications_none, size: 60.sp, color: Colors.grey.withOpacity(0.5)),
                              SizedBox(height: 10.h),
                              Text("No notifications yet", style: GoogleFonts.poppins(color: Colors.grey)),
                            ],
                          ),
                        );
                      }
                      
                      return RefreshIndicator(
                        onRefresh: () => ref.refresh(notificationsListProvider.future),
                        child: ListView.separated(
                          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
                          itemCount: notifications.length,
                          separatorBuilder: (context, index) => SizedBox(height: 12.h),
                          itemBuilder: (context, index) {
                            return _buildNotificationItem(context, ref, notifications[index]);
                          },
                        ),
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
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

  Widget _buildAppBar(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40.w,
              height: 40.w,
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
            'Notifications',
            style: GoogleFonts.lexendDeca(
              fontSize: 19.sp,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF24252C),
            ),
          ),
          // Mark all read button
          IconButton(
            icon: Icon(Icons.done_all, color: const Color(0xFF900EBF), size: 22.sp),
            onPressed: () async {
              await ref.read(notificationRepositoryProvider).markAllAsRead();
              ref.invalidate(notificationsListProvider);
              ref.invalidate(unreadNotificationCountProvider);
            },
            tooltip: 'Mark all as read',
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationItem(BuildContext context, WidgetRef ref, AppNotification notification) {
    final bool isRead = notification.isRead;
    
    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: 20.w),
        color: Colors.red.withOpacity(0.8),
        child: Icon(Icons.delete, color: Colors.white, size: 28.sp),
      ),
      onDismissed: (_) {
        ref.read(notificationRepositoryProvider).deleteNotification(notification.id);
      },
      child: GestureDetector(
        onTap: () async {
          if (!isRead) {
            await ref.read(notificationRepositoryProvider).markAsRead(notification.id);
            ref.invalidate(notificationsListProvider);
            ref.invalidate(unreadNotificationCountProvider);
          }
        },
        child: Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: isRead ? Colors.white.withOpacity(0.9) : const Color(0xFFFDF6FF), // Highlight unread
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: Colors.black.withOpacity(0.05)),
            boxShadow: [
              if (!isRead)
                BoxShadow(
                  color: const Color(0xFF900EBF).withOpacity(0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon based on type
              _buildNotificationIcon(notification.type),
              SizedBox(width: 14.w),
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
                              fontSize: 15.sp,
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
                            fontSize: 11.sp,
                            color: const Color(0xFF8B88B5),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 6.h),
                    Text(
                      notification.message,
                      style: GoogleFonts.poppins(
                        fontSize: 13.sp,
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

  Widget _buildNotificationIcon(String type) {
    IconData icon;
    Color color;

    switch (type) {
      // Authentication & Account (4)
      case 'welcome':
        icon = Icons.waving_hand_rounded;
        color = const Color(0xFFFEB720); // Amber
        break;
      case 'login_alert':
        icon = Icons.security;
        color = const Color(0xFF5D5FEF); // Blue
        break;
      case 'password_changed':
        icon = Icons.lock_reset;
        color = const Color(0xFF5D5FEF); // Blue
        break;
      case 'profile_updated':
        icon = Icons.person_outline;
        color = const Color(0xFF24252C); // Dark
        break;

      // Activity & Workout (4)
      case 'activity_logged':
        icon = Icons.monitor_heart_outlined;
        color = const Color(0xFFF83A71); // Pink
        break;
      case 'workout_logged':
        icon = Icons.fitness_center;
        color = const Color(0xFFF83A71); // Pink
        break;
      case 'goal_achieved':
        icon = Icons.flag_rounded;
        color = const Color(0xFFF83A71); // Pink
        break;
      case 'personal_best':
        icon = Icons.emoji_events_outlined;
        color = const Color(0xFFFEB720); // Amber
        break;
        
      // Challenges (6)
      case 'challenge_invite':
        icon = Icons.mail_outline;
        color = const Color(0xFF900EBF); // Purple
        break;
      case 'challenge_joined':
        icon = Icons.group_add;
        color = const Color(0xFF900EBF); // Purple
        break;
      case 'challenge_update':
        icon = Icons.update;
        color = const Color(0xFF900EBF); // Purple
        break;
      case 'challenge_progress':
        icon = Icons.trending_up;
        color = const Color(0xFF900EBF); // Purple
        break;
      case 'challenge_completed':
        icon = Icons.emoji_events_rounded;
        color = const Color(0xFFFEB720); // Amber
        break;
      case 'challenge_leaderboard':
        icon = Icons.leaderboard;
        color = const Color(0xFFFEB720); // Amber
        break;

      // Rewards & Points (6)
      case 'reward_earned':
        icon = Icons.stars_rounded;
        color = const Color(0xFFFEB720); // Amber
        break;
      case 'redemption_requested':
        icon = Icons.hourglass_empty;
        color = const Color(0xFF8B88B5); // Grey
        break;
      case 'redemption_approved':
        icon = Icons.check_circle_outline;
        color = const Color(0xFF4FFD5B); // Green
        break;
      case 'redemption_rejected':
        icon = Icons.cancel_outlined;
        color = const Color(0xFFFF4B4B); // Red
        break;
      case 'points_earned':
        icon = Icons.add_circle_outline;
        color = const Color(0xFF4FFD5B); // Green
        break;
      case 'points_spent':
        icon = Icons.remove_circle_outline;
        color = const Color(0xFFFF4B4B); // Red
        break;
        
      // Social & System (4)
      case 'friend_request':
        icon = Icons.person_add_alt_1;
        color = const Color(0xFF5D5FEF); // Blue
        break;
      case 'reminder_workout':
      case 'reminder_user':
        icon = Icons.alarm;
        color = const Color(0xFFF83A71); // Pink
        break;
      case 'reminder_instructor':
        icon = Icons.assignment_ind;
        color = const Color(0xFF900EBF); // Purple
        break;
      case 'coupon_received':
        icon = Icons.confirmation_number_outlined;
        color = const Color(0xFF4FFD5B); // Green
        break;

      default:
        icon = Icons.notifications_none_rounded;
        color = const Color(0xFF8B88B5); // Grey
    }

    return Container(
      width: 42.w,
      height: 42.w,
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: 22.sp),
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
