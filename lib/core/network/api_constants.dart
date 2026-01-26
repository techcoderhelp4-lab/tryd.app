class ApiConstants {
  static const String baseUrl = 'https://api.tryd.app/api/v1'; // Example URL

  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String logout = '/auth/logout';
  
  static const String profile = '/users/profile';
  static const String updateProfile = '/users/profile';
  static const String uploadProfilePicture = '/users/profile/picture';
  static const String activitySummary = '/users/activity-summary';

  static const String challenges = '/challenges';
  static String challengeDetails(String id) => '/challenges/$id';
  static String joinChallenge(String id) => '/challenges/$id/join';

  static const String rewards = '/rewards';
  static String redeemReward(String id) => '/rewards/$id/redeem';
  static const String myRedemptions = '/rewards/my-redemptions';

  static const String activities = '/activities';
  static const String workouts = '/workouts';
}
