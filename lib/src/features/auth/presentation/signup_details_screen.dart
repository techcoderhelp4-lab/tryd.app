import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dio/dio.dart';
import '../../../../widgets/gradient_button.dart';
import '../data/auth_repository.dart';
import '../../../../widgets/custom_arrow_icon.dart';
import 'dart:async';
import 'package:flutter/services.dart';
import 'onboarding_rewards_screen.dart';
import '../../../../core/utils/snackbar_utils.dart';
import 'package:tryd/src/features/auth/presentation/controllers/auth_controller.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:tryd/src/generated/l10n/app_localizations.dart';
import 'package:intl_phone_field/country_picker_dialog.dart';

class SignupDetailsScreen extends ConsumerStatefulWidget {
  final String email;

  const SignupDetailsScreen({
    super.key,
    required this.email,
  });

  @override
  ConsumerState<SignupDetailsScreen> createState() => _SignupDetailsScreenState();
}

class _SignupDetailsScreenState extends ConsumerState<SignupDetailsScreen> {
  static const Color _primaryTextColor = Color(0xFF000000);
  static const Color _labelColor = Color(0xFF8B88B5);
  static const Color _inputTextColor = Color(0xFF221F48);
  static const Color _inputBgColor = Color(0xFFFFFFFF);
  static const Color _linkColor = Color(0xFFF83A71);

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _nameFocusNode = FocusNode();
  final _phoneFocusNode = FocusNode();

  bool _isSigningUp = false;
  bool _isResending = false;
  String _completePhoneNumber = '';

  // Referral code
  final _referralController = TextEditingController();
  final _referralFocusNode = FocusNode();
  // 'none' | 'verifying' | 'valid' | 'invalid'
  String _referralStatus = 'none';
  String? _referrerName;
  String? _verifiedReferralCode;

  final List<TextEditingController> _otpControllers = List.generate(
    4,
    (index) => TextEditingController(),
  );

  final List<FocusNode> _otpFocusNodes = List.generate(
    4,
    (index) => FocusNode(),
  );

  static const int _timerDuration = 60;
  int _timerRemaining = _timerDuration;
  bool _canResend = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();

