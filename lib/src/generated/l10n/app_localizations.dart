import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
  ];

  /// Title of the application
  ///
  /// In en, this message translates to:
  /// **'TRYD'**
  String get appTitle;

  /// No description provided for @loginTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter your email address to get started.'**
  String get loginTitle;

  /// No description provided for @loginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in or join to reach your peak performance today'**
  String get loginSubtitle;

  /// No description provided for @emailPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'example@mail.com'**
  String get emailPlaceholder;

  /// No description provided for @continueButton.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueButton;

  /// No description provided for @emailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email Address'**
  String get emailLabel;

  /// No description provided for @checking.
  ///
  /// In en, this message translates to:
  /// **'Checking...'**
  String get checking;

  /// No description provided for @sendingOtp.
  ///
  /// In en, this message translates to:
  /// **'Sending OTP...'**
  String get sendingOtp;

  /// No description provided for @verifyTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter verification code to login'**
  String get verifyTitle;

  /// No description provided for @verifySubtitle.
  ///
  /// In en, this message translates to:
  /// **'We have sent the OTP to {email}'**
  String verifySubtitle(String email);

  /// No description provided for @verifyButton.
  ///
  /// In en, this message translates to:
  /// **'Verify OTP'**
  String get verifyButton;

  /// No description provided for @verifying.
  ///
  /// In en, this message translates to:
  /// **'Verifying...'**
  String get verifying;

  /// No description provided for @resendText.
  ///
  /// In en, this message translates to:
  /// **'If you didn\'t receive a code!'**
  String get resendText;

  /// No description provided for @resendButton.
  ///
  /// In en, this message translates to:
  /// **'Resend'**
  String get resendButton;

  /// No description provided for @sending.
  ///
  /// In en, this message translates to:
  /// **'Sending...'**
  String get sending;

  /// No description provided for @signupTitle.
  ///
  /// In en, this message translates to:
  /// **'Complete your profile'**
  String get signupTitle;

  /// No description provided for @fullNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullNameLabel;

  /// No description provided for @fullNamePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Enter full name'**
  String get fullNamePlaceholder;

  /// No description provided for @phoneNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phoneNumberLabel;

  /// No description provided for @phoneNumberPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'1234 5678'**
  String get phoneNumberPlaceholder;

  /// No description provided for @verificationCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Verification Code'**
  String get verificationCodeLabel;

  /// No description provided for @codeSentTo.
  ///
  /// In en, this message translates to:
  /// **'Code sent to '**
  String get codeSentTo;

  /// No description provided for @didntReceiveCode.
  ///
  /// In en, this message translates to:
  /// **'Didn\'t receive code? '**
  String get didntReceiveCode;

  /// No description provided for @resendCode.
  ///
  /// In en, this message translates to:
  /// **'Resend code'**
  String get resendCode;

  /// No description provided for @changeEmail.
  ///
  /// In en, this message translates to:
  /// **'Change Email'**
  String get changeEmail;

  /// No description provided for @completeSignup.
  ///
  /// In en, this message translates to:
  /// **'Complete Signup'**
  String get completeSignup;

  /// No description provided for @signingUp.
  ///
  /// In en, this message translates to:
  /// **'Signing up...'**
  String get signingUp;

  /// No description provided for @enterCompleteOtp.
  ///
  /// In en, this message translates to:
  /// **'Please enter complete OTP'**
  String get enterCompleteOtp;

  /// No description provided for @invalidPhone.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid phone number'**
  String get invalidPhone;

  /// No description provided for @signupFailed.
  ///
  /// In en, this message translates to:
  /// **'Verification or Signup failed. Try again.'**
  String get signupFailed;

  /// No description provided for @otpResentSuccess.
  ///
  /// In en, this message translates to:
  /// **'OTP Resent'**
  String get otpResentSuccess;

  /// No description provided for @otpResentSubtitle.
  ///
  /// In en, this message translates to:
  /// **'A new verification code has been sent to your email.'**
  String get otpResentSubtitle;

  /// No description provided for @otpResentFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to resend OTP'**
  String get otpResentFailed;

  /// No description provided for @verificationFailed.
  ///
  /// In en, this message translates to:
  /// **'Verification failed. Check OTP.'**
  String get verificationFailed;

  /// No description provided for @invalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email address'**
  String get invalidEmail;

  /// No description provided for @somethingWentWrong.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Try again.'**
  String get somethingWentWrong;

  /// No description provided for @loginLabel.
  ///
  /// In en, this message translates to:
  /// **'Log In'**
  String get loginLabel;

  /// No description provided for @helloGreeting.
  ///
  /// In en, this message translates to:
  /// **'Hello!'**
  String get helloGreeting;

  /// No description provided for @availablePointsLabel.
  ///
  /// In en, this message translates to:
  /// **'Your Available Points'**
  String get availablePointsLabel;

  /// No description provided for @currentMonthLabel.
  ///
  /// In en, this message translates to:
  /// **'Current Month'**
  String get currentMonthLabel;

  /// No description provided for @stepsCountLabel.
  ///
  /// In en, this message translates to:
  /// **'Steps Count'**
  String get stepsCountLabel;

  /// No description provided for @durationsLabel.
  ///
  /// In en, this message translates to:
  /// **'Durations'**
  String get durationsLabel;

  /// No description provided for @minsSuffix.
  ///
  /// In en, this message translates to:
  /// **'mins'**
  String get minsSuffix;

  /// No description provided for @burnedCaloriesLabel.
  ///
  /// In en, this message translates to:
  /// **'Burned Calories'**
  String get burnedCaloriesLabel;

  /// No description provided for @averageBpmLabel.
  ///
  /// In en, this message translates to:
  /// **'Average BPM'**
  String get averageBpmLabel;

  /// No description provided for @activityLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load activity details'**
  String get activityLoadError;

  /// No description provided for @kmSuffix.
  ///
  /// In en, this message translates to:
  /// **'km'**
  String get kmSuffix;

  /// No description provided for @logoutLabel.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logoutLabel;

  /// No description provided for @notificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsTitle;

  /// No description provided for @noNotifications.
  ///
  /// In en, this message translates to:
  /// **'No notifications yet'**
  String get noNotifications;

  /// No description provided for @markAllAsRead.
  ///
  /// In en, this message translates to:
  /// **'Mark all as read'**
  String get markAllAsRead;

  /// No description provided for @justNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get justNow;

  /// No description provided for @minutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{minutes}m ago'**
  String minutesAgo(String minutes);

  /// No description provided for @hoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{hours}h ago'**
  String hoursAgo(String hours);

  /// No description provided for @daysAgo.
  ///
  /// In en, this message translates to:
  /// **'{days}d ago'**
  String daysAgo(String days);

  /// No description provided for @profileTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileTitle;

  /// No description provided for @myRewards.
  ///
  /// In en, this message translates to:
  /// **'My Rewards'**
  String get myRewards;

  /// No description provided for @activityLabel.
  ///
  /// In en, this message translates to:
  /// **'Activity'**
  String get activityLabel;

  /// No description provided for @myWorkouts.
  ///
  /// In en, this message translates to:
  /// **'My Workouts'**
  String get myWorkouts;

  /// No description provided for @settingsLabel.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsLabel;

  /// No description provided for @editNameTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Name'**
  String get editNameTitle;

  /// No description provided for @profileUpdated.
  ///
  /// In en, this message translates to:
  /// **'Profile Updated!'**
  String get profileUpdated;

  /// No description provided for @profilePicChanged.
  ///
  /// In en, this message translates to:
  /// **'Your profile picture has been successfully changed.'**
  String get profilePicChanged;

  /// No description provided for @nameUpdated.
  ///
  /// In en, this message translates to:
  /// **'Name Updated!'**
  String get nameUpdated;

  /// No description provided for @nameChangedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Your display name has been changed to {name}.'**
  String nameChangedSuccess(String name);

  /// No description provided for @failedToUpdateName.
  ///
  /// In en, this message translates to:
  /// **'Failed to update name: {error}'**
  String failedToUpdateName(String error);

  /// No description provided for @failedToUploadImage.
  ///
  /// In en, this message translates to:
  /// **'Failed to upload image: {error}'**
  String failedToUploadImage(String error);

  /// No description provided for @cancelButton.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancelButton;

  /// No description provided for @saveButton.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get saveButton;

  /// No description provided for @retryButton.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retryButton;

  /// No description provided for @loadProfileError.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get loadProfileError;

  /// No description provided for @freePlan.
  ///
  /// In en, this message translates to:
  /// **'Free Plan'**
  String get freePlan;

  /// No description provided for @freePlanSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Basic tracking & community access'**
  String get freePlanSubtitle;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @notificationsSection.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsSection;

  /// No description provided for @pushNotifications.
  ///
  /// In en, this message translates to:
  /// **'Push Notifications'**
  String get pushNotifications;

  /// No description provided for @inAppNotifications.
  ///
  /// In en, this message translates to:
  /// **'In-App Notifications'**
  String get inAppNotifications;

  /// No description provided for @aboutSection.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get aboutSection;

  /// No description provided for @appVersionLabel.
  ///
  /// In en, this message translates to:
  /// **'App Version'**
  String get appVersionLabel;

  /// No description provided for @logoutButton.
  ///
  /// In en, this message translates to:
  /// **'Log Out'**
  String get logoutButton;

  /// No description provided for @passwordChanged.
  ///
  /// In en, this message translates to:
  /// **'Password Changed'**
  String get passwordChanged;

  /// No description provided for @passwordUpdatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Your password has been updated successfully.'**
  String get passwordUpdatedSuccess;

  /// No description provided for @failedToUpdatePreference.
  ///
  /// In en, this message translates to:
  /// **'Failed to update preference'**
  String get failedToUpdatePreference;

  /// No description provided for @deleteAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Account?'**
  String get deleteAccountTitle;

  /// No description provided for @deleteAccountWarning.
  ///
  /// In en, this message translates to:
  /// **'This action is permanent and cannot be undone. All your data will be lost.'**
  String get deleteAccountWarning;

  /// No description provided for @deleteAccountButton.
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get deleteAccountButton;

  /// No description provided for @changePasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get changePasswordTitle;

  /// No description provided for @currentPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Current Password'**
  String get currentPasswordLabel;

  /// No description provided for @newPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'New Password'**
  String get newPasswordLabel;

  /// No description provided for @confirmPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPasswordLabel;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordsDoNotMatch;

  /// No description provided for @passwordLengthError.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get passwordLengthError;

  /// No description provided for @startRun.
  ///
  /// In en, this message translates to:
  /// **'START'**
  String get startRun;

  /// No description provided for @distanceLabel.
  ///
  /// In en, this message translates to:
  /// **'DISTANCE'**
  String get distanceLabel;

  /// No description provided for @durationLabel.
  ///
  /// In en, this message translates to:
  /// **'DURATION'**
  String get durationLabel;

  /// No description provided for @caloriesLabel.
  ///
  /// In en, this message translates to:
  /// **'EST. CALS'**
  String get caloriesLabel;

  /// No description provided for @currentPaceLabel.
  ///
  /// In en, this message translates to:
  /// **'CURRENT PACE'**
  String get currentPaceLabel;

  /// No description provided for @avgPaceLabel.
  ///
  /// In en, this message translates to:
  /// **'AVERAGE PACE'**
  String get avgPaceLabel;

  /// No description provided for @heartRateLabel.
  ///
  /// In en, this message translates to:
  /// **'HEART RATE'**
  String get heartRateLabel;

  /// No description provided for @endRunTitle.
  ///
  /// In en, this message translates to:
  /// **'End Run?'**
  String get endRunTitle;

  /// No description provided for @endRunMessage.
  ///
  /// In en, this message translates to:
  /// **'Save your progress and exit, or continue your run?'**
  String get endRunMessage;

  /// No description provided for @saveAndExit.
  ///
  /// In en, this message translates to:
  /// **'Save & Exit'**
  String get saveAndExit;

  /// No description provided for @keepRunning.
  ///
  /// In en, this message translates to:
  /// **'Keep Running'**
  String get keepRunning;

  /// No description provided for @healthConnectTitle.
  ///
  /// In en, this message translates to:
  /// **'Health Connect Required'**
  String get healthConnectTitle;

  /// No description provided for @healthUpdateTitle.
  ///
  /// In en, this message translates to:
  /// **'Update Required'**
  String get healthUpdateTitle;

  /// No description provided for @healthConnectMessage.
  ///
  /// In en, this message translates to:
  /// **'To track your steps and heart rate accurately, you need to install the Google Health Connect app.'**
  String get healthConnectMessage;

  /// No description provided for @healthUpdateMessage.
  ///
  /// In en, this message translates to:
  /// **'Your Google Health Connect app needs an update to sync workout data properly.'**
  String get healthUpdateMessage;

  /// No description provided for @installUpdate.
  ///
  /// In en, this message translates to:
  /// **'Install / Update'**
  String get installUpdate;

  /// No description provided for @appleHealthTitle.
  ///
  /// In en, this message translates to:
  /// **'Apple Health Access'**
  String get appleHealthTitle;

  /// No description provided for @appleHealthMessage.
  ///
  /// In en, this message translates to:
  /// **'Tryd needs access to Apple Health to track your steps, distance, and heart rate during runs.\n\nPlease go to:'**
  String get appleHealthMessage;

  /// No description provided for @appleHealthPath.
  ///
  /// In en, this message translates to:
  /// **'Settings → Health → Data Access → Tryd'**
  String get appleHealthPath;

  /// No description provided for @appleHealthTurnOnMessage.
  ///
  /// In en, this message translates to:
  /// **'Turn on all categories to get the best experience.'**
  String get appleHealthTurnOnMessage;

  /// No description provided for @openSettings.
  ///
  /// In en, this message translates to:
  /// **'Open Settings'**
  String get openSettings;

  /// No description provided for @go.
  ///
  /// In en, this message translates to:
  /// **'Go'**
  String get go;

  /// No description provided for @runCompleteAmazing.
  ///
  /// In en, this message translates to:
  /// **'Run complete, Amazing effort'**
  String get runCompleteAmazing;

  /// No description provided for @runCompleteGreat.
  ///
  /// In en, this message translates to:
  /// **'Run complete, Great job'**
  String get runCompleteGreat;

  /// No description provided for @runCompleteWellDone.
  ///
  /// In en, this message translates to:
  /// **'Run complete, Well done'**
  String get runCompleteWellDone;

  /// No description provided for @paused.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get paused;

  /// No description provided for @letsGo.
  ///
  /// In en, this message translates to:
  /// **'Let\'s go'**
  String get letsGo;

  /// No description provided for @shareButton.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get shareButton;

  /// No description provided for @stopButton.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get stopButton;

  /// No description provided for @later.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get later;

  /// No description provided for @workoutsTitle.
  ///
  /// In en, this message translates to:
  /// **'Workouts'**
  String get workoutsTitle;

  /// No description provided for @workLabel.
  ///
  /// In en, this message translates to:
  /// **'Work'**
  String get workLabel;

  /// No description provided for @restLabel.
  ///
  /// In en, this message translates to:
  /// **'Rest'**
  String get restLabel;

  /// No description provided for @exercisesLabel.
  ///
  /// In en, this message translates to:
  /// **'Exercises'**
  String get exercisesLabel;

  /// No description provided for @roundsLabel.
  ///
  /// In en, this message translates to:
  /// **'Rounds'**
  String get roundsLabel;

  /// No description provided for @repsLabel.
  ///
  /// In en, this message translates to:
  /// **'Reps'**
  String get repsLabel;

  /// No description provided for @exerciseProgress.
  ///
  /// In en, this message translates to:
  /// **'Exercise {current} of {total}'**
  String exerciseProgress(String current, String total);

  /// No description provided for @roundProgress.
  ///
  /// In en, this message translates to:
  /// **'Round {current} of {total}'**
  String roundProgress(String current, String total);

  /// No description provided for @holdToPause.
  ///
  /// In en, this message translates to:
  /// **'Hold to Pause'**
  String get holdToPause;

  /// No description provided for @holdToResume.
  ///
  /// In en, this message translates to:
  /// **'Hold to Resume'**
  String get holdToResume;

  /// No description provided for @resetWorkout.
  ///
  /// In en, this message translates to:
  /// **'Reset Workout'**
  String get resetWorkout;

  /// No description provided for @endWorkoutTitle.
  ///
  /// In en, this message translates to:
  /// **'End Workout?'**
  String get endWorkoutTitle;

  /// No description provided for @endWorkoutMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to end this workout?'**
  String get endWorkoutMessage;

  /// No description provided for @endButton.
  ///
  /// In en, this message translates to:
  /// **'End'**
  String get endButton;

  /// No description provided for @workoutComplete.
  ///
  /// In en, this message translates to:
  /// **'Workout Complete!'**
  String get workoutComplete;

  /// No description provided for @workoutCompleteMessage.
  ///
  /// In en, this message translates to:
  /// **'Great job! You completed all exercises and rounds.'**
  String get workoutCompleteMessage;

  /// No description provided for @doneButton.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get doneButton;

  /// No description provided for @skipRest.
  ///
  /// In en, this message translates to:
  /// **'Skip Rest'**
  String get skipRest;

  /// No description provided for @unitKm.
  ///
  /// In en, this message translates to:
  /// **'km'**
  String get unitKm;

  /// No description provided for @unitMinKm.
  ///
  /// In en, this message translates to:
  /// **'min/km'**
  String get unitMinKm;

  /// No description provided for @unitBpm.
  ///
  /// In en, this message translates to:
  /// **'bpm'**
  String get unitBpm;

  /// No description provided for @historyTitle.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get historyTitle;

  /// No description provided for @noWorkoutsYet.
  ///
  /// In en, this message translates to:
  /// **'No workouts yet'**
  String get noWorkoutsYet;

  /// No description provided for @todayLabel.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get todayLabel;

  /// No description provided for @yesterdayLabel.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get yesterdayLabel;

  /// No description provided for @exLabel.
  ///
  /// In en, this message translates to:
  /// **'Ex'**
  String get exLabel;

  /// No description provided for @challengesTitle.
  ///
  /// In en, this message translates to:
  /// **'Challenges'**
  String get challengesTitle;

  /// No description provided for @challengesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Join Challenge and surprise points waiting for you once you finish the challenge.'**
  String get challengesSubtitle;

  /// No description provided for @myChallengesTab.
  ///
  /// In en, this message translates to:
  /// **'My Challenges'**
  String get myChallengesTab;

  /// No description provided for @joinAChallengeTab.
  ///
  /// In en, this message translates to:
  /// **'Join a Challenge'**
  String get joinAChallengeTab;

  /// No description provided for @noActiveChallenges.
  ///
  /// In en, this message translates to:
  /// **'No active challenges.'**
  String get noActiveChallenges;

  /// No description provided for @previousChallenges.
  ///
  /// In en, this message translates to:
  /// **'Previous Challenges'**
  String get previousChallenges;

  /// No description provided for @noAvailableChallenges.
  ///
  /// In en, this message translates to:
  /// **'No available challenges to join.'**
  String get noAvailableChallenges;

  /// No description provided for @activeChallengesBadge.
  ///
  /// In en, this message translates to:
  /// **'Active Challenge'**
  String get activeChallengesBadge;

  /// No description provided for @upcomingChallengeBadge.
  ///
  /// In en, this message translates to:
  /// **'Upcoming Challenge'**
  String get upcomingChallengeBadge;

  /// No description provided for @challengeEndedBadge.
  ///
  /// In en, this message translates to:
  /// **'Challenge Ended'**
  String get challengeEndedBadge;

  /// No description provided for @kmLabel.
  ///
  /// In en, this message translates to:
  /// **'KM'**
  String get kmLabel;

  /// No description provided for @myChallengeTitle.
  ///
  /// In en, this message translates to:
  /// **'My Challenge'**
  String get myChallengeTitle;

  /// No description provided for @unlockRewards.
  ///
  /// In en, this message translates to:
  /// **'Unlock Rewards'**
  String get unlockRewards;

  /// No description provided for @totalDistance.
  ///
  /// In en, this message translates to:
  /// **'Total Distance'**
  String get totalDistance;

  /// No description provided for @participantsLabel.
  ///
  /// In en, this message translates to:
  /// **'Participants'**
  String get participantsLabel;

  /// No description provided for @leaderboardTitle.
  ///
  /// In en, this message translates to:
  /// **'Leaderboard'**
  String get leaderboardTitle;

  /// No description provided for @goToChallenge.
  ///
  /// In en, this message translates to:
  /// **'Go to Challenge'**
  String get goToChallenge;

  /// No description provided for @challengeEndedButton.
  ///
  /// In en, this message translates to:
  /// **'Challenge Ended'**
  String get challengeEndedButton;

  /// No description provided for @joinChallenge.
  ///
  /// In en, this message translates to:
  /// **'Join Challenge'**
  String get joinChallenge;

  /// No description provided for @challengeJoinedTitle.
  ///
  /// In en, this message translates to:
  /// **'Challenge Joined!'**
  String get challengeJoinedTitle;

  /// No description provided for @errorLoadingChallenge.
  ///
  /// In en, this message translates to:
  /// **'Error loading challenge'**
  String get errorLoadingChallenge;

  /// No description provided for @challengeDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Challenge Detail'**
  String get challengeDetailTitle;

  /// No description provided for @rankHeaderLabel.
  ///
  /// In en, this message translates to:
  /// **'RANK'**
  String get rankHeaderLabel;

  /// No description provided for @userHeaderLabel.
  ///
  /// In en, this message translates to:
  /// **'USER'**
  String get userHeaderLabel;

  /// No description provided for @distanceHeaderLabel.
  ///
  /// In en, this message translates to:
  /// **'DISTANCE'**
  String get distanceHeaderLabel;

  /// No description provided for @yourRankLabel.
  ///
  /// In en, this message translates to:
  /// **'Your Rank'**
  String get yourRankLabel;

  /// No description provided for @topPerformersLabel.
  ///
  /// In en, this message translates to:
  /// **'Top Performers Rank'**
  String get topPerformersLabel;

  /// No description provided for @yourPositionLabel.
  ///
  /// In en, this message translates to:
  /// **'Your Position'**
  String get yourPositionLabel;

  /// No description provided for @activityTitle.
  ///
  /// In en, this message translates to:
  /// **'Activity'**
  String get activityTitle;

  /// No description provided for @thisWeek.
  ///
  /// In en, this message translates to:
  /// **'This Week'**
  String get thisWeek;

  /// No description provided for @thisMonth.
  ///
  /// In en, this message translates to:
  /// **'This Month'**
  String get thisMonth;

  /// No description provided for @thisYear.
  ///
  /// In en, this message translates to:
  /// **'This Year'**
  String get thisYear;

  /// No description provided for @allActivitiesLabel.
  ///
  /// In en, this message translates to:
  /// **'All Activities'**
  String get allActivitiesLabel;

  /// No description provided for @kilometersLabel.
  ///
  /// In en, this message translates to:
  /// **'Kilometers'**
  String get kilometersLabel;

  /// No description provided for @countLabel.
  ///
  /// In en, this message translates to:
  /// **'Count'**
  String get countLabel;

  /// No description provided for @timeLabel.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get timeLabel;

  /// No description provided for @avgPaceShort.
  ///
  /// In en, this message translates to:
  /// **'Avg pace'**
  String get avgPaceShort;

  /// No description provided for @recentActivities.
  ///
  /// In en, this message translates to:
  /// **'Recent Activities'**
  String get recentActivities;

  /// No description provided for @noRecentActivities.
  ///
  /// In en, this message translates to:
  /// **'No recent activities'**
  String get noRecentActivities;

  /// No description provided for @filterWeekLabel.
  ///
  /// In en, this message translates to:
  /// **'W'**
  String get filterWeekLabel;

  /// No description provided for @filterMonthLabel.
  ///
  /// In en, this message translates to:
  /// **'M'**
  String get filterMonthLabel;

  /// No description provided for @filterYearLabel.
  ///
  /// In en, this message translates to:
  /// **'Y'**
  String get filterYearLabel;

  /// No description provided for @filterAllLabel.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filterAllLabel;

  /// No description provided for @rewardsTitle.
  ///
  /// In en, this message translates to:
  /// **'Rewards'**
  String get rewardsTitle;

  /// No description provided for @availableRewardsTab.
  ///
  /// In en, this message translates to:
  /// **'Available Rewards'**
  String get availableRewardsTab;

  /// No description provided for @myRedemptionsTab.
  ///
  /// In en, this message translates to:
  /// **'My Redemptions'**
  String get myRedemptionsTab;

  /// No description provided for @categoryAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get categoryAll;

  /// No description provided for @categoryCoffee.
  ///
  /// In en, this message translates to:
  /// **'Coffee'**
  String get categoryCoffee;

  /// No description provided for @categoryShop.
  ///
  /// In en, this message translates to:
  /// **'Shop'**
  String get categoryShop;

  /// No description provided for @categoryFood.
  ///
  /// In en, this message translates to:
  /// **'Food'**
  String get categoryFood;

  /// No description provided for @categoryGym.
  ///
  /// In en, this message translates to:
  /// **'Gym'**
  String get categoryGym;

  /// No description provided for @categoryBooks.
  ///
  /// In en, this message translates to:
  /// **'Books'**
  String get categoryBooks;

  /// No description provided for @noRewardsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No rewards available'**
  String get noRewardsAvailable;

  /// No description provided for @noRedemptionsYet.
  ///
  /// In en, this message translates to:
  /// **'No redemptions yet'**
  String get noRedemptionsYet;

  /// No description provided for @manualApprovalBadge.
  ///
  /// In en, this message translates to:
  /// **'Manual Approval'**
  String get manualApprovalBadge;

  /// No description provided for @claimedLabel.
  ///
  /// In en, this message translates to:
  /// **'Claimed'**
  String get claimedLabel;

  /// No description provided for @pendingLabel.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pendingLabel;

  /// No description provided for @redeemButton.
  ///
  /// In en, this message translates to:
  /// **'Redeem'**
  String get redeemButton;

  /// No description provided for @pointsLabel.
  ///
  /// In en, this message translates to:
  /// **'points'**
  String get pointsLabel;

  /// No description provided for @ptsSuffix.
  ///
  /// In en, this message translates to:
  /// **'pts'**
  String get ptsSuffix;

  /// No description provided for @requestedOnDate.
  ///
  /// In en, this message translates to:
  /// **'Requested on {date}'**
  String requestedOnDate(String date);

  /// No description provided for @redeemedOnDate.
  ///
  /// In en, this message translates to:
  /// **'Redeemed on {date}'**
  String redeemedOnDate(String date);

  /// No description provided for @refundedLabel.
  ///
  /// In en, this message translates to:
  /// **'Refunded'**
  String get refundedLabel;

  /// No description provided for @rejectedWithNote.
  ///
  /// In en, this message translates to:
  /// **'Rejected: {note}'**
  String rejectedWithNote(String note);

  /// No description provided for @requestRejectedDefault.
  ///
  /// In en, this message translates to:
  /// **'Your request was rejected. Points have been refunded to your account.'**
  String get requestRejectedDefault;

  /// No description provided for @requestPendingMessage.
  ///
  /// In en, this message translates to:
  /// **'Your request is being reviewed. You\'ll be notified once approved.'**
  String get requestPendingMessage;

  /// No description provided for @yourCouponCode.
  ///
  /// In en, this message translates to:
  /// **'Your Coupon Code'**
  String get yourCouponCode;

  /// No description provided for @copyButton.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copyButton;

  /// No description provided for @confirmRedemptionTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm Redemption'**
  String get confirmRedemptionTitle;

  /// No description provided for @pointsRequired.
  ///
  /// In en, this message translates to:
  /// **'Points Required'**
  String get pointsRequired;

  /// No description provided for @currentBalance.
  ///
  /// In en, this message translates to:
  /// **'Current Balance'**
  String get currentBalance;

  /// No description provided for @afterRedemption.
  ///
  /// In en, this message translates to:
  /// **'After Redemption'**
  String get afterRedemption;

  /// No description provided for @confirmRedeemButton.
  ///
  /// In en, this message translates to:
  /// **'Confirm Redeem'**
  String get confirmRedeemButton;

  /// No description provided for @codeCopiedTitle.
  ///
  /// In en, this message translates to:
  /// **'Code Copied!'**
  String get codeCopiedTitle;

  /// No description provided for @codeCopiedMessage.
  ///
  /// In en, this message translates to:
  /// **'Coupon code copied to clipboard.'**
  String get codeCopiedMessage;

  /// No description provided for @rewardRedeemedTitle.
  ///
  /// In en, this message translates to:
  /// **'Reward Redeemed!'**
  String get rewardRedeemedTitle;

  /// No description provided for @rewardRedeemedMessage.
  ///
  /// In en, this message translates to:
  /// **'{title} has been added to your redemptions.'**
  String rewardRedeemedMessage(String title);

  /// No description provided for @chooseFromGallery.
  ///
  /// In en, this message translates to:
  /// **'Choose from Gallery'**
  String get chooseFromGallery;

  /// No description provided for @takeAPhoto.
  ///
  /// In en, this message translates to:
  /// **'Take a Photo'**
  String get takeAPhoto;

  /// No description provided for @uploadImage.
  ///
  /// In en, this message translates to:
  /// **'Upload Image'**
  String get uploadImage;

  /// No description provided for @changePicture.
  ///
  /// In en, this message translates to:
  /// **'Change Picture'**
  String get changePicture;

  /// No description provided for @totalTimeLabel.
  ///
  /// In en, this message translates to:
  /// **'Total Time'**
  String get totalTimeLabel;

  /// No description provided for @distanceShort.
  ///
  /// In en, this message translates to:
  /// **'Distance'**
  String get distanceShort;

  /// No description provided for @startHeadline.
  ///
  /// In en, this message translates to:
  /// **'Every step brings you closer to your goals and greater rewards.'**
  String get startHeadline;

  /// No description provided for @startSubtitle.
  ///
  /// In en, this message translates to:
  /// **'This productive tool is designed to help you better manage your task project-wise conveniently!'**
  String get startSubtitle;

  /// No description provided for @getStarted.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get getStarted;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navRun.
  ///
  /// In en, this message translates to:
  /// **'Run'**
  String get navRun;

  /// No description provided for @navWorkout.
  ///
  /// In en, this message translates to:
  /// **'Workout'**
  String get navWorkout;

  /// No description provided for @navClub.
  ///
  /// In en, this message translates to:
  /// **'Club'**
  String get navClub;

  /// No description provided for @removePhotoLabel.
  ///
  /// In en, this message translates to:
  /// **'Remove Photo'**
  String get removePhotoLabel;

  /// No description provided for @resumeActivityTitle.
  ///
  /// In en, this message translates to:
  /// **'Resume Activity'**
  String get resumeActivityTitle;

  /// No description provided for @resumeActivityMessage.
  ///
  /// In en, this message translates to:
  /// **'You have an unfinished run. Would you like to resume it?'**
  String get resumeActivityMessage;

  /// No description provided for @discardButton.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get discardButton;

  /// No description provided for @resumeButton.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get resumeButton;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
