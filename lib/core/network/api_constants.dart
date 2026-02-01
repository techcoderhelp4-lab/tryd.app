class ApiConstants {
  static const String baseUrl = 'http://192.168.0.58:4000/api'; 

  static const String login = '/users/login';
  static const String register = '/users/register';
  static const String logout = '/users/logout';
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
}