    // Handle backspace on empty fields (onChanged doesn't fire for empty fields)
    for (int i = 1; i < 4; i++) {
      final index = i;
      _otpFocusNodes[index].onKeyEvent = (node, event) {
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.backspace &&
            _otpControllers[index].text.isEmpty) {
          _otpControllers[index - 1].clear();
          _otpFocusNodes[index - 1].requestFocus();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      };
    }
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() {
      _timerRemaining = _timerDuration;
      _canResend = false;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timerRemaining > 0) {
        if (mounted) setState(() => _timerRemaining--);
      } else {
        if (mounted) setState(() => _canResend = true);
        timer.cancel();
      }
    });
  }

  Future<void> _handleResend() async {
    if (!_canResend || _isResending) return;

    setState(() => _isResending = true);
    try {
      await ref.read(authRepositoryProvider).sendOtp(widget.email);
      if (mounted) {
        // Clear OTP fields first
        for (var controller in _otpControllers) {
          controller.clear();
        }
        // Restart timer
        _startTimer();
        // Focus first OTP field
        _otpFocusNodes[0].requestFocus();
        CustomSnackBar.show(context, message: AppLocalizations.of(context)!.resendCode, isError: false);
      }
    } catch (e) {
      if (mounted) {
        CustomSnackBar.show(context, message: 'Failed to resend OTP');
      }
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  String _getOtpCode() {
    return _otpControllers.map((controller) => controller.text).join();
  }

  void _onOtpDigitChanged(String value, int index) {
    if (value.length > 1) {
      String digits = value.replaceAll(RegExp(r'\D'), '');
      if (digits.isEmpty) {
        _otpControllers[index].clear();
        return;
      }

      // Paste handling
      for (int i = 0; i < digits.length && (index + i) < 4; i++) {
        _otpControllers[index + i].text = digits[i];
      }
      
      // Move focus to the correct position
      int lastFilledIndex = index + digits.length - 1;
      if (lastFilledIndex >= 3) {
        _otpFocusNodes[3].unfocus();
      } else {
        _otpFocusNodes[lastFilledIndex + 1].requestFocus();
      }
      return;
    }

    if (value.isNotEmpty) {
      if (index < 3) {
        _otpFocusNodes[index + 1].requestFocus();
      } else {
        _otpFocusNodes[index].unfocus();
      }
    }
  }

  Future<void> _handleVerifyReferralCode() async {
    final code = _referralController.text.trim();
    if (code.isEmpty) return;
    setState(() => _referralStatus = 'verifying');
    try {
      final result = await ref.read(authRepositoryProvider).verifyReferralCode(code);
      if (!mounted) return;
      if (result['valid'] == true) {
        setState(() {
          _referralStatus = 'valid';
          _referrerName = result['referrerName'] as String?;
          _verifiedReferralCode = code.toUpperCase();
        });
      } else {
        setState(() {
          _referralStatus = 'invalid';
          _verifiedReferralCode = null;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _referralStatus = 'invalid';
          _verifiedReferralCode = null;
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _nameFocusNode.dispose();
    _phoneFocusNode.dispose();
    _referralController.dispose();
    _referralFocusNode.dispose();
    _timer?.cancel();
    for (var c in _otpControllers) {
      c.dispose();
    }
    for (var f in _otpFocusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  Future<void> _handleSignup() async {
    final otp = _getOtpCode();
    if (otp.length < 4) {
      CustomSnackBar.show(context, message: AppLocalizations.of(context)!.enterCompleteOtp);
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    final phoneNumber = _phoneController.text.trim();
    final digitsOnly = phoneNumber.replaceAll(RegExp(r'\D'), '');
    if (digitsOnly.length < 8) {
      CustomSnackBar.show(context, message: AppLocalizations.of(context)!.invalidPhone);
      return;
    }

    if (_isSigningUp) return;
    setState(() => _isSigningUp = true);

    try {
      // Auto-verify referral code if typed but not yet verified
      final typedCode = _referralController.text.trim();
      if (typedCode.isNotEmpty && _verifiedReferralCode == null) {
        try {
          final result = await ref.read(authRepositoryProvider).verifyReferralCode(typedCode);
          if (mounted && result['valid'] == true) {
            _verifiedReferralCode = typedCode.toUpperCase();
            setState(() => _referralStatus = 'valid');
          }
        } catch (_) {
          // Ignore — invalid code just won't be sent
        }
      }

      final authController = ref.read(authControllerProvider.notifier);

      await authController.verifyOtp(widget.email, otp);

      var authState = ref.read(authControllerProvider);
      if (authState.hasError) throw authState.error!;

      final authResponse = await authController.register(
        name: _nameController.text,
        email: widget.email,
        password: 'TRYD@123',
        phoneNumber: _completePhoneNumber,
        referralCode: _verifiedReferralCode,
      );

      authState = ref.read(authControllerProvider);
      if (authState.hasError) throw authState.error!;

      if (mounted) {
        final downloadPts = authResponse?.grantedDownloadRewardPoints ?? 200;
        final referralPts = authResponse?.grantedReferralBonusPoints ?? 0;
        final points = downloadPts + referralPts;
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => OnboardingRewardsScreen(
              userName: _nameController.text,
              points: points,
              referralPoints: referralPts,
            ),
          ),
          (route) => false,
        );
      }
    } catch (e) {
      debugPrint('Signup error: $e');
      if (mounted) {
        String errorMessage = AppLocalizations.of(context)!.signupFailed;
        if (e is DioException) {
          errorMessage = e.response?.data['message'] ?? e.message ?? 'Network error occurred';
        } else {
          errorMessage = e.toString();
        }
        CustomSnackBar.show(context, message: errorMessage);
      }
    } finally {
      if (mounted) setState(() => _isSigningUp = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final screenWidth = size.width;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final screenHeight = size.height + bottomInset;
    final isTablet = screenWidth > 600;

    const double smallScale = 0.70;
    const double mediumScale = 0.78;
    const double largeScale = 0.84;
    const double tabletScale = 1.10;

    final double scale = isTablet
        ? tabletScale
        : screenHeight < 680
            ? smallScale
            : screenHeight < 850
                ? mediumScale
                : largeScale;
    final l10n = AppLocalizations.of(context)!;
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final fontScale = isAr ? 1.2 : 1.0;

    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/bg-gradient.png',
              fit: BoxFit.cover,
            ),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 450),
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 24.0 * scale),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(height: 24.0 * scale),
                                _buildLogo(scale),
                                SizedBox(height: 16.0 * scale),
                                _buildTitle(scale, l10n, fontScale),
                                SizedBox(height: 32.0 * scale),
                                Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 14.0 * scale),
                                  child: _buildInputField(
                                    label: l10n.fullNameLabel,
                                    placeholder: l10n.fullNamePlaceholder,
                                    controller: _nameController,
                                    focusNode: _nameFocusNode,
                                    scale: scale,
                                    fontScale: fontScale,
                                  ),
                                ),
                                SizedBox(height: 18.0 * scale),
                                Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 14.0 * scale),
                                  child: _buildPhoneField(scale, l10n, fontScale),
                                ),
                                SizedBox(height: 18.0 * scale),
                                Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 14.0 * scale),
                                  child: _buildReferralField(scale, fontScale),
                                ),
                                SizedBox(height: 38.0 * scale),
                                _buildOtpField(scale, l10n, fontScale),
                                SizedBox(height: 16.0 * scale),
                                _buildResendSection(scale, l10n, fontScale),
                                SizedBox(height: 44.0 * scale),
                                GradientButton(
                                  text: _isSigningUp ? l10n.signingUp : l10n.completeSignup,
                                  onPressed: _isSigningUp ? () {} : _handleSignup,
                                  height: 66.0 * scale,
                                  textStyle: GoogleFonts.lexendDeca(
                                    fontSize: 21.0 * scale * fontScale,
                                    fontWeight: FontWeight.w600,
                                    height: 1.26,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(height: bottomInset > 0 ? bottomInset * 0.3 : 40.0 * scale),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          PositionedDirectional(
            top: 20,
            start: 20,
            child: SafeArea(
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                behavior: HitTestBehavior.opaque,
                child: SizedBox(
                  width: 42.0 * scale,
                  height: 42.0 * scale,
                  child: CustomArrowIcon(
                    size: 42.0 * scale,
                    color: const Color(0xFF130F26),
                  ),
                ),
              ),
            ),
          ),
          if (defaultTargetPlatform == TargetPlatform.iOS && bottomInset > 0)
            Positioned(
              bottom: bottomInset,
              left: 0,
              right: 0,
              child: Container(
                color: const Color(0xFFD2D5DB),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    GestureDetector(
                      onTap: () => FocusScope.of(context).unfocus(),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Text(
                          'Done',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF007AFF),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLogo(double scale) {
    return Image.asset(
      'assets/images/logo-full.png',
      width: 201.0 * scale,
      height: 80.0 * scale,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
      isAntiAlias: true,
    );
  }

  Widget _buildTitle(double scale, AppLocalizations l10n, double fontScale) {
    return Text(
      l10n.signupTitle,
      textAlign: TextAlign.center,
      style: GoogleFonts.lexendDeca(
        fontSize: 22.0 * scale * fontScale,
        fontWeight: FontWeight.w700,
        height: 1.25,
        color: _primaryTextColor,
      ),
    );
  }

  Widget _buildOtpField(double scale, AppLocalizations l10n, double fontScale) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          l10n.verificationCodeLabel,
          style: GoogleFonts.lexendDeca(
            fontSize: 16.0 * scale * fontScale,
            fontWeight: FontWeight.w600,
            color: _primaryTextColor,
          ),
        ),
        SizedBox(height: 6.0 * scale),
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            children: [
              TextSpan(
                text: l10n.codeSentTo,
                style: GoogleFonts.poppins(
                  fontSize: 16.0 * scale * fontScale,
                  color: _labelColor,
                  fontWeight: FontWeight.w400,
                ),
              ),
              TextSpan(
                text: widget.email,
                style: GoogleFonts.poppins(
                  fontSize: 16.0 * scale * fontScale,
                  color: const Color(0xFF900EBF),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 20.0 * scale),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.0 * scale),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (int i = 0; i < 4; i++) ...[
                  Expanded(
                    child: AspectRatio(
                      aspectRatio: 1.0,
                      child: _buildOtpDigitBox(i, scale, fontScale),
                    ),
                  ),
                  if (i < 3) SizedBox(width: 10.0 * scale),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOtpDigitBox(int index, double scale, double fontScale) {
    return _OtpDigitBox(
      controller: _otpControllers[index],
      focusNode: _otpFocusNodes[index],
      scale: scale,
      fontScale: fontScale,
      isLast: index == 3,
      onChanged: (value) => _onOtpDigitChanged(value, index),
    );
  }

  Widget _buildResendSection(double scale, AppLocalizations l10n, double fontScale) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 6.0 * scale),
      child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  l10n.didntReceiveCode,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 15.0 * scale * fontScale,
                    fontWeight: FontWeight.w400,
                    color: _labelColor,
                  ),
                ),
              ),
              if (_canResend)
                GestureDetector(
                  onTap: _isResending ? null : _handleResend,
                  child: Text(
                    _isResending ? l10n.sending : l10n.resendCode,
                    style: GoogleFonts.poppins(
                      fontSize: 15.0 * scale * fontScale,
                      fontWeight: FontWeight.w600,
                      color: _isResending ? _labelColor : _linkColor,
                    ),
                  ),
                )
              else
                Text(
                  '0:${_timerRemaining.toString().padLeft(2, '0')}',
                  style: GoogleFonts.poppins(
                    fontSize: 15.0 * scale * fontScale,
                    fontWeight: FontWeight.w500,
                    color: _labelColor,
                  ),
                ),
            ],
          ),
        ),
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Text(
            l10n.changeEmail,
            style: GoogleFonts.poppins(
              fontSize: 14.0 * scale * fontScale,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF900EBF),
            ),
          ),
        ),
      ],
      ),
    );
  }

  Widget _buildPhoneField(double scale, AppLocalizations l10n, double fontScale) {
    return ListenableBuilder(
      listenable: _phoneFocusNode,
      builder: (context, child) {
        final isFocused = _phoneFocusNode.hasFocus;
        return Container(
          decoration: BoxDecoration(
            color: _inputBgColor,
            borderRadius: BorderRadius.circular(17),
            border: Border.all(
              color: isFocused ? Colors.black.withValues(alpha: 0.1) : Colors.transparent,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                offset: const Offset(0, 4),
                blurRadius: 10,
                spreadRadius: 0,
                color: const Color(0xFF000000).withValues(alpha: 0.05),
              ),
            ],
          ),
          child: child,
        );
      },
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 0, vertical: 12.0 * scale),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.0 * scale),
                child: Text(
                  l10n.phoneNumberLabel,
                  style: GoogleFonts.lexendDeca(
                    fontSize: 14.0 * scale * fontScale,
                    fontWeight: FontWeight.w500,
                    height: 1.25,
                    color: _labelColor,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
              SizedBox(height: 4.0 * scale),
              IntlPhoneField(
                controller: _phoneController,
                focusNode: _phoneFocusNode,
                textAlign: TextAlign.left,
                decoration: InputDecoration(
                  hintText: l10n.phoneNumberPlaceholder,
                  hintStyle: GoogleFonts.poppins(
                    fontSize: 22.0 * scale * fontScale,
                    fontWeight: FontWeight.w400,
                    color: _labelColor.withValues(alpha: 0.5),
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  focusedErrorBorder: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(horizontal: 24.0 * scale, vertical: 6.0 * scale),
                  counterText: '',
                  errorStyle: const TextStyle(fontSize: 0, height: 0),
                ),
                style: GoogleFonts.poppins(
                  fontSize: 20.0 * scale * fontScale,
                  fontWeight: FontWeight.w500,
                  color: _inputTextColor,
                ),
                initialCountryCode: 'KW',
                disableLengthCheck: true,
                autovalidateMode: AutovalidateMode.disabled,
                onChanged: (phone) {
                  _completePhoneNumber = phone.completeNumber;
                },
                pickerDialogStyle: PickerDialogStyle(
                  backgroundColor: Colors.white,
                  countryCodeStyle: GoogleFonts.poppins(fontSize: 14 * scale),
                  countryNameStyle: GoogleFonts.poppins(fontSize: 14 * scale),
                  searchFieldPadding: EdgeInsets.all(16 * scale),
                ),
                dropdownTextStyle: GoogleFonts.poppins(
                  fontSize: 20.0 * scale,
                  fontWeight: FontWeight.w500,
                  color: _inputTextColor,
                ),
                showCountryFlag: true,
                dropdownIconPosition: IconPosition.trailing,
                dropdownIcon: Icon(Icons.arrow_drop_down, color: _labelColor, size: 20 * scale),
                flagsButtonPadding: EdgeInsets.only(left: 24.0 * scale),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReferralField(double scale, double fontScale) {
    final isValid = _referralStatus == 'valid';
    final isInvalid = _referralStatus == 'invalid';
    final isVerifying = _referralStatus == 'verifying';

    Color borderColor = Colors.transparent;
    if (isValid) borderColor = const Color(0xFF22C55E);
    if (isInvalid) borderColor = const Color(0xFFF83A71);

    return ListenableBuilder(
      listenable: _referralFocusNode,
      builder: (context, _) {
        final isFocused = _referralFocusNode.hasFocus;
        if (isFocused && borderColor == Colors.transparent) {
          borderColor = Colors.black.withValues(alpha: 0.1);
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(
                color: _inputBgColor,
                borderRadius: BorderRadius.circular(17),
                border: Border.all(color: borderColor, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    offset: const Offset(0, 4),
                    blurRadius: 10,
                    spreadRadius: 0,
                    color: const Color(0xFF000000).withValues(alpha: 0.05),
                  ),
                ],
              ),
              child: Directionality(
                textDirection: TextDirection.ltr,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24.0 * scale, vertical: 14.0 * scale),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Referral Code',
                            style: GoogleFonts.lexendDeca(
                              fontSize: 14.0 * scale * fontScale,
                              fontWeight: FontWeight.w500,
                              color: _labelColor,
                            ),
                          ),
                          SizedBox(width: 6 * scale),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 6 * scale, vertical: 2 * scale),
                            decoration: BoxDecoration(
                              color: _labelColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Optional',
                              style: GoogleFonts.lexendDeca(
                                fontSize: 11.0 * scale * fontScale,
                                fontWeight: FontWeight.w500,
                                color: _labelColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8.0 * scale),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _referralController,
                              focusNode: _referralFocusNode,
                              textCapitalization: TextCapitalization.characters,
                              style: GoogleFonts.poppins(
                                fontSize: 18.0 * scale * fontScale,
                                fontWeight: FontWeight.w500,
                                color: _inputTextColor,
                                letterSpacing: 1.5,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Enter code',
                                hintStyle: GoogleFonts.poppins(
                                  fontSize: 16.0 * scale * fontScale,
                                  fontWeight: FontWeight.w400,
                                  color: _labelColor.withValues(alpha: 0.5),
                                  letterSpacing: 0,
                                ),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                              onChanged: (_) {
                                // Keep _verifiedReferralCode applied until user
                                // explicitly re-verifies a new code
                                if (_referralStatus != 'none') {
                                  setState(() {
                                    _referralStatus = 'none';
                                    _referrerName = null;
                                  });
                                }
                              },
                            ),
                          ),
                          SizedBox(width: 8 * scale),
                          if (isValid)
                            const Icon(Icons.check_circle_rounded, color: Color(0xFF22C55E), size: 28)
                          else
                            GestureDetector(
                              onTap: isVerifying ? null : _handleVerifyReferralCode,
                              child: Container(
                                padding: EdgeInsets.symmetric(horizontal: 14 * scale, vertical: 8 * scale),
                                decoration: BoxDecoration(
                                  gradient: isVerifying
                                      ? null
                                      : const LinearGradient(
                                          colors: [Color(0xFF900EBF), Color(0xFFF83A71)],
                                          begin: Alignment.centerLeft,
                                          end: Alignment.centerRight,
                                        ),
                                  color: isVerifying ? _labelColor.withValues(alpha: 0.2) : null,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: isVerifying
                                    ? SizedBox(
                                        width: 16 * scale,
                                        height: 16 * scale,
                                        child: const CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                      )
                                    : Text(
                                        'Verify',
                                        style: GoogleFonts.lexendDeca(
                                          fontSize: 13.0 * scale * fontScale,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (isValid && _referrerName != null)
              Padding(
                padding: EdgeInsets.only(top: 6 * scale, left: 12 * scale),
                child: Text(
                  'Referred by $_referrerName',
                  style: GoogleFonts.poppins(
                    fontSize: 13.0 * scale * fontScale,
                    color: const Color(0xFF22C55E),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            if (!isValid && _verifiedReferralCode != null)
              Padding(
                padding: EdgeInsets.only(top: 6 * scale, left: 12 * scale),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle_rounded, color: const Color(0xFF22C55E), size: 14 * scale),
                    SizedBox(width: 4 * scale),
                    Text(
                      'Promo applied: $_verifiedReferralCode',
                      style: GoogleFonts.poppins(
                        fontSize: 13.0 * scale * fontScale,
                        color: const Color(0xFF22C55E),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            if (isInvalid)
              Padding(
                padding: EdgeInsets.only(top: 6 * scale, left: 12 * scale),
                child: Text(
                  'Invalid referral code',
                  style: GoogleFonts.poppins(
                    fontSize: 13.0 * scale * fontScale,
                    color: const Color(0xFFF83A71),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildInputField({
    required String label,
    required String placeholder,
    required TextEditingController controller,
    required FocusNode focusNode,
    required double scale,
    required double fontScale,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return ListenableBuilder(
      listenable: focusNode,
      builder: (context, child) {
        final isFocused = focusNode.hasFocus;
        return Container(
          decoration: BoxDecoration(
            color: _inputBgColor,
            borderRadius: BorderRadius.circular(17),
            border: Border.all(
              color: isFocused ? Colors.black.withValues(alpha: 0.1) : Colors.transparent,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                offset: const Offset(0, 4),
                blurRadius: 10,
                spreadRadius: 0,
                color: const Color(0xFF000000).withValues(alpha: 0.05),
              ),
            ],
          ),
          child: child,
        );
      },
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.0 * scale, vertical: 16.0 * scale),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: GoogleFonts.lexendDeca(
                  fontSize: 14.0 * scale * fontScale,
                  fontWeight: FontWeight.w500,
                  height: 1.25,
                  color: _labelColor,
                  letterSpacing: 0.2,
                ),
              ),
              SizedBox(height: 8.0 * scale),
              TextFormField(
                controller: controller,
                focusNode: focusNode,
                obscureText: obscureText,
                keyboardType: keyboardType,
                textAlign: TextAlign.left,
                textDirection: TextDirection.ltr,
                style: GoogleFonts.poppins(
                  fontSize: 18.0 * scale * fontScale,
                  fontWeight: FontWeight.w500,
                  color: _inputTextColor,
                  height: 1.4,
                ),
                decoration: InputDecoration(
                  hintText: placeholder,
                  hintStyle: GoogleFonts.poppins(
                    fontSize: 16.0 * scale * fontScale,
                    fontWeight: FontWeight.w400,
                    color: _labelColor.withValues(alpha: 0.5),
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OtpDigitBox extends StatefulWidget {
  const _OtpDigitBox({
    required this.controller,
    required this.focusNode,
    required this.scale,
    required this.fontScale,
    required this.isLast,
    required this.onChanged,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final double scale;
  final double fontScale;
  final bool isLast;
  final ValueChanged<String> onChanged;

  @override
  State<_OtpDigitBox> createState() => _OtpDigitBoxState();
}

class _OtpDigitBoxState extends State<_OtpDigitBox> {
  static const Color _labelColor = Color(0xFF8B88B5);
  static const Color _inputTextColor = Color(0xFF221F48);

  bool _isFocused = false;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _hasText = widget.controller.text.isNotEmpty;
    widget.focusNode.addListener(_onFocusChange);
    widget.controller.addListener(_onTextChange);
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_onFocusChange);
    widget.controller.removeListener(_onTextChange);
    super.dispose();
  }

  void _onFocusChange() {
    final focused = widget.focusNode.hasFocus;
    if (focused != _isFocused) setState(() => _isFocused = focused);
  }

  void _onTextChange() {
    final hasText = widget.controller.text.isNotEmpty;
    if (hasText != _hasText) setState(() => _hasText = hasText);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.0 * widget.scale),
        border: Border.all(
          color: _isFocused
              ? const Color(0xFF900EBF)
              : _hasText
                  ? const Color(0xFF221F48).withValues(alpha: 0.3)
                  : Colors.black.withValues(alpha: 0.08),
          width: _isFocused ? 2.0 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
            offset: const Offset(0, 2),
            blurRadius: 8,
            color: Colors.black.withValues(alpha: 0.06),
          ),
        ],
      ),
      child: TextField(
        controller: widget.controller,
        focusNode: widget.focusNode,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 4,
        textInputAction: widget.isLast ? TextInputAction.done : TextInputAction.next,
        style: GoogleFonts.poppins(
          fontSize: 24.0 * widget.scale * widget.fontScale,
          fontWeight: FontWeight.w700,
          color: _inputTextColor,
        ),
        decoration: InputDecoration(
          counterText: '',
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
          hintText: '·',
          hintStyle: GoogleFonts.poppins(
            fontSize: 28.0 * widget.scale,
            color: _labelColor.withValues(alpha: 0.4),
          ),
        ),
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        onChanged: widget.onChanged,
      ),
    );
  }
}
