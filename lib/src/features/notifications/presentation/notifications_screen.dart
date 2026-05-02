import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:shimmer/shimmer.dart';
import '../data/notification_repository.dart';
import '../domain/app_notification.dart';
import '../../../../widgets/custom_arrow_icon.dart';
import 'package:tryd/src/generated/l10n/app_localizations.dart';
import '../../../../widgets/swipe_to_pop_wrapper.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  final Set<String> _localReadIds = {};
  // Session-level deletions to handle swipe dismissal without crashes
  final Set<String> _deletedIds = {};

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

    final fontScale = Localizations.localeOf(context).languageCode == 'ar' ? 1.15 : 1.0;
    final l10n = AppLocalizations.of(context)!;

    return SwipeToPopWrapper(child: Scaffold(
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
                _buildAppBar(context, scale, l10n, fontScale),
                Expanded(
                  child: notificationsAsync.when(
                    skipLoadingOnRefresh: true,
                    data: (allNotifications) {
                      final notifications = allNotifications.where((n) => !_deletedIds.contains(n.id)).toList();

                      if (notifications.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.notifications_none, size: 60.0 * scale, color: Colors.grey.withOpacity(0.5)),
                              SizedBox(height: 10.0 * scale),
                              Text(l10n.noNotifications, style: GoogleFonts.tajawal(color: Colors.grey, fontSize: 14.0 * scale * fontScale)),
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
                          _deletedIds.clear();
                          await Future.delayed(const Duration(milliseconds: 500));
                        },
                        child: ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                          padding: EdgeInsets.symmetric(horizontal: 16.0 * scale, vertical: 10.0 * scale),
                          itemCount: notifications.length,
                          separatorBuilder: (context, index) => SizedBox(height: 10.0 * scale),
                          itemBuilder: (context, index) {
                            return _buildNotificationItem(context, notifications[index], scale, l10n, fontScale);
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
    ));
  }

  Widget _buildAppBar(BuildContext context, double scale, AppLocalizations l10n, double fontScale) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.0 * scale, vertical: 20.0 * scale),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            behavior: HitTestBehavior.opaque,
            child: SizedBox(
              width: 42.0 * scale,
              height: 42.0 * scale,
              child: Transform.scale(
                scaleX: Directionality.of(context) == TextDirection.rtl ? 1 : -1,
                child: CustomArrowIcon(
                  size: 42.0 * scale,
                  color: const Color(0xFF130F26),
                ),
              ),
            ),
          ),
          Text(
            l10n.notificationsTitle,
            style: GoogleFonts.tajawal(
              fontSize: 19.0 * scale * fontScale,
              fontWeight: FontWeight.w800,
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
                if (mounted) {
                  ref.invalidate(unreadNotificationCountProvider);
                  ref.invalidate(notificationsListProvider);
                }
              });
            },
            tooltip: l10n.markAllAsRead,
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationItem(BuildContext context, AppNotification notification, double scale, AppLocalizations l10n, double fontScale) {
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
        // Optimistic: add to local session deletions so ListView rebuilds without it
        setState(() {
          _deletedIds.add(notification.id);
        });
        
        // Fire API in background
        ref.read(notificationRepositoryProvider).deleteNotification(notification.id);
        ref.invalidate(unreadNotificationCountProvider);
        // Refresh the list to reflect deletion permanency on server
        ref.invalidate(notificationsListProvider);
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
            border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
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
              SizedBox(width: 12.0 * scale),
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
                            style: GoogleFonts.tajawal(
                              fontSize: 15.0 * scale * fontScale,
                              fontWeight: isRead ? FontWeight.w700 : FontWeight.w800,
                              color: const Color(0xFF24252C),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textDirection: TextDirection.ltr,
                            textAlign: fontScale > 1.0 ? TextAlign.right : TextAlign.left,
                          ),
                        ),
                        Text(
                          _formatTime(notification.createdAt, l10n),
                          style: GoogleFonts.tajawal(
                            fontSize: 11.0 * scale * fontScale,
                            color: const Color(0xFF8B88B5),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 6.0 * scale),
                      Text(
                        notification.message,
                        style: GoogleFonts.tajawal(
                          fontSize: 13.0 * scale * fontScale,
                          color: const Color(0xFF24252C).withOpacity(0.7),
                          height: 1.4,
                        ),
                        textDirection: TextDirection.ltr,
                        textAlign: fontScale > 1.0 ? TextAlign.right : TextAlign.left,
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
      case 'download_reward_granted':
        icon = Icons.workspace_premium_rounded;
        color = const Color(0xFFFFB300);
        break;
      case 'referral_bonus_received':
        icon = Icons.redeem_rounded;
        color = const Color(0xFF900EBF);
        break;
      case 'referral_credit_received':
        icon = Icons.people_rounded;
        color = const Color(0xFFF83A71);
        break;
      default:
        icon = Icons.notifications_none_rounded;
        color = const Color(0xFF8B88B5);
    }

    return Container(
      width: 42.0 * scale,
      height: 42.0 * scale,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
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
          border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
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

  String _formatTime(DateTime date, AppLocalizations l10n) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return l10n.justNow;
    } else if (difference.inMinutes < 60) {
      return l10n.minutesAgo(difference.inMinutes.toString());
    } else if (difference.inHours < 24) {
      return l10n.hoursAgo(difference.inHours.toString());
    } else if (difference.inDays < 7) {
      return l10n.daysAgo(difference.inDays.toString());
    } else {
      return DateFormat('d MMM').format(date);
    }
  }
}

