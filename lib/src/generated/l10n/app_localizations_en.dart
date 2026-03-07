// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'TRYD';

  @override
  String get loginTitle => 'Enter your email address to get started.';

  @override
  String get loginSubtitle =>
      'Sign in or join to reach your peak performance today';

  @override
  String get emailPlaceholder => 'example@mail.com';

  @override
  String get continueButton => 'Continue';

  @override
  String get emailLabel => 'Email Address';

  @override
  String get checking => 'Checking...';

  @override
  String get sendingOtp => 'Sending OTP...';

  @override
  String get verifyTitle => 'Enter verification code to login';

  @override
  String verifySubtitle(String email) {
    return 'We have sent the OTP to $email';
  }

  @override
  String get verifyButton => 'Verify OTP';

  @override
  String get verifying => 'Verifying...';

  @override
  String get resendText => 'If you didn\'t receive a code!';

  @override
  String get resendButton => 'Resend';

  @override
  String get sending => 'Sending...';

  @override
  String get signupTitle => 'Complete your profile';

  @override
  String get fullNameLabel => 'Full Name';

  @override
  String get fullNamePlaceholder => 'Enter full name';

  @override
  String get phoneNumberLabel => 'Phone Number';

  @override
  String get phoneNumberPlaceholder => '1234 5678';

  @override
  String get verificationCodeLabel => 'Verification Code';

  @override
  String get codeSentTo => 'Code sent to ';

  @override
  String get didntReceiveCode => 'Didn\'t receive code? ';

  @override
  String get resendCode => 'Resend code';

  @override
  String get changeEmail => 'Change Email';

  @override
  String get completeSignup => 'Complete Signup';

  @override
  String get signingUp => 'Signing up...';

  @override
  String get enterCompleteOtp => 'Please enter complete OTP';

  @override
  String get invalidPhone => 'Please enter a valid phone number';

  @override
  String get signupFailed => 'Verification or Signup failed. Try again.';

  @override
  String get otpResentSuccess => 'OTP Resent';

  @override
  String get otpResentSubtitle =>
      'A new verification code has been sent to your email.';

  @override
  String get otpResentFailed => 'Failed to resend OTP';

  @override
  String get verificationFailed => 'Verification failed. Check OTP.';

  @override
  String get invalidEmail => 'Please enter a valid email address';

  @override
  String get somethingWentWrong => 'Something went wrong. Try again.';

  @override
  String get loginLabel => 'Log In';

  @override
  String get helloGreeting => 'Hello!';

  @override
  String get availablePointsLabel => 'Your Available Points';

  @override
  String get currentMonthLabel => 'Current Month';

  @override
  String get stepsCountLabel => 'Steps Count';

  @override
  String get durationsLabel => 'Durations';

  @override
  String get minsSuffix => 'mins';

  @override
  String get burnedCaloriesLabel => 'Burned Calories';

  @override
  String get averageBpmLabel => 'Average BPM';

  @override
  String get activityLoadError => 'Could not load activity details';

  @override
  String get kmSuffix => 'km';

  @override
  String get logoutLabel => 'Logout';

  @override
  String get notificationsTitle => 'Notifications';

  @override
  String get noNotifications => 'No notifications yet';

  @override
  String get markAllAsRead => 'Mark all as read';

  @override
  String get justNow => 'Just now';

  @override
  String minutesAgo(String minutes) {
    return '${minutes}m ago';
  }

  @override
  String hoursAgo(String hours) {
    return '${hours}h ago';
  }

  @override
  String daysAgo(String days) {
    return '${days}d ago';
  }

  @override
  String get profileTitle => 'Profile';

  @override
  String get myRewards => 'My Rewards';

  @override
  String get activityLabel => 'Activity';

  @override
  String get myWorkouts => 'My Workouts';

  @override
  String get settingsLabel => 'Settings';

  @override
  String get editNameTitle => 'Edit Name';

  @override
  String get profileUpdated => 'Profile Updated!';

  @override
  String get profilePicChanged =>
      'Your profile picture has been successfully changed.';

  @override
  String get nameUpdated => 'Name Updated!';

  @override
  String nameChangedSuccess(String name) {
    return 'Your display name has been changed to $name.';
  }

  @override
  String failedToUpdateName(String error) {
    return 'Failed to update name: $error';
  }

  @override
  String failedToUploadImage(String error) {
    return 'Failed to upload image: $error';
  }

  @override
  String get cancelButton => 'Cancel';

  @override
  String get saveButton => 'Save';

  @override
  String get retryButton => 'Retry';

  @override
  String get loadProfileError => 'Something went wrong';

  @override
  String get freePlan => 'Free Plan';

  @override
  String get freePlanSubtitle => 'Basic tracking & community access';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get notificationsSection => 'Notifications';

  @override
  String get pushNotifications => 'Push Notifications';

  @override
  String get inAppNotifications => 'In-App Notifications';

  @override
  String get aboutSection => 'About';

  @override
  String get appVersionLabel => 'App Version';

  @override
  String get logoutButton => 'Log Out';

  @override
  String get passwordChanged => 'Password Changed';

  @override
  String get passwordUpdatedSuccess =>
      'Your password has been updated successfully.';

  @override
  String get failedToUpdatePreference => 'Failed to update preference';

  @override
  String get deleteAccountTitle => 'Delete Account?';

  @override
  String get deleteAccountWarning =>
      'This action is permanent and cannot be undone. All your data will be lost.';

  @override
  String get deleteAccountButton => 'Delete Account';

  @override
  String get changePasswordTitle => 'Change Password';

  @override
  String get currentPasswordLabel => 'Current Password';

  @override
  String get newPasswordLabel => 'New Password';

  @override
  String get confirmPasswordLabel => 'Confirm Password';

  @override
  String get passwordsDoNotMatch => 'Passwords do not match';

  @override
  String get passwordLengthError => 'Password must be at least 6 characters';

  @override
  String get startRun => 'START';

  @override
  String get distanceLabel => 'DISTANCE';

  @override
  String get durationLabel => 'DURATION';

  @override
  String get caloriesLabel => 'EST. CALS';

  @override
  String get currentPaceLabel => 'CURRENT PACE';

  @override
  String get avgPaceLabel => 'AVERAGE PACE';

  @override
  String get heartRateLabel => 'HEART RATE';

  @override
  String get endRunTitle => 'End Run?';

  @override
  String get endRunMessage =>
      'Save your progress and exit, or continue your run?';

  @override
  String get saveAndExit => 'Save & Exit';

  @override
  String get keepRunning => 'Keep Running';

  @override
  String get healthConnectTitle => 'Health Connect Required';

  @override
  String get healthUpdateTitle => 'Update Required';

  @override
  String get healthConnectMessage =>
      'To track your steps and heart rate accurately, you need to install the Google Health Connect app.';

  @override
  String get healthUpdateMessage =>
      'Your Google Health Connect app needs an update to sync workout data properly.';

  @override
  String get installUpdate => 'Install / Update';

  @override
  String get appleHealthTitle => 'Apple Health Access';

  @override
  String get appleHealthMessage =>
      'Tryd needs access to Apple Health to track your steps, distance, and heart rate during runs.\n\nPlease go to:';

  @override
  String get appleHealthPath => 'Settings → Health → Data Access → Tryd';

  @override
  String get appleHealthTurnOnMessage =>
      'Turn on all categories to get the best experience.';

  @override
  String get openSettings => 'Open Settings';

  @override
  String get go => 'Go';

  @override
  String get runCompleteAmazing => 'Run complete, Amazing effort';

  @override
  String get runCompleteGreat => 'Run complete, Great job';

  @override
  String get runCompleteWellDone => 'Run complete, Well done';

  @override
  String get paused => 'Paused';

  @override
  String get letsGo => 'Let\'s go';

  @override
  String get shareButton => 'Share';

  @override
  String get stopButton => 'Stop';

  @override
  String get later => 'Later';

  @override
  String get workoutsTitle => 'Workouts';

  @override
  String get workLabel => 'Work';

  @override
  String get restLabel => 'Rest';

  @override
  String get exercisesLabel => 'Exercises';

  @override
  String get roundsLabel => 'Rounds';

  @override
  String get repsLabel => 'Reps';

  @override
  String exerciseProgress(String current, String total) {
    return 'Exercise $current of $total';
  }

  @override
  String roundProgress(String current, String total) {
    return 'Round $current of $total';
  }

  @override
  String get holdToPause => 'Hold to Pause';

  @override
  String get holdToResume => 'Hold to Resume';

  @override
  String get resetWorkout => 'Reset Workout';

  @override
  String get endWorkoutTitle => 'End Workout?';

  @override
  String get endWorkoutMessage => 'Are you sure you want to end this workout?';

  @override
  String get endButton => 'End';

  @override
  String get workoutComplete => 'Workout Complete!';

  @override
  String get workoutCompleteMessage =>
      'Great job! You completed all exercises and rounds.';

  @override
  String get doneButton => 'Done';

  @override
  String get skipRest => 'Skip Rest';

  @override
  String get unitKm => 'km';

  @override
  String get unitMinKm => 'min/km';

  @override
  String get unitBpm => 'bpm';

  @override
  String get historyTitle => 'History';

  @override
  String get noWorkoutsYet => 'No workouts yet';

  @override
  String get todayLabel => 'Today';

  @override
  String get yesterdayLabel => 'Yesterday';

  @override
  String get exLabel => 'Ex';

  @override
  String get challengesTitle => 'Challenges';

  @override
  String get challengesSubtitle =>
      'Join Challenge and surprise points waiting for you once you finish the challenge.';

  @override
  String get myChallengesTab => 'My Challenges';

  @override
  String get joinAChallengeTab => 'Join a Challenge';

  @override
  String get noActiveChallenges => 'No active challenges.';

  @override
  String get previousChallenges => 'Previous Challenges';

  @override
  String get noAvailableChallenges => 'No available challenges to join.';

  @override
  String get activeChallengesBadge => 'Active Challenge';

  @override
  String get upcomingChallengeBadge => 'Upcoming Challenge';

  @override
  String get challengeEndedBadge => 'Challenge Ended';

  @override
  String get kmLabel => 'KM';

  @override
  String get myChallengeTitle => 'My Challenge';

  @override
  String get unlockRewards => 'Unlock Rewards';

  @override
  String get totalDistance => 'Total Distance';

  @override
  String get participantsLabel => 'Participants';

  @override
  String get leaderboardTitle => 'Leaderboard';

  @override
  String get goToChallenge => 'Go to Challenge';

  @override
  String get challengeEndedButton => 'Challenge Ended';

  @override
  String get joinChallenge => 'Join Challenge';

  @override
  String get challengeJoinedTitle => 'Challenge Joined!';

  @override
  String get errorLoadingChallenge => 'Error loading challenge';

  @override
  String get challengeDetailTitle => 'Challenge Detail';

  @override
  String get rankHeaderLabel => 'RANK';

  @override
  String get userHeaderLabel => 'USER';

  @override
  String get distanceHeaderLabel => 'DISTANCE';

  @override
  String get yourRankLabel => 'Your Rank';

  @override
  String get topPerformersLabel => 'Top Performers Rank';

  @override
  String get yourPositionLabel => 'Your Position';

  @override
  String get activityTitle => 'Activity';

  @override
  String get thisWeek => 'This Week';

  @override
  String get thisMonth => 'This Month';

  @override
  String get thisYear => 'This Year';

  @override
  String get allActivitiesLabel => 'All Activities';

  @override
  String get kilometersLabel => 'Kilometers';

  @override
  String get countLabel => 'Count';

  @override
  String get timeLabel => 'Time';

  @override
  String get avgPaceShort => 'Avg pace';

  @override
  String get recentActivities => 'Recent Activities';

  @override
  String get noRecentActivities => 'No recent activities';

  @override
  String get filterWeekLabel => 'W';

  @override
  String get filterMonthLabel => 'M';

  @override
  String get filterYearLabel => 'Y';

  @override
  String get filterAllLabel => 'All';

  @override
  String get rewardsTitle => 'Rewards';

  @override
  String get availableRewardsTab => 'Available Rewards';

  @override
  String get myRedemptionsTab => 'My Redemptions';

  @override
  String get categoryAll => 'All';

  @override
  String get categoryCoffee => 'Coffee';

  @override
  String get categoryShop => 'Shop';

  @override
  String get categoryFood => 'Food';

  @override
  String get categoryGym => 'Gym';

  @override
  String get categoryBooks => 'Books';

  @override
  String get noRewardsAvailable => 'No rewards available';

  @override
  String get noRedemptionsYet => 'No redemptions yet';

  @override
  String get manualApprovalBadge => 'Manual Approval';

  @override
  String get claimedLabel => 'Claimed';

  @override
  String get pendingLabel => 'Pending';

  @override
  String get redeemButton => 'Redeem';

  @override
  String get pointsLabel => 'points';

  @override
  String get ptsSuffix => 'pts';

  @override
  String requestedOnDate(String date) {
    return 'Requested on $date';
  }

  @override
  String redeemedOnDate(String date) {
    return 'Redeemed on $date';
  }

  @override
  String get refundedLabel => 'Refunded';

  @override
  String rejectedWithNote(String note) {
    return 'Rejected: $note';
  }

  @override
  String get requestRejectedDefault =>
      'Your request was rejected. Points have been refunded to your account.';

  @override
  String get requestPendingMessage =>
      'Your request is being reviewed. You\'ll be notified once approved.';

  @override
  String get yourCouponCode => 'Your Coupon Code';

  @override
  String get copyButton => 'Copy';

  @override
  String get confirmRedemptionTitle => 'Confirm Redemption';

  @override
  String get pointsRequired => 'Points Required';

  @override
  String get currentBalance => 'Current Balance';

  @override
  String get afterRedemption => 'After Redemption';

  @override
  String get confirmRedeemButton => 'Confirm Redeem';

  @override
  String get codeCopiedTitle => 'Code Copied!';

  @override
  String get codeCopiedMessage => 'Coupon code copied to clipboard.';

  @override
  String get rewardRedeemedTitle => 'Reward Redeemed!';

  @override
  String rewardRedeemedMessage(String title) {
    return '$title has been added to your redemptions.';
  }

  @override
  String get chooseFromGallery => 'Choose from Gallery';

  @override
  String get takeAPhoto => 'Take a Photo';

  @override
  String get uploadImage => 'Upload Image';

  @override
  String get changePicture => 'Change Picture';

  @override
  String get totalTimeLabel => 'Total Time';

  @override
  String get distanceShort => 'Distance';

  @override
  String get startHeadline =>
      'Every step brings you closer to your goals and greater rewards.';

  @override
  String get startSubtitle =>
      'This productive tool is designed to help you better manage your task project-wise conveniently!';

  @override
  String get getStarted => 'Get Started';

  @override
  String get navHome => 'Home';

  @override
  String get navRun => 'Run';

  @override
  String get navWorkout => 'Workout';

  @override
  String get navClub => 'Club';

  @override
  String get removePhotoLabel => 'Remove Photo';

  @override
  String get resumeActivityTitle => 'Resume Activity';

  @override
  String get resumeActivityMessage =>
      'You have an unfinished run. Would you like to resume it?';

  @override
  String get discardButton => 'Discard';

  @override
  String get resumeButton => 'Resume';
}
