// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'ترايد';

  @override
  String get loginTitle => 'أدخل عنوان بريدك الإلكتروني للبدء.';

  @override
  String get loginSubtitle => 'سجل الدخول أو انضم للوصول إلى ذروة أدائك اليوم';

  @override
  String get emailPlaceholder => 'example@mail.com';

  @override
  String get continueButton => 'استمرار';

  @override
  String get emailLabel => 'بريد إلكتروني';

  @override
  String get checking => 'جاري التحقق...';

  @override
  String get sendingOtp => 'جاري إرسال رمز التحقق...';

  @override
  String get verifyTitle => 'أدخل رمز التحقق لتسجيل الدخول';

  @override
  String verifySubtitle(String email) {
    return 'لقد أرسلنا رمز التحقق إلى $email';
  }

  @override
  String get verifyButton => 'تحقق من الرمز';

  @override
  String get verifying => 'جاري التحقق...';

  @override
  String get resendText => 'إذا لم تستلم الرمز!';

  @override
  String get resendButton => 'إعادة إرسال';

  @override
  String get sending => 'جاري الإرسال...';

  @override
  String get signupTitle => 'أكمل ملفك الشخصي';

  @override
  String get fullNameLabel => 'الاسم الكامل';

  @override
  String get fullNamePlaceholder => 'أدخل الاسم الكامل';

  @override
  String get phoneNumberLabel => 'رقم الهاتف';

  @override
  String get phoneNumberPlaceholder => '1234 5678';

  @override
  String get verificationCodeLabel => 'رمز التحقق';

  @override
  String get codeSentTo => 'تم إرسال الرمز إلى ';

  @override
  String get didntReceiveCode => 'لم تستلم الرمز؟ ';

  @override
  String get resendCode => 'إعادة إرسال الرمز';

  @override
  String get changeEmail => 'تغيير البريد الإلكتروني';

  @override
  String get completeSignup => 'إتمام التسجيل';

  @override
  String get signingUp => 'جاري التسجيل...';

  @override
  String get enterCompleteOtp => 'يرجى إدخال الرمز بالكامل';

  @override
  String get invalidPhone => 'يرجى إدخال رقم هاتف صحيح';

  @override
  String get signupFailed => 'فشل التحقق أو التسجيل. يرجى المحاولة مرة أخرى.';

  @override
  String get otpResentSuccess => 'تمت إعادة إرسال الرمز';

  @override
  String get otpResentSubtitle =>
      'تم إرسال رمز تحقق جديد إلى بريدك الإلكتروني.';

  @override
  String get otpResentFailed => 'فشل إعادة إرسال الرمز';

  @override
  String get verificationFailed => 'فشل التحقق. تحقق من الرمز.';

  @override
  String get invalidEmail => 'يرجى إدخال عنوان بريد إلكتروني صحيح';

  @override
  String get somethingWentWrong => 'حدث خطأ ما. يرجى المحاولة مرة أخرى.';

  @override
  String get loginLabel => 'تسجيل الدخول';

  @override
  String get helloGreeting => 'مرحباً!';

  @override
  String get availablePointsLabel => 'نقاطك المتاحة';

  @override
  String get currentMonthLabel => 'الشهر الحالي';

  @override
  String get stepsCountLabel => 'عدد الخطوات';

  @override
  String get durationsLabel => 'المدة';

  @override
  String get minsSuffix => 'دقيقة';

  @override
  String get burnedCaloriesLabel => 'السعرات المحروقة';

  @override
  String get averageBpmLabel => 'متوسط نبض القلب';

  @override
  String get activityLoadError => 'تعذر تحميل تفاصيل النشاط';

  @override
  String get kmSuffix => 'كم';

  @override
  String get logoutLabel => 'تسجيل الخروج';

  @override
  String get notificationsTitle => 'الإشعارات';

  @override
  String get noNotifications => 'لا توجد إشعارات بعد';

  @override
  String get markAllAsRead => 'تمييز الكل كمقروء';

  @override
  String get justNow => 'الآن';

  @override
  String minutesAgo(String minutes) {
    return 'منذ $minutes د';
  }

  @override
  String hoursAgo(String hours) {
    return 'منذ $hours س';
  }

  @override
  String daysAgo(String days) {
    return 'منذ $days ي';
  }

  @override
  String get profileTitle => 'الملف الشخصي';

  @override
  String get myRewards => 'مكافآتي';

  @override
  String get activityLabel => 'النشاط';

  @override
  String get myWorkouts => 'تماريني';

  @override
  String get settingsLabel => 'الإعدادات';

  @override
  String get editNameTitle => 'تعديل الاسم';

  @override
  String get profileUpdated => 'تم تحديث الملف الشخصي!';

  @override
  String get profilePicChanged => 'تم تغيير صورة ملفك الشخصي بنجاح.';

  @override
  String get nameUpdated => 'تم تحديث الاسم!';

  @override
  String nameChangedSuccess(String name) {
    return 'تم تغيير الاسم المعروض إلى $name.';
  }

  @override
  String failedToUpdateName(String error) {
    return 'فشل تحديث الاسم: $error';
  }

  @override
  String failedToUploadImage(String error) {
    return 'فشل تحميل الصورة: $error';
  }

  @override
  String get cancelButton => 'إلغاء';

  @override
  String get saveButton => 'حفظ';

  @override
  String get retryButton => 'إعادة المحاولة';

  @override
  String get loadProfileError => 'حدث خطأ ما';

  @override
  String get freePlan => 'خطة مجانية';

  @override
  String get freePlanSubtitle => 'تتبع أساسي ووصول للمجتمع';

  @override
  String get settingsTitle => 'الإعدادات';

  @override
  String get notificationsSection => 'الإشعارات';

  @override
  String get pushNotifications => 'إشعارات الهاتف';

  @override
  String get inAppNotifications => 'إشعارات التطبيق';

  @override
  String get aboutSection => 'حول التطبيق';

  @override
  String get appVersionLabel => 'إصدار التطبيق';

  @override
  String get logoutButton => 'تسجيل الخروج';

  @override
  String get passwordChanged => 'تم تغيير كلمة المرور';

  @override
  String get passwordUpdatedSuccess => 'تم تحديث كلمة المرور بنجاح.';

  @override
  String get failedToUpdatePreference => 'فشل تحديث التفضل';

  @override
  String get deleteAccountTitle => 'حذف الحساب؟';

  @override
  String get deleteAccountWarning =>
      'هذا الإجراء دائم ولا يمكن التراجع عنه. ستفقد جميع بياناتك.';

  @override
  String get deleteAccountButton => 'حذف الحساب';

  @override
  String get changePasswordTitle => 'تغيير كلمة المرور';

  @override
  String get currentPasswordLabel => 'كلمة المرور الحالية';

  @override
  String get newPasswordLabel => 'كلمة المرور الجديدة';

  @override
  String get confirmPasswordLabel => 'تأكيد كلمة المرور';

  @override
  String get passwordsDoNotMatch => 'كلمات المرور غير متطابقة';

  @override
  String get passwordLengthError => 'يجب أن تكون كلمة المرور 6 أحرف على الأقل';

  @override
  String get startRun => 'ابدأ';

  @override
  String get distanceLabel => 'المسافة';

  @override
  String get durationLabel => 'المدة';

  @override
  String get caloriesLabel => 'السعرات';

  @override
  String get currentPaceLabel => 'السرعة الحالية';

  @override
  String get avgPaceLabel => 'متوسط السرعة';

  @override
  String get heartRateLabel => 'نبض القلب';

  @override
  String get endRunTitle => 'إنهاء الجري؟';

  @override
  String get endRunMessage => 'احفظ الأداء واخرج، أو أكمل الجري؟';

  @override
  String get saveAndExit => 'حفظ وخروج';

  @override
  String get keepRunning => 'إكمال الجري';

  @override
  String get healthConnectTitle => 'يتطلب Health Connect';

  @override
  String get healthUpdateTitle => 'تحديث مطلوب';

  @override
  String get healthPermissionTitle => 'الأذونات مطلوبة';

  @override
  String get healthPermissionMessage =>
      'يحتاج Tryd إلى أذونات Health Connect لتتبع خطواتك والسعرات الحرارية ونبضات قلبك. يرجى تفعيل جميع الأذونات في إعدادات Health Connect.';

  @override
  String get healthConnectMessage =>
      'لتتبع حطواتك ونبضات قلبك بدقة، يجب تثبيت تطبيق Google Health Connect.';

  @override
  String get healthUpdateMessage =>
      'يتطلب تطبيق Google Health Connect تحديثاً لمزامنة بيانات التمرين بشكل صحيح.';

  @override
  String get installUpdate => 'تثبيت / تحديث';

  @override
  String get enablePermissions => 'تفعيل الأذونات';

  @override
  String get appleHealthTitle => 'الوصول للصحة في ابل';

  @override
  String get appleHealthMessage =>
      'يحتاج Tryd الوصول إلى Apple Health لتتبع خطواتك والمسافة ونبضات قلبك أثناء الجري.\n\nيرجى التوجه لـ:';

  @override
  String get appleHealthPath => 'الإعدادات ← الصحة ← الوصول للبيانات ← Tryd';

  @override
  String get appleHealthTurnOnMessage =>
      'قم بتفعيل جميع الخيارات للحصول على أفضل تجربة.';

  @override
  String get openSettings => 'فتح الإعدادات';

  @override
  String get go => 'انطلق';

  @override
  String get runCompleteAmazing => 'اكتمل الجري، أداء مذهل';

  @override
  String get runCompleteGreat => 'اكتمل الجري، عمل رائع';

  @override
  String get runCompleteWellDone => 'اكتمل الجري، أحسنت';

  @override
  String get paused => 'مؤقت';

  @override
  String get letsGo => 'هيا بنا';

  @override
  String get shareButton => 'مشاركة';

  @override
  String get stopButton => 'توقف';

  @override
  String get later => 'لاحقاً';

  @override
  String get workoutsTitle => 'التمارين';

  @override
  String get workLabel => 'عمل';

  @override
  String get restLabel => 'راحة';

  @override
  String get exercisesLabel => 'تمارين';

  @override
  String get roundsLabel => 'جولات';

  @override
  String get repsLabel => 'تكرار';

  @override
  String exerciseProgress(String current, String total) {
    return 'تمرين $current من $total';
  }

  @override
  String roundProgress(String current, String total) {
    return 'الجولة $current من $total';
  }

  @override
  String get holdToPause => 'اضغط مطولاً للإيقاف';

  @override
  String get holdToResume => 'اضغط مطولاً للاستئناف';

  @override
  String get resetWorkout => 'إعادة ضبط التمرين';

  @override
  String get endWorkoutTitle => 'إنهاء التمرين؟';

  @override
  String get endWorkoutMessage => 'هل تريد إنهاء هذا التمرين؟';

  @override
  String get endButton => 'إنهاء';

  @override
  String get workoutComplete => 'اكتمل التمرين!';

  @override
  String get workoutCompleteMessage =>
      'عمل رائع! أكملت جميع التمارين والجولات.';

  @override
  String get doneButton => 'تم';

  @override
  String get skipRest => 'تخطي الراحة';

  @override
  String get unitKm => 'كم';

  @override
  String get unitMinKm => 'د/كم';

  @override
  String get unitBpm => 'ن/د';

  @override
  String get historyTitle => 'السجل';

  @override
  String get noWorkoutsYet => 'لا تمارين بعد';

  @override
  String get todayLabel => 'اليوم';

  @override
  String get yesterdayLabel => 'أمس';

  @override
  String get exLabel => 'تمرين';

  @override
  String get challengesTitle => 'التحديات';

  @override
  String get challengesSubtitle =>
      'انضم للتحديات ونقاط مفاجئة تنتظرك عند الإنهاء.';

  @override
  String get myChallengesTab => 'تحدياتي';

  @override
  String get joinAChallengeTab => 'انضم لتحدٍّ';

  @override
  String get noActiveChallenges => 'لا تحديات نشطة.';

  @override
  String get previousChallenges => 'التحديات السابقة';

  @override
  String get noAvailableChallenges => 'لا تحديات متاحة للانضمام.';

  @override
  String get activeChallengesBadge => 'تحدٍّ نشط';

  @override
  String get upcomingChallengeBadge => 'تحدٍّ قادم';

  @override
  String get challengeEndedBadge => 'التحدي انتهى';

  @override
  String get kmLabel => 'كم';

  @override
  String get myChallengeTitle => 'تحديّي';

  @override
  String get unlockRewards => 'افتح المكافآت';

  @override
  String get totalDistance => 'المسافة الكلية';

  @override
  String get participantsLabel => 'المشاركون';

  @override
  String get leaderboardTitle => 'لوحة المتصدرين';

  @override
  String get goToChallenge => 'اذهب للتحدي';

  @override
  String get challengeEndedButton => 'التحدي انتهى';

  @override
  String get joinChallenge => 'انضم للتحدي';

  @override
  String get challengeJoinedTitle => 'انضممت للتحدي!';

  @override
  String get errorLoadingChallenge => 'خطأ في تحميل التحدي';

  @override
  String get challengeDetailTitle => 'تفاصيل التحدي';

  @override
  String get rankHeaderLabel => 'المركز';

  @override
  String get userHeaderLabel => 'المستخدم';

  @override
  String get distanceHeaderLabel => 'المسافة';

  @override
  String get yourRankLabel => 'مركزك';

  @override
  String get topPerformersLabel => 'تصنيف الأفضل';

  @override
  String get yourPositionLabel => 'موضعك';

  @override
  String get activityTitle => 'النشاط';

  @override
  String get thisWeek => 'هذا الأسبوع';

  @override
  String get thisMonth => 'هذا الشهر';

  @override
  String get thisYear => 'هذه السنة';

  @override
  String get allActivitiesLabel => 'كل الأنشطة';

  @override
  String get kilometersLabel => 'كيلومترات';

  @override
  String get countLabel => 'العدد';

  @override
  String get timeLabel => 'الوقت';

  @override
  String get avgPaceShort => 'متوسط السرعة';

  @override
  String get avgSpeedShort => 'متوسط السرعة';

  @override
  String get runningLabel => 'الجري';

  @override
  String get walkingLabel => 'المشي';

  @override
  String get cyclingLabel => 'ركوب الدراجة';

  @override
  String get recentActivities => 'الأنشطة الأخيرة';

  @override
  String get noRecentActivities => 'لا توجد أنشطة حديثة';

  @override
  String get filterWeekLabel => 'أ';

  @override
  String get filterMonthLabel => 'ش';

  @override
  String get filterYearLabel => 'س';

  @override
  String get filterAllLabel => 'الكل';

  @override
  String get rewardsTitle => 'المكافآت';

  @override
  String get availableRewardsTab => 'المكافآت المتاحة';

  @override
  String get myRedemptionsTab => 'استرداداتي';

  @override
  String get categoryAll => 'الكل';

  @override
  String get categoryCoffee => 'قهوة';

  @override
  String get categoryShop => 'تسوق';

  @override
  String get categoryFood => 'طعام';

  @override
  String get categoryGym => 'جيم';

  @override
  String get categoryBooks => 'كتب';

  @override
  String get noRewardsAvailable => 'لا مكافآت متاحة';

  @override
  String get noRedemptionsYet => 'لا استردادات بعد';

  @override
  String get manualApprovalBadge => 'موافقة يدوية';

  @override
  String get claimedLabel => 'تم الاستلام';

  @override
  String get pendingLabel => 'قيد الانتظار';

  @override
  String get redeemButton => 'استرداد';

  @override
  String get pointsLabel => 'نقطة';

  @override
  String get ptsSuffix => 'نقطة';

  @override
  String requestedOnDate(String date) {
    return 'طُلب في $date';
  }

  @override
  String redeemedOnDate(String date) {
    return 'تم الاسترداد في $date';
  }

  @override
  String get refundedLabel => 'مُسترد';

  @override
  String rejectedWithNote(String note) {
    return 'مرفوض: $note';
  }

  @override
  String get requestRejectedDefault =>
      'تم رفض طلبك. تمت إعادة النقاط إلى حسابك.';

  @override
  String get requestPendingMessage =>
      'طلبك قيد المراجعة. سيتم إخطارك عند الموافقة.';

  @override
  String get yourCouponCode => 'كود القسيمة';

  @override
  String get copyButton => 'نسخ';

  @override
  String get confirmRedemptionTitle => 'تأكيد الاسترداد';

  @override
  String get pointsRequired => 'النقاط المطلوبة';

  @override
  String get currentBalance => 'الرصيد الحالي';

  @override
  String get afterRedemption => 'بعد الاسترداد';

  @override
  String get confirmRedeemButton => 'تأكيد الاسترداد';

  @override
  String get codeCopiedTitle => 'تم نسخ الكود!';

  @override
  String get codeCopiedMessage => 'تم نسخ رمز القسيمة إلى الحافظة.';

  @override
  String get rewardRedeemedTitle => 'تم استرداد المكافأة!';

  @override
  String rewardRedeemedMessage(String title) {
    return 'تمت إضافة $title إلى استرداداتك.';
  }

  @override
  String get chooseFromGallery => 'اختر من المعرض';

  @override
  String get takeAPhoto => 'التقط صورة';

  @override
  String get uploadImage => 'رفع صورة';

  @override
  String get changePicture => 'تغيير الصورة';

  @override
  String get totalTimeLabel => 'الوقت الكلي';

  @override
  String get distanceShort => 'المسافة';

  @override
  String get startHeadline => 'كل خطوة تقربك من أهدافك ومكافآت أكبر.';

  @override
  String get startSubtitle =>
      'هذه الأداة المنتجة مصممة لمساعدتك على إدارة مهامك بشكل أفضل!';

  @override
  String get getStarted => 'ابدأ الآن';

  @override
  String get navHome => 'الرئيسية';

  @override
  String get navRun => 'جري';

  @override
  String get navWorkout => 'تمرين';

  @override
  String get navClub => 'نادي';

  @override
  String get removePhotoLabel => 'إزالة الصورة';

  @override
  String get resumeActivityTitle => 'استئناف النشاط';

  @override
  String get resumeActivityMessage =>
      'لديك جري غير مكتمل. هل ترغب في استئنافه؟';

  @override
  String get discardButton => 'تجاهل';

  @override
  String get resumeButton => 'استئناف';

  @override
  String get locationPermissionTitle => 'السماح بالوصول إلى الموقع';

  @override
  String get locationPermissionMessage =>
      'يحتاج تطبيق تراي إلى موقعك لتتبع مسارك ومسافتك وإيقاعك خلال الركض.';

  @override
  String get locationDeniedTitle => 'الوصول إلى الموقع مطلوب';

  @override
  String get locationDeniedMessage =>
      'قم بتفعيل الموقع في الإعدادات لتتبع ركضك بدقة.';

  @override
  String get allowLocation => 'السماح بالموقع';

  @override
  String get locationServiceDisabledTitle => 'خدمة الموقع معطّلة';

  @override
  String get locationServiceDisabledMessage =>
      'خدمة الموقع في جهازك معطّلة. يرجى تفعيلها لبدء الجري.';

  @override
  String get enableLocation => 'تفعيل الموقع';

  @override
  String get audioPermissionTitle => 'السماح بالوصول إلى الموسيقى';

  @override
  String get audioPermissionMessage =>
      'يحتاج تطبيق تراي إلى الوصول إلى مكتبة موسيقاك لتشغيل الأغاني أثناء التمرين.';

  @override
  String get allowAudio => 'السماح بالوصول إلى الموسيقى';

  @override
  String get newRunButton => 'جري جديد';

  @override
  String get totalWorkoutTime => 'إجمالي وقت التمرين';

  @override
  String get preBuiltWorkoutsTitle => 'تمارين معدة مسبقًا';

  @override
  String get referralCodeLabel => 'رمز الإحالة';

  @override
  String get referralCodeOptional => 'اختياري';

  @override
  String get referralCodePlaceholder => 'أدخل الرمز';

  @override
  String get referralVerifyButton => 'تحقق';

  @override
  String get referralCodeInvalid => 'رمز إحالة غير صالح';

  @override
  String referralCodeVerified(String name) {
    return 'محال من $name';
  }

  @override
  String shareEarnTitle(int points) {
    return 'ادعُ واكسب $points نقاط';
  }

  @override
  String shareEarnSubtitle(int points) {
    return 'شارك رمزك وستكسبان معاً $points نقاط';
  }

  @override
  String shareForPointsBanner(int points) {
    return 'شارك واكسب $points نقاط!';
  }

  @override
  String get shareForPointsSubtitle =>
      'شارك نشاطك على وسائل التواصل واحصل على مكافأة';

  @override
  String sharePointsEarned(int points) {
    return 'حصلت على $points نقاط مقابل مشاركتك!';
  }

  @override
  String get shareAlreadyRewarded => 'تمت المكافأة مسبقاً';

  @override
  String get sharePlatformInstagram => 'إنستغرام';

  @override
  String get sharePlatformWhatsApp => 'واتساب';

  @override
  String get sharePlatformSnapchat => 'سناب شات';

  @override
  String get sharePlatformFacebook => 'فيسبوك';

  @override
  String shareGenZCta(int points) {
    return 'شارك واكسب $points نقطة 🔥';
  }

  @override
  String get shareGenZSubtitle => 'انشر ركضك، راكم نقاطك';

  @override
  String get shareGenZAlreadyClaimed => 'حصلت على نقاطك لهذا المنشور ✅';

  @override
  String get secUnit => 'sec';

  @override
  String get minUnit => 'min';

  @override
  String get minsUnit => 'mins';

  @override
  String get minutesShort => 'MIN';

  @override
  String get secondsShort => 'SEC';

  @override
  String get exerciseTimer => 'مؤقت التمرين';

  @override
  String get workSlash => 'عمل';

  @override
  String get restWord => 'راحة';

  @override
  String get totalTimeColon => 'الوقت الكلي:';

  @override
  String get exercisesPlusRest => 'تمارين + راحة';

  @override
  String get letsGoFire => 'هيا!';

  @override
  String totalWithTime(String time) {
    return 'المجموع: $time (تمارين + راحة)';
  }
}
