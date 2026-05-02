class ApiConstants {
  static const String baseUrl = 'http://api.tryd-it.com:5003/api';
  static const String socketUrl = 'http://api.tryd-it.com:5003';

  static const String login = '/users/login';
  static const String register = '/users/register';
  static const String logout = '/users/logout';
  static const String refreshToken = '/auth/refresh';
  static const String checkUserExists = '/auth/check-user';
  static const String sendOtp = '/auth/send-otp';
  static const String verifyOtp = '/auth/verify-otp';
  static const String verifyOtpLogin = '/auth/verify-otp-login';
  
  static const String profile = '/users/profile';
  static const String updateProfile = '/users/profile';
  static const String uploadProfilePicture = '/users/upload-profile-picture';
  static const String activitySummary = '/users/activity-summary';

  static const String challenges = '/challenges';
  static String challengeDetails(String id) => '/challenges/$id';
  static String joinChallenge(String id) => '/challenges/$id/join';
  static String challengeLeaderboard(String id) => '/challenges/$id/leaderboard';
  static String challengeProgress(String id) => '/challenges/$id/progress';

  static const String rewards = '/rewards';
  static String redeemReward(String id) => '/rewards/$id/redeem';
  static const String myRedemptions = '/rewards/my-redemptions';

  static const String activities = '/activities';
  static const String workouts = '/workouts';
  
  // Notification Endpoints
  static const String notifications = '/notifications';
  static const String notificationsUnreadCount = '/notifications/unread-count';
  static const String notificationsMarkAllRead = '/notifications/mark-all-read';
  static String notificationMarkRead(String id) => '/notifications/$id/read';
  static String notificationDelete(String id) => '/notifications/$id';
  
  static const String pushTokens = '/push-tokens';

  // Notification Preferences
  static const String notificationPreferences = '/notification-preferences';
  static const String notificationPreferencesGlobal = '/notification-preferences/global';

  // Account
  static const String changePassword = '/users/change-password';
  static const String deleteAccount = '/users/delete-account';

  // Referral
  static const String verifyReferralCode = '/users/verify-referral-code';
  static const String myReferralInfo = '/users/me/referral';

  // Share rewards
  static const String shareReward = '/share/reward';
  static const String shareRewardStatus = '/share/reward/status';

  // App Settings (admin)
  static const String appSettings = '/admin/settings';
  static const String homeBanner = '/public/banner';
  static const String updateHomeBanner = '/admin/settings/banner';

  // Pre-built Workouts
  static const String preBuiltWorkouts = '/public/pre-built-workouts';
  static const String adminPreBuiltWorkouts = '/admin/pre-built-workouts';
  static String adminPreBuiltWorkout(String id) => '/admin/pre-built-workouts/$id';
}

