import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../widgets/gradient_button.dart';
import 'package:tryd/src/features/auth/data/auth_repository.dart';
import "../../home/presentation/home_screen.dart";
import '../../notifications/data/real_time_notification_service.dart';
import 'dart:async';
import '../../../../widgets/custom_arrow_icon.dart';
import 'package:tryd/src/features/auth/presentation/controllers/auth_controller.dart';
import 'package:tryd/src/generated/l10n/app_localizations.dart';

class OtpVerificationScreen extends ConsumerStatefulWidget {
  final String email;
  final bool isLogin;
  final Map<String, String>? registrationData;

  const OtpVerificationScreen({
    super.key,
    required this.email,
    this.isLogin = false,
    this.registrationData,
  });

  @override
  ConsumerState<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends ConsumerState<OtpVerificationScreen> {
  static const Color _primaryTextColor = Color(0xFF000000);
  static const Color _labelColor = Color(0xFF8B88B5);
  static const Color _inputTextColor = Color(0xFF221F48);
  static const Color _linkColor = Color(0xFFF83A71);
  static const Color _inputBgColor = Color(0xFFFFFFFF);

  final List<TextEditingController> _otpControllers = List.generate(
    4,
    (index) => TextEditingController(),
  );

  final List<FocusNode> _otpFocusNodes = List.generate(
    4,
    (index) => FocusNode(),
  );

  bool _isVerifying = false;
  bool _isResending = false;

  static const int _timerDuration = 60;
  int _timerRemaining = _timerDuration;
  bool _canResend = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();

    // Auto-focus first OTP field
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _otpFocusNodes[0].requestFocus();
    });

    // Handle backspace on empty fields (onChanged doesn't fire for empty fields)
    for (int i = 1; i < 4; i++) {
      final index = i;
      _otpFocusNodes[index].onKeyEvent = (node, event) {
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.backspace &&
            _otpControllers[index].text.isEmpty) {
          _otpControllers[index - 1].clear();
          _otpFocusNodes[index - 1].requestFocus();
          if (mounted) setState(() {});
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
        // Focus first field
        _otpFocusNodes[0].requestFocus();
        ref.read(realTimeNotificationServiceProvider).showInAppBanner(
          AppLocalizations.of(context)!.otpResentSuccess,
          AppLocalizations.of(context)!.otpResentSubtitle,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.otpResentFailed, style: GoogleFonts.poppins()),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var node in _otpFocusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  Future<void> _handleVerification() async {
    final otp = _getOtpCode();
    if (otp.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.enterCompleteOtp, style: GoogleFonts.poppins()),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    if (_isVerifying) return;
    setState(() => _isVerifying = true);

    try {
      final authController = ref.read(authControllerProvider.notifier);

      if (widget.isLogin) {
        await authController.verifyOtpLogin(widget.email, otp);
      } else if (widget.registrationData != null) {
        await authController.verifyOtp(widget.email, otp);
        await authController.register(
          name: widget.registrationData!['name'] ?? '',
          email: widget.registrationData!['email'] ?? widget.email,
          password: widget.registrationData!['password'] ?? 'TRYD@123',
          phoneNumber: widget.registrationData!['phoneNumber'] ?? '',
        );
      } else {
        await authController.verifyOtpLogin(widget.email, otp);
      }

      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      debugPrint('Verification error: $e');
      if (mounted) {
        String errorMessage = AppLocalizations.of(context)!.verificationFailed;
        if (e is DioException) {
          errorMessage = e.response?.data['message'] ?? e.message ?? 'Network error occurred';
        } else {
          errorMessage = e.toString();
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage, style: GoogleFonts.poppins()),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isVerifying = false);
    }
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
        if (_getOtpCode().length == 4) {
          _handleVerification();
        }
      } else {
        _otpFocusNodes[lastFilledIndex + 1].requestFocus();
      }
      
      if (mounted) setState(() {});
      return;
    }

    if (value.isNotEmpty) {
      if (index < 3) {
        _otpFocusNodes[index + 1].requestFocus();
      } else {
        _otpFocusNodes[index].unfocus();
        _handleVerification();
      }
    }
    
    if (mounted) setState(() {});
  }

  String _getOtpCode() {
    return _otpControllers.map((controller) => controller.text).join();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final screenWidth = size.width;
    final screenHeight = size.height;
    final isTablet = screenWidth > 600;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final l10n = AppLocalizations.of(context)!;

    const double smallScale = 0.80;
    const double mediumScale = 0.90;
    const double largeScale = 0.97;
    const double tabletScale = 1.20;

    final double scale = isTablet
        ? tabletScale
        : screenHeight < 680
            ? smallScale
            : screenHeight < 850
                ? mediumScale
                : largeScale;
    
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
              filterQuality: FilterQuality.high,
              isAntiAlias: true,
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
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(height: 40.0 * scale),
                              _buildLogo(scale),
                              SizedBox(height: 40.0 * scale),
                              _buildTitle(scale, l10n, fontScale),
                              SizedBox(height: 18.0 * scale),
                              _buildSubtitle(scale, l10n, fontScale),
                              SizedBox(height: 20.0 * scale),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 16.0 * scale),
                                child: _buildOtpField(scale, fontScale),
                              ),
                              SizedBox(height: 24.0 * scale),
                              _buildVerifyButton(scale, l10n, fontScale),
                              SizedBox(height: 24.0 * scale),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 16.0 * scale),
                                child: _buildResendSection(scale, l10n, fontScale),
                              ),
                              SizedBox(height: bottomInset > 0 ? bottomInset * 0.3 : 20.0 * scale),
                            ],
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
                child: Container(
                  width: 56.0 * scale,
                  height: 56.0 * scale,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Transform.scale(
                    scaleX: isAr ? 1.0 : -1.0,
                    child: CustomArrowIcon(
                      size: 32.0 * scale,
                      color: const Color(0xFF130F26),
                    ),
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
      l10n.verifyTitle,
      textAlign: TextAlign.center,
      maxLines: 1,
      overflow: TextOverflow.visible,
      softWrap: false,
      style: GoogleFonts.lexendDeca(
        fontSize: 22.0 * scale * fontScale,
        fontWeight: FontWeight.w700,
        height: 1.25,
        color: _primaryTextColor,
      ),
    );
  }

  Widget _buildSubtitle(double scale, AppLocalizations l10n, double fontScale) {
    return Text(
      l10n.verifySubtitle(widget.email),
      textAlign: TextAlign.center,
      style: GoogleFonts.poppins(
        fontSize: 16.0 * scale * fontScale,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: _labelColor,
      ),
    );
  }

  Widget _buildOtpField(double scale, double fontScale) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (int i = 0; i < 4; i++) ...[
            Expanded(child: _buildOtpDigitBox(i, scale, fontScale)),
            if (i < 3) SizedBox(width: 10.0 * scale),
          ],
        ],
      ),
    );
  }

  Widget _buildOtpDigitBox(int index, double scale, double fontScale) {
    return ListenableBuilder(
      listenable: _otpFocusNodes[index],
      builder: (context, child) {
        final isFocused = _otpFocusNodes[index].hasFocus;
        final hasValue = _otpControllers[index].text.isNotEmpty;
        return Container(
          height: 62.0 * scale,
          decoration: BoxDecoration(
            color: _inputBgColor,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: isFocused 
                  ? const Color(0xFF900EBF) 
                  : (hasValue ? const Color(0xFF900EBF).withValues(alpha: 0.2) : Colors.transparent),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                offset: const Offset(0, 4),
                blurRadius: 10,
                spreadRadius: 0,
                color: (isFocused ? const Color(0xFF900EBF) : const Color(0xFFAFA9A9)).withValues(alpha: 0.1),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: child,
        );
      },
      child: TextField(
        controller: _otpControllers[index],
        focusNode: _otpFocusNodes[index],
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        textInputAction: index == 3 ? TextInputAction.done : TextInputAction.next,
        style: GoogleFonts.poppins(
          fontSize: 22.0 * scale * fontScale,
          fontWeight: FontWeight.w600,
          height: 1.5,
          color: _inputTextColor,
        ),
        decoration: const InputDecoration(
          border: InputBorder.none,
          counterText: '',
          contentPadding: EdgeInsets.zero,
        ),
        inputFormatters: [
          LengthLimitingTextInputFormatter(4),
          FilteringTextInputFormatter.digitsOnly,
        ],
        onChanged: (value) => _onOtpDigitChanged(value, index),
        onTap: () {
          _otpControllers[index].selection = TextSelection(
            baseOffset: 0,
            extentOffset: _otpControllers[index].text.length,
          );
        },
      ),
    );
  }

  Widget _buildVerifyButton(double scale, AppLocalizations l10n, double fontScale) {
    return GradientButton(
      text: _isVerifying ? l10n.verifying : l10n.verifyButton,
      textStyle: GoogleFonts.poppins(
        fontSize: 16.0 * scale * fontScale,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
      height: 58.0 * scale,
      onPressed: _isVerifying ? () {} : _handleVerification,
    );
  }

  Widget _buildResendSection(double scale, AppLocalizations l10n, double fontScale) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              l10n.resendText + "  ",
              style: GoogleFonts.poppins(
                fontSize: 16.0 * scale * fontScale,
                fontWeight: FontWeight.w500,
                color: _labelColor,
              ),
            ),
            if (_canResend)
              GestureDetector(
                onTap: _isResending ? null : _handleResend,
                child: Text(
                  _isResending ? l10n.sending : l10n.resendButton,
                  style: GoogleFonts.poppins(
                    fontSize: 16.0 * scale * fontScale,
                    fontWeight: FontWeight.w600,
                    color: _isResending ? _labelColor : _linkColor,
                  ),
                ),
              )
            else
              Text(
                '0:${_timerRemaining.toString().padLeft(2, '0')}',
                style: GoogleFonts.poppins(
                  fontSize: 14.0 * scale * fontScale,
                  fontWeight: FontWeight.w500,
                  color: _labelColor,
                ),
              ),
          ],
        ),
        SizedBox(height: 12.0 * scale),
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 20 * scale, vertical: 8 * scale),
            decoration: BoxDecoration(
              border: Border.all(color: _linkColor.withValues(alpha: 0.3)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              l10n.changeEmail,
              style: GoogleFonts.poppins(
                fontSize: 15.0 * scale * fontScale,
                fontWeight: FontWeight.w600,
                color: _linkColor,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
